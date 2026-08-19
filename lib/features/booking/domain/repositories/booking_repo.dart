import '../entities/booking_entity.dart';
import '../entities/reservation_hold_entity.dart';

abstract class BookingRepo {
  Future<List<BookingEntity>> getBookings();
  Future<List<ReservationHoldEntity>> getActiveHolds();
  Future<ReservationHoldEntity> createReservationHold({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> serviceUnitIds,
  });

  Future<void> releaseHold(String holdId);

  Future<void> cancelBooking(String bookingId);
  Future<void> checkInBooking(String bookingId, String code);
}
