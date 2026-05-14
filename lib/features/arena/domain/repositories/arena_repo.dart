import '../entities/arena_entity.dart';
import '../entities/arena_details_entity.dart';

abstract class ArenaRepo {
  Future<List<ArenaEntity>> getArenas();
  Future<ArenaDetailsEntity?> getArenaDetails(String id);
}
