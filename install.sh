#!/usr/bin/env bash
#
# Paddle Checkout for WemX — one-line installer
#
#   curl -fsSL https://raw.githubusercontent.com/EWANZO101/Paddle-Checkout/main/install.sh | bash
#
# Run this from your WemX installation root (the directory containing `artisan`).
# Safe to re-run — every step checks whether it's already done first, and any
# file this script edits in place is backed up before it's touched.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/EWANZO101/Paddle-Checkout/main"

say() { printf '  - %s\n' "$1"; }
die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

[ -f "artisan" ] && [ -d "app/Http/Controllers/Client" ] \
    || die "run this from your WemX installation root (the directory containing 'artisan')."

[ -f "app/Http/Controllers/Client/PaymentsController.php" ] \
    || die "app/Http/Controllers/Client/PaymentsController.php not found — is this really a WemX v3 install?"

echo "==> Installing Paddle Checkout gateway for WemX"

# 1. Extension folder
mkdir -p extensions/Gateways/PaddleCheckout
curl -fsSL "$REPO_RAW/Gateway.php" -o extensions/Gateways/PaddleCheckout/Gateway.php
say "extensions/Gateways/PaddleCheckout/Gateway.php"

# 2. Checkout view — respects APP_THEME from .env, falls back to "default"
THEME="default"
if [ -f .env ]; then
    env_theme=$(grep -E '^APP_THEME=' .env | head -n1 | cut -d'=' -f2- | tr -d '"'"'"'"' || true)
    [ -n "$env_theme" ] && THEME="$env_theme"
fi
view_dir="resources/client_area/${THEME}/payments"
mkdir -p "$view_dir"
curl -fsSL "$REPO_RAW/resources/paddle-checkout.blade.php" -o "$view_dir/paddle-checkout.blade.php"
say "$view_dir/paddle-checkout.blade.php"

# 3. Route — idempotent, inserted right after the existing gateway callback route
routes_file="routes/web.php"
if grep -q "payments.paddle.checkout" "$routes_file"; then
    say "route already present in routes/web.php, skipping"
else
    anchor="payments.gateway.callback');"
    grep -qF "$anchor" "$routes_file" \
        || die "could not find the expected anchor line in routes/web.php — add the route manually, see INSTALL.md"

    cp "$routes_file" "${routes_file}.bak.$(date +%s)"
    route_line=$(curl -fsSL "$REPO_RAW/snippets/route.php")

    awk -v anchor="$anchor" -v line="$route_line" '
        { print }
        index($0, anchor) { print line }
    ' "$routes_file" > "${routes_file}.tmp" && mv "${routes_file}.tmp" "$routes_file"
    say "route added to routes/web.php (backup saved alongside it)"
fi

# 4. Controller method — idempotent, inserted right before the existing pay() method
controller_file="app/Http/Controllers/Client/PaymentsController.php"
if grep -q "function paddleCheckout" "$controller_file"; then
    say "paddleCheckout() already present in PaymentsController.php, skipping"
else
    anchor='public function pay($gatewayConfigId, Payment $payment)'
    grep -qF "$anchor" "$controller_file" \
        || die "could not find the expected anchor method in PaymentsController.php — add paddleCheckout() manually, see INSTALL.md"

    cp "$controller_file" "${controller_file}.bak.$(date +%s)"
    method_body=$(curl -fsSL "$REPO_RAW/snippets/paddleCheckout-method.php")

    awk -v anchor="$anchor" -v body="$method_body" '
        index($0, anchor) { print body }
        { print }
    ' "$controller_file" > "${controller_file}.tmp" && mv "${controller_file}.tmp" "$controller_file"
    say "paddleCheckout() added to PaymentsController.php (backup saved alongside it)"

    # Make sure the three classes the new method needs are imported.
    for use_line in \
        'use App\Models\GatewayConfig;' \
        'use App\Models\Payment;' \
        'use Illuminate\Http\Request;'
    do
        grep -qF "$use_line" "$controller_file" || sed -i "/^namespace /a ${use_line}" "$controller_file"
    done
    say "verified required 'use' imports in PaymentsController.php"
fi

# 5. Clear caches so the new route/view/class are picked up immediately
if command -v php >/dev/null 2>&1; then
    php artisan optimize:clear >/dev/null 2>&1 || true
    say "cleared Laravel caches"
fi

echo
echo "==> Done. Next steps:"
echo "   1. Admin -> Gateways -> Configs -> create a config for 'Paddle Checkout'"
echo "   2. Fill in your Paddle API Key, Client-side Token, and Webhook Secret"
echo "   3. Point a Paddle notification destination at the Webhook URL shown there, subscribed to 'transaction.completed'"
echo "   See INSTALL.md for full details: https://github.com/EWANZO101/Paddle-Checkout/blob/main/INSTALL.md"
