import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/features/home/presentation/controllers/location_ctrl.dart';
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
  final SupabaseClient supabase;
  final LocationCtrl locationCtrl;

  ArenaCtrl({
    required this.getArenasUC,
    required this.getArenaDetailsUC,
    required this.getAvailableUnitsUC,
    required this.supabase,
    required this.locationCtrl,
  }) {
    locationCtrl.addListener(_onLocationChanged);
    _realtimeChannel =
        supabase
            .channel('arena_discovery_updates')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'venues',
              filter: const PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'is_listed',
                value: true,
              ),
              callback: (_) => _scheduleRealtimeRefresh(),
            )
            .subscribe();
    _availabilityTicker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }

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
  double? _minRating;
  Set<String> _platforms = {};
  bool? _onlyOpenNow;
  bool? _hasOffers;
  String? _sortBy;

  Timer? _searchDebounce;
  Timer? _realtimeDebounce;
  Timer? _availabilityTicker;
  RealtimeChannel? _realtimeChannel;
  bool _hasResolvedLocation = false;

  void _onLocationChanged() {
    final hasLocation = locationCtrl.currentPosition != null;
    if (!hasLocation || _hasResolvedLocation) return;
    _hasResolvedLocation = true;
    if (_arenas.isNotEmpty) loadArenas(isRefresh: true, silent: true);
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_arenas.isNotEmpty) loadArenas(isRefresh: true, silent: true);
    });
  }

  Future<void> loadArenas({bool isRefresh = false, bool silent = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
      if (!silent) _arenas = [];
    }

    if (!_hasMore) return;

    if (_currentPage == 0 && !silent) {
      _isLoading = true;
    } else if (!silent) {
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
        minRating: _minRating,
        platforms: _platforms,
        onlyOpenNow: _onlyOpenNow,
        hasOffers: _hasOffers,
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
    double? minRating,
    Set<String> platforms = const {},
    bool onlyOpenNow = false,
    bool hasOffers = false,
    String? sortBy,
  }) {
    _maxDistance = maxDistance;
    _maxPriceTier = maxPriceTier;
    _minRating = minRating;
    _platforms = Set.from(platforms);
    _onlyOpenNow = onlyOpenNow ? true : null;
    _hasOffers = hasOffers ? true : null;
    _sortBy = sortBy;
    loadArenas(isRefresh: true);
  }

  void clearFilters() {
    _query = '';
    _activity = 'All';
    _maxDistance = null;
    _maxPriceTier = null;
    _minRating = null;
    _platforms = {};
    _onlyOpenNow = null;
    _hasOffers = null;
    _sortBy = null;
    loadArenas(isRefresh: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeDebounce?.cancel();
    _availabilityTicker?.cancel();
    locationCtrl.removeListener(_onLocationChanged);
    final channel = _realtimeChannel;
    if (channel != null) supabase.removeChannel(channel);
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

  Future<DateTime?> loadNextAvailableBookingStart({
    required String serviceId,
    required Duration duration,
    required DateTime fromTime,
  }) {
    return getAvailableUnitsUC.nextAvailableStart(
      serviceId: serviceId,
      duration: duration,
      fromTime: fromTime,
    );
  }
}
