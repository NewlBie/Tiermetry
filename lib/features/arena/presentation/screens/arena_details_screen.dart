import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_image.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/arena/domain/entities/arena_details_entity.dart';
import 'package:tiermetry/features/arena/domain/entities/arena_entity.dart';
import 'package:tiermetry/features/booking/domain/entities/booking_accessory.dart';
import 'package:tiermetry/features/booking/domain/entities/booking_entity.dart';
import 'package:tiermetry/features/booking/presentation/widgets/review_dialog.dart';

import '../../../../features/booking/presentation/screens/final_invoice_screen.dart';
import '../widgets/booking_sheet.dart';
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
  late Future<BookingEntity?> _reviewableBookingFuture;
  final ValueNotifier<Set<String>> _selectedDevices = ValueNotifier(<String>{});
  String? _selectedServiceId;
  bool isDescExpanded = false;
  int activeTab = 0; // 0: Overview, 1: Specs & Games, 2: Rules

  final PageController _imagePageController = PageController();
  final ValueNotifier<int> _currentImageIndex = ValueNotifier(0);
  RealtimeChannel? _detailsChannel;
  Timer? _detailsRefreshDebounce;

  @override
  void initState() {
    super.initState();
    _detailsFuture = locator.arenaCtrl.loadArenaDetails(widget.arena.id);
    _reviewableBookingFuture = locator.bookingCtrl.getReviewableBookingForVenue(
      widget.arena.id,
    );
    _detailsChannel =
        locator.supabase
            .channel('arena_details_${widget.arena.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'venues',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: widget.arena.id,
              ),
              callback: (_) => _scheduleDetailsRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'venue_reviews',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'venue_id',
                value: widget.arena.id,
              ),
              callback: (_) => _scheduleDetailsRefresh(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'service_units',
              callback: (_) => _scheduleDetailsRefresh(),
            )
            .subscribe();
  }

  void _scheduleDetailsRefresh() {
    _detailsRefreshDebounce?.cancel();
    _detailsRefreshDebounce = Timer(
      const Duration(milliseconds: 300),
      _refreshReviewState,
    );
  }

  @override
  void dispose() {
    _detailsRefreshDebounce?.cancel();
    _imagePageController.dispose();
    _currentImageIndex.dispose();
    _selectedDevices.dispose();
    final channel = _detailsChannel;
    if (channel != null) locator.supabase.removeChannel(channel);
    super.dispose();
  }

  void _refreshReviewState() {
    setState(() {
      _detailsFuture = locator.arenaCtrl.loadArenaDetails(widget.arena.id);
      _reviewableBookingFuture = locator.bookingCtrl
          .getReviewableBookingForVenue(widget.arena.id);
    });
  }

  void _showDynamicIslandNotification(String message, Color accentColor) {
    AppIslandNotice.show(
      context,
      title: message,
      tone: AppIslandNoticeTone.info,
    );
  }

  void toggleSelection(String serviceId, String deviceId) {
    final selected = Set<String>.of(_selectedDevices.value);
    if (_selectedServiceId != null && _selectedServiceId != serviceId) {
      selected.clear();
    }
    _selectedServiceId = serviceId;

    if (selected.contains(deviceId)) {
      selected.remove(deviceId);
      if (selected.isEmpty) _selectedServiceId = null;
    } else {
      selected.add(deviceId);
    }
    _selectedDevices.value = selected;
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
                    _reviewableBookingFuture = locator.bookingCtrl
                        .getReviewableBookingForVenue(widget.arena.id);
                  }),
            );
          }

          final arenaDetails = snapshot.data!;

          return Stack(
            children: [
              const Positioned.fill(child: _ArenaAmbientBackdrop()),
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                cacheExtent: 640,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _buildCoverImage(context, arenaDetails),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      TiermetrySpacing.screenPadding,
                      TiermetrySpacing.xl,
                      TiermetrySpacing.screenPadding,
                      0,
                    ),
                    sliver: SliverList.builder(
                      itemCount: arenaDetails.devices.length + 4,
                      itemBuilder:
                          (context, index) => _buildDetailsSection(
                            context,
                            arenaDetails,
                            accentColor,
                            index,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<Set<String>>(
        valueListenable: _selectedDevices,
        builder:
            (context, selectedDevices, _) =>
                _buildBottomBookingBar(context, accentColor, selectedDevices),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCoverImage(BuildContext context, ArenaDetailsEntity arena) {
    final gallery = arena.galleryImages;
    final coverWidth =
        MediaQuery.sizeOf(context).width - (TiermetrySpacing.screenPadding * 2);
    final coverHeight = coverWidth * 9 / 16;
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        gallery.length > 1
                            ? Stack(
                              children: [
                                PageView.builder(
                                  controller: _imagePageController,
                                  onPageChanged:
                                      (index) =>
                                          _currentImageIndex.value = index,
                                  itemCount: gallery.length,
                                  itemBuilder: (context, index) {
                                    return AppImage(
                                      imagePath: gallery[index],
                                      width: coverWidth,
                                      height: coverHeight,
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _currentImageIndex,
                                    builder:
                                        (_, currentIndex, __) => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            gallery.length,
                                            (index) => AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              height: 8,
                                              width:
                                                  currentIndex == index
                                                      ? 24
                                                      : 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    currentIndex == index
                                                        ? TiermetryColors
                                                            .accentAppleBlue
                                                        : Colors.white54,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            )
                            : AppImage(
                              imagePath: gallery.isEmpty ? '' : gallery.first,
                              width: coverWidth,
                              height: coverHeight,
                            ),
                  ),
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
                          '${arena.rating.toStringAsFixed(1)} (${arena.reviews})',
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

  Widget _buildDetailsSection(
    BuildContext context,
    ArenaDetailsEntity arena,
    Color accentColor,
    int index,
  ) {
    const textColorPrimary = TiermetryColors.white;
    const textColorSecondary = TiermetryColors.textMuted;
    const cardBackgroundColor = TiermetryColors.surfaceUnderlay;

    if (index == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arena.name.toUpperCase(),
            style: TiermetryTypography.displayLarge(
              color: textColorPrimary,
            ).copyWith(height: 1.1, fontSize: 32, fontWeight: FontWeight.w900),
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
          _buildFeaturesQuickRow(arena, textColorSecondary),
          const SizedBox(height: TiermetrySpacing.xl),
          _buildDescription(arena.desc, textColorSecondary, accentColor),
          const SizedBox(height: TiermetrySpacing.md),
          _buildInformationPanel(
            arena,
            textColorSecondary,
            cardBackgroundColor,
            accentColor,
          ),
          const SizedBox(height: TiermetrySpacing.xl),
        ],
      );
    }

    if (index == 1) {
      return RepaintBoundary(
        child: Column(
          children: [
            _buildVerifiedReviewPanel(arena, accentColor),
            const SizedBox(height: TiermetrySpacing.sectionGap),
          ],
        ),
      );
    }

    if (index == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTitle('Reserve Your Experience'),
          const SizedBox(height: TiermetrySpacing.lg),
        ],
      );
    }

    final deviceIndex = index - 3;
    if (deviceIndex < arena.devices.length) {
      final deviceGroup = arena.devices[deviceIndex];
      final sortedUnits = List<ArenaDevice>.of(deviceGroup.units)..sort((a, b) {
        if (a.isOccupied == b.isOccupied) return 0;
        return a.isOccupied ? 1 : -1;
      });
      return _unitRow(
        serviceId: deviceGroup.id,
        label: deviceGroup.name,
        units: sortedUnits,
        accentColor: accentColor,
        cardBackgroundColor: cardBackgroundColor,
      );
    }

    return const SizedBox(height: 140);
  }

  Widget _buildVerifiedReviewPanel(
    ArenaDetailsEntity arena,
    Color accentColor,
  ) {
    return FutureBuilder<BookingEntity?>(
      future: _reviewableBookingFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final booking = snapshot.data;
        final hasCompletedVisit = booking != null;
        final canReview = hasCompletedVisit && !booking.hasReview;
        final accent =
            canReview
                ? TiermetryColors.positive
                : TiermetryColors.accentAppleBlue;

        return AppSurface(
          padding: const EdgeInsets.fromLTRB(
            TiermetrySpacing.lg,
            TiermetrySpacing.lg,
            TiermetrySpacing.lg,
            TiermetrySpacing.md,
          ),
          color: TiermetryColors.surface,
          borderRadius: TiermetryRadii.lg,
          shadows: const [],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                    ),
                    child: Icon(
                      canReview
                          ? Icons.auto_awesome_rounded
                          : Icons.verified_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TiermetrySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ratings & Reviews',
                          style: TiermetryTypography.titleSmall(
                            color: TiermetryColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _reviewPanelSubtitle(arena, isLoading, booking),
                          style: TiermetryTypography.bodySmall(
                            color: TiermetryColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading)
                    _reviewStatusPill(canReview: canReview, booking: booking),
                ],
              ),
              const SizedBox(height: TiermetrySpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TiermetrySpacing.md),
                decoration: BoxDecoration(
                  color: TiermetryColors.surfaceUnderlay,
                  borderRadius: BorderRadius.circular(TiermetryRadii.md),
                ),
                child: Row(
                  children: [
                    _reviewMetric(
                      icon: FontAwesomeIcons.solidStar,
                      value: arena.rating.toStringAsFixed(1),
                      label: _reviewCountLabel(arena.reviews),
                      color: Colors.amber,
                    ),
                    const SizedBox(width: TiermetrySpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star_rounded,
                                color:
                                    index < arena.rating.round()
                                        ? Colors.amber
                                        : Colors.white24,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'From verified visits only',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TiermetryTypography.caption(
                              color: TiermetryColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (arena.reviewItems.isNotEmpty) ...[
                const SizedBox(height: TiermetrySpacing.lg),
                Text(
                  'Recent verified reviews',
                  style: TiermetryTypography.titleSmall(
                    color: TiermetryColors.white,
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.sm),
                ...arena.reviewItems.take(3).map(_reviewTile),
              ],
              const SizedBox(height: TiermetrySpacing.md),
              if (canReview)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ReviewDialog.show(context, booking);
                      if (mounted) _refreshReviewState();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: TiermetryColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TiermetryRadii.md),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: Text(
                      'Write a review',
                      style: TiermetryTypography.action(
                        color: TiermetryColors.white,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Icon(
                      isLoading
                          ? Icons.hourglass_empty_rounded
                          : booking?.hasReview == true
                          ? Icons.check_circle_rounded
                          : Icons.lock_rounded,
                      size: 17,
                      color: TiermetryColors.textMuted,
                    ),
                    const SizedBox(width: TiermetrySpacing.sm),
                    Expanded(
                      child: Text(
                        isLoading
                            ? 'Checking your visit history'
                            : booking?.hasReview == true
                            ? 'Your verified review is published'
                            : 'Complete a booking to unlock reviewing',
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String _reviewPanelSubtitle(
    ArenaDetailsEntity arena,
    bool isLoading,
    BookingEntity? booking,
  ) {
    if (isLoading) return 'Checking your completed visits at ${arena.name}.';
    if (booking == null) {
      return 'Feedback unlocks after you complete a booking at this arena.';
    }
    if (booking.hasReview) {
      return 'Your completed visit is already counted in this arena score.';
    }
    return 'Your completed visit unlocks one verified review for this arena.';
  }

  String _reviewCountLabel(int reviews) {
    return reviews == 1 ? '1 review' : '$reviews reviews';
  }

  Widget _reviewStatusPill({
    required bool canReview,
    required BookingEntity? booking,
  }) {
    final isReviewed = booking?.hasReview == true;
    final color =
        canReview
            ? TiermetryColors.positive
            : isReviewed
            ? TiermetryColors.accentAppleBlue
            : TiermetryColors.textMuted;
    final label =
        canReview
            ? 'READY'
            : isReviewed
            ? 'SHARED'
            : 'LOCKED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TiermetryRadii.pill),
      ),
      child: Text(label, style: TiermetryTypography.label(color: color)),
    );
  }

  Widget _reviewTile(ArenaReview review) {
    final months = <String>[
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
    final date =
        '${months[review.createdAt.month - 1]} ${review.createdAt.day}';
    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TiermetrySpacing.md),
        decoration: BoxDecoration(
          color: TiermetryColors.surfaceUnderlay,
          borderRadius: BorderRadius.circular(TiermetryRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    size: 15,
                    color:
                        index < review.rating ? Colors.amber : Colors.white24,
                  ),
                ),
                const Spacer(),
                Text(
                  '$date · Verified visit',
                  style: TiermetryTypography.caption(
                    color: TiermetryColors.textMuted,
                  ),
                ),
              ],
            ),
            if ((review.comment ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: TiermetrySpacing.sm),
              Text(
                review.comment!.trim(),
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white.withValues(alpha: 0.78),
                  height: 1.4,
                ),
              ),
            ],
            if (review.highlights.isNotEmpty) ...[
              const SizedBox(height: TiermetrySpacing.sm),
              Text(
                review.highlights.join(' · '),
                style: TiermetryTypography.caption(
                  color: TiermetryColors.accentAppleBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reviewMetric({
    required FaIconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TiermetryTypography.titleSmall(
                  color: TiermetryColors.white,
                ),
              ),
              Text(
                label,
                style: TiermetryTypography.caption(
                  color: TiermetryColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildDescription(
    String description,
    Color textColorSecondary,
    Color accentColor,
  ) {
    final textStyle = TiermetryTypography.bodySmall(
      height: 1.5,
      color: textColorSecondary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 5,
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              maxLines: isDescExpanded ? null : 5,
              overflow:
                  isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: textStyle,
            ),
            if (canExpand)
              TextButton(
                onPressed:
                    () => setState(() => isDescExpanded = !isDescExpanded),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.only(top: TiermetrySpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isDescExpanded ? 'Read less' : 'Read more',
                  style: TiermetryTypography.bodySmall(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInformationPanel(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
    return AppSurface(
      padding: const EdgeInsets.all(TiermetrySpacing.sm),
      color: TiermetryColors.surface,
      borderRadius: TiermetryRadii.lg,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabsHeader(accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TiermetrySpacing.md,
              TiermetrySpacing.xl,
              TiermetrySpacing.md,
              TiermetrySpacing.md,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(activeTab),
                child: _buildTabContent(
                  arena,
                  textColorSecondary,
                  cardBackgroundColor,
                  accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
      ),
      child: Row(
        children: [
          Expanded(child: _tabItem(0, 'Overview', accentColor)),
          Expanded(child: _tabItem(1, 'Specs', accentColor)),
          Expanded(child: _tabItem(2, 'Policies', accentColor)),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, Color accentColor) {
    final bool isSelected = activeTab == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => activeTab = index),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? TiermetryColors.surfaceElement : null,
              borderRadius: BorderRadius.circular(TiermetryRadii.sm),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.bodySmall(
                color:
                    isSelected
                        ? TiermetryColors.white
                        : TiermetryColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
            _buildScheduleCard(
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
    padding: const EdgeInsets.symmetric(
      horizontal: TiermetrySpacing.md,
      vertical: TiermetrySpacing.sm,
    ),
    color: TiermetryColors.surfaceUnderlay,
    borderRadius: TiermetryRadii.sm,
    shadows: const [],
    child: Text(
      label,
      style: TiermetryTypography.bodySmall(
        color: TiermetryColors.white.withValues(alpha: 0.7),
      ),
    ),
  );

  FaIconData _getAmenityIcon(String key) {
    switch (key.trim().toLowerCase()) {
      case 'ac':
        return {'Air Conditioning': FontAwesomeIcons.snowflake}.values.first;
      case 'wifi':
        return {'Free WiFi': FontAwesomeIcons.wifi}.values.first;
      case 'food':
        return {'Food/Snacks': FontAwesomeIcons.utensils}.values.first;
      case 'cafe':
        return {'In-house Cafe': FontAwesomeIcons.mugHot}.values.first;
      case 'parking':
        return {'Parking': FontAwesomeIcons.squareParking}.values.first;
      case 'power':
        return {'Power Backup': FontAwesomeIcons.bolt}.values.first;
      case 'washroom':
        return {'Washrooms': FontAwesomeIcons.restroom}.values.first;
      case 'wheelchair':
        return {'Wheelchair Access': FontAwesomeIcons.wheelchair}.values.first;
      case 'lockers':
        return {'Lockers': FontAwesomeIcons.lock}.values.first;
      case 'smoking':
        return {'Smoking Area': FontAwesomeIcons.smoking}.values.first;
      case 'water':
        return {'Drinking Water': FontAwesomeIcons.glassWater}.values.first;
      case 'medical':
        return {'First Aid': FontAwesomeIcons.suitcaseMedical}.values.first;
      case 'cctv':
        return {'CCTV Security': FontAwesomeIcons.video}.values.first;
      case 'waiting_area':
        return {'Waiting Area': FontAwesomeIcons.couch}.values.first;
      case 'vr':
        return {'VR Setup': FontAwesomeIcons.vrCardboard}.values.first;
      case 'console':
        return {'Console Gaming': FontAwesomeIcons.gamepad}.values.first;
      case 'pc':
        return {'PC Gaming': FontAwesomeIcons.desktop}.values.first;
      case 'streaming':
        return {
          'Streaming Setup': FontAwesomeIcons.microphoneLines,
        }.values.first;
      case 'turf':
        return {'Turf Field': FontAwesomeIcons.leaf}.values.first;
      case 'pool':
        return {'Swimming Pool': FontAwesomeIcons.personSwimming}.values.first;
      case 'gym':
        return {'Gym/Fitness': FontAwesomeIcons.dumbbell}.values.first;
      case 'camping':
        return {'Camping Area': FontAwesomeIcons.campground}.values.first;
      case 'skydiving':
        return {'Skydiving': FontAwesomeIcons.parachuteBox}.values.first;
      case 'go_karting':
        return {'Go-Karting': FontAwesomeIcons.flagCheckered}.values.first;
      case 'paintball':
        return {'Paintball': FontAwesomeIcons.bullseye}.values.first;
      case 'bowling':
        return {'Bowling Alley': FontAwesomeIcons.bowlingBall}.values.first;
      case 'bar':
        return {'Bar/Lounge': FontAwesomeIcons.martiniGlass}.values.first;
      case 'changing_room':
        return {'Changing Room': FontAwesomeIcons.shirt}.values.first;
      case 'shower':
        return {'Shower Facilities': FontAwesomeIcons.shower}.values.first;
      default:
        return FontAwesomeIcons.check;
    }
  }

  String _getAmenityLabel(String key) {
    switch (key.trim().toLowerCase()) {
      case 'ac':
        return 'Air Conditioning';
      case 'wifi':
        return 'Free WiFi';
      case 'food':
        return 'Food/Snacks';
      case 'cafe':
        return 'In-house Cafe';
      case 'parking':
        return 'Parking';
      case 'power':
        return 'Power Backup';
      case 'washroom':
        return 'Washrooms';
      case 'wheelchair':
        return 'Wheelchair Access';
      case 'lockers':
        return 'Lockers';
      case 'smoking':
        return 'Smoking Area';
      case 'water':
        return 'Drinking Water';
      case 'medical':
        return 'First Aid';
      case 'cctv':
        return 'CCTV Security';
      case 'waiting_area':
        return 'Waiting Area';
      case 'vr':
        return 'VR Setup';
      case 'console':
        return 'Console Gaming';
      case 'pc':
        return 'PC Gaming';
      case 'streaming':
        return 'Streaming Setup';
      case 'turf':
        return 'Turf Field';
      case 'pool':
        return 'Swimming Pool';
      case 'gym':
        return 'Gym/Fitness';
      case 'camping':
        return 'Camping Area';
      case 'skydiving':
        return 'Skydiving';
      case 'go_karting':
        return 'Go-Karting';
      case 'paintball':
        return 'Paintball';
      case 'bowling':
        return 'Bowling Alley';
      case 'bar':
        return 'Bar/Lounge';
      case 'changing_room':
        return 'Changing Room';
      case 'shower':
        return 'Shower Facilities';
      default:
        return key;
    }
  }

  Widget _buildScheduleCard(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
    if (arena.schedule.isEmpty) {
      return _specChip(
        FontAwesomeIcons.clock,
        'Hours',
        arena.hours.isEmpty ? 'Not specified' : arena.hours,
        textColorSecondary,
        cardBackgroundColor,
      );
    }

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return AppSurface(
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      color: cardBackgroundColor,
      borderRadius: TiermetryRadii.md,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.clock, size: 20, color: accentColor),
              const SizedBox(width: 12),
              Text(
                'Operating Hours',
                style: TiermetryTypography.title(
                  color: TiermetryColors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...days.map((day) {
            final dayData = arena.schedule[day] as Map<String, dynamic>?;
            final isClosed = dayData?['closed'] as bool? ?? false;
            final openTime = dayData?['open'] as String? ?? '-';
            final closeTime = dayData?['close'] as String? ?? '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: TiermetryTypography.bodySmall(
                      color: textColorSecondary,
                    ),
                  ),
                  Text(
                    isClosed ? 'Closed' : '$openTime - $closeTime',
                    style: TiermetryTypography.bodySmall(
                      color:
                          isClosed ? Colors.redAccent : TiermetryColors.white,
                      fontWeight:
                          isClosed ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSpecificationsGrid(
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
  ) {
    final List<Widget> specsList = [];
    if (arena.specs is DynamicSpecs) {
      final ds = arena.specs as DynamicSpecs;
      for (final entry in ds.specs.entries) {
        specsList.add(
          _specChip(
            FontAwesomeIcons.cube,
            entry.key,
            entry.value.toString(),
            textColorSecondary,
            cardBackgroundColor,
          ),
        );
      }
    }

    if (arena.internet.isNotEmpty) {
      specsList.add(
        _specChip(
          FontAwesomeIcons.gaugeHigh,
          'Internet',
          arena.internet,
          textColorSecondary,
          cardBackgroundColor,
        ),
      );
    }

    if (arena.amenity.isNotEmpty) {
      final amenityKeys = arena.amenity.split(',');
      for (final key in amenityKeys) {
        if (key.trim().isEmpty) continue;
        specsList.add(
          _specChip(
            _getAmenityIcon(key),
            'Amenity',
            _getAmenityLabel(key),
            textColorSecondary,
            cardBackgroundColor,
          ),
        );
      }
    }

    if (specsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No specifications available.',
          style: TiermetryTypography.bodySmall(color: textColorSecondary),
        ),
      );
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: specsList,
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
          cardBackgroundColor,
        ),
        const SizedBox(height: 16),
        _policyItem(
          FontAwesomeIcons.phone,
          'Contact',
          arena.contactPhone,
          textColorSecondary,
          cardBackgroundColor,
        ),
        const SizedBox(height: 16),
        ...arena.rules.map(
          (rule) => _policyItem(
            FontAwesomeIcons.gavel,
            'Rule',
            rule,
            textColorSecondary,
            cardBackgroundColor,
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
    Color cardBackgroundColor,
  ) {
    return AppSurface(
      padding: const EdgeInsets.all(TiermetrySpacing.md),
      color: cardBackgroundColor,
      borderRadius: TiermetryRadii.sm,
      shadows: const [],
      child: Row(
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TiermetryTypography.bodySmall(
                    color: textColorSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    ArenaDetailsEntity arena,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
    final hasExactPin = arena.hasValidCoordinates;
    final address =
        arena.location.trim().isNotEmpty
            ? arena.location.trim()
            : arena.shortAddress.trim();

    return GestureDetector(
      onTap: () {
        if (!hasExactPin) {
          AppIslandNotice.show(
            context,
            title: 'Map pin unavailable',
            message: 'This arena has not published an exact map pin yet.',
            tone: AppIslandNoticeTone.warning,
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ArenaMapScreen(arena: arena)),
        );
      },
      child: AppSurface(
        padding: const EdgeInsets.all(TiermetrySpacing.lg),
        color: cardBackgroundColor,
        borderRadius: TiermetryRadii.md,
        shadows: const [],
        child: Row(
          children: [
            AppSurface(
              padding: const EdgeInsets.all(TiermetrySpacing.md),
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: TiermetryRadii.pill,
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
                    hasExactPin ? 'Exact location' : 'Location',
                    style: TiermetryTypography.bodySmall(
                      color: textColorSecondary,
                    ),
                  ),
                  Text(
                    address.isEmpty ? 'Address unavailable' : address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Text(
              hasExactPin ? 'VIEW MAP' : 'NO PIN',
              style: TiermetryTypography.bodySmall(
                color: hasExactPin ? accentColor : textColorSecondary,
              ).copyWith(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitRow({
    required String serviceId,
    required String label,
    required List<ArenaDevice> units,
    required Color accentColor,
    required Color cardBackgroundColor,
  }) {
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
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            cacheExtent: 360,
            itemCount: units.length,
            separatorBuilder:
                (_, __) => const SizedBox(width: TiermetrySpacing.cardGap),
            itemBuilder:
                (context, index) => RepaintBoundary(
                  child: _unitCard(
                    context,
                    serviceId,
                    units[index],
                    index,
                    accentColor,
                    cardBackgroundColor,
                  ),
                ),
          ),
        ),
        const SizedBox(height: TiermetrySpacing.xl),
      ],
    );
  }

  String? _getActivityImage(String name) {
    final lowerName = name.toLowerCase().trim();
    const imageMap = <String, String>{
      'airsoft': 'airsoft.webp',
      'arcade machine': 'pc.webp',
      'archery': 'archer.webp',
      'archery range': 'archer.webp',
      'atv quad bike': 'ATV_qwadbike.webp',
      'axe throwing': 'axe.webp',
      'badminton': 'badminton.webp',
      'batting cage': 'cricket.webp',
      'board game lounge': 'vr.webp',
      'bowling': 'bowling.webp',
      'bumper cars': 'gokart.webp',
      'bungee jumping': 'bungee.webp',
      'camping': 'camp.webp',
      'climbing wall': 'mountain_climb.webp',
      'cricket': 'cricket.webp',
      'dance': 'dance.webp',
      'escape room': 'vr.webp',
      'foosball': 'snooker.webp',
      'football': 'football.webp',
      'go-kart': 'gokart.webp',
      'horse riding': 'horse.webp',
      'ice skating': 'ice_skate.webp',
      'jet ski': 'jet_ski.webp',
      'karaoke room': 'dance.webp',
      'kayak': 'kayak.webp',
      'laser tag arena': 'laser_tag.webp',
      'mini golf': 'snooker.webp',
      'mountain climbing': 'mountain_climb.webp',
      'nintendo switch': 'ps5.webp',
      'offroad': 'offroad.webp',
      'padel': 'padel.webp',
      'paintball arena': 'paintball.webp',
      'paragliding': 'para_glide.webp',
      'parasailing': 'para_sail.webp',
      'pc': 'pc.webp',
      'pickleball': 'pickel.webp',
      'pool table': 'snooker.webp',
      'pottery': 'pottery.webp',
      'ps3': 'ps5.webp',
      'ps4': 'ps5.webp',
      'ps5': 'ps5.webp',
      'race sim': 'race_sim.webp',
      'river rafting': 'river_raft.webp',
      'roller coaster': 'roller_coaster.webp',
      'roller skating': 'roller_skate.webp',
      'ropes course': 'mountain_climb.webp',
      'scuba': 'scuba.webp',
      'shooting range': 'laser_tag.webp',
      'simulator (flight)': 'vr.webp',
      'simulator (golf)': 'vr.webp',
      'simulator (racing)': 'race_sim.webp',
      'skating rink': 'roller_skate.webp',
      'sky dive': 'sky_dive.webp',
      'snooker': 'snooker.webp',
      'surf': 'surf.webp',
      'swiming': 'swiming.webp',
      'table tennis': 'snooker.webp',
      'trampoline park': 'trampoline.webp',
      'treck': 'treck.webp',
      'turf (cricket)': 'cricket.webp',
      'turf (football)': 'football.webp',
      'turf (multipurpose)': 'football.webp',
      'vr room': 'vr.webp',
      'waterpark': 'waterpark.webp',
      'xbox one': 'ps5.webp',
      'xbox series s': 'ps5.webp',
      'xbox series x': 'ps5.webp',
      'zip line': 'zipline.webp',
    };

    final fileName = imageMap[lowerName];
    if (fileName != null) {
      return 'assets/activity_images/$fileName';
    }

    return null;
  }

  Widget _unitCard(
    BuildContext context,
    String serviceId,
    ArenaDevice unit,
    int index,
    Color accentColor,
    Color cardBackgroundColor,
  ) {
    final match = RegExp(r'^(.*?)\s+(\d+)$').firstMatch(unit.name);
    final String baseName = match?.group(1) ?? unit.name;
    final String assignedNumber = match?.group(2) ?? '${index + 1}';
    final String? imagePath = _getActivityImage(baseName);

    String formatTime(DateTime time) {
      final h = time.hour;
      final m = time.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour12:$m $ampm';
    }

    final imageCacheWidth =
        (170 * MediaQuery.devicePixelRatioOf(context)).round();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selectedDevices,
      builder: (context, selectedDevices, _) {
        final isSelected = selectedDevices.contains(unit.id);
        return GestureDetector(
          onTap: () {
            if (unit.isOccupied && !isSelected) {
              _showDynamicIslandNotification(
                'Rig is in use. Book for a later slot.',
                TiermetryColors.negative,
              );
            }
            toggleSelection(serviceId, unit.id);
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
                  boxShadow: null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    if (unit.isOccupied)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            TiermetryRadii.md,
                          ),
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

                    // Keep the operational red state dominant over selection.
                    if (!unit.isOccupied && isSelected)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            TiermetryRadii.md,
                          ),
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
                    Positioned(
                      left: -10,
                      top: -20,
                      child: Text(
                        assignedNumber,
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
                      child:
                          imagePath != null
                              ? Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                cacheWidth: imageCacheWidth,
                              )
                              : Icon(
                                CupertinoIcons.sportscourt,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                    ),
                    if (unit.isOccupied)
                      const ColoredBox(color: Color(0x33FF0000)),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors:
                              unit.isOccupied
                                  ? const [Color(0xCC5C0000), Color(0x00330000)]
                                  : [
                                    TiermetryColors.black.withValues(
                                      alpha: 0.7,
                                    ),
                                    TiermetryColors.black.withValues(
                                      alpha: 0.0,
                                    ),
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
                              baseName,
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
                              '${unit.priceRangeLabel}${unit.dayPrices.isEmpty ? '' : ' · day rates'}',
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
                  style: TiermetryTypography.label(
                    color: TiermetryColors.negative,
                  ),
                )
              else if (unit.isMaintenance)
                Text(
                  'MAINTENANCE',
                  style: TiermetryTypography.label(color: Colors.amber),
                )
              else if (!unit.isBookable)
                Text(
                  unit.availabilityStatus.replaceAll('_', ' ').toUpperCase(),
                  style: TiermetryTypography.label(color: Colors.amber),
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
      },
    );
  }

  Widget _buildBottomBookingBar(
    BuildContext context,
    Color accentColor,
    Set<String> selectedDevices,
  ) {
    if (selectedDevices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: AppSurface(
        borderRadius: 100, // Pill shape
        color: TiermetryColors.surfaceUnderlay,
        shadows: TiermetryShadows.highEmphasis,
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
              'BOOK SELECTED (${selectedDevices.length})',
              style: TiermetryTypography.action(
                color: TiermetryColors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Color accentColor) async {
    if (_selectedServiceId == null) return;
    final arenaDetails = await _detailsFuture;
    if (arenaDetails == null) return;

    if (!context.mounted) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BookingSheet(
            venueId: widget.arena.id,
            serviceId: _selectedServiceId!,
            initialSelectedUnitIds: _selectedDevices.value.toList(),
            accentColor: accentColor,
            onConfirm: ({
              required int duration,
              required DateTime startDateTime,
              required List<String> serviceUnitIds,
              required List<BookingAccessorySelection> accessorySelections,
            }) async {
              final endDateTime = startDateTime.add(Duration(hours: duration));

              try {
                final hold = await locator.bookingCtrl.createReservationHold(
                  venueId: widget.arena.id,
                  startTime: startDateTime,
                  endTime: endDateTime,
                  serviceUnitIds: serviceUnitIds,
                  accessorySelections: accessorySelections,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close sheet

                  // Get unit names for the selected IDs
                  final unitNames =
                      arenaDetails.devices
                          .expand((ArenaDeviceCat d) => d.units)
                          .where(
                            (ArenaDevice u) => serviceUnitIds.contains(u.id),
                          )
                          .map<String>((ArenaDevice u) => u.name)
                          .toList();

                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (context) => FinalInvoiceScreen(
                            hold: hold,
                            venueName: widget.arena.name,
                            serviceUnitNames: unitNames,
                            accentColor: accentColor,
                          ),
                    ),
                  );

                  _selectedDevices.value = <String>{};
                  _selectedServiceId = null;
                }
              } catch (e) {
                if (context.mounted) {
                  AppIslandNotice.show(
                    context,
                    title: 'Could not reserve this slot',
                    message: e.toString().replaceAll('Exception: ', ''),
                    tone: AppIslandNoticeTone.error,
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

class _ArenaAmbientBackdrop extends StatelessWidget {
  const _ArenaAmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TiermetryColors.background,
          gradient: RadialGradient(
            center: Alignment(0.72, -0.82),
            radius: 1.18,
            colors: [
              Color(0x332A65A8),
              Color(0x14172B45),
              TiermetryColors.background,
            ],
            stops: [0, 0.44, 1],
          ),
        ),
      ),
    );
  }
}
