import '../entities/booking_accessory.dart';
import '../entities/booking_cancellation.dart';
import '../entities/booking_entity.dart';
import '../entities/reservation_hold_entity.dart';

abstract class BookingRepo {
  Future<List<BookingEntity>> getBookings();
  Future<List<BookingEntity>> getCompletedBookingsForVenue(String venueId);
  Future<List<ReservationHoldEntity>> getActiveHolds();
  Future<ReservationHoldEntity> createReservationHold({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> serviceUnitIds,
    List<BookingAccessorySelection> accessorySelections = const [],
  });

  Future<void> releaseHold(String holdId);
  Future<ReservationHoldStatusSnapshot> getHoldStatus(String holdId);

  Future<BookingCancellationQuote> quoteCancellation(String bookingId);
  Future<BookingCancellationResult> cancelBooking(
    String bookingId, {
    required String reason,
    RefundDestination refundDestination =
        RefundDestination.originalPaymentMethod,
  });
  Future<void> checkInBooking(String bookingId, String code);
  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String> highlights = const [],
  });
}
