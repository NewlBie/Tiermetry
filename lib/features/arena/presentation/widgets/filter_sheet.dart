import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/arena_entity.dart'; // For ArenaActivity enum

// Copy of default constants used in the filter sheet
const double _defaultDistance = 10.0;
const String _defaultTime = 'Anytime';
const String _defaultSortBy = 'Popularity';

class FilterSheet extends StatefulWidget {
  final double? initialDistance;
  final int? initialPrice;
  final String initialTime;
  final ArenaActivity? initialType;
  final String initialSortBy;

  const FilterSheet({
    required this.initialTime, required this.initialSortBy, super.key,
    this.initialDistance,
    this.initialPrice,
    this.initialType,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late double? _distance;
  late int? _price;
  late String _time;
  late ArenaActivity? _type;
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
      'time': _time,
      'type': _type,
      'sortBy': _sortBy,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      borderRadius: 0,
      color: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: TiermetryBlur.filter(TiermetryBlur.sm),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding:
              const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
            color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TiermetryRadii.xl),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _filterTitle('Distance (km)'),
                    _distanceSlider(),
                    _filterTitle('Price'),
                    _priceTiers(),
                    _filterTitle('Time'),
                    _timeOptions(),
                    _filterTitle('Type'),
                    _typeChips(),
                    _filterTitle('Sort By'),
                    _sortOptions(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
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
          'Filter & Sort',
          style: TiermetryTypography.title(
            fontSize: 20,
            color: Colors.white,
          ),
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
            child: const Text(
              'Reset',
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
            child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _filterTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TiermetryTypography.titleSmall(
        fontSize: 16,
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
      children: ArenaActivity.values.map((type) {
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
      backgroundColor: TiermetryColors.surface,
      selectedColor: Colors.greenAccent,
      labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold),
      shape: const StadiumBorder(), // More modern, pill-shaped border
      side: BorderSide(
        color: isSelected ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }
}

