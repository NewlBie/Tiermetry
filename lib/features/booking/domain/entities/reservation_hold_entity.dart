enum ReservationHoldStatus { active, released, expired, converted }

class ReservationHoldEntity {
  final String id;
  final String userId;
  final String venueId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final ReservationHoldStatus status;
  final DateTime expiresAt;
  final String? convertedBookingId;

  ReservationHoldEntity({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    required this.expiresAt,
    this.convertedBookingId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
}
