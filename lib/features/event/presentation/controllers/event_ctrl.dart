import 'package:flutter/foundation.dart';
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

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await repo.getEvents();
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRegistrations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myRegistrations = await repo.getMyRegistrations();
    } catch (e) {
      debugPrint('Error loading registrations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerForEvent(String eventId) async {
    try {
      await repo.registerForEvent(eventId);
      await loadEvents(); // Refresh to update enrollment counts
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  Future<bool> checkRegistrationStatus(String eventId) async {
    return await repo.isRegistered(eventId);
  }
}
