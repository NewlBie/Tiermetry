import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

// ─── Filter Result ────────────────────────────────────────────────────────────

class ArenaFilterResult {
  final double? maxDistance;
  final int? maxPriceTier;
  final double? minRating;
  final Set<String> platforms;
  final bool onlyOpenNow;
  final bool onlyOffers;
  final Set<String> amenities;
  final String sortBy;

  const ArenaFilterResult({
    required this.platforms,
    required this.onlyOpenNow,
    required this.onlyOffers,
    required this.amenities,
    required this.sortBy,
    this.maxDistance,
    this.maxPriceTier,
    this.minRating,
  });

  bool get hasActiveFilters =>
      maxDistance != null ||
      maxPriceTier != null ||
      minRating != null ||
      platforms.isNotEmpty ||
      onlyOpenNow ||
      onlyOffers ||
      amenities.isNotEmpty ||
      sortBy != ArenaFilterDefaults.sortBy;

  static const ArenaFilterResult defaults = ArenaFilterResult(
    platforms: {},
    onlyOpenNow: false,
    onlyOffers: false,
    amenities: {},
    sortBy: ArenaFilterDefaults.sortBy,
  );
}

class ArenaFilterDefaults {
  static const String sortBy = 'Recommended';
  static const double maxDistanceMax = 25.0;
}

// ─── All Sort Options ─────────────────────────────────────────────────────────

const List<_SortOption> _kSortOptions = [
  _SortOption('Recommended', Icons.auto_awesome_rounded),
  _SortOption('Distance', Icons.near_me_rounded),
  _SortOption('Rating', Icons.star_rounded),
  _SortOption('Price: Low → High', Icons.trending_up_rounded),
  _SortOption('Price: High → Low', Icons.trending_down_rounded),
  _SortOption('Popularity', Icons.local_fire_department_rounded),
  _SortOption('Newest', Icons.new_releases_rounded),
];

// ─── Platform Tags ────────────────────────────────────────────────────────────

const List<String> kPlatforms = [
  'PC',
  'PS5',
  'Xbox',
  'VR',
  'Racing',
  'Pool',
  'Bowling',
  'Other',
];

// ─── Amenity Tags ─────────────────────────────────────────────────────────────

const List<String> kAmenities = [
  'Parking',
  'Food & Drinks',
  'AC',
  'WiFi',
  'Locker',
  'Coaching',
];

// ─── Filter Sheet ─────────────────────────────────────────────────────────────

class FilterSheet extends StatefulWidget {
  final ArenaFilterResult initial;

  const FilterSheet({required this.initial, super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late double? _distance;
  late int? _priceTier;
  late double? _minRating;
  late Set<String> _platforms;
  late bool _onlyOpenNow;
  late bool _onlyOffers;
  late Set<String> _amenities;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.initial);
  }

  void _loadFrom(ArenaFilterResult r) {
    _distance = r.maxDistance;
    _priceTier = r.maxPriceTier;
    _minRating = r.minRating;
    _platforms = Set.from(r.platforms);
    _onlyOpenNow = r.onlyOpenNow;
    _onlyOffers = r.onlyOffers;
    _amenities = Set.from(r.amenities);
    _sortBy = r.sortBy;
  }

  void _resetToDefaults() {
    HapticFeedback.mediumImpact();
    setState(() => _loadFrom(ArenaFilterResult.defaults));
  }

  void _apply() {
    HapticFeedback.lightImpact();
    Navigator.pop(
      context,
      ArenaFilterResult(
        maxDistance: _distance,
        maxPriceTier: _priceTier,
        minRating: _minRating,
        platforms: Set.unmodifiable(_platforms),
        onlyOpenNow: _onlyOpenNow,
        onlyOffers: _onlyOffers,
        amenities: Set.unmodifiable(_amenities),
        sortBy: _sortBy,
      ),
    );
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
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.90),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TiermetryRadii.xl),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Sort By ──────────────────────────────────────────────
                    _sectionTitle('Sort By'),
                    _sortGrid(),

                    // ── Distance ─────────────────────────────────────────────
                    _sectionTitle('Distance'),
                    _distanceSlider(),

                    // ── Price ────────────────────────────────────────────────
                    _sectionTitle('Price'),
                    _priceTiers(),

                    // ── Rating ───────────────────────────────────────────────
                    _sectionTitle('Minimum Rating'),
                    _ratingPicker(),

                    // ── Platform ─────────────────────────────────────────────
                    _sectionTitle('Platform / Activity'),
                    _chipWrap(
                      items: kPlatforms,
                      selected: _platforms,
                      onToggle:
                          (v) => setState(() {
                            if (_platforms.contains(v)) {
                              _platforms.remove(v);
                            } else {
                              _platforms.add(v);
                            }
                          }),
                    ),

                    // ── Availability ─────────────────────────────────────────
                    _sectionTitle('Availability'),
                    _toggleRow(
                      label: 'Open Now',
                      icon: Icons.access_time_rounded,
                      value: _onlyOpenNow,
                      onChanged: (v) => setState(() => _onlyOpenNow = v),
                    ),

                    // ── Offers ───────────────────────────────────────────────
                    _sectionTitle('Offers'),
                    _toggleRow(
                      label: 'Has Active Offers',
                      icon: Icons.local_offer_rounded,
                      value: _onlyOffers,
                      onChanged: (v) => setState(() => _onlyOffers = v),
                    ),

                    // ── Amenities ────────────────────────────────────────────
                    _sectionTitle('Amenities'),
                    _chipWrap(
                      items: kAmenities,
                      selected: _amenities,
                      onToggle:
                          (v) => setState(() {
                            if (_amenities.contains(v)) {
                              _amenities.remove(v);
                            } else {
                              _amenities.add(v);
                            }
                          }),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildDragHandle() {
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
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FILTER & SORT',
              style: TiermetryTypography.title(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: _resetToDefaults,
              child: Text(
                'Reset all',
                style: TiermetryTypography.caption(
                  color: TiermetryColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white12, height: 20),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: _apply,
        style: ElevatedButton.styleFrom(
          backgroundColor: TiermetryColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TiermetryRadii.md),
          ),
        ),
        child: Text(
          'Apply Filters',
          style: TiermetryTypography.action(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: TiermetryTypography.titleSmall(
        fontSize: 13,
        color: Colors.white70,
      ),
    ),
  );

  // ─── Sort Grid ─────────────────────────────────────────────────────────────

  Widget _sortGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _kSortOptions.map((opt) {
            final isSelected = _sortBy == opt.label;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sortBy = opt.label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? TiermetryColors.primary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                  border: Border.all(
                    color:
                        isSelected
                            ? TiermetryColors.primary
                            : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color:
                          isSelected ? TiermetryColors.primary : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: TiermetryTypography.caption(
                        color:
                            isSelected
                                ? TiermetryColors.primary
                                : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // ─── Distance Slider ───────────────────────────────────────────────────────

  Widget _distanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _distance == null
                  ? 'Any distance'
                  : 'Up to ${_distance!.toStringAsFixed(1)} km',
              style: TiermetryTypography.caption(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            if (_distance != null)
              GestureDetector(
                onTap: () => setState(() => _distance = null),
                child: Text(
                  'Clear',
                  style: TiermetryTypography.caption(
                    color: TiermetryColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: TiermetryColors.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: TiermetryColors.primary,
            overlayColor: TiermetryColors.primary.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: _distance ?? ArenaFilterDefaults.maxDistanceMax,
            min: 1,
            max: ArenaFilterDefaults.maxDistanceMax,
            divisions: 48,
            onChanged: (v) => setState(() => _distance = v),
          ),
        ),
      ],
    );
  }

  // ─── Price Tiers ───────────────────────────────────────────────────────────

  Widget _priceTiers() {
    const tiers = {1: '₹', 2: '₹₹', 3: '₹₹₹', 4: '₹₹₹₹'};
    return Wrap(
      spacing: 8,
      children:
          tiers.entries
              .map(
                (e) => _chip(
                  label: e.value,
                  isSelected: _priceTier == e.key,
                  onTap:
                      () => setState(
                        () => _priceTier = (_priceTier == e.key) ? null : e.key,
                      ),
                ),
              )
              .toList(),
    );
  }

  // ─── Rating Picker ─────────────────────────────────────────────────────────

  Widget _ratingPicker() {
    final options = [null, 3.0, 3.5, 4.0, 4.5];
    return Wrap(
      spacing: 8,
      children:
          options.map((r) {
            final isSelected = _minRating == r;
            final label = r == null ? 'Any' : '$r+';
            return _chip(
              label: label,
              isSelected: isSelected,
              onTap:
                  () => setState(
                    () => _minRating = (isSelected && r != null) ? null : r,
                  ),
              leadingIcon: r != null ? Icons.star_rounded : null,
            );
          }).toList(),
    );
  }

  // ─── Generic Chip Wrap ─────────────────────────────────────────────────────

  Widget _chipWrap({
    required List<String> items,
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items
              .map(
                (item) => _chip(
                  label: item,
                  isSelected: selected.contains(item),
                  onTap: () => onToggle(item),
                ),
              )
              .toList(),
    );
  }

  // ─── Toggle Row ────────────────────────────────────────────────────────────

  Widget _toggleRow({
    required String label,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              value
                  ? TiermetryColors.primary.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
          border: Border.all(
            color:
                value
                    ? TiermetryColors.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? TiermetryColors.primary : Colors.white54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TiermetryTypography.caption(
                  color: value ? Colors.white : Colors.white70,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? TiermetryColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? TiermetryColors.primary : Colors.white30,
                  width: 1.5,
                ),
              ),
              child:
                  value
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Generic Chip ──────────────────────────────────────────────────────────

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? leadingIcon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? TiermetryColors.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
          border: Border.all(
            color:
                isSelected
                    ? TiermetryColors.primary
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 13,
                color: isSelected ? TiermetryColors.primary : Colors.white54,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TiermetryTypography.caption(
                color: isSelected ? TiermetryColors.primary : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Types ───────────────────────────────────────────────────────────────

class _SortOption {
  final String label;
  final IconData icon;
  const _SortOption(this.label, this.icon);
}
