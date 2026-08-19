import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/reservation_hold_entity.dart';
import '../../domain/repositories/booking_repo.dart';
import '../models/booking_model.dart';
import '../models/reservation_hold_model.dart';

class BookingRepoImpl implements BookingRepo {
  final SupabaseClient _supabase;

  BookingRepoImpl(this._supabase);

  @override
  Future<List<BookingEntity>> getBookings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('bookings')
        .select(
          '*, venues(*), booking_items(*, service_units(id, name, service_id)), sessions(*), booking_events(*), payments(*)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReservationHoldEntity>> getActiveHolds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('reservation_holds')
        .select('*, venues(*)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => ReservationHoldModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<ReservationHoldEntity> createReservationHold({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> serviceUnitIds,
  }) async {
    try {
      final holdId = await _supabase.rpc<String>(
        'create_reservation_hold_atomic',
        params: {
          'p_venue_id': venueId,
          'p_start_time': startTime.toUtc().toIso8601String(),
          'p_end_time': endTime.toUtc().toIso8601String(),
          'p_service_unit_ids': serviceUnitIds,
        },
      );

      // Fetch the created hold to get expires_at and other authoritative fields
      final response =
          await _supabase
              .from('reservation_holds')
              .select()
              .eq('id', holdId)
              .single();

      return ReservationHoldModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('no longer available')) {
        throw Exception(
          'This slot is no longer available. Please select another rig or time.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> releaseHold(String holdId) async {
    try {
      await _supabase.rpc<void>(
        'release_reservation_hold',
        params: {'p_hold_id': holdId},
      );
    } catch (e) {
      debugPrint('Error releasing hold: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.rpc<void>(
        'cancel_booking',
        params: {'p_booking_id': bookingId},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('already cancelled')) {
        throw Exception('This booking is already cancelled.');
      }
      if (e.message.contains('completed booking')) {
        throw Exception('Cannot cancel a completed booking.');
      }
      rethrow;
    }
  }

  @override
  Future<void> checkInBooking(String bookingId, String code) async {
    try {
      await _supabase.rpc<void>(
        'check_in_booking',
        params: {'p_booking_id': bookingId, 'p_method': 'code', 'p_code': code},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('Invalid check-in code')) {
        throw Exception('Invalid check-in code.');
      }
      if (e.message.contains('Check-in is not open yet')) {
        throw Exception(e.message);
      }
      if (e.message.contains('Check-in window has passed')) {
        throw Exception(e.message);
      }
      rethrow;
    }
  }
}
