import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';
import '../datasources/event_source.dart';

class EventRepoImpl implements EventRepo {
  final EventSource source;

  EventRepoImpl(this.source);

  @override
  Future<List<EventEntity>> getUpcomingEvents() async {
    return await source.getUpcomingEvents();
  }
}
