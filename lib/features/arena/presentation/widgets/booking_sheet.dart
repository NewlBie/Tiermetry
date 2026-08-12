import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../domain/entities/arena_details_entity.dart';

class BookingSheet extends StatefulWidget {
  final String venueId;
  final String serviceId;
  final List<String> initialSelectedUnitIds;
  final Color accentColor;
  final void Function({
    required int duration,
    required DateTime startDateTime,
    required int players,
    required List<String> addOns,
    required List<String> serviceUnitIds,
    required double totalAmount,
  }) onConfirm;

  const BookingSheet({
    required this.venueId,
    required this.serviceId,
    required this.initialSelectedUnitIds,
    required this.accentColor,
    required this.onConfirm,
    super.key,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  int _duration = 1;
  TimeOfDay _startTime = TimeOfDay.now();
  int _players = 1;
  final Set<String> _addOns = {};
  bool _isProcessing = false;
  int _selectedDateIndex = 0; // 0: Today, 1: Tomorrow

  final List<String> _dates = ['Today', 'Tomorrow', 'Next Day'];
  
  List<ArenaDevice> _availableUnits = [];
  final Set<String> _selectedUnitIds = {};
  bool _isLoadingAvailability = false;
  String? _availabilityError;

  @override
  void initState() {
    super.initState();
    _selectedUnitIds.addAll(widget.initialSelectedUnitIds);
    _loadAvailability().ignore();
  }

  double get baseRate {
    if (_availableUnits.isEmpty) return 120;
    return _availableUnits.first.price.toDouble();
  }
  
  double get totalCost => (baseRate * _selectedUnitIds.length * _duration) + (_addOns.length * 30 * _duration);

  DateTime get _startDateTime {
    final now = DateTime.now();
    final date = now.add(Duration(days: _selectedDateIndex));
    return DateTime(date.year, date.month, date.day, _startTime.hour, _startTime.minute);
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
    });

    try {
      final start = _startDateTime;
      final end = start.add(Duration(hours: _duration));
      
      final units = await locator.arenaCtrl.loadAvailableUnits(
        serviceId: widget.serviceId,
        startTime: start,
        endTime: end,
      );

      if (mounted) {
        setState(() {
          _availableUnits = units;
          // Keep only units that are still available
          _selectedUnitIds.retainWhere((id) => units.any((u) => u.id == id));
          _isLoadingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availabilityError = 'Failed to load availability.';
          _isLoadingAvailability = false;
        });
      }
    }
  }

  void _pickStartTime() async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accentColor,
              onPrimary: TiermetryColors.white,
              surface: TiermetryColors.surfaceUnderlay,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) {
      setState(() => _startTime = picked);
      _loadAvailability().ignore();
    }
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
        filter: TiermetryBlur.filter(TiermetryBlur.md),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: TiermetryColors.background.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TiermetryRadii.xl),
            ),
            border:
                Border.all(color: TiermetryColors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('DATE & TIME SLOT'),
                      _buildDateSelector(),
                      const SizedBox(height: 16),
                      _buildTimeAndDurationPicker(context),
                      const SizedBox(height: 32),

                      _buildSectionHeader('AVAILABLE RIGS'),
                      _buildRigSelection(),
                      const SizedBox(height: 32),
  
                      _buildSectionHeader('PLAYERS'),
                      _buildPlayerCounter(),
                      const SizedBox(height: 32),
  
                      _buildSectionHeader('PREMIUM ADD-ONS'),
                      _buildAddonsGrid(),
                      const SizedBox(height: 100), // Space for footer
                    ],
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ).animate().moveY(begin: 300, end: 0, duration: 400.ms, curve: Curves.easeOutCirc),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: TiermetrySpacing.md),
      decoration: BoxDecoration(color: TiermetryColors.white.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TiermetrySpacing.xl).copyWith(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Reservation',
            style: TiermetryTypography.title(
              fontSize: 24,
              color: TiermetryColors.white,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: TiermetryColors.white.withValues(alpha: 0.54)),
            style: IconButton.styleFrom(backgroundColor: TiermetryColors.white.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TiermetryTypography.label(
          color: widget.accentColor,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRigSelection() {
    if (_isLoadingAvailability) {
      return const Center(child: CupertinoActivityIndicator(color: TiermetryColors.white));
    }
    if (_availabilityError != null) {
      return Text(_availabilityError!, style: const TextStyle(color: Colors.redAccent));
    }
    if (_availableUnits.isEmpty) {
      return Text('No rigs available for this slot.', style: TextStyle(color: TiermetryColors.white.withValues(alpha: 0.6)));
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableUnits.length,
        itemBuilder: (context, index) {
          final unit = _availableUnits[index];
          final isSelected = _selectedUnitIds.contains(unit.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedUnitIds.remove(unit.id);
                } else {
                  _selectedUnitIds.add(unit.id);
                }
              });
            },
            child: AppSurface(
              borderRadius: TiermetryRadii.sm,
              color: isSelected ? widget.accentColor.withValues(alpha: 0.2) : TiermetryColors.white.withValues(alpha: 0.05),
              border: Border.all(color: isSelected ? widget.accentColor : TiermetryColors.white.withValues(alpha: 0.1)),
              shadows: const [],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.computer_rounded,
                    size: 18,
                    color: isSelected ? TiermetryColors.white : TiermetryColors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    unit.name,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_dates.length, (index) {
        final bool isSelected = _selectedDateIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedDateIndex = index);
              _loadAvailability();
            },
            child: AppSurface(
              borderRadius: TiermetryRadii.sm,
              color:
                  isSelected
                      ? widget.accentColor.withValues(alpha: 0.15)
                      : Colors.transparent,
              border:
                  Border.all(
                    color: isSelected ? widget.accentColor : TiermetryColors.white.withValues(alpha: 0.1),
                  ),
              shadows: const [],
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  _dates[index],
                  style: TiermetryTypography.bodySmall(
                    color: isSelected ? TiermetryColors.white : TiermetryColors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeAndDurationPicker(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _pickStartTime,
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              color: TiermetryColors.surfaceUnderlay,
              borderRadius: TiermetryRadii.sm,
              border: Border.all(color: TiermetryColors.white.withValues(alpha: 0.1)),
              shadows: const [],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START AT',
                    style: TiermetryTypography.label(
                      fontSize: 10,
                      color: TiermetryColors.white.withValues(alpha: 0.38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startTime.format(context),
                    style: TiermetryTypography.title(
                      color: TiermetryColors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: AppSurface(
            padding: const EdgeInsets.all(16),
            color: TiermetryColors.surfaceUnderlay,
            borderRadius: TiermetryRadii.sm,
            border: Border.all(color: TiermetryColors.white.withValues(alpha: 0.1)),
            shadows: const [],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DURATION',
                  style: TiermetryTypography.label(
                    fontSize: 10,
                    color: TiermetryColors.white.withValues(alpha: 0.38),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _duration,
                  onValueChanged: (val) {
                    setState(() => _duration = val ?? 1);
                    _loadAvailability();
                  },
                  thumbColor: widget.accentColor,
                  backgroundColor: TiermetryColors.black.withValues(alpha: 0.26),
                  children: {
                    for (var i = 1; i <= 4; i++)
                      i: Text(
                        '${i}h',
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.white,
                          fontSize: 13,
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCounter() {
    return AppSurface(
      padding: const EdgeInsets.all(20),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.md,
      border: Border.all(color: TiermetryColors.white.withValues(alpha: 0.1)),
      shadows: const [],
      child: Row(
        children: [
          Icon(Icons.group_rounded, color: TiermetryColors.white.withValues(alpha: 0.54)),
          const SizedBox(width: 16),
          Text(
            'Total Players',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _counterButton(
            Icons.remove_rounded,
            () => setState(() => _players = (_players - 1).clamp(1, 8)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_players',
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 20,
              ),
            ),
          ),
          _counterButton(
            Icons.add_rounded,
            () => setState(() => _players = (_players + 1).clamp(1, 8)),
          ),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        padding: const EdgeInsets.all(TiermetrySpacing.sm),
        color: TiermetryColors.white.withValues(alpha: 0.1),
        borderRadius: 10,
        border: Border.all(color: Colors.transparent),
        shadows: const [],
        child: Icon(icon, color: TiermetryColors.white, size: 20),
      ),
    );
  }

  Widget _buildAddonsGrid() {
    final List<Map<String, dynamic>> addons = [
      {'label': '🎧 Headset', 'price': '₹30'},
      {'label': '🎮 Controller', 'price': '₹40'},
      {'label': '⚡ FPS Boost', 'price': '₹20'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
      itemBuilder: (context, index) {
        final addon = addons[index];
        final label = addon['label'] as String;
        final price = addon['price'] as String;
        final isSelected = _addOns.contains(label);
        return GestureDetector(
          onTap:
              () => setState(
                () => isSelected ? _addOns.remove(label) : _addOns.add(label),
              ),
          child: AppSurface(
            duration: const Duration(milliseconds: 200),
            color:
                isSelected
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : TiermetryColors.surfaceUnderlay,
            borderRadius: TiermetryRadii.sm,
            border:
                Border.all(
                  color: isSelected ? widget.accentColor : TiermetryColors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
            shadows: const [],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.split(' ')[0], style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  label.split(' ')[1],
                  style: TiermetryTypography.bodySmall(
                    fontSize: 11,
                    color: TiermetryColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  price,
                  style: TiermetryTypography.label(
                    fontSize: 10,
                    color: TiermetryColors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: TiermetryColors.black.withValues(alpha: 0.45),
            border: Border(top: BorderSide(color: TiermetryColors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PRICE',
                        style: TiermetryTypography.label(
                          fontSize: 10,
                          color: TiermetryColors.white.withValues(alpha: 0.38),
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: TiermetryTypography.title(
                              fontSize: 16,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(
                            '${totalCost.toInt()}',
                            style: TiermetryTypography.title(
                              fontSize: 28,
                              color: TiermetryColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 180,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          _isProcessing || _selectedUnitIds.isEmpty || _isLoadingAvailability
                              ? null
                              : () async {
                                setState(() => _isProcessing = true);
                                try {
                                  widget.onConfirm(
                                    duration: _duration,
                                    startDateTime: _startDateTime,
                                    players: _players,
                                    addOns: _addOns.toList(),
                                    serviceUnitIds: _selectedUnitIds.toList(),
                                    totalAmount: totalCost,
                                  );
                                } finally {
                                  if (mounted) setState(() => _isProcessing = false);
                                }
                              },
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                      child:
                          _isProcessing
                              ? const CupertinoActivityIndicator(
                                color: TiermetryColors.white,
                              )
                              : Text(
                                'Confirm & Pay',
                                style: TiermetryTypography.action(
                                  color: TiermetryColors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
