class PaystackResponse {
  final String code;
  final String message;
  final String? reference;

  PaystackResponse({required this.code, required this.message, this.reference});

  factory PaystackResponse.success(String reference) {
    return PaystackResponse(
      code: '00',
      message: 'Payment successful',
      reference: reference,
    );
  }

  factory PaystackResponse.error(String message) {
    return PaystackResponse(code: '01', message: message, reference: null);
  }

  factory PaystackResponse.cancelled() {
    return PaystackResponse(
      code: '02',
      message: 'Payment cancelled',
      reference: null,
    );
  }

  @override
  String toString() {
    return 'PaystackResponse(code: $code, message: $message, reference: $reference)';
  }
}
