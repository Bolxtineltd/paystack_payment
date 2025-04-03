import 'package:flutter_test/flutter_test.dart';
import 'package:paystack_payment/paystack_payment.dart';

void main() {
  test('PaystackPayment initializes with secret key', () {
    final paystack = PaystackPayment(
      secretKey: "sk_test_4ff99bef4ba252eb050bcd80451d50c87e9bdf67",
    );
    expect(
      paystack.secretKey,
      'sk_test_4ff99bef4ba252eb050bcd80451d50c87e9bdf67',
    );
  });
}
