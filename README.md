# Paddle Checkout for WemX

Accept payments via [Paddle](https://paddle.com) (Merchant of Record) in WemX — card, PayPal, and local payment methods, with Paddle handling global tax/VAT compliance for you.

## Installation

**See [INSTALL.md](INSTALL.md) for full setup steps.**

Quick version: unlike most WemX gateways, this one needs a small checkout page added to your WemX install, not just the extension folder — because Paddle Billing's checkout is a client-side overlay (Paddle.js), not a hosted page you can redirect to. INSTALL.md walks through all 5 steps, including the one route and one controller method you need to add.

## How it works

- Creates a Paddle transaction via the API when a customer pays.
- Redirects the customer to a dedicated checkout page that loads Paddle.js and opens Paddle's secure payment overlay for that transaction.
- Paddle's webhook notifies WemX when payment completes, which marks the invoice paid and creates the order.
- Supports full and partial refunds via Paddle's Adjustments API, issued directly from WemX.

## Requirements

- A Paddle account (sandbox or live).
- WemX v3.
