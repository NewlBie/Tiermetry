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
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bookingId,
    this.holdId,
    this.method,
  });
}
