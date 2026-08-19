import '../entities/arena_details_entity.dart';
import '../entities/arena_entity.dart';

abstract class ArenaRepo {
  Future<List<ArenaEntity>> getArenas({
    String? query,
    String? activity,
    double? maxDistance,
    int? maxPriceTier,
    bool? onlyOpenNow,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  });
  Future<ArenaDetailsEntity?> getArenaDetails(String id);
  Future<List<ArenaDevice>> getAvailableUnits({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  });
}
