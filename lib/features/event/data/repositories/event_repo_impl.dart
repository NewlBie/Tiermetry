import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';
import '../models/event_model.dart';

class EventRepoImpl implements EventRepo {
  final SupabaseClient _supabase;

  EventRepoImpl(this._supabase);

  @override
  Future<List<EventEntity>> getEvents({
    String? query,
    String? category,
    int page = 0,
    int pageSize = 20,
  }) async {
    // Fetch events and join registration count and venue name
    const listColumns =
        'id, title, description, image, venue_id, start_time, end_time, registration_start, registration_end, max_participants, registration_type, status, cost, points, tags, perks, venues(name, short_address), enrollments:event_registrations(count)';
    var supabaseQuery = _supabase
        .from('events')
        .select(listColumns)
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
      // Flatten the enrollment count
      final enrollments =
          (json['enrollments'] as List).isNotEmpty
              ? (json['enrollments'][0]['count'] as int)
              : 0;
      json['enrollments'] = enrollments;

      // Extract location from venue if available
      if (json['venues'] != null) {
        json['location'] =
            json['venues']['short_address'] ?? json['venues']['name'];
      } else {
        json['location'] = 'Online';
      }

      return EventModel.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    try {
      await _supabase.rpc<String>(
        'register_for_event',
        params: {'p_event_id': eventId},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('You are already registered for this event.');
      }
      if (e.message.contains('Event is full')) {
        throw Exception('This event is already full.');
      }
      rethrow;
    }
  }

  @override
  Future<List<EventEntity>> getMyRegistrations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch registrations joined with event details and venue info
    final response = await _supabase
        .from('event_registrations')
        .select(
          '*, events(*, venues(name, short_address), enrollments:event_registrations(count))',
        )
        .eq('user_id', userId)
        .order('registered_at', ascending: false);

    return (response as List).map((reg) {
      final eventJson = reg['events'] as Map<String, dynamic>;

      // Flatten the enrollment count inside the nested event
      final enrollments =
          (eventJson['enrollments'] as List).isNotEmpty
              ? (eventJson['enrollments'][0]['count'] as int)
              : 0;
      eventJson['enrollments'] = enrollments;

      // Extract location from venue if available
      if (eventJson['venues'] != null) {
        eventJson['location'] =
            eventJson['venues']['short_address'] ?? eventJson['venues']['name'];
      } else {
        eventJson['location'] = 'Online';
      }

      return EventModel.fromJson(eventJson);
    }).toList();
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
}
