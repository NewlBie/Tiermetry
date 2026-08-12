import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_search_hero.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';

import '../../domain/entities/event_entity.dart';
import 'event_details_screen.dart';

class EventBrowserScreen extends StatefulWidget {
  const EventBrowserScreen({super.key});

  @override
  State<EventBrowserScreen> createState() => _EventBrowserScreenState();
}

class _EventBrowserScreenState extends State<EventBrowserScreen> with RefreshRateMixin {
  final _eventCtrl = locator.eventCtrl;
  final _searchController = TextEditingController();
  late final ScrollController _scrollCtrl;

  String _query = '';
  String _selectedCategory = 'All';

  static const List<_ExploreCategory> _categories = [
    _ExploreCategory('All', Icons.explore_rounded),
    _ExploreCategory('Events', Icons.confirmation_number_rounded),
    _ExploreCategory('Deals', Icons.local_offer_rounded),
    _ExploreCategory('Redeem', Icons.stars_rounded),
    _ExploreCategory('Online', Icons.wifi_tethering_rounded),
  ];

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
    Future.microtask(_eventCtrl.loadEvents);
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
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<EventEntity> _filteredEvents(List<EventEntity> events) {
    return events.where((event) {
        final haystack =
            [
              event.title,
              event.subtitle,
              event.location,
              event.cost,
              ...event.tags,
            ].join(' ').toLowerCase();

        final matchesQuery = _query.isEmpty || haystack.contains(_query);
        final matchesCategory = switch (_selectedCategory) {
          'Deals' => event.cost.toLowerCase().contains('free'),
          'Redeem' => event.points > 0,
          'Online' => event.location.toLowerCase().contains('online'),
          'Events' => true,
          _ => true,
        };

        return matchesQuery && matchesCategory;
      }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
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
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    TiermetrySpacing.screenPadding,
                    topPad + 120,
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
                      onClear: _query.isEmpty ? null : _searchController.clear,
                    ),
                  ),
                ),
              ),
              _buildCategoryStrip(),
              _buildRewardsSection(),
              _buildEventSections(),
              _buildDealsSection(),
              const SliverToBoxAdapter(
                child: SizedBox(height: TiermetrySpacing.bottomSafeArea),
              ),
            ],
          ),
          ScrollGradientOverlay(scrollController: _scrollCtrl),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.xl),
            Padding(
              padding: TiermetrySpacing.pagePadding,
              child: Text(
                'Browse explore',
                style: TiermetryTypography.title(color: TiermetryColors.white),
              ),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            SizedBox(
              height: 116,
              child: ListView.builder(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: TiermetrySpacing.listInset,
                  right: TiermetrySpacing.listInset,
                  top: 4,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: TiermetrySpacing.lg),
                    child: _ExploreCapsule(
                      category: category,
                      isSelected: _selectedCategory == category.label,
                      onTap:
                          () => setState(
                            () => _selectedCategory = category.label,
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: TiermetrySpacing.sectionGap),
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

  Widget _buildEventSections() {
    return ListenableBuilder(
      listenable: _eventCtrl,
      builder: (context, _) {
        if (_eventCtrl.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: TiermetrySpacing.sectionGap),
              child: Center(
                child: CircularProgressIndicator(color: TiermetryColors.white),
              ),
            ),
          );
        }

        final events = _eventCtrl.events;
        final matches = _filteredEvents(events);
        final featured = [...events]
          ..sort((a, b) => b.points.compareTo(a.points));
        final hasActiveSearch = _query.isNotEmpty || _selectedCategory != 'All';

        return SliverList.list(
          children: [
            const SizedBox(height: TiermetrySpacing.sectionGap),
            RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: TiermetrySpacing.pagePadding,
                    child: SectionHeader(
                      title:
                          hasActiveSearch ? 'Best matches' : 'Events for you',
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.headerToContent),
                  matches.isEmpty
                      ? const AppEmptyState(message: 'No matching events found.')
                      : Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: Column(
                          children:
                              matches
                                  .take(3)
                                  .map(
                                    (event) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: TiermetrySpacing.md,
                                      ),
                                      child: _EventResultTile(
                                        event: event,
                                        onTap: () => _openEvent(event),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                  const SizedBox(height: TiermetrySpacing.sectionGap),
                ],
              ),
            ),
            RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: TiermetrySpacing.pagePadding,
                    child: SectionHeader(title: 'Featured events'),
                  ),
                  const SizedBox(height: TiermetrySpacing.headerToContent),
                  featured.isEmpty
                      ? const AppEmptyState(
                        message: 'No featured events found.',
                      )
                      : SizedBox(
                        height: 236,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: TiermetrySpacing.listPadding,
                          itemCount: featured.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(
                                width: TiermetrySpacing.cardGap,
                              ),
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 300,
                              child: _FeaturedEventCard(
                                event: featured[index],
                                onTap: () => _openEvent(featured[index]),
                              ),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
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
          child: Text(
            'Explore the scene',
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

class _ExploreCapsule extends StatelessWidget {
  final _ExploreCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExploreCapsule({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = TiermetryColors.accentNeonGreen;

    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 105,
        borderRadius: 24,
        border:
            isSelected
                ? Border.all(color: primaryColor, width: 1.5)
                : Border.all(
                  color: TiermetryColors.cardBorder,
                  width: 1,
                ),
        shadows: TiermetryShadows.capsule,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(isSelected ? 28 : 20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(
                      alpha: isSelected ? 0.35 : 0.16,
                    ),
                    blurRadius: isSelected ? 16 : 8,
                    spreadRadius: isSelected ? 2 : 1,
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                color: Colors.black.withAlpha(220),
                size: 25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
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
            child: const Icon(Icons.stars_rounded, color: TiermetryColors.white),
          ),
          const SizedBox(width: TiermetrySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '240 points available',
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
        shadows: TiermetryShadows.venueTile, // Shared logic for horizontal tiles
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Hero(
                tag: event.image,
                child: Image.asset(
                  event.image,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
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
                    '${event.date} - ${event.location}',
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

class _FeaturedEventCard extends StatelessWidget {
  final EventEntity event;
  final VoidCallback onTap;

  const _FeaturedEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        padding: const EdgeInsets.all(12),
        borderRadius: 28,
        shadows: TiermetryShadows.liveActivity, // Use same shadow as Home horizontal cards
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(event.image, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: AppPill(text: '${event.points} pts'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${event.date} - ${event.time}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.caption(
                color: TiermetryColors.white.withValues(alpha: 0.58),
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
                child: Icon(data.icon, color: TiermetryColors.black.withAlpha(220)),
              ),
              const Spacer(),
              AppPill(text: data.label),
            ],
          ),
          const Spacer(),
          Text(
            data.title,
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

class _ExploreCategory {
  final String label;
  final IconData icon;

  const _ExploreCategory(this.label, this.icon);
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
