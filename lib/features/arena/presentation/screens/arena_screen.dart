import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() {
      _arenaCtrl.loadArenas();
      unawaited(_resolveLocationForDistances());
      _setupRealtimePromotions();
      _fetchLiveBanners();
    });
  }

  Future<void> _resolveLocationForDistances() async {
    if (_arenaCtrl.locationCtrl.currentPosition != null) return;
    await _arenaCtrl.locationCtrl.resolveCurrentCity();
  }

  @override
  void dispose() {
    _promotionsSub?.cancel();
    _sponsorsSub?.cancel();
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
        sortBy:
            result.sortBy == ArenaFilterDefaults.sortBy ? null : result.sortBy,
      );
    }
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
                  final searchQuery = _searchController.text.trim();
                  final isSearching = searchQuery.isNotEmpty;
                  final featured = rankTopPicks(
                    arenas,
                    searchQuery: searchQuery,
                    selectedActivity: _selectedActivity,
                  );

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
                              activeFilterCount:
                                  _currentFilter.hasActiveFilters ? 1 : 0,
                              onFilter: _openFilterSheet,
                              onClear:
                                  _searchController.text.isEmpty
                                      ? null
                                      : _searchController.clear,
                            ),
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

  List<Map<String, dynamic>> _liveBanners = [];
  List<Map<String, dynamic>> _liveSponsors = [];
  StreamSubscription<List<Map<String, dynamic>>>? _promotionsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _sponsorsSub;

  void _setupRealtimePromotions() {
    try {
      _promotionsSub = Supabase.instance.client
          .from('promotions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
            if (mounted) {
              setState(() {
                _liveBanners = List<Map<String, dynamic>>.from(
                  data.where((item) => item['is_active'] == true),
                );
              });
            }
          });
      _sponsorsSub = Supabase.instance.client
          .from('sponsors')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
            if (mounted) {
              setState(() {
                _liveSponsors = List<Map<String, dynamic>>.from(
                  data.where((item) => item['is_active'] == true),
                );
              });
            }
          });
    } catch (_) {
      _fetchLiveBanners();
    }
  }

  Future<void> _fetchLiveBanners() async {
    try {
      final res = await Supabase.instance.client
          .from('promotions')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      if (res.isNotEmpty && mounted) {
        setState(() {
          _liveBanners = List<Map<String, dynamic>>.from(res);
        });
      }
      final sponsors = await Supabase.instance.client
          .from('sponsors')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(
          () => _liveSponsors = List<Map<String, dynamic>>.from(sponsors),
        );
      }
    } catch (_) {}
  }

  Widget _buildSponsoredSection(bool isSearching) {
    final banners = [
      ..._liveBanners,
      ..._liveSponsors.map(
        (sponsor) => <String, dynamic>{
          'title': sponsor['name'],
          'code': sponsor['tier'],
          'image_url': sponsor['logo_url'],
        },
      ),
    ];

    if (banners.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

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
                        height: 135,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: TiermetrySpacing.listPadding,
                          itemCount: banners.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12.0),
                          itemBuilder: (context, index) {
                            final item = banners[index];
                            final imageUrl = item['image_url'] as String? ?? '';
                            final title =
                                item['title'] as String? ?? 'Special Offer';
                            final code = item['code'] as String? ?? '';

                            return Container(
                                  width: 250,
                                  height: 135,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF181C24),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child:
                                        imageUrl.isNotEmpty
                                            ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      _buildBannerTextFallback(
                                                        title,
                                                        code,
                                                      ),
                                            )
                                            : _buildBannerTextFallback(
                                              title,
                                              code,
                                            ),
                                  ),
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

  Widget _buildBannerTextFallback(String title, String code) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A1B4E), Color(0xFF140D28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(bool isSearching, List<ArenaEntity> featured) {
    final bool showSection = !isSearching || featured.isNotEmpty;
    final deckArenas = featured.take(5).toList(growable: false);
    final int openCount = deckArenas.where((arena) => arena.isOpenNow).length;

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
                      Padding(
                        padding: TiermetrySpacing.pagePadding,
                        child: SectionHeader(
                          title: isSearching ? 'Best Matches' : 'Top Picks',
                          tagLabel:
                              openCount > 0 ? '$openCount OPEN NOW' : null,
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.headerToContent),
                      if (featured.isNotEmpty)
                        SizedBox(
                          height: 370,
                          child: _FeaturedArenaDeck(arenas: deckArenas),
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

class _FeaturedArenaDeck extends StatefulWidget {
  final List<ArenaEntity> arenas;

  const _FeaturedArenaDeck({required this.arenas});

  @override
  State<_FeaturedArenaDeck> createState() => _FeaturedArenaDeckState();
}

class _FeaturedArenaDeckState extends State<_FeaturedArenaDeck> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.74);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.arenas.length;
    return PageView.builder(
      controller: _controller,
      clipBehavior: Clip.none,
      padEnds: count == 1,
      physics: const BouncingScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          child: Semantics(
            label:
                'Top pick ${index + 1} of $count: ${widget.arenas[index].name}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
              child: ArenaCard(arena: widget.arenas[index], isFeatured: true),
            ),
          ),
          builder: (context, child) {
            final page =
                _controller.hasClients
                    ? (_controller.page ?? _controller.initialPage.toDouble())
                    : _controller.initialPage.toDouble();
            final offset = (page - index).clamp(-1.0, 1.0);
            return Transform.rotate(
              angle: offset * 0.075,
              child: Transform.scale(
                scale: 1 - (offset.abs() * 0.075),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

/// Presentation-only ordering for the swipe deck. Availability stays derived
/// from each arena's authoritative operating-hours data; this does not change
/// server-side search, filters, or the venue list order.
List<ArenaEntity> rankTopPicks(
  Iterable<ArenaEntity> arenas, {
  required String searchQuery,
  required String selectedActivity,
}) {
  final normalizedQuery = searchQuery.trim().toLowerCase();
  final normalizedActivity = selectedActivity.trim().toLowerCase();
  final ranked = arenas.toList(growable: false);

  int relevance(ArenaEntity arena) {
    if (normalizedQuery.isEmpty) return 0;
    final name = arena.name.toLowerCase();
    final searchableDetails =
        <String>[
          arena.activityLabel,
          arena.location,
          arena.shortAddress,
          ...arena.tags,
        ].join(' ').toLowerCase();
    if (name.contains(normalizedQuery)) return 2;
    return searchableDetails.contains(normalizedQuery) ? 1 : 0;
  }

  bool activityMatches(ArenaEntity arena) {
    if (normalizedActivity.isEmpty || normalizedActivity == 'all') return false;
    final haystack =
        <String>[arena.activityLabel, ...arena.tags].join(' ').toLowerCase();
    return haystack.contains(normalizedActivity);
  }

  ranked.sort((left, right) {
    final openComparison = (right.isOpenNow ? 1 : 0).compareTo(
      left.isOpenNow ? 1 : 0,
    );
    if (openComparison != 0) return openComparison;

    final relevanceComparison = relevance(right).compareTo(relevance(left));
    if (relevanceComparison != 0) return relevanceComparison;

    final activityComparison = (activityMatches(right) ? 1 : 0).compareTo(
      activityMatches(left) ? 1 : 0,
    );
    if (activityComparison != 0) return activityComparison;

    final distanceComparison = (left.distance ?? double.infinity).compareTo(
      right.distance ?? double.infinity,
    );
    if (distanceComparison != 0) return distanceComparison;

    final ratingComparison = right.rating.compareTo(left.rating);
    if (ratingComparison != 0) return ratingComparison;

    final reviewComparison = right.reviewCount.compareTo(left.reviewCount);
    if (reviewComparison != 0) return reviewComparison;

    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });

  return ranked;
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

class _ActivityChoice {
  final String label;
  final IconData icon;

  const _ActivityChoice(this.label, this.icon);
}
