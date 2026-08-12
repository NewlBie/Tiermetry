import 'package:flutter/material.dart';

import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';
import '../../domain/usecases/get_arena_details_uc.dart';
import '../../domain/usecases/get_arenas_uc.dart';
import '../../domain/usecases/get_available_units_uc.dart';

class ArenaCtrl extends ChangeNotifier {
  final GetArenasUC getArenasUC;
  final GetArenaDetailsUC getArenaDetailsUC;
  final GetAvailableUnitsUC getAvailableUnitsUC;

  ArenaCtrl({
    required this.getArenasUC,
    required this.getArenaDetailsUC,
    required this.getAvailableUnitsUC,
  });

  List<ArenaEntity> _arenas = [];
  List<ArenaEntity> get arenas => _arenas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadArenas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _arenas = await getArenasUC();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ArenaDetailsEntity?> loadArenaDetails(String id) async {
    return await getArenaDetailsUC(id);
  }

  Future<List<ArenaDevice>> loadAvailableUnits({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return await getAvailableUnitsUC(
      serviceId: serviceId,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
