import '../entities/arena_details_entity.dart';
import '../repositories/arena_repo.dart';

class GetArenaDetailsUC {
  final ArenaRepo repo;
  GetArenaDetailsUC(this.repo);

  Future<ArenaDetailsEntity?> call(String id) => repo.getArenaDetails(id);
}
