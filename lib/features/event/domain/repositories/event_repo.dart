import '../entities/event_entity.dart';

abstract class EventRepo {
  Future<List<EventEntity>> getEvents();
  Future<void> registerForEvent(String eventId);
  Future<bool> isRegistered(String eventId);
}
