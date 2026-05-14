import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
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

class _ArenaScreenState extends State<ArenaScreen> {
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
      MaterialPageRoute(builder: (_) => const AllArenasScreen()),
    );
  }

  void _openArena(ArenaEntity arena) {
    Navigator.of(context).push(
      PageRouteBuilder(
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
                    child: _SearchHero(
                      controller: _searchController,
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
              child: CircularProgressIndicator(color: Colors.white),
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
                      ? const _EmptyState(message: 'No matching places found.')
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
                      ? const _EmptyState(message: 'No top picks found.')
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
            Padding(
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
                choice.icon,
                color: Colors.black.withAlpha(220),
                size: 25,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                choice.label,
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
    return Container(
      width: 300,
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
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.fromLTRB(0, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TinyPill(text: data.label),
                  const Spacer(),
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.title(
                      color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.58),
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
                hintText: 'Search gaming cafes, turfs, paintball...',
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

class _VenueResultTile extends StatelessWidget {
  final ArenaEntity arena;
  final VoidCallback onTap;

  const _VenueResultTile({required this.arena, required this.onTap});

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
                            color: Colors.white,
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
                          color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TinyPill(text: arena.isOpen ? 'Open now' : 'Closed'),
                      const SizedBox(width: TiermetrySpacing.sm),
                      Text(
                        '${arena.distance} km',
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
