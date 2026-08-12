enum BookingStatus { pending, confirmed, cancelled, completed, expired }

class BookingEntity {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime;
  final String imageUrl;
  final BookingStatus status;
  final double totalAmount;

  BookingEntity({
    required this.id,
    required this.title,
    required this.location,
    required this.dateTime,
    required this.imageUrl,
    required this.status,
    required this.totalAmount,
  });

  bool get isUpcoming => dateTime.isAfter(DateTime.now()) && (status == BookingStatus.confirmed || status == BookingStatus.pending);
}
