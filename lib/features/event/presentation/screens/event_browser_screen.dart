import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
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

class _EventBrowserScreenState extends State<EventBrowserScreen> {
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
      PageRouteBuilder(
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
                    child: _SearchHero(
                      controller: _searchController,
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
                style: TiermetryTypography.title(color: Colors.white),
              ),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            SizedBox(
              height: 116,
              child: ListView.builder(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
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
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Padding(
          padding: TiermetrySpacing.pagePadding,
          child: const _RewardsCard(),
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
                child: CircularProgressIndicator(color: Colors.white),
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
                      ? const _EmptyState(message: 'No matching events found.')
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
                  Padding(
                    padding: TiermetrySpacing.pagePadding,
                    child: SectionHeader(title: 'Featured events'),
                  ),
                  const SizedBox(height: TiermetrySpacing.headerToContent),
                  featured.isEmpty
                      ? const _EmptyState(message: 'No featured events found.')
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
            Padding(
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
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Events, deals, sponsored drops, and rewards in one place.',
          style: TiermetryTypography.caption(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _SearchHero extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onClear;

  const _SearchHero({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _SearchField(controller: controller)),
          if (onClear != null) ...[
            const SizedBox(width: TiermetrySpacing.sm),
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TiermetryColors.surfaceElement,
                  borderRadius: BorderRadius.circular(TiermetryRadii.md),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.58),
          ),
          const SizedBox(width: TiermetrySpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: TiermetryTypography.caption(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: TiermetryColors.accentNeonGreen,
              decoration: InputDecoration(
                hintText: 'Search events, deals, rewards...',
                hintStyle: TiermetryTypography.caption(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 105,
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              isSelected
                  ? Border.all(color: primaryColor, width: 1.5)
                  : Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
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
            child: const Icon(Icons.stars_rounded, color: Colors.white),
          ),
          const SizedBox(width: TiermetrySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '240 points available',
                  style: TiermetryTypography.title(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Redeem on tickets, passes, and partner deals.',
                  style: TiermetryTypography.caption(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
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
                      color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TinyPill(text: event.cost),
                      const SizedBox(width: TiermetrySpacing.sm),
                      Text(
                        '${event.points} pts',
                        style: TiermetryTypography.caption(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
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
                      child: _TinyPill(text: '${event.points} pts'),
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
                color: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.58),
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
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: TiermetryColors.accentNeonGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: Colors.black.withAlpha(220)),
              ),
              const Spacer(),
              _TinyPill(text: data.label),
            ],
          ),
          const Spacer(),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.title(
              color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String text;

  const _TinyPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.pill),
      ),
      child: Text(
        text,
        style: TiermetryTypography.caption(
          color: Colors.white.withValues(alpha: 0.74),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TiermetrySpacing.pagePadding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TiermetrySpacing.lg),
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TiermetryTypography.caption(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
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
