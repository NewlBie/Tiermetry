import 'package:flutter/material.dart';

// Features
import 'package:tiermetry/features/skill/presentation/screens/skill_browser_screen.dart';
import 'package:tiermetry/features/event/presentation/screens/event_browser_screen.dart';

import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';

// Components
import 'package:tiermetry/core/widgets/section_header.dart';

// Modular Sections
import '../widgets/adventure_greeting.dart';
import '../widgets/scroll_gradient_overlay.dart';
import '../widgets/metrics_section.dart';
import '../widgets/live_around_you_section.dart';
import '../widgets/trending_activities_section.dart';
import '../widgets/featured_skills_section.dart';
import '../widgets/upcoming_events_section.dart';
import '../widgets/home_backdrop.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({required this.userName, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _skillCtrl = locator.skillCtrl;
  final _eventCtrl = locator.eventCtrl;
  final _trendingActivityCtrl = locator.trendingActivityCtrl;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    Future.microtask(() {
      _skillCtrl.loadSkills();
      _eventCtrl.loadEvents();
      _trendingActivityCtrl.loadActivities();
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
                      child: Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                    children: const [
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
                          style: TiermetryTypography.title(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: _trendingActivityCtrl,
                        builder: (context, _) {
                          return TrendingActivitiesSection(
                            activities: _trendingActivityCtrl.activities,
                            isLoading: _trendingActivityCtrl.isLoading,
                            onActivitySelected: (id) {
                              _trendingActivityCtrl.updateActivitySelection(
                                id,
                                true,
                              );
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
                      Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: 'Featured Skills',
                          onViewMore:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SkillBrowserScreen(),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: _skillCtrl,
                        builder: (context, _) {
                          return FeaturedSkillsSection(
                            skills: _skillCtrl.skills,
                            isLoading: _skillCtrl.isLoading,
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
                          onViewMore:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EventBrowserScreen(),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      ListenableBuilder(
                        listenable: _eventCtrl,
                        builder: (context, _) {
                          return UpcomingEventsSection(
                            events: _eventCtrl.events,
                            isLoading: _eventCtrl.isLoading,
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
