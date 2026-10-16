import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/services/analytics_service.dart';
import 'package:tiermetry/features/booking/domain/entities/booking_accessory.dart';
import 'package:tiermetry/features/booking/domain/entities/reservation_hold_entity.dart';

import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/booking_cancellation.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repo.dart';

class BookingCtrl extends ChangeNotifier {
  final BookingRepo repo;
  final List<RealtimeChannel> _channels = [];
  StreamSubscription<AuthState>? _authSubscription;
  String? _realtimeUserId;

  BookingCtrl(this.repo) {
    final supabase = Supabase.instance.client;
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      unawaited(_ensureRealtime());
    });
    unawaited(_ensureRealtime());
  }

  Future<void> _ensureRealtime() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (_realtimeUserId == userId && _channels.isNotEmpty) return;

    for (final channel in _channels) {
      await channel.unsubscribe();
    }
    _channels.clear();
    _realtimeUserId = userId;
    if (userId == null) {
      _bookings = [];
      _activeHolds = [];
      notifyListeners();
      return;
    }

    _subscribeToTable(supabase, 'bookings', userId);
    _subscribeToTable(supabase, 'tiermetry_credit_ledger', userId);
    _subscribeToTable(supabase, 'reservation_holds', userId);
    _subscribeToTable(supabase, 'booking_refunds', userId);
  }

  void _subscribeToTable(SupabaseClient supabase, String table, String userId) {
    final channel =
        supabase.channel('public:$table-$userId')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
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
    _authSubscription?.cancel();
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
    await _ensureRealtime();
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

  Future<BookingEntity?> getReviewableBookingForVenue(String venueId) async {
    final bookings = await repo.getCompletedBookingsForVenue(venueId);
    if (bookings.isEmpty) return null;

    for (final booking in bookings) {
      if (!booking.hasReview) return booking;
    }
    return bookings.first;
  }

  Future<ReservationHoldEntity> createReservationHold({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> serviceUnitIds,
    List<BookingAccessorySelection> accessorySelections = const [],
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
        accessorySelections: accessorySelections,
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

  Future<ReservationHoldStatusSnapshot> getHoldStatus(String holdId) {
    return repo.getHoldStatus(holdId);
  }

  Future<BookingCancellationQuote> quoteCancellation(String bookingId) {
    return repo.quoteCancellation(bookingId);
  }

  Future<BookingCancellationResult> cancelBooking(
    String bookingId, {
    required String reason,
    RefundDestination refundDestination = RefundDestination.tiergies,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repo.cancelBooking(
        bookingId,
        reason: reason,
        refundDestination: refundDestination,
      );
      unawaited(AnalyticsService.instance.logEvent('booking_cancelled', {
        'booking_id': bookingId,
        'reason': reason,
        'refund_status': result.refundStatus,
        'refund_amount': result.refundAmount,
      }));
      await loadBookings();
      return result;
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
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

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String> highlights = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repo.submitReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        highlights: highlights,
      );
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
