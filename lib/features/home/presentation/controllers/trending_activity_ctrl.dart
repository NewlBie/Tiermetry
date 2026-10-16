import 'package:flutter/foundation.dart';
import 'package:tiermetry/core/services/api_service.dart';
import 'package:tiermetry/features/home/domain/entities/trending_activity.dart';

class TrendingActivityCtrl extends ChangeNotifier {
  final ApiService apiService;

  TrendingActivityCtrl({required this.apiService});

  List<TrendingActivity> _activities = [];
  List<TrendingActivity> get activities => _activities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await apiService.getTrendingActivities();
    } catch (e) {
      debugPrint('Error loading trending activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateActivitySelection(String activityId, bool selected) {
    _activities =
        _activities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(isSelected: selected);
          }
          return activity;
        }).toList();
    notifyListeners();
  }
}
