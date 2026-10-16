import '../entities/payment_order.dart';
import '../entities/payment_status.dart';

abstract class PaymentProvider {
  /// Name of the provider (e.g., 'cashfree', 'development')
  String get name;

  /// The provider environment expected by this app build, when checkout is
  /// environment-specific. The server must echo the same value before the
  /// client opens an SDK checkout session.
  String? get checkoutEnvironment => null;

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
  Future<PaymentStatus> openPaymentWorkflow(PaymentOrder order);
}
