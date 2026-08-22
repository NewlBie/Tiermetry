import 'dart:async';

import 'package:flutter/material.dart';
import 'package:silky_scroll/silky_scroll.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/arena/presentation/screens/arena_screen.dart';
import 'package:tiermetry/features/event/presentation/screens/event_browser_screen.dart';
import 'package:tiermetry/features/event/presentation/screens/my_events_screen.dart';
import 'package:tiermetry/features/home/presentation/controllers/home_controller.dart';

import '../widgets/adventure_greeting.dart';
import '../widgets/featured_skills_section.dart';
import '../widgets/home_backdrop.dart';
import '../widgets/horizontal_activity_section.dart';
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

  /// Simulated location grant — in production this would come from a
  /// LocationService / permission controller.
  final bool _isLocationGranted = true;

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
    // DO NOT dispose _scrollCtrl here, it is owned by HomeController.instance
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
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                HomeController.instance.skillCtrl.loadSkills(),
                HomeController.instance.eventCtrl.loadEvents(),
                HomeController.instance.trendingActivityCtrl.loadActivities(),
              ]);
            },
            color: TiermetryColors.accentNeonGreen,
            backgroundColor: const Color(0xFF111111),
            child: SilkyCustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
              // --- Greeting ---------------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    TiermetrySpacing.screenPadding,
                    topPad + TiermetrySpacing.topBarHeight + TiermetrySpacing.sectionGap,
                    TiermetrySpacing.screenPadding,
                    TiermetrySpacing.xl,
                  ),
                  child: AdventureGreeting(userName: widget.userName),
                ),
              ),

              // --- New User Welcome Banner ------------------------------------
              // Shown when the user has no events yet (first-time / new user state)
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: HomeController.instance.eventCtrl,
                  builder: (context, _) {
                    final ctrl = HomeController.instance.eventCtrl;
                    final isNewUser = !ctrl.isLoading && ctrl.events.isEmpty;
                    if (!isNewUser) return const SizedBox.shrink();
                    return Padding(
                      padding: TiermetrySpacing.pagePadding,
                      child: _NewUserWelcomeBanner(
                        onDiscoverArenas: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const ArenaScreen()),
                        ),
                        onExploreEvents: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const EventBrowserScreen()),
                        ),
                      ),
                    );
                  },
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
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LiveAroundYouSection(
                        isLocationGranted: _isLocationGranted,
                      ),
                      const SizedBox(height: TiermetrySpacing.sectionGap),
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
                        child: Text(('Trending Activities').toUpperCase(),
                          style: TiermetryTypography.title(
                            color: TiermetryColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable:
                            HomeController.instance.trendingActivityCtrl,
                        builder: (context, _) {
                          final ctrl =
                              HomeController.instance.trendingActivityCtrl;
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
                          if (!ctrl.isLoading && ctrl.skills.isEmpty) {
                            return const AppEmptyState(
                              message:
                                  'No personalized skills available right now.\nCheck back later or explore the full catalog.',
                              icon: Icons.auto_awesome_outlined,
                            );
                          }
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
                      Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: 'Upcoming Events',
                          onViewMore: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const MyEventsScreen(),
                              ),
                            );
                          },
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
                      const SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Recently Visited ------------------------------------------
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HorizontalActivitySection(title: 'Recently Visited'),
                      SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Recently Booked -------------------------------------------
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HorizontalActivitySection(title: 'Recently Booked'),
                      SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
              ),

              // --- Continue Browsing -----------------------------------------
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HorizontalActivitySection(title: 'Continue Browsing'),
                      SizedBox(height: TiermetrySpacing.bottomSafeArea),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),

          // --- Independent scroll-responsive gradient overlay ---
          // This has its own listener and doesn't rebuild the main tree
          const ScrollGradientOverlay(),
        ],
      ),
    );
  }
}

// ─── New User Welcome Banner ──────────────────────────────────────────────────
/// Shown when the user has no events/bookings yet — guides them into the app.
class _NewUserWelcomeBanner extends StatelessWidget {
  final VoidCallback onDiscoverArenas;
  final VoidCallback onExploreEvents;

  const _NewUserWelcomeBanner({
    required this.onDiscoverArenas,
    required this.onExploreEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
        gradient: LinearGradient(
          colors: [
            TiermetryColors.primary.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: TiermetryColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TiermetryColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'WELCOME',
              style: TiermetryTypography.caption(
                color: TiermetryColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.md),

          Text(
            'Your city is waiting.',
            style: TiermetryTypography.title(color: Colors.white),
          ),
          const SizedBox(height: TiermetrySpacing.xs),
          Text(
            'Discover arenas, events, and experiences near you.',
            style: TiermetryTypography.caption(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: TiermetrySpacing.lg),

          // CTA Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDiscoverArenas,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: TiermetryColors.primary,
                      borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                    ),
                    child: Center(
                      child: Text(
                        'Find Arenas',
                        style: TiermetryTypography.action(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TiermetrySpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: onExploreEvents,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Browse Events',
                        style: TiermetryTypography.action(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
