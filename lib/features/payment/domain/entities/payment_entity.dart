import 'payment_status.dart';

class PaymentEntity {
  final String id;
  final String? bookingId;
  final String? holdId;
  final double amount;
  final PaymentStatus status;
  final String? method;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentEntity({
    required this.id,
    this.bookingId,
    this.holdId,
    required this.amount,
    required this.status,
    this.method,
    required this.createdAt,
    required this.updatedAt,
  });
}
