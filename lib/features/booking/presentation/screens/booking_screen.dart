import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/core/widgets/sliding_segmented_tabs.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/reservation_hold_entity.dart';
import '../widgets/cancellation_sheet.dart';
import '../widgets/check_in_sheet.dart';
import 'booking_details_screen.dart';
import 'final_invoice_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

@visibleForTesting
bool bookingBelongsToTab(BookingEntity booking, String tab) {
  if (booking.status == BookingStatus.pending) return false;

  return switch (tab) {
    'Upcoming' =>
      booking.isUpcoming ||
          booking.status == BookingStatus.active ||
          booking.sessionStatus == 'active',
    'Completed' => booking.status == BookingStatus.completed,
    'Cancelled' =>
      booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.expired ||
          booking.status == BookingStatus.noShow,
    _ => false,
  };
}

class _BookingScreenState extends State<BookingScreen> with RefreshRateMixin {
  final _bookingCtrl = locator.bookingCtrl;
  String _selectedTab = 'Upcoming';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _bookingCtrl.loadBookings());
  }

  Future<void> _onCancelBooking(String id) async {
    final booking =
        _bookingCtrl.bookings.where((item) => item.id == id).firstOrNull;
    if (booking == null || !mounted) return;
    await CancellationSheet.show(context, booking);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: RefreshIndicator(
        onRefresh: _bookingCtrl.loadBookings,
        backgroundColor: TiermetryColors.surface,
        color: TiermetryColors.accentNeonGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildTabs()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.lg,
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.bottomSafeArea,
              ),
              sliver: ListenableBuilder(
                listenable: _bookingCtrl,
                builder: (context, child) {
                  if (_bookingCtrl.isLoading &&
                      _bookingCtrl.bookings.isEmpty &&
                      _bookingCtrl.activeHolds.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: ShimmerLoadingVerticalList(
                        itemHeight: 220,
                        itemCount: 4,
                        spacing: TiermetrySpacing.lg,
                      ),
                    );
                  }

                  if (_bookingCtrl.error != null &&
                      _bookingCtrl.bookings.isEmpty &&
                      _bookingCtrl.activeHolds.isEmpty) {
                    return SliverToBoxAdapter(
                      child: AppErrorState(
                        message: _bookingCtrl.error!,
                        onRetry: _bookingCtrl.loadBookings,
                      ),
                    );
                  }

                  // Filter out pending bookings (we use reservation holds now)
                  // Filter bookings based on selected tab
                  final bookings =
                      _bookingCtrl.bookings
                          .where(
                            (booking) =>
                                bookingBelongsToTab(booking, _selectedTab),
                          )
                          .toList();
                  final holds =
                      _selectedTab == 'Upcoming'
                          ? _bookingCtrl.activeHolds
                          : <ReservationHoldEntity>[];

                  if (bookings.isEmpty && holds.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'No bookings found.',
                          style: TextStyle(color: TiermetryColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (holds.isNotEmpty) ...[
                        _buildSectionHeader('Pending Confirmation'),
                        const SizedBox(height: 12),
                        ...holds.map((hold) => _buildHoldItem(context, hold)),
                        const SizedBox(height: 32),
                      ],
                      if (bookings.isNotEmpty) ...[
                        _buildSectionHeader('My Tickets'),
                        const SizedBox(height: 12),
                        ...bookings.map(
                          (booking) => _buildBookingItem(context, booking),
                        ),
                      ],
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 92,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: TiermetrySpacing.screenPadding,
              bottom: 16,
            ),
            title: Text(
              'My Bookings'.toUpperCase(),
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Upcoming', 'Completed', 'Cancelled'];
    final selectedIndex = tabs.indexOf(_selectedTab).clamp(0, tabs.length - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.screenPadding,
      ),
      child: SlidingSegmentedTabs(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTabSelected: (index) {
          setState(() => _selectedTab = tabs[index]);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TiermetryTypography.label(
        color: TiermetryColors.accentAppleBlue,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHoldItem(BuildContext context, ReservationHoldEntity hold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.md),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF161F2E), Color(0xFF101620)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TiermetryColors.accentAppleBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                hold.isPaymentConfirmationPending
                    ? Icons.sync_rounded
                    : Icons.hourglass_top_rounded,
                color: TiermetryColors.accentAppleBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: TiermetryColors.accentAppleBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hold.isPaymentConfirmationPending
                            ? 'PAYMENT PENDING'
                            : 'TEMPORARY HOLD',
                        style: TiermetryTypography.label(
                          fontSize: 11,
                          color: TiermetryColors.accentAppleBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hold.isPaymentConfirmationPending
                        ? 'Cashfree confirmation in progress'
                        : 'Expires at ${DateFormat('hh:mm a').format(hold.expiresAt)}',
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: TiermetryColors.accentAppleBlue,
              borderRadius: BorderRadius.circular(14),
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => FinalInvoiceScreen(
                          hold: hold,
                          venueName: hold.venueName,
                          serviceUnitNames: hold.serviceUnitNames,
                          accentColor: TiermetryColors.accentAppleBlue,
                        ),
                  ),
                );
              },
              child: Text(
                hold.isPaymentConfirmationPending ? 'CHECK' : 'PAY NOW',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, BookingEntity booking) {
    return _BookingCard(booking: booking, onCancel: _onCancelBooking);
  }
}

class _BookingCard extends StatefulWidget {
  final BookingEntity booking;
  final Future<void> Function(String) onCancel;

  const _BookingCard({required this.booking, required this.onCancel});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => TiermetryColors.positive,
      BookingStatus.active => TiermetryColors.accentNeonGreen,
      BookingStatus.checkedIn => TiermetryColors.accentAppleBlue,
      BookingStatus.pending => Colors.amberAccent,
      BookingStatus.cancelled => Colors.redAccent,
      BookingStatus.completed => TiermetryColors.accentLavender,
      BookingStatus.expired => Colors.grey,
      BookingStatus.noShow => Colors.orangeAccent,
    };

    final isActuallyActive =
        booking.status == BookingStatus.active ||
        booking.sessionStatus == 'active';
    final hasCheckInEvent = booking.events.any(
      (event) => event.eventType == 'CHECK_IN',
    );
    final isVerifiedForStart =
        booking.status == BookingStatus.checkedIn ||
        (booking.sessionStatus == 'checked_in' && hasCheckInEvent);

    final passId =
        (booking.bookingCode ?? booking.id.split('-').first).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => BookingDetailsScreen(booking: booking),
              ),
            );
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1D1E22), Color(0xFF141518)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero / Cover with Apple Glass Status Pill
                Stack(
                  children: [
                    Image.network(
                      booking.imageUrl,
                      fit: BoxFit.cover,
                      height: 165,
                      width: double.infinity,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 165,
                            color: TiermetryColors.surfaceElement,
                            child: const Center(
                              child: Icon(
                                Icons.confirmation_number_outlined,
                                color: Colors.white24,
                                size: 40,
                              ),
                            ),
                          ),
                    ),
                    // Gradient overlay to seamlessly merge into the pass body
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              const Color(0xFF1D1E22).withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Pass ID floating chip (Top Left)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'PASS #$passId',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Status Floating Badge (Top Right)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: (isActuallyActive
                                      ? TiermetryColors.accentNeonGreen
                                      : statusColor)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        isActuallyActive
                                            ? TiermetryColors.accentNeonGreen
                                            : statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isActuallyActive
                                                ? TiermetryColors
                                                    .accentNeonGreen
                                                : statusColor)
                                            .withValues(alpha: 0.8),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (isActuallyActive
                                          ? 'ACTIVE'
                                          : isVerifiedForStart
                                          ? 'VERIFIED'
                                          : booking.status ==
                                              BookingStatus.noShow
                                          ? 'NO SHOW'
                                          : booking.status.name)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color:
                                        isActuallyActive
                                            ? TiermetryColors.accentNeonGreen
                                            : statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Apple Ticket Divider (Perforation line without borders)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: TiermetryColors.background,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final count = (constraints.maxWidth / 8).floor();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                count,
                                (_) => Container(
                                  width: 4,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: TiermetryColors.background,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pass Content Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Price Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              booking.title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TiermetryTypography.title(
                                color: TiermetryColors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: TiermetryColors.accentNeonGreen.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '₹${booking.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: TiermetryColors.accentNeonGreen,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Apple-style Structured Data Grid
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111215),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Date & Time Row
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 15,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DATE & TIME',
                                              style: TiermetryTypography.label(
                                                color:
                                                    TiermetryColors.textMuted,
                                                fontSize: 9,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat(
                                                'EEE, d MMM • h:mm a',
                                              ).format(booking.dateTime),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  TiermetryTypography.bodySmall(
                                                    color:
                                                        TiermetryColors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Location Row
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          size: 15,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'VENUE',
                                              style: TiermetryTypography.label(
                                                color:
                                                    TiermetryColors.textMuted,
                                                fontSize: 9,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              booking.location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  TiermetryTypography.bodySmall(
                                                    color:
                                                        TiermetryColors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (booking.assignedAssetName != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.computer_rounded,
                                            size: 15,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ASSIGNED STATION',
                                                style:
                                                    TiermetryTypography.label(
                                                      color:
                                                          TiermetryColors
                                                              .textMuted,
                                                      fontSize: 9,
                                                      letterSpacing: 0.8,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                booking.assignedAssetName!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    TiermetryTypography.bodySmall(
                                                      color:
                                                          TiermetryColors
                                                              .accentAppleBlue,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      _ServiceRecoveryBanner(booking: booking),

                      // Dynamic State Cards: Live Session, Verified, Summaries & Actions
                      if (isActuallyActive) ...[
                        const SizedBox(height: 16),
                        _LiveSessionTimer(
                          endTime: booking.effectiveEndTime,
                          label: 'SESSION ACTIVE',
                          accentColor: TiermetryColors.accentNeonGreen,
                        ),
                      ] else if (isVerifiedForStart) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF132034), Color(0xFF0F1826)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: TiermetryColors.accentAppleBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'IDENTITY VERIFIED',
                                    style: TiermetryTypography.label(
                                      color: TiermetryColors.accentAppleBlue,
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ready to play! Waiting for session time...',
                                style: TiermetryTypography.bodySmall(
                                  color: TiermetryColors.white.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (booking.status == BookingStatus.cancelled) ...[
                        const SizedBox(height: 16),
                        _BookingFinanceSummary(booking: booking),
                      ] else if (booking.status == BookingStatus.completed ||
                          booking.status == BookingStatus.noShow) ...[
                        const SizedBox(height: 16),
                        _BookingUsageSummary(booking: booking),
                      ] else if (booking.status == BookingStatus.confirmed &&
                          booking.effectiveEndTime.isAfter(DateTime.now())) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              CheckInSheet.show(context, booking);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TiermetryColors.positive,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Check In / Show PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () => widget.onCancel(booking.id),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ] else if (booking.status == BookingStatus.confirmed) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () => widget.onCancel(booking.id),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveSessionTimer extends StatefulWidget {
  final DateTime endTime;
  final String? label;
  final Color? accentColor;

  const _LiveSessionTimer({
    required this.endTime,
    this.label,
    this.accentColor,
  });

  @override
  State<_LiveSessionTimer> createState() => _LiveSessionTimerState();
}

class _LiveSessionTimerState extends State<_LiveSessionTimer> {
  late Stream<Duration> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.endTime.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? TiermetryColors.accentNeonGreen;
    final labelText = widget.label ?? 'SESSION ACTIVE';

    return StreamBuilder<Duration>(
      stream: _timerStream,
      initialData: widget.endTime.difference(DateTime.now()),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final d = duration.inDays;
        final h = (duration.inHours % 24).toString().padLeft(2, '0');
        final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.14),
                accent.withValues(alpha: 0.05),
                const Color(0xFF101214),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Activity Pill Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labelText.toUpperCase(),
                    style: TiermetryTypography.label(
                      color: accent,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Apple Watch / Live Activity Digital Blocks
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (d > 0) ...[
                    _buildTimeBlock(
                      d.toString().padLeft(2, '0'),
                      'DAYS',
                      accent,
                    ),
                    _buildColon(accent),
                  ],
                  _buildTimeBlock(h, 'HOURS', accent),
                  _buildColon(accent),
                  _buildTimeBlock(m, 'MINUTES', accent),
                  _buildColon(accent),
                  _buildTimeBlock(s, 'SECONDS', accent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeBlock(String value, String unit, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: TiermetryColors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TiermetryTypography.label(
            color: TiermetryColors.textMuted,
            fontSize: 8,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildColon(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ServiceRecoveryBanner extends StatelessWidget {
  final BookingEntity booking;

  const _ServiceRecoveryBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final credit =
        booking.events
            .where(
              (event) => event.eventType == 'SERVICE_RECOVERY_CREDIT_ISSUED',
            )
            .firstOrNull;
    final reassignment =
        booking.events
            .where(
              (event) =>
                  event.eventType == 'BOOKING_ASSET_REASSIGNED' ||
                  event.eventType == 'SESSION_RECOVERED',
            )
            .firstOrNull;
    if (credit == null && reassignment == null) return const SizedBox.shrink();

    final isCredit = credit != null;
    final event = credit ?? reassignment!;
    final amount = (event.metadata['amount'] as num?)?.toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isCredit ? Colors.amber : TiermetryColors.accentAppleBlue)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCredit
                  ? Icons.account_balance_wallet_rounded
                  : Icons.swap_horiz_rounded,
              color: isCredit ? Colors.amber : TiermetryColors.accentAppleBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCredit
                    ? 'Your booking was affected. ₹${(amount ?? 0).toStringAsFixed(0)} HOMIES Credits have been added to your account.'
                    : 'Your assigned station changed because the original station became unavailable. Your booking time and price are unchanged.',
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingFinanceSummary extends StatelessWidget {
  final BookingEntity booking;

  const _BookingFinanceSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.currency_rupee_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Refund tracked: ₹${booking.refundAmount.toStringAsFixed(0)}',
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (booking.refundPercentage > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Refund rate ${booking.refundPercentage.toStringAsFixed(0)}% • Paid ₹${booking.paidAmount.toStringAsFixed(0)}',
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          if ((booking.cancelReason ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                booking.cancelReason!,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingUsageSummary extends StatelessWidget {
  final BookingEntity booking;

  const _BookingUsageSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.status == BookingStatus.noShow
                ? 'No-show recorded for this booking.'
                : 'Usage tracked: ${booking.actualUsageHours.toStringAsFixed(1)}h used of ${booking.scheduledHours.toStringAsFixed(1)}h scheduled.',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Paid ₹${booking.paidAmount.toStringAsFixed(0)} • Refund ₹${booking.refundAmount.toStringAsFixed(0)} • ${booking.paymentState.name.toUpperCase()}',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
