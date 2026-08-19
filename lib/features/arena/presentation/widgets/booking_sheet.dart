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
  final Future<void> Function({
    required int duration,
    required DateTime startDateTime,
    required int players,
    required List<String> addOns,
    required List<String> serviceUnitIds,
    required double totalAmount,
  })
  onConfirm;

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
  int _selectedDateIndex = 0; // 0 = today

  late final List<DateTime> _dates;

  List<ArenaDevice> _availableUnits = [];
  final Set<String> _selectedUnitIds = {};
  bool _isLoadingAvailability = false;
  String? _availabilityError;
  int _availabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    _selectedUnitIds.addAll(widget.initialSelectedUnitIds);
    _loadAvailability().ignore();
  }

  double get baseRate {
    if (_availableUnits.isEmpty) return 120;
    return _availableUnits.first.price.toDouble();
  }

  double get totalCost =>
      (baseRate * _selectedUnitIds.length * _duration) +
      (_addOns.length * 30 * _duration);

  DateTime get _startDateTime {
    final date = _dates[_selectedDateIndex];
    return DateTime(
      date.year,
      date.month,
      date.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  String get _formattedDatePreview {
    final date = _dates[_selectedDateIndex];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dayLabel;
    if (date == today) {
      dayLabel = 'Today';
    } else if (date == tomorrow) {
      dayLabel = 'Tomorrow';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayLabel = weekdays[date.weekday - 1];
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$dayLabel, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _loadAvailability() async {
    final requestId = ++_availabilityRequestId;
    if (!mounted) return;
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

      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _availableUnits = units;
        _selectedUnitIds.retainWhere((id) => units.any((u) => u.id == id));
        _isLoadingAvailability = false;
      });
    } catch (e) {
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _availabilityError = 'Failed to load availability.';
        _isLoadingAvailability = false;
      });
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
      },
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
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: TiermetryColors.background.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TiermetryRadii.xl),
            ),
          ),
          child: Stack(
            children: [
              // Subtle ambient glow blobs — matching the home screen language
              Positioned(
                right: -80,
                top: -60,
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: TiermetryBlur.filter(TiermetryBlur.lg),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.accentColor.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: 120,
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: TiermetryBlur.filter(TiermetryBlur.lg),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            TiermetryColors.accentLavender.withValues(
                              alpha: 0.10,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Column(
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
                          _buildSectionLabel('DATE'),
                          const SizedBox(height: 12),
                          _buildDateSelector(),
                          const SizedBox(height: 28),
                          _buildSectionLabel('TIME & DURATION'),
                          const SizedBox(height: 12),
                          _buildTimeAndDurationPicker(context),
                          const SizedBox(height: 28),
                          _buildSectionLabel('AVAILABLE RIGS'),
                          const SizedBox(height: 12),
                          _buildRigSelection(),
                          const SizedBox(height: 28),
                          _buildSectionLabel('PLAYERS'),
                          const SizedBox(height: 12),
                          _buildPlayerCounter(),
                          const SizedBox(height: 28),
                          _buildSectionLabel('ADD-ONS'),
                          const SizedBox(height: 12),
                          _buildAddonsRow(),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(context),
                ],
              ),
            ],
          ),
        ),
      ).animate().moveY(
        begin: 300,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: TiermetrySpacing.md),
      decoration: BoxDecoration(
        color: TiermetryColors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(('Reservation').toUpperCase(),
                    style: TiermetryTypography.title(
                      fontSize: 26,
                      color: TiermetryColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Book your slot in seconds',
                  style: TiermetryTypography.bodySmall(
                    fontSize: 13,
                    color: TiermetryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TiermetryColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close_rounded,
                color: TiermetryColors.white.withValues(alpha: 0.54),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: TiermetryTypography.label(
        color: widget.accentColor.withValues(alpha: 0.90),
        fontSize: 11,
        letterSpacing: 1.4,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Date selector — scrollable to prevent horizontal squishing on small screens
  // ─────────────────────────────────────────────────────────────
  Widget _buildDateSelector() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final todayMonth = today.month;

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _selectedDateIndex == index;
          final dayName = dayNames[date.weekday - 1];
          final dayNumber = date.day.toString().padLeft(2, '0');
          final isDifferentMonth = date.month != todayMonth;

          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final topLabel = isDifferentMonth ? months[date.month - 1] : dayName;

          return GestureDetector(
            onTap: () {
              if (_selectedDateIndex == index) return;
              setState(() => _selectedDateIndex = index);
              _loadAvailability();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              width: 54,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF2C2C2E)
                        : TiermetryColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: TiermetryColors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.12),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    topLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color:
                          isSelected
                              ? TiermetryColors.white.withValues(alpha: 0.70)
                              : TiermetryColors.white.withValues(alpha: 0.38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected
                              ? TiermetryColors.white
                              : TiermetryColors.white.withValues(alpha: 0.55),
                      height: 1.0,
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

  // ─────────────────────────────────────────────────────────────
  // Time + Duration: side-by-side, wrapped in FittedBox for responsiveness
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimeAndDurationPicker(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time picker tile
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: _pickStartTime,
              child: _InfoTile(
                label: 'START TIME',
                accentColor: widget.accentColor,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.clock_fill,
                        size: 16,
                        color: widget.accentColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text((_startTime.format(context)).toUpperCase(),
                        style: TiermetryTypography.title(
                          color: TiermetryColors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: TiermetryColors.white.withValues(alpha: 0.38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Duration tile
          Expanded(
            flex: 7,
            child: _InfoTile(
              label: 'DURATION',
              accentColor: widget.accentColor,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _duration,
                  onValueChanged: (val) {
                    setState(() => _duration = val ?? 1);
                    _loadAvailability();
                  },
                  thumbColor: widget.accentColor,
                  backgroundColor: TiermetryColors.black.withValues(
                    alpha: 0.30,
                  ),
                  children: {
                    for (var i = 1; i <= 4; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${i}h',
                          style: TiermetryTypography.bodySmall(
                            color: TiermetryColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRigSelection() {
    if (_isLoadingAvailability) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CupertinoActivityIndicator(color: widget.accentColor),
        ),
      );
    }
    if (_availabilityError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _availabilityError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (_availableUnits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: TiermetryColors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
        ),
        child: Text(
          'No rigs available for this slot.',
          style: TextStyle(
            color: TiermetryColors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _availableUnits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? widget.accentColor.withValues(alpha: 0.18)
                        : TiermetryColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(TiermetryRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.computer_rounded,
                    size: 16,
                    color:
                        isSelected
                            ? widget.accentColor
                            : TiermetryColors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.name,
                    style: TiermetryTypography.bodySmall(
                      color:
                          isSelected
                              ? TiermetryColors.white
                              : TiermetryColors.white.withValues(alpha: 0.65),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: widget.accentColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.group_rounded,
            color: TiermetryColors.white.withValues(alpha: 0.45),
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Players',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.white.withValues(alpha: 0.80),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.remove_rounded,
            accentColor: widget.accentColor,
            onTap: () => setState(() => _players = (_players - 1).clamp(1, 8)),
          ),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(('$_players').toUpperCase(),
                style: TiermetryTypography.title(
                  color: TiermetryColors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            accentColor: widget.accentColor,
            onTap: () => setState(() => _players = (_players + 1).clamp(1, 8)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Add-ons as a horizontal row, but wrapped in Expanded and FittedBoxes to fit any width
  // ─────────────────────────────────────────────────────────────
  Widget _buildAddonsRow() {
    final List<Map<String, dynamic>> addons = [
      {'emoji': '🎧', 'label': 'Headset', 'price': '₹30/h'},
      {'emoji': '🎮', 'label': 'Controller', 'price': '₹40/h'},
      {'emoji': '⚡', 'label': 'FPS Boost', 'price': '₹20/h'},
    ];

    return Row(
      children:
          addons.asMap().entries.map((entry) {
            final idx = entry.key;
            final addon = entry.value;
            final label = addon['label'] as String;
            final emoji = addon['emoji'] as String;
            final price = addon['price'] as String;
            final key = label;
            final isSelected = _addOns.contains(key);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx < addons.length - 1 ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap:
                      () => setState(
                        () =>
                            isSelected ? _addOns.remove(key) : _addOns.add(key),
                      ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? widget.accentColor.withValues(alpha: 0.14)
                              : TiermetryColors.surfaceUnderlay,
                      borderRadius: BorderRadius.circular(TiermetryRadii.md),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TiermetryTypography.bodySmall(
                              fontSize: 12,
                              color:
                                  isSelected
                                      ? TiermetryColors.white
                                      : TiermetryColors.white.withValues(
                                        alpha: 0.70,
                                      ),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            price,
                            style: TiermetryTypography.label(
                              fontSize: 10,
                              color:
                                  isSelected
                                      ? widget.accentColor
                                      : TiermetryColors.white.withValues(
                                        alpha: 0.35,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Footer: responsive layouts + FittedBoxes to prevent overflows
  // ─────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    final canConfirm =
        !_isProcessing &&
        _selectedUnitIds.isNotEmpty &&
        !_isLoadingAvailability;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: TiermetryColors.background.withValues(alpha: 0.80),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary strip — what the user is booking
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: TiermetryColors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 14,
                      color: TiermetryColors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$_formattedDatePreview  ·  ${_startTime.format(context)}  ·  ${_duration}h',
                          style: TiermetryTypography.bodySmall(
                            fontSize: 12,
                            color: TiermetryColors.white.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedUnitIds.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedUnitIds.length} rig${_selectedUnitIds.length > 1 ? 's' : ''}  ·  $_players player${_players > 1 ? 's' : ''}',
                        style: TiermetryTypography.bodySmall(
                          fontSize: 11,
                          color: TiermetryColors.white.withValues(alpha: 0.40),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Price + CTA
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL',
                        style: TiermetryTypography.label(
                          fontSize: 9,
                          color: TiermetryColors.white.withValues(alpha: 0.35),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(('₹').toUpperCase(),
                            style: TiermetryTypography.title(
                              fontSize: 15,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(('${totalCost.toInt()}').toUpperCase(),
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
                  const SizedBox(width: 16),
                  // CTA button
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          canConfirm
                              ? () async {
                                setState(() => _isProcessing = true);
                                try {
                                  await widget.onConfirm(
                                    duration: _duration,
                                    startDateTime: _startDateTime,
                                    players: _players,
                                    addOns: _addOns.toList(),
                                    serviceUnitIds: _selectedUnitIds.toList(),
                                    totalAmount: totalCost,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isProcessing = false);
                                  }
                                }
                              }
                              : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              canConfirm
                                  ? widget.accentColor
                                  : TiermetryColors.white.withValues(
                                    alpha: 0.10,
                                  ),
                          borderRadius: BorderRadius.circular(
                            TiermetryRadii.md,
                          ),
                          boxShadow:
                              canConfirm
                                  ? [
                                    BoxShadow(
                                      color: widget.accentColor.withValues(
                                        alpha: 0.38,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Center(
                          child:
                              _isProcessing
                                  ? const CupertinoActivityIndicator(
                                    color: TiermetryColors.white,
                                  )
                                  : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Confirm & Pay',
                                            style: TiermetryTypography.action(
                                              color:
                                                  canConfirm
                                                      ? TiermetryColors.white
                                                      : TiermetryColors.white
                                                          .withValues(
                                                            alpha: 0.30,
                                                          ),
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (canConfirm) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: TiermetryColors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
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

// ─────────────────────────────────────────────────────────────
// Reusable info tile (label on top, content below)
// ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String label;
  final Color accentColor;
  final Widget child;

  const _InfoTile({
    required this.label,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(TiermetryRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TiermetryTypography.label(
              fontSize: 9,
              color: TiermetryColors.white.withValues(alpha: 0.35),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Counter button (+ / -)
// ─────────────────────────────────────────────────────────────
class _CounterButton extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: TiermetryColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TiermetryColors.white, size: 20),
      ),
    );
  }
}
