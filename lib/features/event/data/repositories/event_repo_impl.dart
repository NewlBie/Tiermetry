import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';
import '../models/event_model.dart';

class EventRepoImpl implements EventRepo {
  final SupabaseClient _supabase;

  EventRepoImpl(this._supabase);

  @override
  Future<List<EventEntity>> getEvents() async {
    // Fetch events and join registration count and venue name
    final response = await _supabase
        .from('events')
        .select('*, venues(name, short_address), enrollments:event_registrations(count)')
        .eq('status', 'published')
        .order('start_time', ascending: true);

    return (response as List).map((json) {
      // Flatten the enrollment count
      final enrollments = (json['enrollments'] as List).isNotEmpty 
          ? (json['enrollments'][0]['count'] as int) 
          : 0;
      json['enrollments'] = enrollments;

      // Extract location from venue if available
      if (json['venues'] != null) {
        json['location'] = json['venues']['short_address'] ?? json['venues']['name'];
      } else {
        json['location'] = 'Online';
      }

      return EventModel.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    try {
      await _supabase.rpc<String>('register_for_event', params: {
        'p_event_id': eventId,
      });
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
  Future<bool> isRegistered(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('event_registrations')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }
}
