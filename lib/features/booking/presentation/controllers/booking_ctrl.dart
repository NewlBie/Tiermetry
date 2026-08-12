import 'package:flutter/foundation.dart';
// Updated to ReservationHoldEntity
import '../../domain/entities/booking_entity.dart';
import 'package:tiermetry/features/booking/domain/entities/reservation_hold_entity.dart';
import '../../domain/repositories/booking_repo.dart';

class BookingCtrl extends ChangeNotifier {
  final BookingRepo repo;

  BookingCtrl(this.repo);

  List<BookingEntity> _bookings = [];
  List<BookingEntity> get bookings => _bookings;

  List<ReservationHoldEntity> _activeHolds = [];
  List<ReservationHoldEntity> get activeHolds => _activeHolds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookings = await repo.getBookings();
      _activeHolds = await repo.getActiveHolds();
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReservationHoldEntity> createReservationHold({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> serviceUnitIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final hold = await repo.createReservationHold(
        venueId: venueId,
        startTime: startTime,
        endTime: endTime,
        serviceUnitIds: serviceUnitIds,
      );
      return hold;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> releaseHold(String holdId) async {
    await repo.releaseHold(holdId);
  }

  Future<void> cancelBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repo.cancelBooking(bookingId);
      await loadBookings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
