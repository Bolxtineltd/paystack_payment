# Paystack Payment for Flutter

A Flutter helper for completing Paystack Standard Checkout flows inside a resilient in-app WebView. Hand it an access code from your backend and it keeps the payment UI alive while customers hop between your app, their bank app, USSD, or transfer steps.

## Features

- **Access Code Checkout** – Skip client-side initialization: just pass the access code returned by your server.
- **Multi-channel Ready** – Card, bank transfer, and USSD are all supported through Paystack’s hosted checkout.
- **Resilient WebView** – External app launches (banking apps, dialers) no longer close the WebView on return.
- **Unified Responses** – Receive consistent success, cancel, and error callbacks with `PaystackResponse`.
- **Customizable UI** – Override title and colors via `PaystackCheckoutOptions`.

## Installation

Add the dependency to `pubspec.yaml` and fetch packages:

```yaml
dependencies:
  paystack_payment: ^1.0.0
```

```bash
flutter pub get
```

Import where needed:

```dart
import 'package:paystack_payment/paystack_payment.dart';
```

## Usage

```dart
const paystack = PaystackPayment();

await paystack.checkout(
  context: context,
  // Obtain this access code securely from your backend after calling
  // Paystack's initialization endpoint.
  accessCode: 'ACCESS_CODE_FROM_SERVER',
  onSuccess: (response) {
    // Verify the transaction on your backend before fulfilling the order.
    debugPrint('Payment success: ${response.reference}');
  },
  onCancel: (response) {
    debugPrint('Payment cancelled by customer');
  },
  onError: (response) {
    debugPrint('Payment failed: ${response.message}');
  },
  options: const PaystackCheckoutOptions(
    title: 'Complete your payment',
    // successUrl: 'https://example.com/paystack-success',
    // cancelUrl: 'https://example.com/paystack-cancel',
  ),
);
```

Your backend remains responsible for:

1. Initializing the transaction with Paystack.
2. Supplying the access code (or hosted authorization URL) to the app.
3. Verifying the payment once the SDK reports success.

## Additional Information

- Paystack documentation: [https://paystack.com/docs/api/transaction](https://paystack.com/docs/api/transaction)
- For support or issues, open a ticket on the [GitHub issue tracker](https://github.com/Bolxtineltd/paystack_payment/issues).
