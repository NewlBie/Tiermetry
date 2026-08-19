// lib/pages/all_arenas_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/glass_search_bar.dart';

import '../../domain/entities/arena_entity.dart';
import '../widgets/arena_card.dart';
import '../widgets/filter_sheet.dart';

// Default filter values for easy comparison and reset
const double _defaultDistance = 10.0;
const String _defaultTime = 'Anytime';
const String _defaultSortBy = 'Popularity';

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
  double? _selectedDistance = _defaultDistance;
  int? _selectedPriceTier;
  String _selectedTime = _defaultTime;
  ArenaActivity? _selectedType;
  String _sortBy = _defaultSortBy;

  // Helper to check if any filters are active
  bool get _areFiltersActive {
    return _selectedDistance != _defaultDistance ||
        _selectedPriceTier != null ||
        _selectedTime != _defaultTime ||
        _selectedType != null ||
        _sortBy != _defaultSortBy;
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => FilterSheet(
            initialDistance: _selectedDistance,
            initialPrice: _selectedPriceTier,
            initialTime: _selectedTime,
            initialType: _selectedType,
            initialSortBy: _sortBy,
          ),
    );

    if (result != null) {
      setState(() {
        _selectedDistance = result['distance'] as double?;
        _selectedPriceTier = result['price'] as int?;
        _selectedTime = result['time'] as String? ?? _defaultTime;
        _selectedType = result['type'] as ArenaActivity?;
        _sortBy = result['sortBy'] as String? ?? _defaultSortBy;
      });

      _arenaCtrl.setFilters(
        maxDistance: _selectedDistance,
        maxPriceTier: _selectedPriceTier,
        onlyOpenNow: _selectedTime == 'Open Now',
        sortBy: _sortBy,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: _buildAppBar(),
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
        style: TiermetryTypography.title(color: Colors.white, fontSize: 22),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: GlassSearchBar(controller: _searchController)),
          const SizedBox(width: 12),
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
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _arenaCtrl.arenas.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ArenaCard(arena: _arenaCtrl.arenas[index]),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
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
