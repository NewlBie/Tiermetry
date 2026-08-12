// lib/pages/all_arenas_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
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

class _AllArenasScreenState extends State<AllArenasScreen> with RefreshRateMixin {
  final _arenaCtrl = locator.arenaCtrl;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<ArenaEntity> _filteredArenas = [];
  bool _isLoading = true;

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
    unawaited(_fetchArenas());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchArenas() async {
    try {
      if (_arenaCtrl.arenas.isEmpty) {
        await _arenaCtrl.loadArenas();
      }
      setState(() {
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching arenas: $e');
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<ArenaEntity> tempArenas = List.from(_arenaCtrl.arenas);
    final String searchQuery = _searchController.text.toLowerCase();

    // Search query filter
    if (searchQuery.isNotEmpty) {
      tempArenas = tempArenas.where((arena) {
        return arena.name.toLowerCase().contains(searchQuery) ||
            arena.activity.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Distance filter
    if (_selectedDistance != null) {
      tempArenas = tempArenas.where((arena) => arena.distance <= _selectedDistance!).toList();
    }

    // Price tier filter
    if (_selectedPriceTier != null) {
      tempArenas = tempArenas.where((arena) => arena.priceTier <= _selectedPriceTier!).toList();
    }

    // Time filter
    if (_selectedTime == 'Open Now') {
      tempArenas = tempArenas.where((arena) => arena.isOpen).toList();
    }

    // Type filter
    if (_selectedType != null) {
      tempArenas = tempArenas.where((arena) => arena.activity == _selectedType).toList();
    }

    // Sorting logic
    switch (_sortBy) {
      case 'Ratings':
        tempArenas.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest Price':
        tempArenas.sort((a, b) => a.priceTier.compareTo(b.priceTier));
        break;
      case 'Nearest':
        tempArenas.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'Popularity':
      default:
      // A slightly more weighted popularity score
        tempArenas.sort((a, b) => (b.rating * b.capacity * 0.7).compareTo(a.rating * a.capacity * 0.7));
        break;
    }

    setState(() {
      _filteredArenas = tempArenas;
    });
  }

  void _showFilterSheet() async {
    unawaited(HapticFeedback.lightImpact());
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
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
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: TiermetryColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'All Arenas',
        style: TiermetryTypography.title(
          color: Colors.white,
          fontSize: 22,
        ),
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

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _filteredArenas.isEmpty
          ? _buildEmptyState()
          : _buildArenaList(),
    );
  }

  Widget _buildArenaList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredArenas.length,
      addRepaintBoundaries: false, // We use RepaintBoundary inside ArenaCard
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ArenaCard(arena: _filteredArenas[index]),
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

// FilterSheet and GlassSearchBar moved to dedicated files in lib/components

