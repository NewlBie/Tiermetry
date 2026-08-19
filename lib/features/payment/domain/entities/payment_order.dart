class PaymentOrder {
  final String orderId;
  final String? sessionToken; // Optional, for web/SDK flows
  final String? paymentUrl; // Optional, for hosted flows
  final double amount;
  final String currency;

  PaymentOrder({
    required this.orderId,
    required this.amount,
    this.sessionToken,
    this.paymentUrl,
    this.currency = 'INR',
  });
}
