import 'dart:async';
import '../../domain/entities/payment_order.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/payment_provider.dart';

class DevelopmentPaymentProvider implements PaymentProvider {
  @override
  String get name => 'development';

  // In-memory store for orders to simulate backend behavior
  final Map<String, PaymentStatus> _orderStatus = {};

  @override
  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final orderId = 'DEV_ORDER_${DateTime.now().millisecondsSinceEpoch}';
    _orderStatus[orderId] = PaymentStatus.created;

    return PaymentOrder(
      orderId: orderId,
      amount: amount,
      paymentUrl: 'https://dev.tiermetry.com/pay/$orderId',
    );
  }

  @override
  Future<PaymentStatus> verifyPayment(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _orderStatus[orderId] ?? PaymentStatus.failed;
  }

  @override
  Future<void> openPaymentWorkflow(PaymentOrder order) async {
    // This will be handled by the UI controller which might show a mock payment screen
    // For now, we simulate the user "paying"
    _orderStatus[order.orderId] = PaymentStatus.pending;
  }

  /// Helper for the dev UI to simulate success/failure
  void simulatePaymentResult(String orderId, PaymentStatus status) {
    _orderStatus[orderId] = status;
  }
}
