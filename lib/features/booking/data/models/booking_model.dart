import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  BookingModel({
    required super.title,
    required super.location,
    required super.dateTime,
    required super.imageUrl,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      dateTime: json['dateTime'] != null 
          ? DateTime.parse(json['dateTime']) 
          : DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
