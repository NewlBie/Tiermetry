import '../entities/event_entity.dart';

abstract class EventRepo {
  Future<List<EventEntity>> getUpcomingEvents();
}
