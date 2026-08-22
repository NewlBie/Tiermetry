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
    double? minRating,
    Set<String> platforms = const {},
    bool? onlyOpenNow,
    bool? hasOffers,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) => repo.getArenas(
    query: query,
    activity: activity,
    maxDistance: maxDistance,
    maxPriceTier: maxPriceTier,
    minRating: minRating,
    platforms: platforms,
    onlyOpenNow: onlyOpenNow,
    hasOffers: hasOffers,
    sortBy: sortBy,
    page: page,
    pageSize: pageSize,
  );
}
