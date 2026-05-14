import '../entities/booking_entity.dart';

abstract class BookingRepo {
  Future<List<BookingEntity>> getBookings();
}
