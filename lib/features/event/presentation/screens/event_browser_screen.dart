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
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';
import 'package:tiermetry/features/home/presentation/widgets/upcoming_events_section.dart';

import '../../domain/entities/event_entity.dart';
import '../widgets/showdown_event_card.dart';
import '../widgets/upcoming_event_card.dart';
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
                listenable: Listenable.merge([_eventCtrl, _searchController]),
                builder: (context, _) {
                  final isSearching = _searchController.text.trim().isNotEmpty;
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
                            topPad +
                                TiermetrySpacing.topBarHeight +
                                TiermetrySpacing.sectionGap,
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
                      if (!isSearching) ...[
                        _buildRadarSection(context),
                        _buildHeadlinersSection(context),
                        _buildShowdownsSection(),
                        _buildDealsSection(),
                        _buildTheSceneSection(),
                      ] else ...[
                        _buildSearchResultsSection(),
                      ],
                      
                      // We can keep the loader if it's paginating
                      if (_eventCtrl.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: TiermetrySpacing.screenPadding,
                            ),
                            child: ShimmerLoadingVerticalList(itemCount: 1),
                          ),
                        ),

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
          const ScrollGradientOverlay(),
        ],
      ),
    );
  }

  Widget _buildRadarSection(BuildContext context) {
    if (!_eventCtrl.isLoading && _eventCtrl.radarEvents.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.65).clamp(200.0, 240.0);
    final cardHeight = cardWidth * 1.33; // 3:4 aspect ratio approx
    
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(title: 'Radar', onViewMore: null),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            UpcomingEventsSection(
              events: _eventCtrl.radarEvents,
              isLoading: _eventCtrl.isLoading,
              cardWidth: cardWidth,
              sectionHeight: cardHeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlinersSection(BuildContext context) {
    if (!_eventCtrl.isLoading && _eventCtrl.headlinerEvents.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.82).clamp(250.0, 300.0);
    final cardHeight = cardWidth * 1.25;
    
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(
                title: 'Headliners',
                onViewMore: null,
                tagLabel: 'Sponsored',
              ),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            UpcomingEventsSection(
              events: _eventCtrl.headlinerEvents,
              isLoading: _eventCtrl.isLoading,
              cardWidth: cardWidth,
              sectionHeight: cardHeight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowdownsSection() {
    if (!_eventCtrl.isLoading && _eventCtrl.showdownEvents.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(title: 'Showdowns', onViewMore: null),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            UpcomingEventsSection(
              events: _eventCtrl.showdownEvents,
              isLoading: _eventCtrl.isLoading,
              cardWidth: 280,
              sectionHeight: 310,
              cardBuilder: (context, event) => ShowdownEventCard(event: event),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheSceneSection() {
    final events = _eventCtrl.sceneEvents;

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: TiermetrySpacing.sectionGap),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: TiermetrySpacing.pagePadding,
            child: SectionHeader(
              title: _eventCtrl.isLoading ? 'Searching...' : 'The Scene',
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: TiermetrySpacing.headerToContent),
        ),
        if (_eventCtrl.isLoading && events.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: TiermetrySpacing.md,
                left: TiermetrySpacing.screenPadding,
                right: TiermetrySpacing.screenPadding,
              ),
              child: ShimmerLoadingVerticalList(),
            ),
          )
        else if (_eventCtrl.error != null && events.isEmpty)
          SliverToBoxAdapter(
            child: AppErrorState(
              message: _eventCtrl.error!,
              onRetry: () => _eventCtrl.loadEvents(isRefresh: true),
            ),
          )
        else if (events.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyState(
              message: 'No more events in the scene.',
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
                  padding: const EdgeInsets.only(bottom: TiermetrySpacing.md),
                  child: _EventResultTile(
                    event: events[index],
                    onTap: () => _openEvent(events[index]),
                  ),
                );
              },
            ),
          ),
      ],
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

  Widget _buildSearchResultsSection() {
    if (_eventCtrl.isLoading && _eventCtrl.events.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            top: TiermetrySpacing.md,
            left: TiermetrySpacing.screenPadding,
            right: TiermetrySpacing.screenPadding,
          ),
          child: ShimmerLoadingVerticalList(),
        ),
      );
    }
    
    if (_eventCtrl.error != null && _eventCtrl.events.isEmpty) {
      return SliverToBoxAdapter(
        child: AppErrorState(
          message: _eventCtrl.error!,
          onRetry: () => _eventCtrl.loadEvents(isRefresh: true),
        ),
      );
    }
    
    if (_eventCtrl.events.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          message: 'No events found.',
          onAction: _onClearAll,
          actionLabel: 'Clear Filters',
        ),
      );
    }

    return SliverPadding(
      padding: TiermetrySpacing.pagePadding.copyWith(top: TiermetrySpacing.md),
      sliver: SliverList.builder(
        itemCount: _eventCtrl.events.length,
        itemBuilder: (context, index) {
          final event = _eventCtrl.events[index];
          final isShowdown = _eventCtrl.showdownEvents.any((e) => e.id == event.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: TiermetrySpacing.lg),
            child: AspectRatio(
              aspectRatio: isShowdown ? 280 / 310 : 225 / 300,
              child: isShowdown 
                  ? ShowdownEventCard(event: event) 
                  : UpcomingEventCard(event: event),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
          );
        },
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
          child: Text(
            ('Explore the scene').toUpperCase(),
            style: TiermetryTypography.displayLarge(
              color: TiermetryColors.white,
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
                  Text(
                    (event.title).toUpperCase(),
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
          Text(
            (data.title).toUpperCase(),
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
