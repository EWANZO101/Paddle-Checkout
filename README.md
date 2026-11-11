# Paddle Checkout for WemX

Accept payments via [Paddle](https://paddle.com) (Merchant of Record) in WemX — card, PayPal, and local payment methods, with Paddle handling global tax/VAT compliance for you.

## Installation

1. Extract this zip into your WemX installation's `extensions/Gateways/` directory, so you end up with `extensions/Gateways/PaddleCheckout/Gateway.php`.
2. In WemX Admin → Gateways → Configs, create a new config for "Paddle Checkout".
3. Fill in:
   - **Paddle API Key** — Paddle Dashboard → Developer Tools → Authentication.
   - **Client-side Token** — same page, under "Client-side tokens" (a separate, publicly-safe token, not the API Key).
   - **Sandbox Mode** — enable while testing with a Paddle sandbox account.
4. Save, then copy the **Webhook URL** shown on the config edit page.
5. In Paddle Dashboard → Developer Tools → Notifications → New destination, paste that URL, subscribe to the `transaction.completed` event, and copy the destination's secret key back into the **Notification Secret Key** field in WemX.

That's it — WemX automatically configures Paddle's "default payment link" for you via the API the first time a payment is attempted, so there's no manual Paddle Dashboard checkout-URL setup required.

## How it works

- Creates a Paddle transaction via the API when a customer pays.
- Redirects the customer to a dedicated checkout page that loads Paddle.js and opens Paddle's secure payment overlay for that transaction.
- Paddle's webhook notifies WemX when payment completes, which marks the invoice paid and creates the order.
- Supports full and partial refunds via Paddle's Adjustments API, issued directly from WemX.

## Requirements

- A Paddle account (sandbox or live).
- WemX v3.
