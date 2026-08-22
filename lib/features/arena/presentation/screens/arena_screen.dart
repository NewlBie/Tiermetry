import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silky_scroll/silky_scroll.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_search_hero.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';

import '../../domain/entities/arena_entity.dart';
import '../widgets/arena_backdrop.dart';
import '../widgets/arena_card.dart';
import '../widgets/arena_greeting.dart';
import '../widgets/filter_sheet.dart';
import 'all_arenas_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> with RefreshRateMixin {
  final _arenaCtrl = locator.arenaCtrl;
  final _searchController = TextEditingController();
  late final ScrollController _scrollCtrl;

  String _selectedActivity = 'All';
  ArenaFilterResult _currentFilter = ArenaFilterResult.defaults;

  static const List<_ActivityChoice> _activityChoices = [
    _ActivityChoice('All', Icons.grid_view_rounded),
    _ActivityChoice('Gaming cafes', Icons.sports_esports_rounded),
    _ActivityChoice('Turfs', Icons.sports_soccer_rounded),
    _ActivityChoice('Paintball', Icons.center_focus_strong_rounded),
    _ActivityChoice('Karting', Icons.sports_motorsports_rounded),
  ];

  static const List<_SponsoredCardData> _sponsoredCards = [
    _SponsoredCardData(
      offerValue: '50% OFF',
      title: 'Squad night deals',
      subtitle: 'Gaming cafes, turf slots, and group bookings for tonight.',
      label: 'Sponsored',
    ),
    _SponsoredCardData(
      offerValue: '₹73',
      title: 'Weekend turf rush',
      subtitle: 'Late slots, floodlights, and quick bookings near you.',
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
    _arenaCtrl.search(_searchController.text.trim());
  }

  void _onActivityChanged(String label) {
    setState(() => _selectedActivity = label);
    _arenaCtrl.setActivity(label);
  }

  void _onClearAll() {
    _searchController.clear();
    setState(() {
      _selectedActivity = 'All';
      _currentFilter = ArenaFilterResult.defaults;
    });
    _arenaCtrl.clearFilters();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<ArenaFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(initial: _currentFilter),
    );
    if (result != null) {
      setState(() => _currentFilter = result);
      _arenaCtrl.setFilters(
        maxDistance: result.maxDistance,
        maxPriceTier: result.maxPriceTier,
        minRating: result.minRating,
        platforms: result.platforms,
        onlyOpenNow: result.onlyOpenNow,
        hasOffers: result.onlyOffers,
        sortBy: result.sortBy == ArenaFilterDefaults.sortBy ? null : result.sortBy,
      );
    }
  }

  void _openAllArenas() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AllArenasScreen()),
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
          RefreshIndicator(
            onRefresh: () => _arenaCtrl.loadArenas(isRefresh: true),
            backgroundColor: TiermetryColors.surface,
            color: TiermetryColors.accentNeonGreen,
            edgeOffset: topPad + TiermetrySpacing.topBarHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200 &&
                    !_arenaCtrl.isLoadingMore) {
                  _arenaCtrl.loadArenas();
                }
                return false;
              },
              child: ListenableBuilder(
                listenable: _arenaCtrl,
                builder: (context, _) {
                  final arenas = _arenaCtrl.arenas;
                  final isSearching = _searchController.text.trim().isNotEmpty;
                  final featured = [...arenas]
                    ..sort((a, b) => b.rating.compareTo(a.rating));

                  return SilkyCustomScrollView(
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
                          child: const ArenaGreeting(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: Padding(
                            padding: TiermetrySpacing.pagePadding,
                            child: AppSearchHero(
                              controller: _searchController,
                              hintText:
                                  'Search gaming cafes, turfs, paintball...',
                              onClear:
                                  _searchController.text.isEmpty
                                      ? null
                                      : _searchController.clear,
                            ),
                          ),
                        ),
                      ),
                      // ── Filter & Sort Row ───────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TiermetrySpacing.screenPadding,
                            TiermetrySpacing.sm,
                            TiermetrySpacing.screenPadding,
                            0,
                          ),
                          child: Row(
                            children: [
                              // Filter button
                              _FilterSortButton(
                                label: 'Filter',
                                icon: Icons.tune_rounded,
                                hasActive: _currentFilter.hasActiveFilters &&
                                    _currentFilter.sortBy == ArenaFilterDefaults.sortBy,
                                onTap: _openFilterSheet,
                              ),
                              const SizedBox(width: 8),
                              // Sort button shows current sort when not default
                              _FilterSortButton(
                                label: _currentFilter.sortBy == ArenaFilterDefaults.sortBy
                                    ? 'Sort'
                                    : _currentFilter.sortBy,
                                icon: Icons.sort_rounded,
                                hasActive: _currentFilter.sortBy != ArenaFilterDefaults.sortBy,
                                onTap: _openFilterSheet,
                              ),
                              const Spacer(),
                              // Clear all — only show when filters active
                              if (_currentFilter.hasActiveFilters || _selectedActivity != 'All')
                                GestureDetector(
                                  onTap: _onClearAll,
                                  child: Text(
                                    'Clear all',
                                    style: TiermetryTypography.caption(
                                      color: TiermetryColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _buildActivityStrip(),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: TiermetrySpacing.sectionGap),
                      ),
                      _buildSponsoredSection(isSearching),
                      _buildFeaturedSection(isSearching, featured),

                      // Main Venue Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: TiermetrySpacing.pagePadding,
                          child: SectionHeader(
                            title:
                                _arenaCtrl.isLoading
                                    ? 'Searching...'
                                    : 'Venues',
                            onViewMore: _openAllArenas,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: TiermetrySpacing.headerToContent,
                        ),
                      ),

                      if (_arenaCtrl.isLoading && arenas.isEmpty)
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            TiermetrySpacing.screenPadding,
                            TiermetrySpacing.topBarHeight,
                            TiermetrySpacing.screenPadding,
                            TiermetrySpacing.screenPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: ShimmerLoadingVerticalList(
                              itemHeight: 240,
                              itemCount: 4,
                              spacing: TiermetrySpacing.md,
                            ),
                          ),
                        )
                      else if (_arenaCtrl.error != null && arenas.isEmpty)
                        SliverToBoxAdapter(
                          child: AppErrorState(
                            message: _arenaCtrl.error!,
                            onRetry:
                                () => _arenaCtrl.loadArenas(isRefresh: true),
                          ),
                        )
                      else if (arenas.isEmpty)
                        SliverToBoxAdapter(
                          child: AppEmptyState(
                            message: 'No matching places found.',
                            onAction: _onClearAll,
                            actionLabel: 'Clear Filters',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: TiermetrySpacing.pagePadding,
                          sliver: SliverList.builder(
                            itemCount: arenas.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TiermetrySpacing.md,
                                ),
                                child: ArenaCard(arena: arenas[index]),
                              );
                            },
                          ),
                        ),

                      if (_arenaCtrl.isLoadingMore)
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: TiermetrySpacing.screenPadding,
                            vertical: TiermetrySpacing.xl,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: ShimmerLoadingVerticalList(
                              itemHeight: 240,
                              itemCount: 1,
                            ),
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

  Widget _buildActivityStrip() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TiermetrySpacing.md),
            SizedBox(
              height: 48,
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
                      onTap: () => _onActivityChanged(choice.label),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoredSection(bool isSearching) {
    return SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child:
            isSearching
                ? const SizedBox.shrink()
                : RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(title: 'Offers and spotlights'),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: TiermetrySpacing.listPadding,
                          itemCount: _sponsoredCards.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 8.0),
                          itemBuilder: (context, index) {
                            return _SponsoredVenueTile(
                                  data: _sponsoredCards[index],
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.08);
                          },
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildFeaturedSection(bool isSearching, List<ArenaEntity> featured) {
    final bool showSection = !isSearching || featured.isNotEmpty;

    return SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child:
            !showSection
                ? const SizedBox.shrink()
                : RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: 'Featured Arenas',
                          onViewMore: null,
                          tagLabel: 'Sponsored',
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      if (featured.isNotEmpty)
                        SizedBox(
                          height: 330,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: TiermetrySpacing.listPadding,
                            itemCount:
                                featured.length > 5 ? 5 : featured.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(
                                  width: TiermetrySpacing.cardGap,
                                ),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 320,
                                child: ArenaCard(
                                  arena: featured[index],
                                  isFeatured: true,
                                ),
                              );
                            },
                          ),
                        )
                      else if (!_arenaCtrl.isLoading)
                        const AppEmptyState(message: 'No top picks found.'),
                      const SizedBox(height: TiermetrySpacing.sectionGap),
                    ],
                  ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: TiermetrySpacing.lg,
          vertical: TiermetrySpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? primaryColor.withValues(alpha: 0.15)
                  : TiermetryColors.surfaceElement,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : TiermetryColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? TiermetryShadows.capsule : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              choice.icon,
              color:
                  isSelected
                      ? primaryColor
                      : TiermetryColors.white.withValues(alpha: 0.7),
              size: 18,
            ),
            const SizedBox(width: TiermetrySpacing.sm),
            Text(
              choice.label,
              style: TiermetryTypography.label(
                color:
                    isSelected
                        ? TiermetryColors.white
                        : TiermetryColors.white.withValues(alpha: 0.7),
              ).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

class _SponsoredVenueTile extends StatelessWidget {
  final _SponsoredCardData data;

  const _SponsoredVenueTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF4E00), // Vibrant neon orange
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0, // Hard shadow
            ),
          ],
        ),
        child: Stack(
          children: [
            // The custom black shape
            Positioned.fill(
              child: CustomPaint(
                painter: _TicketPainter(color: Colors.black),
              ),
            ),
            
            // Top Left Logo
            Positioned(
              left: 14,
              top: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
            
            // Offer Value (Center)
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 16),
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    heightFactor: 0.5,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: Text(
                        data.offerValue.replaceAll(' OFF', ''),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Left Text
            Positioned(
              left: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title.split(' ').first.toLowerCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    data.title.split(' ').skip(1).join(' ').toLowerCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
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

class _TicketPainter extends CustomPainter {
  final Color color;
  
  _TicketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double r = 12.0; // Corner radius for the black shape
    const double p = 8.0; // Orange border thickness
    
    // Intrusions based on proportions of the card
    final double tlW = size.width * 0.18;
    final double tlH = size.height * 0.35;
    
    final double blW = size.width * 0.48;
    final double blH = size.height * 0.40;

    final path = Path()
      // 1. Top edge, start after top-left intrusion
      ..moveTo(tlW + r, p)
      ..lineTo(size.width - p - r, p)
      
      // 2. Top-right corner (convex)
      ..arcToPoint(Offset(size.width - p, p + r), radius: const Radius.circular(r), clockwise: true)
      
      // 3. Right edge
      ..lineTo(size.width - p, size.height - p - r)
      
      // 4. Bottom-right corner (convex)
      ..arcToPoint(Offset(size.width - p - r, size.height - p), radius: const Radius.circular(r), clockwise: true)
      
      // 5. Bottom edge (right of bottom-left intrusion)
      ..lineTo(blW + r, size.height - p)
      
      // 6. Corner turning UP (convex)
      ..arcToPoint(Offset(blW, size.height - p - r), radius: const Radius.circular(r), clockwise: true)
      
      // 7. Right edge of bottom-left intrusion
      ..lineTo(blW, size.height - blH + r)
      
      // 8. Corner turning LEFT (concave)
      ..arcToPoint(Offset(blW - r, size.height - blH), radius: const Radius.circular(r), clockwise: false)
      
      // 9. Top edge of bottom-left intrusion
      ..lineTo(p + r, size.height - blH)
      
      // 10. Corner turning UP (convex)
      ..arcToPoint(Offset(p, size.height - blH - r), radius: const Radius.circular(r), clockwise: true)
      
      // 11. Left edge (between bottom-left and top-left intrusions)
      ..lineTo(p, tlH + r)
      
      // 12. Corner turning RIGHT (convex)
      ..arcToPoint(Offset(p + r, tlH), radius: const Radius.circular(r), clockwise: true)
      
      // 13. Bottom edge of top-left intrusion
      ..lineTo(tlW - r, tlH)
      
      // 14. Corner turning UP (concave)
      ..arcToPoint(Offset(tlW, tlH - r), radius: const Radius.circular(r), clockwise: false)
      
      // 15. Right edge of top-left intrusion
      ..lineTo(tlW, p + r)
      
      // 16. Corner turning RIGHT (convex)
      ..arcToPoint(Offset(tlW + r, p), radius: const Radius.circular(r), clockwise: true)
      
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TicketPainter oldDelegate) {
    return oldDelegate.color != color;
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
  final String offerValue;
  final String label;

  const _SponsoredCardData({
    required this.title,
    required this.subtitle,
    required this.offerValue,
    required this.label,
  });
}

// ─── Filter / Sort Button ─────────────────────────────────────────────────────
/// A pill-shaped button with an active indicator dot.
class _FilterSortButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasActive;
  final VoidCallback onTap;

  const _FilterSortButton({
    required this.label,
    required this.icon,
    required this.hasActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: hasActive
              ? TiermetryColors.primary.withValues(alpha: 0.12)
              : TiermetryColors.surfaceElement,
          borderRadius: BorderRadius.circular(TiermetryRadii.pill),
          border: Border.all(
            color: hasActive
                ? TiermetryColors.primary
                : TiermetryColors.cardBorder,
            width: hasActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: hasActive
                  ? TiermetryColors.primary
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TiermetryTypography.caption(
                color: hasActive ? TiermetryColors.primary : Colors.white70,
                fontWeight: hasActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: TiermetryColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
