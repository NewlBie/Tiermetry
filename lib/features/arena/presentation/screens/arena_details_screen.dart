import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/arena/domain/entities/arena_details_entity.dart';
import 'package:tiermetry/features/arena/domain/entities/arena_entity.dart';
import 'package:tiermetry/features/booking/presentation/screens/booking_screen.dart';
import 'package:tiermetry/features/payment/domain/entities/payment_status.dart';
import 'package:tiermetry/features/payment/presentation/screens/mock_payment_screen.dart';

import '../widgets/booking_sheet.dart';
import '../widgets/booking_status_overlay.dart';
import 'arena_map_screen.dart';

class ArenaDetailsScreen extends StatefulWidget {
  final ArenaEntity arena;

  const ArenaDetailsScreen({required this.arena, super.key});

  @override
  State<ArenaDetailsScreen> createState() => _ArenaDetailsScreenState();
}

class _ArenaDetailsScreenState extends State<ArenaDetailsScreen>
    with RefreshRateMixin {
  late Future<ArenaDetailsEntity?> _detailsFuture;
  final Set<String> _selectedDevices = {};
  String? _selectedServiceId;
  bool isDescExpanded = false;
  int activeTab = 0; // 0: Overview, 1: Specs & Games, 2: Rules
  bool _showSuccessOverlay = false;
  bool _isProcessingPayment = false;
  String? _lastHoldId;
  DateTime? _holdExpiresAt;

  @override
  void initState() {
    super.initState();
    _detailsFuture = locator.arenaCtrl.loadArenaDetails(widget.arena.id);
  }

  void toggleSelection(String serviceId, String deviceId) {
    setState(() {
      if (_selectedServiceId != null && _selectedServiceId != serviceId) {
        _selectedDevices.clear();
      }
      _selectedServiceId = serviceId;

      if (_selectedDevices.contains(deviceId)) {
        _selectedDevices.remove(deviceId);
        if (_selectedDevices.isEmpty) _selectedServiceId = null;
      } else {
        _selectedDevices.add(deviceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldColor = TiermetryColors.background;
    const accentColor = TiermetryColors.accentAppleBlue;

    return Scaffold(
      backgroundColor: scaffoldColor,
      extendBody: true,
      body: FutureBuilder<ArenaDetailsEntity?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(
                radius: 15,
                color: TiermetryColors.white,
              ),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return AppErrorState(
              message: 'Failed to load arena details.',
              onRetry:
                  () => setState(() {
                    _detailsFuture = locator.arenaCtrl.loadArenaDetails(
                      widget.arena.id,
                    );
                  }),
            );
          }

          final arenaDetails = snapshot.data!;

          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    arenaDetails.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildCoverImage(context, arenaDetails),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TiermetrySpacing.screenPadding,
                        vertical: TiermetrySpacing.xl,
                      ),
                      child: _buildDetailsContent(
                        context,
                        arenaDetails,
                        accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBookingBar(context, accentColor),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton:
          _showSuccessOverlay
              ? BookingStatusOverlay(
                isSuccess: true,
                title: 'Spot Reserved!',
                message:
                    'Your rig is temporarily held at ${widget.arena.name}. Please complete the payment to confirm.',
                bookingId: _lastHoldId,
                expiresAt: _holdExpiresAt,
                actionLabel: 'Pay Now',
                onTimeout: () {
                  if (mounted) {
                    setState(() => _showSuccessOverlay = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Reservation hold expired. Please try booking again.',
                        ),
                        backgroundColor: TiermetryColors.negative,
                      ),
                    );
                  }
                },
                onAction: () async {
                  if (_lastHoldId != null && !_isProcessingPayment) {
                    setState(() => _isProcessingPayment = true);
                    try {
                      final order = await locator.paymentRepo.initiatePayment(
                        holdId: _lastHoldId!,
                      );

                      if (!context.mounted) return;

                      final result = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (context) => MockPaymentScreen(order: order),
                        ),
                      );

                      if (result == PaymentStatus.paid) {
                        await locator.paymentCtrl.verifyPayment(order.orderId);
                        if (!context.mounted) return;
                        setState(() => _showSuccessOverlay = false);
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const BookingScreen(),
                          ),
                        );
                      } else {
                        // Sync status to DB if it's not null (meaning a button was clicked)
                        if (result is PaymentStatus) {
                          await locator.paymentCtrl.verifyPayment(
                            order.orderId,
                          );
                        }

                        // Release the hold on failure or cancel
                        if (_lastHoldId != null) {
                          await locator.bookingCtrl.releaseHold(_lastHoldId!);
                        }

                        if (context.mounted) {
                          setState(() => _showSuccessOverlay = false);
                          final message =
                              result == PaymentStatus.failed
                                  ? 'Payment failed. Your hold has been released.'
                                  : 'Payment cancelled. Your hold has been released.';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    } catch (e) {
                      debugPrint('Payment failed: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessingPayment = false);
                    }
                  }
                },
              )
              : null,
    );
  }

  Widget _buildCoverImage(BuildContext context, ArenaDetailsEntity arena) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple back button at the top
        Padding(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.lg,
            right: TiermetrySpacing.lg,
            top: 60, // Padding for status bar
            bottom: TiermetrySpacing.sm,
          ),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const FaIcon(
              FontAwesomeIcons.chevronLeft,
              color: TiermetryColors.white,
              size: 22,
            ),
          ),
        ),
        // Embedded rounded image
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TiermetrySpacing.screenPadding,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'arena_${arena.id}',
                  child: Image.asset(arena.image, fit: BoxFit.cover),
                ),
                if (arena.isVerified)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/logo/HomiesTrans.svg',
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HOMIE CHECKED',
                          style: TiermetryTypography.label(
                            color: TiermetryColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: TiermetryColors.surfaceUnderlay,
                    borderRadius: TiermetryRadii.pill,
                    border: Border.all(color: Colors.transparent),
                    shadows: const [],
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.solidStar,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          arena.rating.toString(),
                          style: TiermetryTypography.label(
                            color: Colors.amber,
                          ).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    ArenaDetailsEntity arena,
    Color accentColor,
  ) {
    const textColorPrimary = TiermetryColors.white;
    const textColorSecondary = TiermetryColors.textMuted;
    const cardBackgroundColor = TiermetryColors.surfaceUnderlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (arena.name).toUpperCase(),
          style: TiermetryTypography.displayLarge(
            color: textColorPrimary,
          ).copyWith(
            height: 1.1,
            fontSize: 32, // Reduced from 44
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        _buildLocationCard(
          context,
          arena,
          textColorSecondary,
          cardBackgroundColor,
          accentColor,
        ),
        const SizedBox(height: 20),

        // Features Quick Grid (Compact)
        _buildFeaturesQuickRow(arena, textColorSecondary),
        const SizedBox(height: TiermetrySpacing.xl),

        // Description with Read More
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              arena.desc,
              maxLines: isDescExpanded ? null : 3,
              overflow:
                  isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TiermetryTypography.bodySmall(
                height: 1.5,
                color: textColorSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => isDescExpanded = !isDescExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: TiermetrySpacing.sm,
                ),
                child: Text(
                  isDescExpanded ? 'Read Less' : 'Read More',
                  style: TiermetryTypography.bodySmall(color: accentColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TiermetrySpacing.md),

        // Segmented Control Tabs
        _buildTabsHeader(accentColor),
        const SizedBox(height: TiermetrySpacing.xl),

        // Tab Content
        _buildTabContent(
          arena,
          textColorSecondary,
          cardBackgroundColor,
          accentColor,
        ),
        const SizedBox(height: TiermetrySpacing.sectionGap),

        _infoTitle('Reserve Your Experience'),
        const SizedBox(height: TiermetrySpacing.lg),
        ...arena.devices.map((deviceGroup) {
          final sortedUnits = List.of(deviceGroup.units)..sort((a, b) {
            if (a.isOccupied == b.isOccupied) return 0;
            return a.isOccupied ? 1 : -1;
          });

          return _unitRow(
            deviceGroup.name,
            sortedUnits
                .asMap()
                .entries
                .map(
                  (entry) => _unitCard(
                    deviceGroup.id,
                    entry.value,
                    entry.key,
                    accentColor,
                    cardBackgroundColor,
                  ),
                )
                .toList(),
          );
        }),
        const SizedBox(height: 140),
      ],
    );
  }

  Widget _buildFeaturesQuickRow(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
  ) {
    return Wrap(
      spacing: TiermetrySpacing.lg,
      runSpacing: TiermetrySpacing.md,
      children: [
        _featureIcon(FontAwesomeIcons.snowflake, 'AC', arena.hasAC),
        _featureIcon(FontAwesomeIcons.bolt, 'UPS', arena.hasPowerBackup),
        _featureIcon(FontAwesomeIcons.wifi, 'Fiber', true),
        _featureIcon(
          FontAwesomeIcons.utensils,
          'Food',
          arena.amenity.toLowerCase().contains('cafe'),
        ),
        _featureIcon(FontAwesomeIcons.shieldHalved, 'Safety', true),
      ],
    );
  }

  Widget _featureIcon(FaIconData icon, String label, bool active) {
    return Column(
      children: [
        AppSurface(
          padding: const EdgeInsets.all(TiermetrySpacing.md),
          color:
              active
                  ? TiermetryColors.accentAppleBlue.withValues(alpha: 0.1)
                  : TiermetryColors.surfaceUnderlay,
          borderRadius: TiermetryRadii.pill,
          border: Border.all(color: Colors.transparent),
          shadows: const [],
          child: FaIcon(
            icon,
            size: 20,
            color:
                active
                    ? TiermetryColors.accentAppleBlue
                    : TiermetryColors.gray100,
          ),
        ),
        const SizedBox(height: TiermetrySpacing.sm),
        Text(
          label,
          style: TiermetryTypography.bodySmall(
            color:
                active
                    ? TiermetryColors.white.withValues(alpha: 0.7)
                    : TiermetryColors.gray100,
          ),
        ),
      ],
    );
  }

  Widget _buildTabsHeader(Color accentColor) {
    return Row(
      children: [
        _tabItem(0, 'Overview', accentColor),
        const SizedBox(width: 24),
        _tabItem(1, 'Hardware', accentColor),
        const SizedBox(width: 24),
        _tabItem(2, 'Policies', accentColor),
      ],
    );
  }

  Widget _tabItem(int index, String label, Color accentColor) {
    final bool isSelected = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TiermetryTypography.title(
          color: isSelected ? TiermetryColors.white : TiermetryColors.textMuted,
          fontSize: 22,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTabContent(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
    switch (activeTab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewGrid(arena, textColorSecondary, cardBackgroundColor),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpecificationsGrid(
              arena,
              textColorSecondary,
              cardBackgroundColor,
            ),
            const SizedBox(height: 24),
            _infoTitle('Pre-installed Games'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  arena.gameLibrary.map((game) => _gameBadge(game)).toList(),
            ),
          ],
        );
      case 2:
        return _buildPoliciesSection(
          arena,
          textColorSecondary,
          cardBackgroundColor,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _gameBadge(String label) => AppSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: TiermetrySpacing.md,
      vertical: TiermetrySpacing.sm,
    ),
    color: TiermetryColors.surfaceUnderlay,
    borderRadius: TiermetryRadii.sm,
    border: Border.all(color: TiermetryColors.borderSubtle, width: 0.5),
    shadows: const [],
    child: Text(
      label,
      style: TiermetryTypography.bodySmall(
        color: TiermetryColors.white.withValues(alpha: 0.7),
      ),
    ),
  );

  Widget _buildOverviewGrid(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _specChip(
                FontAwesomeIcons.clock,
                'Hours',
                arena.hours,
                textColorSecondary,
                cardBackgroundColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _specChip(
                FontAwesomeIcons.gaugeHigh,
                'Internet',
                arena.internet,
                textColorSecondary,
                cardBackgroundColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _specChip(
          FontAwesomeIcons.chair,
          'Amenities',
          arena.amenity,
          textColorSecondary,
          cardBackgroundColor,
        ),
      ],
    );
  }

  Widget _buildSpecificationsGrid(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) {
    List<Widget> specs;
    if (arena.specs is GamingSpecs) {
      final gs = arena.specs as GamingSpecs;
      specs = [
        _specChip(
          FontAwesomeIcons.desktop,
          'Monitor',
          gs.refreshRate,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          FontAwesomeIcons.gamepad,
          'GPU',
          gs.graphicsCard,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          FontAwesomeIcons.microchip,
          'Processor',
          gs.processor,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          FontAwesomeIcons.keyboard,
          'Peripherals',
          'Pro-grade',
          textColorSecondary,
          cardBackgroundColor,
        ),
      ];
    } else {
      final ts = arena.specs as TurfSpecs;
      specs = [
        _specChip(
          FontAwesomeIcons.leaf,
          'Surface',
          ts.surface,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          FontAwesomeIcons.lightbulb,
          'Lighting',
          ts.lighting,
          textColorSecondary,
          cardBackgroundColor,
        ),
      ];
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: specs,
    );
  }

  Widget _buildPoliciesSection(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policyItem(
          FontAwesomeIcons.ban,
          'Cancellation',
          arena.cancellationPolicy,
          textColorSecondary,
        ),
        const SizedBox(height: 16),
        _policyItem(
          FontAwesomeIcons.phone,
          'Contact',
          arena.contactPhone,
          textColorSecondary,
        ),
        const SizedBox(height: 16),
        ...arena.rules.map(
          (rule) => _policyItem(
            FontAwesomeIcons.gavel,
            'Rule',
            rule,
            textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _policyItem(
    FaIconData icon,
    String title,
    String value,
    Color textColorSecondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, color: TiermetryColors.accentAppleBlue, size: 18),
        const SizedBox(width: TiermetrySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TiermetryTypography.bodySmall(color: textColorSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ArenaMapScreen(arena: arena),
            ),
          ),
      child: AppSurface(
        padding: const EdgeInsets.all(TiermetrySpacing.lg),
        color: cardBackgroundColor,
        borderRadius: TiermetryRadii.md,
        border: Border.all(color: Colors.transparent),
        shadows: const [],
        child: Row(
          children: [
            AppSurface(
              padding: const EdgeInsets.all(TiermetrySpacing.md),
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: TiermetryRadii.pill,
              border: Border.all(color: Colors.transparent),
              shadows: const [],
              child: Icon(
                Icons.location_on_rounded,
                size: 24,
                color: accentColor,
              ),
            ),
            const SizedBox(width: TiermetrySpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TiermetryTypography.bodySmall(
                      color: textColorSecondary,
                    ),
                  ),
                  Text(
                    arena.shortAddress,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              color: textColorSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitRow(String label, List<Widget> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TiermetryTypography.bodySmall(
            color: TiermetryColors.textMuted,
          ),
        ),
        const SizedBox(height: TiermetrySpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (int i = 0; i < units.length; i++) ...[
                units[i],
                if (i < units.length - 1)
                  const SizedBox(width: TiermetrySpacing.cardGap),
              ],
            ],
          ),
        ),
        const SizedBox(height: TiermetrySpacing.xl),
      ],
    );
  }

  Widget _unitCard(
    String serviceId,
    ArenaDevice unit,
    int index,
    Color accentColor,
    Color cardBackgroundColor,
  ) {
    final bool isSelected = _selectedDevices.contains(unit.id);

    String formatTime(DateTime time) {
      final h = time.hour;
      final m = time.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour12:$m $ampm';
    }

    return GestureDetector(
      onTap: () {
        if (!unit.isOccupied) toggleSelection(serviceId, unit.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 170,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
              border: Border.all(color: Colors.transparent, width: 2.5),
              boxShadow: null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.antiAlias,
              children: [
                // 0a. In-Use Red Gradient Overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  opacity: unit.isOccupied ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TiermetryRadii.md),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF0000), // Pure Red
                          Color(0x00FF0000), // Transparent Red
                        ],
                      ),
                    ),
                  ),
                ),

                // 0b. Selected Blue/Accent Gradient Overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TiermetryRadii.md),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withValues(alpha: 0.6),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  top: -20,
                  child: Text(
                    '${index + 1}',
                    textScaler: TextScaler.noScaling,
                    style: GoogleFonts.inter(
                      fontSize: 180,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Center(
                  child: Image.asset(
                    unit.image,
                    fit: BoxFit.contain,
                    color:
                        unit.isOccupied
                            ? TiermetryColors.black.withValues(alpha: 0.5)
                            : null,
                    colorBlendMode:
                        unit.isOccupied ? BlendMode.darken : BlendMode.dst,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        TiermetryColors.black.withValues(alpha: 0.7),
                        TiermetryColors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(TiermetrySpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: GoogleFonts.inter(
                            color: TiermetryColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${unit.price}',
                          textScaler: TextScaler.noScaling,
                          style: GoogleFonts.inter(
                            color: TiermetryColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AppSurface(
                      borderRadius: TiermetryRadii.pill,
                      color: accentColor,
                      border: Border.all(color: Colors.transparent),
                      shadows: const [],
                      padding: const EdgeInsets.all(TiermetrySpacing.xs),
                      child: const FaIcon(
                        FontAwesomeIcons.check,
                        color: TiermetryColors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TiermetrySpacing.sm),
          if (unit.isOccupied)
            Text(
              unit.occupiedTill != null
                  ? 'IN USE TILL ${formatTime(unit.occupiedTill!)}'
                  : 'IN USE',
              style: TiermetryTypography.label(color: TiermetryColors.negative),
            )
          else if (unit.nextBookingAt != null)
            Text(
              'NEXT AT ${formatTime(unit.nextBookingAt!)}',
              style: TiermetryTypography.label(color: Colors.amber),
            )
          else
            Text(
              'AVAILABLE',
              style: TiermetryTypography.label(
                color: TiermetryColors.accentNeonGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBookingBar(BuildContext context, Color accentColor) {
    if (_selectedDevices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: AppSurface(
        borderRadius: 100, // Pill shape
        color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.85),
        border: Border.all(color: TiermetryColors.borderSubtle),
        shadows: TiermetryShadows.highEmphasis,
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: TiermetryBlur.filter(TiermetryBlur.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: () => _showBookingSheet(context, accentColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 0,
              ),
              child: Text(
                'BOOK SELECTED (${_selectedDevices.length})',
                style: TiermetryTypography.action(
                  color: TiermetryColors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Color accentColor) {
    if (_selectedServiceId == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BookingSheet(
            venueId: widget.arena.id,
            serviceId: _selectedServiceId!,
            initialSelectedUnitIds: _selectedDevices.toList(),
            accentColor: accentColor,
            onConfirm: ({
              required int duration,
              required DateTime startDateTime,
              required int players,
              required List<String> addOns,
              required List<String> serviceUnitIds,
              required double totalAmount,
            }) async {
              final endDateTime = startDateTime.add(Duration(hours: duration));

              try {
                final hold = await locator.bookingCtrl.createReservationHold(
                  venueId: widget.arena.id,
                  startTime: startDateTime,
                  endTime: endDateTime,
                  serviceUnitIds: serviceUnitIds,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _lastHoldId = hold.id;
                    _holdExpiresAt = hold.expiresAt;
                    _showSuccessOverlay = true;
                    _selectedDevices.clear();
                    _selectedServiceId = null;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Widget _infoTitle(String label) => Text(
    (label).toUpperCase(),
    style: TiermetryTypography.title(
      color: TiermetryColors.white.withValues(alpha: 0.9),
      height: 1.2,
    ),
  );

  Widget _specChip(
    FaIconData icon,
    String label,
    String value,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) => AppSurface(
    height: 56,
    padding: const EdgeInsets.symmetric(
      horizontal: TiermetrySpacing.md,
      vertical: TiermetrySpacing.sm,
    ),
    color: cardBackgroundColor,
    borderRadius: TiermetryRadii.sm,
    border: Border.all(color: Colors.transparent),
    shadows: const [],
    child: Row(
      children: [
        FaIcon(icon, color: textColorSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TiermetryTypography.bodySmall(color: textColorSecondary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
