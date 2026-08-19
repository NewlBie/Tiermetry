import '../entities/payment_entity.dart';
import '../entities/payment_order.dart';

abstract class PaymentRepo {
  Future<PaymentOrder> initiatePayment({required String holdId});

  Future<PaymentEntity> verifyAndSyncPayment(String orderId);

  Future<List<PaymentEntity>> getPaymentsForBooking(String bookingId);
}
