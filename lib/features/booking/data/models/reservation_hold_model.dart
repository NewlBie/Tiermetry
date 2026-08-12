import '../../domain/entities/reservation_hold_entity.dart';

class ReservationHoldModel extends ReservationHoldEntity {
  ReservationHoldModel({
    required super.id,
    required super.userId,
    required super.venueId,
    required super.startTime,
    required super.endTime,
    required super.totalAmount,
    required super.status,
    required super.expiresAt,
    super.convertedBookingId,
  });

  factory ReservationHoldModel.fromJson(Map<String, dynamic> json) {
    return ReservationHoldModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      venueId: json['venue_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: ReservationHoldStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => ReservationHoldStatus.active,
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      convertedBookingId: json['converted_booking_id'] as String?,
    );
  }
}
