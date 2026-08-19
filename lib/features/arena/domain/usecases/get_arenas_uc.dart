import '../entities/arena_entity.dart';
import '../repositories/arena_repo.dart';

class GetArenasUC {
  final ArenaRepo repo;
  GetArenasUC(this.repo);

  Future<List<ArenaEntity>> call({
    String? query,
    String? activity,
    double? maxDistance,
    int? maxPriceTier,
    bool? onlyOpenNow,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) => repo.getArenas(
    query: query,
    activity: activity,
    maxDistance: maxDistance,
    maxPriceTier: maxPriceTier,
    onlyOpenNow: onlyOpenNow,
    sortBy: sortBy,
    page: page,
    pageSize: pageSize,
  );
}
