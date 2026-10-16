import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_accessory.dart';
import '../../domain/entities/booking_cancellation.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/reservation_hold_entity.dart';
import '../../domain/repositories/booking_repo.dart';
import '../models/booking_model.dart';
import '../models/reservation_hold_model.dart';

const _kBookingNetworkTimeout = Duration(seconds: 30);

class BookingRepoImpl implements BookingRepo {
  final SupabaseClient _supabase;

  static const _customerVenueColumns =
      'id, name, cover_image, rating, review_count, address, city, state, pin_code, activity, short_address, hours, is_open, price_tier, is_verified, latitude, longitude, images';
  static const _customerPaymentColumns =
      'id, booking_id, hold_id, amount, status, method, created_at, updated_at';
  static const _customerRefundColumns =
      'id, booking_id, requested_amount, refund_value_amount, refund_percentage, refund_destination, tiergies_restored, tiergies_credited, status, provider, provider_reference, refund_arn, status_description, failure_message, requested_at, processed_at, updated_at';

  BookingRepoImpl(this._supabase);

  @override
  Future<List<BookingEntity>> getBookings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('bookings')
        .select(
          '*, venues($_customerVenueColumns, services(name)), venue_reviews(booking_id), booking_items(id, booking_id, service_unit_id, price_at_booking, created_at, service_units(id, name, service_id)), sessions(id, booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at, checked_in_at, started_at, ended_at, check_in_method, created_at, updated_at), booking_events(id, booking_id, session_id, event_type, actor_type, metadata, created_at), payments($_customerPaymentColumns), booking_refunds($_customerRefundColumns)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BookingEntity>> getCompletedBookingsForVenue(
    String venueId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('bookings')
        .select(
          '*, venues($_customerVenueColumns, services(name)), venue_reviews(booking_id), booking_items(id, booking_id, service_unit_id, price_at_booking, created_at, service_units(id, name, service_id)), sessions(id, booking_id, venue_id, service_unit_id, status, scheduled_start_at, scheduled_end_at, checked_in_at, started_at, ended_at, check_in_method, created_at, updated_at), booking_events(id, booking_id, session_id, event_type, actor_type, metadata, created_at), payments($_customerPaymentColumns), booking_refunds($_customerRefundColumns)',
        )
        .eq('user_id', userId)
        .eq('venue_id', venueId)
        .eq('status', 'completed')
        .order('end_time', ascending: false);

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
        .select(
          'id, user_id, venue_id, start_time, end_time, status, total_amount, expires_at, converted_booking_id, venues(id, name, cover_image, address, city, state, short_address), reservation_hold_items(service_unit_id, service_units(name)), reservation_hold_accessories(service_unit_id, name_at_hold, quantity, included_quantity, billing_type, billing_interval_minutes, unit_price, amount, service_units(name)), payments(order_id, status)',
        )
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
    List<BookingAccessorySelection> accessorySelections = const [],
  }) async {
    try {
      final holdId = await _supabase
          .rpc<String>(
            'create_reservation_hold_atomic',
            params: {
              'p_venue_id': venueId,
              'p_start_time': startTime.toUtc().toIso8601String(),
              'p_end_time': endTime.toUtc().toIso8601String(),
              'p_service_unit_ids': serviceUnitIds,
              'p_accessory_selections':
                  accessorySelections
                      .map((selection) => selection.toJson())
                      .toList(),
            },
          )
          .timeout(_kBookingNetworkTimeout);

      // Fetch the created hold to get expires_at and other authoritative fields
      final response = await _supabase
          .from('reservation_holds')
          .select(
            'id, user_id, venue_id, start_time, end_time, status, total_amount, expires_at, converted_booking_id, venues(id, name), reservation_hold_items(service_unit_id, service_units(name)), reservation_hold_accessories(service_unit_id, name_at_hold, quantity, included_quantity, billing_type, billing_interval_minutes, unit_price, amount, service_units(name))',
          )
          .eq('id', holdId)
          .single()
          .timeout(_kBookingNetworkTimeout);

      return ReservationHoldModel.fromJson(response);
    } on PostgrestException {
      rethrow;
    }
  }

  @override
  Future<void> releaseHold(String holdId) async {
    try {
      await _supabase
          .rpc<void>('release_reservation_hold', params: {'p_hold_id': holdId})
          .timeout(_kBookingNetworkTimeout);
    } catch (e) {
      debugPrint('Error releasing hold: $e');
    }
  }

  @override
  Future<ReservationHoldStatusSnapshot> getHoldStatus(String holdId) async {
    final response = await _supabase
        .rpc<Map<String, dynamic>>(
          'get_reservation_hold_status',
          params: {'p_hold_id': holdId},
        )
        .timeout(_kBookingNetworkTimeout);
    return ReservationHoldStatusSnapshotModel.fromJson(response);
  }

  @override
  Future<BookingCancellationQuote> quoteCancellation(String bookingId) async {
    final response = await _supabase.rpc<Map<String, dynamic>>(
      'quote_booking_cancellation',
      params: {'p_booking_id': bookingId},
    );
    return BookingCancellationQuote.fromJson(response);
  }

  @override
  Future<BookingCancellationResult> cancelBooking(
    String bookingId, {
    required String reason,
    RefundDestination refundDestination =
        RefundDestination.originalPaymentMethod,
  }) async {
    final response = await _supabase.functions.invoke(
      'cancel-booking',
      body: {
        'booking_id': bookingId,
        'reason': reason,
        'refund_destination':
            refundDestination == RefundDestination.tiergies
                ? 'tiergies'
                : 'original_payment_method',
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    if (response.status < 200 || response.status >= 300) {
      throw Exception(data['error'] as String? ?? 'Unable to cancel booking.');
    }
    return BookingCancellationResult.fromJson(data);
  }

  @override
  Future<void> checkInBooking(String bookingId, String code) async {
    try {
      await _supabase.rpc<void>(
        'check_in_booking',
        params: {'p_booking_id': bookingId, 'p_method': 'code', 'p_code': code},
      );
    } on PostgrestException {
      rethrow;
    }
  }

  @override
  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String> highlights = const [],
  }) async {
    await _supabase.rpc<Map<String, dynamic>>(
      'submit_venue_review',
      params: {
        'p_booking_id': bookingId,
        'p_rating': rating,
        'p_comment': comment,
        'p_highlights': highlights,
      },
    );
  }
}
