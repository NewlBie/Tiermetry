// lib/pages/all_arenas_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/glass_search_bar.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';

import '../../domain/entities/arena_entity.dart';
import '../widgets/arena_card.dart';
import '../widgets/filter_sheet.dart';
import 'arena_details_screen.dart';

// Default filter values are now in ArenaFilterResult
class AllArenasScreen extends StatefulWidget {
  const AllArenasScreen({super.key});

  @override
  State<AllArenasScreen> createState() => _AllArenasScreenState();
}

class _AllArenasScreenState extends State<AllArenasScreen>
    with RefreshRateMixin {
  final _arenaCtrl = locator.arenaCtrl;
  final TextEditingController _searchController = TextEditingController();

  // Filter state variables
  ArenaFilterResult _currentFilter = ArenaFilterResult.defaults;

  // Helper to check if any filters are active
  bool get _areFiltersActive {
    return _currentFilter.hasActiveFilters;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() => _arenaCtrl.loadArenas(isRefresh: true));
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _arenaCtrl.search(_searchController.text.trim());
  }

  void _showFilterSheet() async {
    unawaited(HapticFeedback.lightImpact());
    final result = await showModalBottomSheet<ArenaFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterSheet(initial: _currentFilter),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ArenaDetailsScreen(
                arena: ArenaEntity(
                  id: 'mock-test-arena',
                  name: 'UI Test Arena',
                  image: 'assets/images/arena_1.jpg',
                  rating: 4.8,
                  capacity: 50,
                  location: 'UI City',
                  screenCount: 10,
                  activity: ArenaActivity.gaming,
                  shortAddress: '123 Testing Lane',
                  hours: '24/7',
                  isOpen: true,
                  distance: 2.5,
                  priceTier: 2,
                  isVerified: true,
                  latitude: 0,
                  longitude: 0,
                ),
              ),
            ),
          );
        },
        backgroundColor: TiermetryColors.accentNeonGreen,
        icon: const Icon(Icons.bug_report, color: Colors.black),
        label: const Text('Test UI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _arenaCtrl.loadArenas(isRefresh: true),
          backgroundColor: TiermetryColors.surface,
          color: TiermetryColors.accentNeonGreen,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200 &&
                  !_arenaCtrl.isLoadingMore) {
                _arenaCtrl.loadArenas();
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                _buildContentSliver(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: TiermetryColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(('All Arenas').toUpperCase(),
        style: TiermetryTypography.title(color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TiermetrySpacing.screenPadding),
      child: Row(
        children: [
          Expanded(child: GlassSearchBar(controller: _searchController)),
          const SizedBox(width: TiermetrySpacing.md),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppSurface(
          color: TiermetryColors.surfaceUnderlay,
          borderRadius: 16,
          border: Border.all(color: TiermetryColors.cardBorderEmphasis),
          shadows: const [],
          child: IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ),
        if (_areFiltersActive)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSliver() {
    return ListenableBuilder(
      listenable: _arenaCtrl,
      builder: (context, _) {
        if (_arenaCtrl.isLoading) {
          return const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: TiermetrySpacing.screenPadding),
            sliver: SliverToBoxAdapter(
              child: ShimmerLoadingVerticalList(
                itemHeight: 240,
                itemCount: 4,
                spacing: TiermetrySpacing.cardGap,
              ),
            ),
          );
        }

        if (_arenaCtrl.error != null && _arenaCtrl.arenas.isEmpty) {
          return SliverToBoxAdapter(
            child: AppErrorState(
              message: _arenaCtrl.error!,
              onRetry: () => _arenaCtrl.loadArenas(isRefresh: true),
            ),
          );
        }

        if (_arenaCtrl.arenas.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: TiermetrySpacing.screenPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _arenaCtrl.arenas.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: TiermetrySpacing.cardGap),
                    child: ArenaCard(arena: _arenaCtrl.arenas[index]),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: TiermetrySpacing.cardGap),
                  child: ShimmerLoadingVerticalList(
                    itemHeight: 240,
                    itemCount: 1,
                  ),
                );
              },
              childCount:
                  _arenaCtrl.arenas.length + (_arenaCtrl.isLoadingMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      message: 'No Arenas Found',
      icon: Icons.search_off_rounded,
    );
  }
}
