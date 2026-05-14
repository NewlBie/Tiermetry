import '../models/booking_model.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repo.dart';

abstract class BookingSource {
  Future<List<BookingModel>> getBookings();
}

class BookingSourceImpl implements BookingSource {
  @override
  Future<List<BookingModel>> getBookings() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      BookingModel(
        title: "Indie Music Festival",
        location: "City Park Amphitheater",
        dateTime: DateTime(2025, 9, 12, 18),
        imageUrl: "https://placehold.co/600x400/1a1a1a/ffffff?text=Indie+Fest",
      ),
      BookingModel(
        title: "Pro Gaming Tournament",
        location: "Esports Arena Central",
        dateTime: DateTime(2025, 9, 20, 14),
        imageUrl: "https://placehold.co/600x400/3a1a3a/ffffff?text=Gaming+Tournament",
      ),
      BookingModel(
        title: "Art & Design Expo",
        location: "Downtown Convention Hall",
        dateTime: DateTime(2025, 10, 5, 10),
        imageUrl: "https://placehold.co/600x400/1a3a3a/ffffff?text=Art+Expo",
      ),
    ];
  }
}

class BookingRepoImpl implements BookingRepo {
  final BookingSource source;
  BookingRepoImpl(this.source);

  @override
  Future<List<BookingEntity>> getBookings() async {
    return await source.getBookings();
  }
}
