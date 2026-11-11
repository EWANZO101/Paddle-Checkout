    Route::get('/payments/paddle/checkout', [Client\PaymentsController::class, 'paddleCheckout'])->name('payments.paddle.checkout');
