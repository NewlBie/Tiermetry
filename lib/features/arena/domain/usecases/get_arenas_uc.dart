import '../entities/arena_entity.dart';
import '../repositories/arena_repo.dart';

class GetArenasUC {
  final ArenaRepo repo;
  GetArenasUC(this.repo);

  Future<List<ArenaEntity>> call() => repo.getArenas();
}
