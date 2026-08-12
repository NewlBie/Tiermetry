import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/home/presentation/controllers/home_controller.dart';

import '../widgets/adventure_greeting.dart';
import '../widgets/featured_skills_section.dart';
import '../widgets/home_backdrop.dart';
import '../widgets/live_around_you_section.dart';
import '../widgets/metrics_section.dart';
import '../widgets/scroll_gradient_overlay.dart';
import '../widgets/trending_activities_section.dart';
import '../widgets/upcoming_events_section.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({required this.userName, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RefreshRateMixin {
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = HomeController.instance.scrollController;
    Future.microtask(() {
      HomeController.instance.skillCtrl.loadSkills();
      HomeController.instance.eventCtrl.loadEvents();
      HomeController.instance.trendingActivityCtrl.loadActivities();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          const HomeBackdrop(),
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- Greeting ---------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    TiermetrySpacing.screenPadding,
                    topPad + 120,
                    TiermetrySpacing.screenPadding,
                    TiermetrySpacing.xl,
                  ),
                  child: AdventureGreeting(userName: widget.userName),
                ),
              ),

              // --- Metrics Bento Grid ----------------------------------------
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: const Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MetricsSection(),
                            SizedBox(height: TiermetrySpacing.sectionGap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- Live Around You -------------------------------------------
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LiveAroundYouSection(),
                      SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Trending Activities --------------------------------------
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: Text(
                          'Trending Activities',
                          style: TiermetryTypography.title(color: TiermetryColors.white),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: HomeController.instance.trendingActivityCtrl,
                        builder: (context, _) {
                          final ctrl = HomeController.instance.trendingActivityCtrl;
                          return TrendingActivitiesSection(
                            activities: ctrl.activities,
                            isLoading: ctrl.isLoading,
                            onActivitySelected: (String id) {
                              ctrl.updateActivitySelection(id, true);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Featured Skills -------------------------------------------
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: 'Featured Skills',
                          onViewMore: null,
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: HomeController.instance.skillCtrl,
                        builder: (context, _) {
                          final ctrl = HomeController.instance.skillCtrl;
                          return FeaturedSkillsSection(
                            skills: ctrl.skills,
                            isLoading: ctrl.isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Upcoming Events -------------------------------------------
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: 'Upcoming Events',
                          onViewMore: null,
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: HomeController.instance.eventCtrl,
                        builder: (context, _) {
                          final ctrl = HomeController.instance.eventCtrl;
                          return UpcomingEventsSection(
                            events: ctrl.events,
                            isLoading: ctrl.isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: TiermetrySpacing.bottomSafeArea),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- Independent scroll-responsive gradient overlay ---
          // This has its own listener and doesn't rebuild the main tree
          ScrollGradientOverlay(scrollController: _scrollCtrl),
        ],
      ),
    );
  }
}
