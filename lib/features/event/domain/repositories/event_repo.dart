import '../entities/event_entity.dart';

abstract class EventRepo {
  Future<List<EventEntity>> getEvents();
  Future<List<EventEntity>> getMyRegistrations();
  Future<void> registerForEvent(String eventId);
  Future<bool> isRegistered(String eventId);
}
