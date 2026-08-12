import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_status.dart';

class PaymentModel extends PaymentEntity {
  PaymentModel({
    required super.id,
    required super.amount,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.bookingId,
    super.holdId,
    super.method,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      holdId: json['hold_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.created,
      ),
      method: json['method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
