import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';
import '../models/event_model.dart';

class EventRepoImpl implements EventRepo {
  final SupabaseClient _supabase;

  EventRepoImpl(this._supabase);

  static const _venueColumns =
      'id, name, address, short_address, cover_image, rating, capacity, activity, hours, is_open, price_tier, is_verified, latitude, longitude';

  static const _safeVenueColumns =
      'id, name, address, short_address, cover_image, rating, activity, hours, is_open, price_tier, is_verified, latitude, longitude';

  static const _baseListColumns =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, venues($_venueColumns), enrollments:event_registrations(count)';

  static const _baseListColumnsNoEnrollments =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, venues($_venueColumns)';

  static const _detailsListColumns =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, organizer, game, platform, rules, format, schedule, bracket_url, rewards, faqs, contact_email, venues($_venueColumns), enrollments:event_registrations(count)';

  static const _detailsListColumnsNoEnrollments =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, organizer, game, platform, rules, format, schedule, bracket_url, rewards, faqs, contact_email, venues($_venueColumns)';

  static const _safeBaseListColumnsNoEnrollments =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, venues($_safeVenueColumns)';

  static const _safeDetailsListColumnsNoEnrollments =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, organizer, game, platform, rules, format, schedule, bracket_url, rewards, faqs, contact_email, venues($_safeVenueColumns)';

  static const _detailsListColumnsNoVenue =
      'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, location, points, tags, perks, organizer, game, platform, rules, format, schedule, bracket_url, rewards, faqs, contact_email';

  @override
  Future<List<EventEntity>> getEvents({
    String? query,
    String? category,
    int page = 0,
    int pageSize = 20,
  }) async {
    final candidates = <String>[
      _detailsListColumns,
      _detailsListColumnsNoEnrollments,
      _safeDetailsListColumnsNoEnrollments,
      _baseListColumns,
      _baseListColumnsNoEnrollments,
      _safeBaseListColumnsNoEnrollments,
      _detailsListColumnsNoVenue,
    ];

    PostgrestException? lastError;
    for (final columns in candidates) {
      try {
        return await _getEventsWithColumns(
          columns: columns,
          query: query,
          category: category,
          page: page,
          pageSize: pageSize,
        );
      } on PostgrestException catch (e) {
        lastError = e;
        if (_isRetriableEventListError(e)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return const [];
  }

  bool _isEnrollmentAccessIssue(PostgrestException e) {
    final message = e.message.toLowerCase();
    return message.contains('event_registrations') &&
        (message.contains('permission') ||
            message.contains('policy') ||
            message.contains('not allowed') ||
            e.code == '42501');
  }

  bool _isRetriableEventListError(PostgrestException e) {
    return e.code == '42703' || _isEnrollmentAccessIssue(e);
  }

  int _parseEnrollmentCount(Map<String, dynamic> json) {
    final raw = json['enrollments'];
    if (raw is List && raw.isNotEmpty) {
      final count = raw.first;
      if (count is Map<String, dynamic>) {
        return count['count'] as int? ?? 0;
      }
    }
    if (raw is int) {
      return raw;
    }
    return 0;
  }

  Future<List<EventEntity>> _getEventsWithColumns({
    required String columns,
    required int page,
    required int pageSize,
    String? query,
    String? category,
  }) async {
    var supabaseQuery = _supabase
        .from('events')
        .select(columns)
        .eq('status', 'published');

    if (query != null && query.isNotEmpty) {
      supabaseQuery = supabaseQuery.or(
        'title.ilike.%$query%,description.ilike.%$query%',
      );
    }

    if (category != null && category != 'All') {
      if (category == 'Deals') {
        supabaseQuery = supabaseQuery.ilike('cost', '%free%');
      } else if (category == 'Redeem') {
        supabaseQuery = supabaseQuery.gt('points', 0);
      } else if (category == 'Online') {
        // Events are online if they have no venue OR the venue is explicitly marked as online
        supabaseQuery = supabaseQuery.or(
          'venue_id.is.null,venues.short_address.ilike.%online%',
        );
      }
    }

    final response = await supabaseQuery
        .order('start_time', ascending: true)
        .order('id', ascending: true) // Stable secondary sort
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List).map((json) {
      json['enrollments'] = _parseEnrollmentCount(json as Map<String, dynamic>);

      _flattenVenue(json);

      return EventModel.fromJson(json);
    }).toList();
  }

  @override
  Future<String> registerForEvent(EventRegistrationRequest request) async {
    try {
      final registrationId = await _supabase.rpc<String>(
        'register_for_event',
        params: {
          'p_event_id': request.eventId,
          'p_registration_kind': request.registrationKind,
          'p_attendee_name': request.attendeeName,
          'p_attendee_email': request.attendeeEmail,
          'p_attendee_phone': request.attendeePhone,
          'p_team_name': request.teamName,
          'p_participants': request.participants,
          'p_rules_accepted': request.rulesAccepted,
          'p_payment_method': request.paymentMethod,
          'p_payment_status': request.paymentStatus,
          'p_amount_label': request.amountLabel,
        },
      );
      return registrationId;
    } on PostgrestException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('You are already registered for this event.');
      }
      if (e.message.contains('Event is full')) {
        throw Exception('This event is already full.');
      }
      if (e.code != '42883') rethrow;

      final registrationId = await _supabase.rpc<String>(
        'register_for_event',
        params: {'p_event_id': request.eventId},
      );
      return registrationId;
    }
  }

  @override
  Future<List<EventEntity>> getMyRegistrations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final candidates = <String>[
      '*, events(*, venues($_venueColumns), enrollments:event_registrations(count))',
      '*, events(*, venues($_safeVenueColumns), enrollments:event_registrations(count))',
      '*, events(*, venues($_safeVenueColumns))',
      '*, events(*)',
    ];

    PostgrestException? lastError;
    for (final columns in candidates) {
      try {
        final response = await _supabase
            .from('event_registrations')
            .select(columns)
            .eq('user_id', userId)
            .order('registered_at', ascending: false);
        return _mapMyRegistrations(response as List);
      } on PostgrestException catch (e) {
        lastError = e;
        if (_isRetriableEventListError(e)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return const [];
  }

  List<EventEntity> _mapMyRegistrations(List<dynamic> response) {
    return response.map((reg) {
      final eventJson = reg['events'] as Map<String, dynamic>;

      // Flatten the enrollment count inside the nested event
      final rawEnrollments = eventJson['enrollments'];
      final enrollments =
          rawEnrollments is List && rawEnrollments.isNotEmpty
              ? (rawEnrollments[0]['count'] as int? ?? 0)
              : rawEnrollments is int
              ? rawEnrollments
              : 0;
      eventJson['enrollments'] = enrollments;

      _flattenVenue(eventJson);

      eventJson['user_registration_id'] = reg['id'];
      eventJson['user_registration_kind'] = reg['registration_kind'];
      eventJson['user_registration_status'] = reg['status'];
      eventJson['user_payment_status'] = reg['payment_status'];
      eventJson['user_payment_method'] = reg['payment_method'];
      eventJson['user_team_name'] = reg['team_name'];
      eventJson['user_participants'] = reg['participants'];

      return EventModel.fromJson(eventJson);
    }).toList();
  }

  void _flattenVenue(Map<String, dynamic> json) {
    final venue = json['venues'];
    if (venue is Map<String, dynamic>) {
      json['venue_name'] = venue['name'];
      json['venue_address'] =
          venue['address'] ?? venue['short_address'] ?? venue['name'];
      json['venue_image'] = venue['cover_image'];
      json['venue_rating'] = venue['rating'];
      json['venue_capacity'] = venue['capacity'];
      json['venue_activity'] = venue['activity'];
      json['venue_hours'] = venue['hours'];
      json['venue_is_open'] = venue['is_open'];
      json['venue_price_tier'] = venue['price_tier'];
      json['venue_is_verified'] = venue['is_verified'];
      json['venue_latitude'] = venue['latitude'];
      json['venue_longitude'] = venue['longitude'];
      json['location'] =
          venue['short_address'] ?? venue['address'] ?? venue['name'];
    } else {
      final location = json['location'] as String?;
      json['location'] =
          location != null && location.trim().isNotEmpty ? location : 'Online';
    }
  }

  @override
  Future<bool> isRegistered(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response =
        await _supabase
            .from('event_registrations')
            .select('id')
            .eq('event_id', eventId)
            .eq('user_id', userId)
            .maybeSingle();

    return response != null;
  }

  @override
  Future<void> checkInEventRegistration({
    required String registrationId,
    required String code,
  }) async {
    try {
      await _supabase.rpc<void>(
        'check_in_event_registration',
        params: {'p_registration_id': registrationId, 'p_code': code},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('Invalid event check-in code')) {
        throw Exception('Invalid event check-in code.');
      }
      if (e.message.contains('Registration can no longer be checked in')) {
        throw Exception(e.message);
      }
      rethrow;
    }
  }
}
