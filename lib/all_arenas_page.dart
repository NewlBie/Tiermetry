// lib/pages/all_arenas_page.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import for animations

import '../services/api_service.dart';
import '../models/arena.dart';
import '../widget/arena_card.dart';

// Default filter values for easy comparison and reset
const double _defaultDistance = 10.0;
const String _defaultTime = 'Anytime';
const String _defaultSortBy = 'Popularity';

class AllArenasPage extends StatefulWidget {
  const AllArenasPage({super.key});

  @override
  State<AllArenasPage> createState() => _AllArenasPageState();
}

class _AllArenasPageState extends State<AllArenasPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Arena> _allArenas = [];
  List<Arena> _filteredArenas = [];
  bool _isLoading = true;

  // Filter state variables
  double? _selectedDistance = _defaultDistance;
  int? _selectedPriceTier;
  String _selectedTime = _defaultTime;
  MainActivity? _selectedType;
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
    _fetchArenas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchArenas() async {
    try {
      final arenas = await _apiService.getArenas();
      setState(() {
        _allArenas = arenas;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // In a real app, you'd show a user-friendly error message
      debugPrint("Error fetching arenas: $e");
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Arena> tempArenas = List.from(_allArenas);
    String searchQuery = _searchController.text.toLowerCase();

    // Search query filter
    if (searchQuery.isNotEmpty) {
      tempArenas = tempArenas.where((arena) {
        return arena.name.toLowerCase().contains(searchQuery) ||
            arena.mainActivity.name.toLowerCase().contains(searchQuery);
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
      tempArenas = tempArenas.where((arena) => arena.mainActivity == _selectedType).toList();
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
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initialDistance: _selectedDistance,
        initialPrice: _selectedPriceTier,
        initialTime: _selectedTime,
        initialType: _selectedType,
        initialSortBy: _sortBy,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDistance = result['distance'];
        _selectedPriceTier = result['price'];
        _selectedTime = result['time'];
        _selectedType = result['type'];
        _sortBy = result['sortBy'];
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1015),
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
      backgroundColor: const Color(0xFF0D1015),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        "All Arenas",
        style: GoogleFonts.urbanist(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _GlassSearchBar(controller: _searchController)),
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
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
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ArenaCard(arena: _filteredArenas[index]),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          Text(
            "No Arenas Found",
            style: GoogleFonts.urbanist(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your search or filters.",
            style: GoogleFonts.urbanist(color: Colors.white54, fontSize: 16),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _GlassSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white54),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.greenAccent,
                  decoration: const InputDecoration(
                    hintText: "Search arenas, activities...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final double? initialDistance;
  final int? initialPrice;
  final String initialTime;
  final MainActivity? initialType;
  final String initialSortBy;

  const _FilterSheet({
    this.initialDistance,
    this.initialPrice,
    required this.initialTime,
    this.initialType,
    required this.initialSortBy,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double? _distance;
  late int? _price;
  late String _time;
  late MainActivity? _type;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _resetToInitial();
  }

  void _resetToInitial() {
    _distance = widget.initialDistance;
    _price = widget.initialPrice;
    _time = widget.initialTime;
    _type = widget.initialType;
    _sortBy = widget.initialSortBy;
  }

  void _resetToDefaults() {
    HapticFeedback.mediumImpact();
    setState(() {
      _distance = _defaultDistance;
      _price = null;
      _time = _defaultTime;
      _type = null;
      _sortBy = _defaultSortBy;
    });
  }

  void _applyAndPop() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, {
      'distance': _distance,
      'price': _price,
      'time': 'time',
      'type': 'type',
      'sortBy': _sortBy,
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _filterTitle("Distance (km)"),
                  _distanceSlider(),
                  _filterTitle("Price"),
                  _priceTiers(),
                  _filterTitle("Time"),
                  _timeOptions(),
                  _filterTitle("Type"),
                  _typeChips(),
                  _filterTitle("Sort By"),
                  _sortOptions(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 5,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Filter & Sort",
          style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _resetToDefaults,
            child: Text(
              "Reset",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _applyAndPop,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ... rest of the filter widgets (_filterTitle, sliders, chips) ...
  // They are mostly the same, but with haptic feedback added to selections.

  Widget _filterTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget _distanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _distance == null ? 'Any' : 'Up to ${_distance?.toStringAsFixed(1)} km',
          style: const TextStyle(color: Colors.white70),
        ),
        Slider(
          value: _distance ?? 10.0,
          min: 0,
          max: 20,
          divisions: 40, // More divisions for smoother sliding
          activeColor: Colors.greenAccent,
          inactiveColor: Colors.white30,
          label: _distance?.toStringAsFixed(1),
          onChanged: (value) {
            setState(() => _distance = value);
          },
        ),
      ],
    );
  }

  Widget _priceTiers() {
    final tiers = {1: '₹', 2: '₹₹', 3: '₹₹₹', 4: '₹₹₹₹'};
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiers.entries.map((entry) {
        return _buildChip(
          label: entry.value,
          isSelected: _price == entry.key,
          onSelected: () {
            HapticFeedback.lightImpact();
            setState(() => _price = (_price == entry.key) ? null : entry.key);
          },
        );
      }).toList(),
    );
  }

  Widget _timeOptions() {
    final times = ['Anytime', 'Open Now'];
    return Wrap(
      spacing: 12,
      children: times.map((label) {
        return _buildChip(
          label: label,
          isSelected: _time == label,
          onSelected: () {
            HapticFeedback.lightImpact();
            setState(() => _time = label);
          },
        );
      }).toList(),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: MainActivity.values.map((type) {
        final label = type.name[0].toUpperCase() + type.name.substring(1);
        return _buildChip(
          label: label,
          isSelected: _type == type,
          onSelected: () {
            HapticFeedback.lightImpact();
            setState(() => _type = (_type == type) ? null : type);
          },
        );
      }).toList(),
    );
  }

  Widget _sortOptions() {
    final sorts = ['Popularity', 'Ratings', 'Lowest Price', 'Nearest'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: sorts.map((label) {
        return _buildChip(
          label: label,
          isSelected: _sortBy == label,
          onSelected: () {
            HapticFeedback.lightImpact();
            setState(() => _sortBy = label);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: const Color(0xFF2C2C2E),
      selectedColor: Colors.greenAccent,
      labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold),
      shape: const StadiumBorder(), // More modern, pill-shaped border
      side: BorderSide(
        color: isSelected ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }
}