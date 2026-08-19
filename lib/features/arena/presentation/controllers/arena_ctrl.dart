import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';

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

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 0;
  static const int _pageSize = 20;

  String? _error;
  String? get error => _error;

  String _query = '';
  String _activity = 'All';
  double? _maxDistance;
  int? _maxPriceTier;
  bool? _onlyOpenNow;
  String? _sortBy;

  Timer? _searchDebounce;

  Future<void> loadArenas({bool isRefresh = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _arenas = [];
    }

    if (!_hasMore) return;

    if (_currentPage == 0) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }

    _error = null;
    notifyListeners();

    try {
      final results = await getArenasUC(
        query: _query,
        activity: _activity,
        maxDistance: _maxDistance,
        maxPriceTier: _maxPriceTier,
        onlyOpenNow: _onlyOpenNow,
        sortBy: _sortBy,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (_currentPage == 0) {
        _arenas = results;
      } else {
        _arenas.addAll(results);
      }
      _currentPage++;
    } catch (e) {
      _error = ErrorMapper.map(e);
      debugPrint('Error loading arenas: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadArenas(isRefresh: true);
    });
  }

  void setActivity(String activity) {
    if (_activity == activity) return;
    _activity = activity;
    loadArenas(isRefresh: true);
  }

  void setFilters({
    double? maxDistance,
    int? maxPriceTier,
    bool? onlyOpenNow,
    String? sortBy,
  }) {
    _maxDistance = maxDistance;
    _maxPriceTier = maxPriceTier;
    _onlyOpenNow = onlyOpenNow;
    _sortBy = sortBy;
    loadArenas(isRefresh: true);
  }

  void clearFilters() {
    _query = '';
    _activity = 'All';
    _maxDistance = null;
    _maxPriceTier = null;
    _onlyOpenNow = null;
    _sortBy = null;
    loadArenas(isRefresh: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
