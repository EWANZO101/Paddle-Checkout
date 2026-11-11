# Paddle Checkout for WemX

Accept payments via [Paddle](https://paddle.com) (Merchant of Record) in WemX — card, PayPal, and local payment methods, with Paddle handling global tax/VAT compliance for you.

## Installation

Run this from your WemX installation root:

```bash
curl -fsSL https://raw.githubusercontent.com/EWANZO101/Paddle-Checkout/main/install.sh | bash
```

Then configure the gateway in **Admin → Gateways → Configs** — see [INSTALL.md](INSTALL.md) for that step and the full manual install if you'd rather not pipe a script into bash.

## How it works

- Creates a Paddle transaction via the API when a customer pays.
- Redirects the customer to a dedicated checkout page that loads Paddle.js and opens Paddle's secure payment overlay for that transaction.
- Paddle's webhook notifies WemX when payment completes, which marks the invoice paid and creates the order.
- Supports full and partial refunds via Paddle's Adjustments API, issued directly from WemX.

## Requirements

- A Paddle account (sandbox or live).
- WemX v3.
