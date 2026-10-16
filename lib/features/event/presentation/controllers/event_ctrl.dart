import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';

class EventCtrl extends ChangeNotifier {
  final EventRepo repo;
  final List<RealtimeChannel> _channels = [];
  Timer? _realtimeDebounce;

  EventCtrl(this.repo) {
    _initRealtime();
  }

  void _initRealtime() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    _subscribeToTable(supabase, 'events');
    if (userId != null) {
      _subscribeToTable(supabase, 'event_registrations', userId: userId);
    }
  }

  void _subscribeToTable(SupabaseClient supabase, String table, {String? userId}) {
    final channelName = userId != null ? 'public:events:$table-$userId' : 'public:events:$table';
    final channel =
        supabase.channel(channelName)
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: userId != null
                ? PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'user_id',
                    value: userId,
                  )
                : null,
            callback: (_) => _refreshFromRealtime(),
          )
          ..subscribe();
    _channels.add(channel);
  }

  void _refreshFromRealtime() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
      loadEvents(isRefresh: true);
      if (_myRegistrations.isNotEmpty) {
        loadMyRegistrations();
      }
    });
  }

  List<EventEntity> _events = [];
  List<EventEntity> get events => _applyFilters(_events);

  List<EventEntity> get rawEvents => _events;

  List<EventEntity> _myRegistrations = [];
  List<EventEntity> get myRegistrations => _myRegistrations;

  List<EventEntity> get _filteredEvents => _applyFilters(_events);

  List<EventEntity> get _standardEvents =>
      _filteredEvents.where((e) => e.isStandardEvent).toList();

  List<EventEntity> get _competitionEvents =>
      _filteredEvents.where((e) => !e.isStandardEvent).toList();

  List<EventEntity> get radarEvents => _standardEvents.take(2).toList();

  List<EventEntity> get headlinerEvents =>
      _standardEvents
          .where(
            (e) =>
                e.points >= 150 || e.cost != 'Free' || e.title.contains('Pro'),
          )
          .toList();

  List<EventEntity> get showdownEvents => _competitionEvents;

  List<EventEntity> get sceneEvents {
    final excludedIds = {
      ...radarEvents.map((e) => e.id),
      ...headlinerEvents.map((e) => e.id),
    };

    return _standardEvents.where((e) => !excludedIds.contains(e.id)).toList();
  }

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
  String _category = 'All';

  // Filter states
  String _sortBy = 'Date';
  String get sortBy => _sortBy;

  bool? _isFree;
  bool? get isFree => _isFree;

  bool? _isOnline;
  bool? get isOnline => _isOnline;

  bool _registrationOpen = false;
  bool get registrationOpen => _registrationOpen;

  Timer? _searchDebounce;

  Future<void> loadEvents({bool isRefresh = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
      _events = [];
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
      final results = await repo.getEvents(
        query: _query,
        category: _category,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (results.length < _pageSize) {
        _hasMore = false;
      }

      if (_currentPage == 0) {
        _events = results;
      } else {
        _events.addAll(results);
      }
      _currentPage++;
    } catch (e) {
      _error = ErrorMapper.map(e);
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadEvents(isRefresh: true);
    });
  }

  void setCategory(String category) {
    if (_category == category) return;
    _category = category;
    loadEvents(isRefresh: true);
  }

  void clearFilters() {
    _query = '';
    _category = 'All';
    _sortBy = 'Date';
    _isFree = null;
    _isOnline = null;
    _registrationOpen = false;
    loadEvents(isRefresh: true);
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    notifyListeners();
  }

  void setIsFree(bool? val) {
    if (_isFree == val) return;
    _isFree = val;
    notifyListeners();
  }

  void setIsOnline(bool? val) {
    if (_isOnline == val) return;
    _isOnline = val;
    notifyListeners();
  }

  void setRegistrationOpen(bool val) {
    if (_registrationOpen == val) return;
    _registrationOpen = val;
    notifyListeners();
  }

  int get activeFilterCount {
    int count = 0;
    if (_sortBy != 'Date') count++;
    if (_isFree != null) count++;
    if (_isOnline != null) count++;
    if (_registrationOpen) count++;
    return count;
  }

  List<EventEntity> _applyFilters(List<EventEntity> source) {
    List<EventEntity> filtered = List.from(source);

    // Explore should surface active/upcoming events rather than stale past ones.
    filtered = filtered.where((e) => !e.isCompleted).toList();

    // Apply category filter
    if (_category != 'All') {
      if (_category == 'Competitions' || _category == 'Tournaments') {
        filtered =
            filtered.where((e) {
              return e.tags.any(
                    (t) =>
                        t.toLowerCase() == 'tournament' ||
                        t.toLowerCase() == 'competitive',
                  ) ||
                  e.title.toLowerCase().contains('clash') ||
                  e.title.toLowerCase().contains('cup');
            }).toList();
      } else if (_category == 'Community') {
        filtered =
            filtered
                .where(
                  (e) => e.tags.any(
                    (t) =>
                        t.toLowerCase() == 'community' ||
                        t.toLowerCase() == 'casual',
                  ),
                )
                .toList();
      }
    }

    if (_isFree != null) {
      if (_isFree!) {
        filtered =
            filtered.where((e) => e.cost.toLowerCase() == 'free').toList();
      } else {
        filtered =
            filtered.where((e) => e.cost.toLowerCase() != 'free').toList();
      }
    }

    if (_isOnline != null) {
      if (_isOnline!) {
        filtered =
            filtered
                .where(
                  (e) =>
                      e.location.toLowerCase().contains('online') ||
                      e.tags.any((t) => t.toLowerCase() == 'online'),
                )
                .toList();
      } else {
        filtered =
            filtered
                .where(
                  (e) =>
                      !e.location.toLowerCase().contains('online') &&
                      !e.tags.any((t) => t.toLowerCase() == 'online'),
                )
                .toList();
      }
    }

    if (_registrationOpen) {
      filtered = filtered.where((e) => e.isRegistrationOpen).toList();
    }

    if (_sortBy == 'Date') {
      filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    } else if (_sortBy == 'Prize Pool') {
      filtered.sort((a, b) => b.points.compareTo(a.points));
    }

    return filtered;
  }

  Future<void> loadMyRegistrations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myRegistrations = await repo.getMyRegistrations();
    } catch (e) {
      _error = ErrorMapper.map(e);
      debugPrint('Error loading registrations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> registerForEvent(EventRegistrationRequest request) async {
    try {
      final registrationId = await repo.registerForEvent(request);
      await loadEvents(isRefresh: true); // Refresh to update enrollment counts
      return registrationId;
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  Future<bool> checkRegistrationStatus(String eventId) async {
    return await repo.isRegistered(eventId);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeDebounce?.cancel();
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    super.dispose();
  }
}
