import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_search_hero.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';

import '../../domain/entities/arena_entity.dart';
import '../widgets/arena_backdrop.dart';
import '../widgets/arena_card.dart';
import '../widgets/arena_greeting.dart';
import 'all_arenas_screen.dart';
import 'arena_details_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> with RefreshRateMixin {
  final _arenaCtrl = locator.arenaCtrl;
  final _searchController = TextEditingController();
  late final ScrollController _scrollCtrl;

  String _query = '';
  String _selectedActivity = 'All';

  static const List<_ActivityChoice> _activityChoices = [
    _ActivityChoice('All', Icons.grid_view_rounded),
    _ActivityChoice('Gaming cafes', Icons.sports_esports_rounded),
    _ActivityChoice('Turfs', Icons.sports_soccer_rounded),
    _ActivityChoice('Paintball', Icons.center_focus_strong_rounded),
    _ActivityChoice('Karting', Icons.sports_motorsports_rounded),
  ];

  static const List<_SponsoredCardData> _sponsoredCards = [
    _SponsoredCardData(
      title: 'Squad night deals',
      subtitle: 'Gaming cafes, turf slots, and group bookings for tonight.',
      image: 'assets/arena1.jpeg',
      label: 'Sponsored',
    ),
    _SponsoredCardData(
      title: 'Weekend turf rush',
      subtitle: 'Late slots, floodlights, and quick bookings near you.',
      image: 'assets/kart_arena.png',
      label: 'Promoted',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() => _arenaCtrl.loadArenas());
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

  List<ArenaEntity> _filteredArenas(List<ArenaEntity> arenas) {
    return arenas.where((arena) {
        final matchesQuery =
            _query.isEmpty ||
            arena.name.toLowerCase().contains(_query) ||
            arena.location.toLowerCase().contains(_query) ||
            arena.activityLabel.toLowerCase().contains(_query);

        final matchesActivity =
            _selectedActivity == 'All' ||
            (_selectedActivity == 'Gaming cafes' &&
                arena.activity == ArenaActivity.gaming) ||
            (_selectedActivity == 'Turfs' &&
                arena.activity == ArenaActivity.recreational) ||
            (_selectedActivity == 'Paintball' &&
                arena.activity == ArenaActivity.arcade) ||
            (_selectedActivity == 'Karting' &&
                arena.activity == ArenaActivity.recreational);

        return matchesQuery && matchesActivity;
      }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  void _openAllArenas() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AllArenasScreen()),
    );
  }

  void _openArena(ArenaEntity arena) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, _) => ArenaDetailsScreen(arena: arena),
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
          const ArenaBackdrop(),
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
                  child: const ArenaGreeting(),
                ),
              ),
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Padding(
                    padding: TiermetrySpacing.pagePadding,
                    child: AppSearchHero(
                      controller: _searchController,
                      hintText: 'Search gaming cafes, turfs, paintball...',
                      onClear: _query.isEmpty ? null : _searchController.clear,
                    ),
                  ),
                ),
              ),
              _buildActivityStrip(),
              _buildVenueSections(),
              _buildSponsoredSection(),
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

  Widget _buildActivityStrip() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.xl),
            Padding(
              padding: TiermetrySpacing.pagePadding,
              child: Text(
                'Browse by activity',
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
                itemCount: _activityChoices.length,
                itemBuilder: (context, index) {
                  final choice = _activityChoices[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: TiermetrySpacing.lg),
                    child: _ActivityCapsule(
                      choice: choice,
                      isSelected: _selectedActivity == choice.label,
                      onTap:
                          () =>
                              setState(() => _selectedActivity = choice.label),
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

  Widget _buildVenueSections() {
    return ListenableBuilder(
      listenable: _arenaCtrl,
      builder: (context, _) {
        if (_arenaCtrl.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: TiermetryColors.white),
            ),
          );
        }

        final arenas = _arenaCtrl.arenas;
        final featured = [...arenas]
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final places = _filteredArenas(arenas);
        final hasActiveSearch = _query.isNotEmpty || _selectedActivity != 'All';

        return SliverList.list(
          children: [
            RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: TiermetrySpacing.pagePadding,
                    child: SectionHeader(
                      title:
                          hasActiveSearch
                              ? 'Best matches'
                              : 'Recommended near you',
                      onViewMore: _openAllArenas,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.headerToContent),
                  places.isEmpty
                      ? const AppEmptyState(message: 'No matching places found.')
                      : Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: Column(
                          children:
                              places
                                  .take(3)
                                  .map(
                                    (arena) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: TiermetrySpacing.md,
                                      ),
                                      child: _VenueResultTile(
                                        arena: arena,
                                        onTap: () => _openArena(arena),
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
                    child: SectionHeader(
                      title: 'Top picks this week',
                      onViewMore: _openAllArenas,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.headerToContent),
                  featured.isEmpty
                      ? const AppEmptyState(message: 'No top picks found.')
                      : SizedBox(
                        height: 286,
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
                              width: 320,
                              child: ArenaCard(arena: featured[index]),
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: TiermetrySpacing.sectionGap),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSponsoredSection() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: TiermetrySpacing.pagePadding,
              child: SectionHeader(title: 'Offers and spotlights'),
            ),
            const SizedBox(height: TiermetrySpacing.headerToContent),
            SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: TiermetrySpacing.listPadding,
                itemCount: _sponsoredCards.length,
                separatorBuilder:
                    (_, __) => const SizedBox(width: TiermetrySpacing.cardGap),
                itemBuilder: (context, index) {
                  return _SponsoredVenueTile(
                    data: _sponsoredCards[index],
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

class _ActivityCapsule extends StatelessWidget {
  final _ActivityChoice choice;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCapsule({
    required this.choice,
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
        borderRadius: TiermetryRadii.lg,
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
                borderRadius: BorderRadius.circular(isSelected ? 28 : TiermetryRadii.md),
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
                choice.icon,
                color: TiermetryColors.black.withAlpha(220),
                size: 25,
              ),
            ),
            const SizedBox(height: TiermetrySpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                choice.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.caption(
                  color: TiermetryColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
    );
  }
}

class _SponsoredVenueTile extends StatelessWidget {
  final _SponsoredCardData data;

  const _SponsoredVenueTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: 300,
      borderRadius: TiermetryRadii.lg,
      shadows: TiermetryShadows.highEmphasis,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(TiermetrySpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
              child: Image.asset(
                data.image,
                width: 116,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, TiermetrySpacing.lg, 14, TiermetrySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPill(text: data.label),
                  const Spacer(),
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.title(
                      color: TiermetryColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.caption(
                      color: TiermetryColors.white.withValues(alpha: 0.58),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ).copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueResultTile extends StatelessWidget {
  final ArenaEntity arena;
  final VoidCallback onTap;

  const _VenueResultTile({required this.arena, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        padding: const EdgeInsets.all(10),
        borderRadius: TiermetryRadii.lg,
        shadows: TiermetryShadows.venueTile,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                arena.image,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          arena.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TiermetryTypography.title(
                            color: TiermetryColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amberAccent.shade200,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        arena.rating.toStringAsFixed(1),
                        style: TiermetryTypography.caption(
                          color: TiermetryColors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${arena.activityLabel} - ${arena.location}',
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
                      AppPill(text: arena.isOpen ? 'Open now' : 'Closed'),
                      const SizedBox(width: TiermetrySpacing.sm),
                      Text(
                        '${arena.distance} km',
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

class _ActivityChoice {
  final String label;
  final IconData icon;

  const _ActivityChoice(this.label, this.icon);
}

class _SponsoredCardData {
  final String title;
  final String subtitle;
  final String image;
  final String label;

  const _SponsoredCardData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.label,
  });
}
