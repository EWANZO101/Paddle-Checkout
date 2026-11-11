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

