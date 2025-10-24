import 'package:flutter/material.dart';
import 'package:paystack_payment/paystack_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const paystack = PaystackPayment();

    return Scaffold(
      appBar: AppBar(title: const Text('Paystack Payment Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            paystack.checkout(
              context: context,
              accessCode: 'ACCESS_CODE_FROM_SERVER',
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
          },
          child: const Text('Pay N1000'),
        ),
      ),
    );
  }
}
