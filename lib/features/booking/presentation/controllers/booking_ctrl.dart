import 'package:flutter/foundation.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repo.dart';

class BookingCtrl extends ChangeNotifier {
  final BookingRepo repo;

  BookingCtrl(this.repo);

  List<BookingEntity> _bookings = [];
  List<BookingEntity> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookings = await repo.getBookings();
    } catch (e) {
      debugPrint("Error loading bookings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
