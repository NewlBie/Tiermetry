import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/features/booking/domain/entities/reservation_hold_entity.dart';

import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repo.dart';

class BookingCtrl extends ChangeNotifier {
  final BookingRepo repo;
  final List<RealtimeChannel> _channels = [];

  BookingCtrl(this.repo) {
    _initRealtime();
  }

  void _initRealtime() {
    final supabase = Supabase.instance.client;

    _subscribeToTable(supabase, 'bookings');
    _subscribeToTable(supabase, 'sessions');
    _subscribeToTable(supabase, 'booking_events');
    _subscribeToTable(supabase, 'booking_items');
    _subscribeToTable(supabase, 'tiermetry_credit_ledger');
    _subscribeToTable(supabase, 'payments');
    _subscribeToTable(supabase, 'reservation_holds');
  }

  void _subscribeToTable(SupabaseClient supabase, String table) {
    final channel =
        supabase.channel('public:$table')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              loadBookings();
            },
          )
          ..subscribe();
    _channels.add(channel);
  }

  @override
  void dispose() {
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    super.dispose();
  }

  List<BookingEntity> _bookings = [];
  List<BookingEntity> get bookings => _bookings;

  List<ReservationHoldEntity> _activeHolds = [];
  List<ReservationHoldEntity> get activeHolds => _activeHolds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await repo.getBookings();
      _activeHolds = await repo.getActiveHolds();
    } catch (e) {
      _error = ErrorMapper.map(e);
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
    _error = null;
    notifyListeners();

    try {
      final hold = await repo.createReservationHold(
        venueId: venueId,
        startTime: startTime,
        endTime: endTime,
        serviceUnitIds: serviceUnitIds,
      );
      return hold;
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
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

  Future<void> checkInBooking(String bookingId, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.checkInBooking(bookingId, code);
      // Refresh immediately so the success state is authoritative even if the
      // realtime event arrives a moment later.
      await loadBookings();
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
