import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_image.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_search_hero.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';
import 'package:tiermetry/features/home/presentation/widgets/upcoming_events_section.dart';

import '../../domain/entities/event_entity.dart';
import 'event_details_screen.dart';

class EventBrowserScreen extends StatefulWidget {
  const EventBrowserScreen({super.key});

  @override
  State<EventBrowserScreen> createState() => _EventBrowserScreenState();
}

class _EventBrowserScreenState extends State<EventBrowserScreen>
    with RefreshRateMixin {
  final _eventCtrl = locator.eventCtrl;
  final _searchController = TextEditingController();
  late final ScrollController _scrollCtrl;

  static const List<_DealData> _deals = [
    _DealData(
      title: 'Use points on event passes',
      subtitle: 'Redeem 100 pts on selected tournaments and workshops.',
      label: 'Redeem',
      icon: Icons.stars_rounded,
    ),
    _DealData(
      title: 'Free entry picks',
      subtitle: 'Events with no entry cost and community perks.',
      label: 'Deal',
      icon: Icons.local_offer_rounded,
    ),
    _DealData(
      title: 'Partner spotlight',
      subtitle: 'Sponsored experiences from venues and organizers.',
      label: 'Sponsored',
      icon: Icons.campaign_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() => _eventCtrl.loadEvents());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _eventCtrl.search(_searchController.text.trim());
  }

  void _onClearAll() {
    _searchController.clear();
    _eventCtrl.clearFilters();
  }

  void _openEvent(EventEntity event) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, _) => EventDetailsScreen(event: event),
        transitionsBuilder:
            (context, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
      ),
    );
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
            onRefresh: () => _eventCtrl.loadEvents(isRefresh: true),
            backgroundColor: TiermetryColors.surface,
            color: TiermetryColors.accentNeonGreen,
            edgeOffset: topPad + TiermetrySpacing.topBarHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200 &&
                    !_eventCtrl.isLoadingMore) {
                  _eventCtrl.loadEvents();
                }
                return false;
              },
              child: ListenableBuilder(
                listenable: _eventCtrl,
                builder: (context, _) {
                  final events = _eventCtrl.events;

                  return CustomScrollView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            TiermetrySpacing.screenPadding,
                            topPad + TiermetrySpacing.topBarHeight + TiermetrySpacing.sectionGap,
                            TiermetrySpacing.screenPadding,
                            TiermetrySpacing.lg,
                          ),
                          child: const _ExploreGreeting(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: Padding(
                            padding: TiermetrySpacing.pagePadding,
                            child: AppSearchHero(
                              controller: _searchController,
                              hintText: 'Search events, deals, rewards...',
                              onClear:
                                  _searchController.text.isEmpty
                                      ? null
                                      : _searchController.clear,
                            ),
                          ),
                        ),
                      ),
                      _buildUpcomingEventsSection(),
                      _buildRewardsSection(),

                      // Main Event Section Header
                      const SliverToBoxAdapter(
                        child: SizedBox(height: TiermetrySpacing.sectionGap),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: TiermetrySpacing.pagePadding,
                          child: SectionHeader(
                            title:
                                _eventCtrl.isLoading
                                    ? 'Searching...'
                                    : 'Events',
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: TiermetrySpacing.headerToContent,
                        ),
                      ),

                      if (_eventCtrl.isLoading && events.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (_eventCtrl.error != null && events.isEmpty)
                        SliverToBoxAdapter(
                          child: AppErrorState(
                            message: _eventCtrl.error!,
                            onRetry:
                                () => _eventCtrl.loadEvents(isRefresh: true),
                          ),
                        )
                      else if (events.isEmpty)
                        SliverToBoxAdapter(
                          child: AppEmptyState(
                            message: 'No matching events found.',
                            onAction: _onClearAll,
                            actionLabel: 'Clear Filters',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: TiermetrySpacing.pagePadding,
                          sliver: SliverList.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TiermetrySpacing.md,
                                ),
                                child: _EventResultTile(
                                  event: events[index],
                                  onTap: () => _openEvent(events[index]),
                                ),
                              );
                            },
                          ),
                        ),

                      if (_eventCtrl.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      _buildDealsSection(),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: TiermetrySpacing.bottomSafeArea,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          ScrollGradientOverlay(scrollController: _scrollCtrl),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(title: 'Upcoming Events', onViewMore: null),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            UpcomingEventsSection(
              events: _eventCtrl.events,
              isLoading: _eventCtrl.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    return const SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Padding(
          padding: TiermetrySpacing.pagePadding,
          child: _RewardsCard(),
        ),
      ),
    );
  }

  Widget _buildDealsSection() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(title: 'Deals and sponsored'),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: TiermetrySpacing.listPadding,
                itemCount: _deals.length,
                separatorBuilder:
                    (_, __) => const SizedBox(width: TiermetrySpacing.cardGap),
                itemBuilder: (context, index) {
                  return _DealCard(
                    data: _deals[index],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.08);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreGreeting extends StatelessWidget {
  const _ExploreGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(('Explore the scene').toUpperCase(),
            style: TiermetryTypography.display(
              color: TiermetryColors.white,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Events, deals, sponsored drops, and rewards in one place.',
          style: TiermetryTypography.caption(
            color: TiermetryColors.white.withValues(alpha: 0.62),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard();

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      shadows: TiermetryShadows.highEmphasis,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  TiermetryColors.gradientStart,
                  TiermetryColors.gradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: TiermetryColors.white,
            ),
          ),
          const SizedBox(width: TiermetrySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(('240 points available').toUpperCase(),
                  style: TiermetryTypography.title(
                    color: TiermetryColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Redeem on tickets, passes, and partner deals.',
                  style: TiermetryTypography.caption(
                    color: TiermetryColors.white.withValues(alpha: 0.62),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: TiermetryColors.white),
        ],
      ),
    );
  }
}

class _EventResultTile extends StatelessWidget {
  final EventEntity event;
  final VoidCallback onTap;

  const _EventResultTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        padding: const EdgeInsets.all(10),
        borderRadius: 24,
        shadows:
            TiermetryShadows.venueTile, // Shared logic for horizontal tiles
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Hero(
                tag: event.id,
                child: AppImage(
                  imagePath: event.image ?? 'assets/Hackathon.jpg',
                  width: 82,
                  height: 82,
                ),
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((event.title).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.title(
                      color: TiermetryColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(event.startTime)} - ${event.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.caption(
                      color: TiermetryColors.white.withValues(alpha: 0.52),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AppPill(text: event.cost),
                      const SizedBox(width: TiermetrySpacing.sm),
                      Text(
                        '${event.points} pts',
                        style: TiermetryTypography.caption(
                          color: TiermetryColors.white.withValues(alpha: 0.58),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: TiermetryColors.white.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final _DealData data;

  const _DealCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: 260,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      shadows: TiermetryShadows.highEmphasis,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSurface(
                width: 42,
                height: 42,
                color: TiermetryColors.accentNeonGreen,
                borderRadius: 16,
                border: Border.all(color: Colors.transparent),
                shadows: const [],
                child: Icon(
                  data.icon,
                  color: TiermetryColors.black.withAlpha(220),
                ),
              ),
              const Spacer(),
              AppPill(text: data.label),
            ],
          ),
          const Spacer(),
          Text((data.title).toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.title(
              color: TiermetryColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.caption(
              color: TiermetryColors.white.withValues(alpha: 0.58),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _DealData {
  final String title;
  final String subtitle;
  final String label;
  final IconData icon;

  const _DealData({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
  });
}
