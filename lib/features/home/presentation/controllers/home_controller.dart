import 'package:flutter/widgets.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/features/event/presentation/controllers/event_ctrl.dart';
import 'package:tiermetry/features/home/presentation/controllers/trending_activity_ctrl.dart';
import 'package:tiermetry/features/skill/presentation/controllers/skill_ctrl.dart';

/// Centralised controller for Home screen to reduce widget rebuilds and share a single ScrollController.
class HomeController {
  HomeController._internal() {
    // Initialise a shared scroll controller.
    scrollController = ScrollController();
    // Expose existing feature controllers from the service locator.
    skillCtrl = locator.skillCtrl;
    eventCtrl = locator.eventCtrl;
    trendingActivityCtrl = locator.trendingActivityCtrl;
  }

  static final HomeController instance = HomeController._internal();

  late final ScrollController scrollController;
  late final SkillCtrl skillCtrl;
  late final EventCtrl eventCtrl;
  late final TrendingActivityCtrl trendingActivityCtrl;

  void dispose() {
    scrollController.dispose();
    // Individual feature controllers are disposed elsewhere.
  }
}
