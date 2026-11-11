# Installing Paddle Checkout

Unlike most WemX gateways, this one needs a few small additions to your WemX core files, not just a drop-in extension folder. That's because **Paddle Billing's checkout is a client-side overlay (Paddle.js), not a plain hosted page you can redirect to** — Paddle has no "checkout page URL" to send customers to directly, so this extension ships a small page of its own that loads Paddle.js and opens the overlay.

## Quick install

Run this from your WemX installation root (the directory containing `artisan`):

```bash
curl -fsSL https://raw.githubusercontent.com/EWANZO101/Paddle-Checkout/main/install.sh | bash
```

It does exactly steps 1–4 below for you — backing up `routes/web.php` and `PaymentsController.php` before editing them, and safe to re-run (it skips anything already in place). You still need step 5 (configuring the gateway in WemX admin).

Prefer to do it by hand, or want to see exactly what the script changes first? Read [`install.sh`](install.sh) or follow the manual steps below.

## Manual install

### 1. Add the extension

Extract this repo so you end up with:

```
extensions/Gateways/PaddleCheckout/Gateway.php
```

### 2. Add the checkout view

Copy `resources/paddle-checkout.blade.php` from this repo to:

```
resources/client_area/default/payments/paddle-checkout.blade.php
```

(If you're on a custom theme, use that theme's `payments/` folder instead of `default/`.)

### 3. Add one route

Open `routes/web.php`, find the `Route::middleware(['web'])->group(...)` block (it already contains `payments.gateway.webhook` and `payments.gateway.callback`), and add this line inside it:

```php
Route::get('/payments/paddle/checkout', [Client\PaymentsController::class, 'paddleCheckout'])->name('payments.paddle.checkout');
```

### 4. Add one controller method

Open `app/Http/Controllers/Client/PaymentsController.php` and add this method anywhere inside the `PaymentsController` class (e.g. just above the existing `pay()` method):

```php
/**
 * Paddle's "default payment link" destination. Paddle appends ?_ptxn={transaction_id}
 * to this URL once a transaction is created, and Paddle.js (embedded in the view)
 * reads that parameter to open the actual checkout overlay for the customer.
 */
public function paddleCheckout(Request $request)
{
    $transactionId = (string) $request->query('_ptxn', '');

    $payment = $transactionId !== ''
        ? Payment::where('transaction_id', $transactionId)->first()
        : null;

    abort_if(! $payment, 404);

    $gatewayConfig = $payment->gatewayConfig;

    abort_if(! $gatewayConfig, 404);

    return view('theme::payments.paddle-checkout', [
        'payment' => $payment,
        'transactionId' => $transactionId,
        'sandbox' => (string) $gatewayConfig->config('sandbox', '0') === '1',
        'clientSideToken' => $gatewayConfig->config('client_side_token'),
        'callbackUrl' => route('payments.gateway.callback', [
            'webhook_id' => $gatewayConfig->webhook_id,
            'payment_token' => $payment->token,
        ]),
    ]);
}
```

`Payment`, `GatewayConfig`, and `Request` should already be imported at the top of this controller — if not, add:

```php
use App\Models\GatewayConfig;
use App\Models\Payment;
use Illuminate\Http\Request;
```

### 5. Configure the gateway in WemX

1. **Admin → Gateways → Configs** → create a new config for "Paddle Checkout".
2. Fill in:
   - **Paddle API Key** — Paddle Dashboard → Developer Tools → Authentication.
   - **Client-side Token** — same page, under "Client-side tokens" (a separate, publicly-safe token — not the API Key).
   - **Sandbox Mode** — enable while testing with a Paddle sandbox account.
3. Save, then copy the webhook URL. If your WemX admin doesn't show a webhook URL preview on the gateway edit page, it follows this pattern:
   ```
   https://your-domain.com/gateways/webhooks/{webhook_id}
   ```
   where `{webhook_id}` is whatever you set the "Webhook ID" field to when creating the config.
4. In Paddle Dashboard → Developer Tools → Notifications → New destination, paste that URL, subscribe to the `transaction.completed` event, and copy the destination's secret key back into the **Notification Secret Key** field in WemX.

That's it — you do **not** need to set a default payment link / checkout URL in Paddle's dashboard yourself. The gateway configures that automatically via the API the first time a customer pays.

## Verifying it works

1. Create a cheap test package and attempt checkout as a customer (not while logged in as staff/admin — staff accounts don't get a storefront cart in WemX).
2. You should land on a brief "Preparing your payment..." page, then Paddle's checkout overlay should appear.
3. Complete payment with a [Paddle sandbox test card](https://developer.paddle.com/concepts/payment-methods/credit-debit-card#test-cards) if Sandbox Mode is on.
4. The order should appear in **Admin → Orders** once Paddle's webhook fires (usually within a few seconds).

## Troubleshooting

- **Nothing shows up in Orders after "payment is being processed"** — check the transaction's status directly via Paddle's API/dashboard. If it's stuck in `draft` with no payment attempts, the checkout overlay never actually opened — re-check steps 2–4 above (the view file and route are the most commonly missed pieces).
- **"transaction_default_checkout_url_not_set" error** — this shouldn't happen since the gateway sets it automatically, but if your API key lacks permission to change account settings, set it manually in Paddle Dashboard → Checkout → Checkout settings to your `/payments/paddle/checkout` URL.
