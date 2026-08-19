import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repo.dart';

class EventCtrl extends ChangeNotifier {
  final EventRepo repo;

  EventCtrl(this.repo);

  List<EventEntity> _events = [];
  List<EventEntity> get events => _events;

  List<EventEntity> _myRegistrations = [];
  List<EventEntity> get myRegistrations => _myRegistrations;

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
    loadEvents(isRefresh: true);
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

  Future<void> registerForEvent(String eventId) async {
    try {
      await repo.registerForEvent(eventId);
      await loadEvents(isRefresh: true); // Refresh to update enrollment counts
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
    super.dispose();
  }
}
