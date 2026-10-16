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
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/booking/domain/entities/booking_accessory.dart';
import '../../domain/entities/arena_details_entity.dart';

class BookingSheet extends StatefulWidget {
  final String venueId;
  final String serviceId;
  final List<String> initialSelectedUnitIds;
  final Color accentColor;
  final Future<void> Function({
    required int duration,
    required DateTime startDateTime,
    required List<String> serviceUnitIds,
    required List<BookingAccessorySelection> accessorySelections,
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
  bool _isProcessing = false;
  int _selectedDateIndex = 0; // 0 = today

  late final List<DateTime> _dates;

  List<ArenaDevice> _availableUnits = [];
  final Set<String> _selectedUnitIds = {};
  final Map<String, int> _accessoryQuantities = {};
  bool _isLoadingAvailability = false;
  bool _isFindingNextSlot = false;
  String? _availabilityError;
  int _availabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialStart = _nextBookableStart(now);
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    _startTime = TimeOfDay.fromDateTime(initialStart);
    _selectedDateIndex = DateTime(
      initialStart.year,
      initialStart.month,
      initialStart.day,
    ).difference(_dates.first).inDays.clamp(0, _dates.length - 1);
    _selectedUnitIds.addAll(widget.initialSelectedUnitIds);
    _loadSmartInitialSlot().ignore();
  }

  DateTime _nextBookableStart(DateTime now) {
    final roundedMinute = ((now.minute ~/ 5) + 1) * 5;
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(Duration(minutes: roundedMinute));
  }

  double get totalCost {
    final selectedUnitRate = _availableUnits
        .where((unit) => _selectedUnitIds.contains(unit.id))
        .fold<double>(
          0,
          (total, unit) => total + unit.priceFor(_dates[_selectedDateIndex]),
        );
    return selectedUnitRate * _duration + _accessoryPreviewTotal;
  }

  String _accessoryKey(String unitId, String accessoryId) =>
      '$unitId:$accessoryId';

  int _accessoryQuantity(String unitId, String accessoryId) =>
      _accessoryQuantities[_accessoryKey(unitId, accessoryId)] ?? 0;

  double get _accessoryPreviewTotal {
    var total = 0.0;
    for (final unit in _availableUnits) {
      if (!_selectedUnitIds.contains(unit.id)) continue;
      for (final accessory in unit.accessories) {
        final quantity = _accessoryQuantity(unit.id, accessory.id);
        final billableQuantity = quantity - accessory.includedQuantity;
        if (billableQuantity <= 0) continue;
        final intervals =
            accessory.isTimeBased
                ? (_duration * 60 / accessory.billingIntervalMinutes).ceil()
                : 1;
        total += billableQuantity * accessory.unitPrice * intervals;
      }
    }
    return total;
  }

  List<BookingAccessorySelection> get _accessorySelections =>
      _accessoryQuantities.entries.where((entry) => entry.value > 0).map((
        entry,
      ) {
        final parts = entry.key.split(':');
        return BookingAccessorySelection(
          serviceUnitId: parts.first,
          accessoryId: parts.last,
          quantity: entry.value,
        );
      }).toList();

  void _pruneAccessorySelections() {
    _accessoryQuantities.removeWhere((key, _) {
      final unitId = key.split(':').first;
      return !_selectedUnitIds.contains(unitId);
    });
  }

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

  bool get _startsInFuture => _startDateTime.isAfter(DateTime.now());

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

  Future<void> _loadSmartInitialSlot() async {
    if (mounted) setState(() => _isFindingNextSlot = true);
    try {
      final next = await locator.arenaCtrl.loadNextAvailableBookingStart(
        serviceId: widget.serviceId,
        duration: Duration(hours: _duration),
        fromTime: _nextBookableStart(DateTime.now()),
      );
      if (!mounted) return;
      if (next == null || !_applySlot(next)) {
        setState(() {
          _availabilityError =
              'No bookable time is available in the next 7 days.';
          _availableUnits = [];
        });
        return;
      }
      await _loadAvailability(autoAdvance: false);
    } catch (_) {
      if (mounted) {
        setState(
          () => _availabilityError = 'Failed to find the next available time.',
        );
      }
    } finally {
      if (mounted) setState(() => _isFindingNextSlot = false);
    }
  }

  bool _applySlot(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    final index = day.difference(_dates.first).inDays;
    if (index < 0 || index >= _dates.length) return false;
    setState(() {
      _selectedDateIndex = index;
      _startTime = TimeOfDay.fromDateTime(value);
    });
    return true;
  }

  Future<void> _loadAvailability({bool autoAdvance = true}) async {
    final requestId = ++_availabilityRequestId;
    if (!mounted) return;
    setState(() {
      _isLoadingAvailability = true;
      _availabilityError = null;
    });

    try {
      final start = _startDateTime;
      final end = start.add(Duration(hours: _duration));

      if (!start.isAfter(DateTime.now())) {
        if (!mounted || requestId != _availabilityRequestId) return;
        setState(() {
          _availableUnits = [];
          _selectedUnitIds.clear();
          _accessoryQuantities.clear();
          _availabilityError = 'Choose a future start time.';
          _isLoadingAvailability = false;
        });
        return;
      }

      final units = await locator.arenaCtrl.loadAvailableUnits(
        serviceId: widget.serviceId,
        startTime: start,
        endTime: end,
      );

      if (!mounted || requestId != _availabilityRequestId) return;
      if (units.isEmpty && autoAdvance) {
        final next = await locator.arenaCtrl.loadNextAvailableBookingStart(
          serviceId: widget.serviceId,
          duration: Duration(hours: _duration),
          fromTime: start.add(const Duration(minutes: 1)),
        );
        if (!mounted || requestId != _availabilityRequestId) return;
        if (next != null && _applySlot(next)) {
          AppIslandNotice.show(
            context,
            title: 'Next available time selected',
            message:
                'That slot is unavailable. We moved you to ${TimeOfDay.fromDateTime(next).format(context)}.',
            tone: AppIslandNoticeTone.warning,
          );
          await _loadAvailability(autoAdvance: false);
          return;
        }
      }
      setState(() {
        _availableUnits = units;
        _selectedUnitIds.retainWhere(
          (id) => units.any((u) => u.id == id && u.isBookable),
        );
        _pruneAccessorySelections();
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
                          if (_selectedUnitIds.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _buildSectionLabel('ADD EXTRAS'),
                            const SizedBox(height: 12),
                            _buildAccessorySelection(),
                          ],
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
                  child: Text(
                    ('Reservation').toUpperCase(),
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
                      Text(
                        (_startTime.format(context)).toUpperCase(),
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
          final disabled = !unit.isBookable;
          return GestureDetector(
            onTap:
                disabled
                    ? null
                    : () {
                      setState(() {
                        if (isSelected) {
                          _selectedUnitIds.remove(unit.id);
                          _pruneAccessorySelections();
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
                    disabled
                        ? TiermetryColors.white.withValues(alpha: 0.025)
                        : isSelected
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
                        disabled
                            ? TiermetryColors.white.withValues(alpha: 0.22)
                            : isSelected
                            ? widget.accentColor
                            : TiermetryColors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.name,
                    style: TiermetryTypography.bodySmall(
                      color:
                          disabled
                              ? TiermetryColors.white.withValues(alpha: 0.38)
                              : isSelected
                              ? TiermetryColors.white
                              : TiermetryColors.white.withValues(alpha: 0.65),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.isMaintenance
                        ? 'Maintenance'
                        : disabled
                        ? 'Unavailable'
                        : '₹${unit.priceFor(_dates[_selectedDateIndex]).toStringAsFixed(0)} selected rate',
                    style: TiermetryTypography.bodySmall(
                      color:
                          disabled
                              ? TiermetryColors.white.withValues(alpha: 0.35)
                              : widget.accentColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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

  Widget _buildAccessorySelection() {
    final selectedUnits =
        _availableUnits
            .where((unit) => _selectedUnitIds.contains(unit.id))
            .where((unit) => unit.accessories.isNotEmpty)
            .toList();
    if (selectedUnits.isEmpty) {
      return Text(
        'No extras are configured for the selected rigs.',
        style: TiermetryTypography.bodySmall(
          color: TiermetryColors.white.withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      children:
          selectedUnits.map((unit) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TiermetryColors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(TiermetryRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unit.accessories.map((accessory) {
                    final quantity = _accessoryQuantity(unit.id, accessory.id);
                    final unitLabel =
                        accessory.isTimeBased
                            ? '₹${accessory.unitPrice.toStringAsFixed(0)} / ${accessory.billingIntervalMinutes} min'
                            : '₹${accessory.unitPrice.toStringAsFixed(0)} each';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  accessory.name,
                                  style: TiermetryTypography.bodySmall(
                                    color: TiermetryColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${accessory.includedQuantity} included · $unitLabel',
                                  style: TiermetryTypography.bodySmall(
                                    color: TiermetryColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove ${accessory.name}',
                            onPressed:
                                quantity == 0
                                    ? null
                                    : () => setState(() {
                                      _accessoryQuantities[_accessoryKey(
                                            unit.id,
                                            accessory.id,
                                          )] =
                                          quantity - 1;
                                    }),
                            icon: const Icon(CupertinoIcons.minus_circle),
                            color: TiermetryColors.white,
                          ),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add ${accessory.name}',
                            onPressed:
                                quantity >= 25
                                    ? null
                                    : () => setState(() {
                                      _accessoryQuantities[_accessoryKey(
                                            unit.id,
                                            accessory.id,
                                          )] =
                                          quantity + 1;
                                    }),
                            icon: const Icon(CupertinoIcons.add_circled_solid),
                            color: widget.accentColor,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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
        !_isFindingNextSlot &&
        _selectedUnitIds.isNotEmpty &&
        !_isLoadingAvailability &&
        _startsInFuture;

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
                        '${_selectedUnitIds.length} rig${_selectedUnitIds.length > 1 ? 's' : ''}',
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
                          Text(
                            ('₹').toUpperCase(),
                            style: TiermetryTypography.title(
                              fontSize: 15,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(
                            ('${totalCost.toInt()}').toUpperCase(),
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
                                if (!_startDateTime.isAfter(DateTime.now())) {
                                  AppIslandNotice.show(
                                    context,
                                    title: 'Choose a future time',
                                    message:
                                        'The booking start must be later than now.',
                                    tone: AppIslandNoticeTone.warning,
                                  );
                                  return;
                                }
                                setState(() => _isProcessing = true);
                                try {
                                  await widget.onConfirm(
                                    duration: _duration,
                                    startDateTime: _startDateTime,
                                    serviceUnitIds: _selectedUnitIds.toList(),
                                    accessorySelections: _accessorySelections,
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
