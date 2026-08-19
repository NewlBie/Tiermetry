import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, arenaDetails),
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

  Widget _buildSliverAppBar(BuildContext context, ArenaDetailsEntity arena) {
    return SliverAppBar(
      expandedHeight: 320.0,
      backgroundColor: TiermetryColors.background,
      pinned: true,
      stretch: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'arena_${arena.id}',
              child: Image.asset(arena.image, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    TiermetryColors.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            if (arena.isVerified)
              Positioned(
                bottom: 16,
                left: 20,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/verified.svg',
                      height: 22,
                      width: 22,
                      colorFilter: const ColorFilter.mode(
                        TiermetryColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: TiermetrySpacing.sm),
                    Text(
                      'Verified Partner',
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: AppSurface(
            borderRadius: TiermetryRadii.pill,
            color: TiermetryColors.black.withValues(alpha: 0.3),
            border: Border.all(color: Colors.transparent),
            shadows: const [],
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: TiermetryBlur.filter(TiermetryBlur.sm),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: TiermetryColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
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
        // Title and Rating Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((arena.name).toUpperCase(),
                    style: TiermetryTypography.title(
                      fontSize: 26,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: TiermetryColors.positive,
                      ),
                      const SizedBox(width: TiermetrySpacing.xs),
                      Text(
                        arena.shortAddress,
                        style: TiermetryTypography.bodySmall(
                          color: textColorSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSurface(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: TiermetryRadii.sm,
              border: Border.all(color: Colors.transparent),
              shadows: const [],
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    arena.rating.toString(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                fontSize: 14,
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
                  style: TiermetryTypography.bodySmall(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
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
        ...arena.devices.map(
          (deviceGroup) => _unitRow(
            deviceGroup.name,
            deviceGroup.units
                .map(
                  (unit) => _unitCard(
                    deviceGroup.id,
                    unit,
                    accentColor,
                    cardBackgroundColor,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFeaturesQuickRow(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _featureIcon(Icons.ac_unit_rounded, 'AC', arena.hasAC),
        _featureIcon(Icons.bolt_rounded, 'UPS', arena.hasPowerBackup),
        _featureIcon(Icons.wifi_rounded, 'Fiber', true),
        _featureIcon(
          Icons.restaurant_rounded,
          'Food',
          arena.amenity.toLowerCase().contains('cafe'),
        ),
        _featureIcon(Icons.verified_user_rounded, 'Safety', true),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label, bool active) {
    return Column(
      children: [
        AppSurface(
          padding: const EdgeInsets.all(10),
          color:
              active
                  ? TiermetryColors.accentAppleBlue.withValues(alpha: 0.1)
                  : TiermetryColors.surfaceUnderlay,
          borderRadius: TiermetryRadii.pill,
          border: Border.all(color: Colors.transparent),
          shadows: const [],
          child: Icon(
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
            fontSize: 11,
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
    return AppSurface(
      height: 48,
      padding: const EdgeInsets.all(4),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.sm,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      child: Row(
        children: [
          _tabItem(0, 'Overview', accentColor),
          _tabItem(1, 'Hardware', accentColor),
          _tabItem(2, 'Policies', accentColor),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, Color accentColor) {
    final bool isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: AppSurface(
          duration: const Duration(milliseconds: 200),
          borderRadius: 10,
          color:
              isSelected ? TiermetryColors.surfaceElement : Colors.transparent,
          border: Border.all(color: Colors.transparent),
          shadows: const [],
          child: Center(
            child: Text(
              label,
              style: TiermetryTypography.bodySmall(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? TiermetryColors.white
                        : TiermetryColors.textMuted,
              ),
            ),
          ),
        ),
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
            const SizedBox(height: 24),
            _buildLocationCard(
              context,
              arena,
              textColorSecondary,
              cardBackgroundColor,
              accentColor,
            ),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    color: TiermetryColors.surfaceUnderlay,
    borderRadius: TiermetryRadii.sm,
    border: Border.all(color: TiermetryColors.borderSubtle, width: 0.5),
    shadows: const [],
    child: Text(
      label,
      style: TiermetryTypography.bodySmall(
        fontSize: 12,
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
                Icons.access_time_filled_rounded,
                'Hours',
                arena.hours,
                textColorSecondary,
                cardBackgroundColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _specChip(
                Icons.speed_rounded,
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
          Icons.chair_rounded,
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
          Icons.monitor_rounded,
          'Monitor',
          gs.refreshRate,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          Icons.videogame_asset_rounded,
          'GPU',
          gs.graphicsCard,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          Icons.memory_rounded,
          'Processor',
          gs.processor,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          Icons.keyboard_rounded,
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
          Icons.grass_rounded,
          'Surface',
          ts.surface,
          textColorSecondary,
          cardBackgroundColor,
        ),
        _specChip(
          Icons.lightbulb_rounded,
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
          Icons.cancel_rounded,
          'Cancellation',
          arena.cancellationPolicy,
          textColorSecondary,
        ),
        const SizedBox(height: 16),
        _policyItem(
          Icons.phone_rounded,
          'Contact',
          arena.contactPhone,
          textColorSecondary,
        ),
        const SizedBox(height: 16),
        ...arena.rules.map(
          (rule) => _policyItem(
            Icons.gavel_rounded,
            'Rule',
            rule,
            textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _policyItem(
    IconData icon,
    String title,
    String value,
    Color textColorSecondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TiermetryColors.accentAppleBlue, size: 18),
        const SizedBox(width: TiermetrySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TiermetryTypography.bodySmall(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: TiermetryColors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TiermetryTypography.bodySmall(
                  fontSize: 13,
                  color: textColorSecondary,
                ),
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
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
        shadows: const [],
        child: Row(
          children: [
            AppSurface(
              padding: const EdgeInsets.all(12),
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: TiermetryRadii.pill,
              border: Border.all(color: Colors.transparent),
              shadows: const [],
              child: Icon(Icons.map_rounded, color: accentColor),
            ),
            const SizedBox(width: TiermetrySpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TiermetryTypography.bodySmall(
                      fontSize: 12,
                      color: textColorSecondary,
                    ),
                  ),
                  Text(
                    arena.shortAddress,
                    style: TiermetryTypography.bodySmall(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TiermetryColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
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
            fontSize: 15,
            fontWeight: FontWeight.w500,
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
    Color accentColor,
    Color cardBackgroundColor,
  ) {
    final bool isSelected = _selectedDevices.contains(unit.id);

    return GestureDetector(
      onTap: () {
        if (!unit.isOccupied) toggleSelection(serviceId, unit.id);
      },
      child: AppSurface(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 170,
        height: 220,
        borderRadius: TiermetryRadii.xl,
        border: Border.all(
          color: isSelected ? accentColor : Colors.transparent,
          width: 2.5,
        ),
        shadows:
            isSelected
                ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : TiermetryShadows.card,
        padding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              unit.image,
              fit: BoxFit.cover,
              color:
                  unit.isOccupied
                      ? TiermetryColors.black.withValues(alpha: 0.5)
                      : null,
              colorBlendMode:
                  unit.isOccupied ? BlendMode.darken : BlendMode.dst,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    TiermetryColors.black.withValues(alpha: 0.8),
                    TiermetryColors.black.withValues(alpha: 0.2),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(TiermetrySpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: TiermetryTypography.bodySmall(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TiermetryColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.desc,
                      style: TiermetryTypography.bodySmall(
                        fontSize: 12,
                        color: TiermetryColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${unit.price}/hr',
                      style: TiermetryTypography.bodySmall(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TiermetryColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (unit.isOccupied)
              Center(
                child: AppSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: TiermetryColors.black.withValues(alpha: 0.7),
                  borderRadius: TiermetryRadii.sm,
                  border: Border.all(color: Colors.transparent),
                  shadows: const [],
                  child: Text(
                    'IN USE',
                    style: TiermetryTypography.bodySmall(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TiermetryColors.negative,
                    ),
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
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: TiermetryColors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBookingBar(BuildContext context, Color accentColor) {
    return AppSurface(
      borderRadius: 0,
      color: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: TiermetryBlur.filter(TiermetryBlur.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.8),
            border: const Border(
              top: BorderSide(color: TiermetryColors.borderSubtle, width: 0.5),
            ),
          ),
          child: ElevatedButton(
            onPressed:
                _selectedDevices.isEmpty
                    ? null
                    : () => _showBookingSheet(context, accentColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              disabledBackgroundColor: TiermetryColors.surfaceElement,
              disabledForegroundColor: TiermetryColors.gray100,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TiermetryRadii.sm),
              ),
              elevation: 5,
              shadowColor: accentColor.withValues(alpha: 0.4),
            ),
            child: Text(
              'Book Selected (${_selectedDevices.length})',
              style: TiermetryTypography.bodySmall(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TiermetryColors.white,
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

  Widget _infoTitle(String label) => Text((label).toUpperCase(),
    style: TiermetryTypography.title(
      fontSize: 18,
      color: TiermetryColors.white.withValues(alpha: 0.9),
      height: 1.2,
    ),
  );

  Widget _specChip(
    IconData icon,
    String label,
    String value,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) => AppSurface(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    color: cardBackgroundColor,
    borderRadius: TiermetryRadii.sm,
    border: Border.all(color: Colors.transparent),
    shadows: const [],
    child: Row(
      children: [
        Icon(icon, color: textColorSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TiermetryTypography.bodySmall(
                  fontSize: 11,
                  color: textColorSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TiermetryTypography.bodySmall(
                  fontSize: 13,
                  color: TiermetryColors.white,
                  fontWeight: FontWeight.w500,
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
