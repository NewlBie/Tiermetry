import '../entities/event_entity.dart';

abstract class EventRepo {
  Future<List<EventEntity>> getEvents({
    String? query,
    String? category,
    int page = 0,
    int pageSize = 20,
  });
  Future<List<EventEntity>> getMyRegistrations();
  Future<void> registerForEvent(String eventId);
  Future<bool> isRegistered(String eventId);
}
