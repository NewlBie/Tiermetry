import '../entities/payment_order.dart';
import '../entities/payment_status.dart';

abstract class PaymentProvider {
  /// Name of the provider (e.g., 'cashfree', 'development')
  String get name;

  /// Initiates a payment order
  Future<PaymentOrder> createOrder({
    required String bookingId,
    required double amount,
    required String userEmail,
    required String userPhone,
  });

  /// Verifies the status of a payment
  Future<PaymentStatus> verifyPayment(String orderId);
  
  /// Opens the payment UI/SDK if applicable
  Future<void> openPaymentWorkflow(PaymentOrder order);
}
