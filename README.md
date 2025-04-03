# Paystack Payment for Flutter

A Flutter package to integrate Paystack payments into your app with support for multiple payment channels, custom metadata, and split payments. This package uses Paystack’s Checkout API to provide a seamless payment experience via a WebView.

## Features

- **Simple Payment Integration**: Initialize and process payments with minimal setup.
- **Payment Channels**: Restrict payments to specific channels (e.g., `card`, `bank`, `ussd`).
- **Custom Metadata**: Attach additional data to transactions (e.g., order IDs).
- **Split Payments**: Split transaction amounts between your account and subaccounts.
- **Consistent Responses**: Handle success, error.ConcurrentModificationException, and cancel outcomes with a unified `PaystackResponse` model.
- **WebView-Based Checkout**: Displays Paystack’s payment UI securely within your app.

## Installation

### Add to Your Project

### Add to `pubspec.yaml`:

```yaml
paystack_payment: latest version
```

Run `flutter pub get`

### Import in Dart File:

```dart
import 'package:paystack_payment/paystack_payment.dart';
```

### Example Usage


```dart
    final paystack = PaystackPayment(secretKey: 'sk_test_key');
    paystack.pay(
              context: context,
              email: 'user@example.com',
              amount: 1000.00,
              currency: 'NGN',
              onSuccess: (response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Success: ${response.code} - ${response.message} (Ref: ${response.reference})',
                    ),
                  ),
                );
              },
              onError: (response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${response.message}')),
                );
              },
              onCancel: (response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cancelled: ${response.message}')),
                );
              },
            );
```

## Additional information
Visit the paystack documentation for [more information](https://paystack.com/docs/api/transaction)
