import '../entities/arena_details_entity.dart';
import '../repositories/arena_repo.dart';

class GetAvailableUnitsUC {
  final ArenaRepo repository;

  GetAvailableUnitsUC(this.repository);

  Future<List<ArenaDevice>> call({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return await repository.getAvailableUnits(
      serviceId: serviceId,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
