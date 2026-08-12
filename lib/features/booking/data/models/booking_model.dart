import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  final String userId;
  final String venueId;

  BookingModel({
    required super.id,
    required this.userId,
    required this.venueId,
    required super.status,
    required super.totalAmount,
    required super.title,
    required super.location,
    required super.dateTime,
    required super.imageUrl,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final venue = json['venues'] as Map<String, dynamic>? ?? {};
    
    final statusStr = json['status'] as String? ?? 'pending';
    final status = BookingStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => BookingStatus.pending,
    );

    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      venueId: json['venue_id'] as String? ?? '',
      status: status,
      totalAmount: (json['total_amount'] as num? ?? 0.0).toDouble(),
      title: venue['name'] as String? ?? 'Booking',
      location: venue['short_address'] as String? ?? '',
      dateTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      imageUrl: venue['cover_image'] as String? ?? '',
    );
  }
}
