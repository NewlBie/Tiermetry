import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/reservation_hold_entity.dart';
import '../widgets/check_in_sheet.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with RefreshRateMixin {
  final _bookingCtrl = locator.bookingCtrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _bookingCtrl.loadBookings());
  }

  Future<void> _onCancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: TiermetryColors.surface,
            title: Text(('Cancel Booking').toUpperCase(),
              style: TiermetryTypography.title(color: TiermetryColors.white),
            ),
            content: Text(
              'Are you sure you want to cancel this booking?',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.white,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _bookingCtrl.cancelBooking(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
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
            SliverAppBar(
              pinned: true,
              expandedHeight: 80.0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(('My Bookings').toUpperCase(),
                      style: TiermetryTypography.title(
                        color: TiermetryColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
              sliver: ListenableBuilder(
                listenable: _bookingCtrl,
                builder: (context, child) {
                  if (_bookingCtrl.isLoading &&
                      _bookingCtrl.bookings.isEmpty &&
                      _bookingCtrl.activeHolds.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TiermetryColors.accentNeonGreen,
                        ),
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
                  final bookings =
                      _bookingCtrl.bookings
                          .where((b) => b.status != BookingStatus.pending)
                          .toList();
                  final holds = _bookingCtrl.activeHolds;

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
      child: AppSurface(
        padding: const EdgeInsets.all(16),
        color: TiermetryColors.accentAppleBlue.withValues(alpha: 0.05),
        borderRadius: TiermetryRadii.md,
        border: Border.all(
          color: TiermetryColors.accentAppleBlue.withValues(alpha: 0.2),
        ),
        shadows: const [],
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: TiermetryColors.accentAppleBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: TiermetryColors.accentAppleBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(('Temporary Hold').toUpperCase(),
                    style: TiermetryTypography.title(
                      fontSize: 16,
                      color: TiermetryColors.white,
                    ),
                  ),
                  Text(
                    'Expires at ${DateFormat('hh:mm a').format(hold.expiresAt)}',
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: TiermetryColors.accentAppleBlue,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                // Return to Arena screen to complete payment
                Navigator.popUntil(context, (route) => route.isFirst);
                // The main screen has the bottom nav, user can go to Arenas
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please select the arena to complete your pending payment.',
                    ),
                  ),
                );
              },
              child: const Text(
                'PAY NOW',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.lg),
      child: AppSurface(
        padding: EdgeInsets.zero,
        borderRadius: TiermetryRadii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  booking.imageUrl,
                  fit: BoxFit.cover,
                  height: 160,
                  width: double.infinity,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 160,
                        color: TiermetryColors.surfaceElement,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white24,
                        ),
                      ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: AppPill(
                    text:
                        (isActuallyActive
                                ? 'ACTIVE'
                                : isVerifiedForStart
                                ? 'VERIFIED'
                                : booking.status == BookingStatus.noShow
                                ? 'NO SHOW'
                                : booking.status.name)
                            .toUpperCase(),
                    color:
                        isActuallyActive
                            ? TiermetryColors.accentNeonGreen
                            : statusColor,
                    textColor: Colors.black,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((booking.title).toUpperCase(),
                              style: TiermetryTypography.title(
                                color: TiermetryColors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'ID: ${(booking.bookingCode ?? booking.id.split('-').first).toUpperCase()}',
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(('₹${booking.totalAmount.toStringAsFixed(0)}').toUpperCase(),
                        style: TiermetryTypography.title(
                          color: TiermetryColors.accentNeonGreen,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: TiermetryColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.location,
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (booking.assignedAssetName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.computer_rounded,
                          size: 14,
                          color: TiermetryColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Assigned station: ${booking.assignedAssetName}',
                          style: TiermetryTypography.bodySmall(
                            color: TiermetryColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  _ServiceRecoveryBanner(booking: booking),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: TiermetryColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat(
                          'EEE, MMM d • hh:mm a',
                        ).format(booking.dateTime),
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isActuallyActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: TiermetryColors.accentNeonGreen.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TiermetryColors.accentNeonGreen.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SESSION ACTIVE',
                            style: TiermetryTypography.label(
                              color: TiermetryColors.accentNeonGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _LiveSessionTimer(endTime: booking.effectiveEndTime),
                        ],
                      ),
                    ),
                  ] else if (isVerifiedForStart) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: TiermetryColors.accentAppleBlue.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TiermetryColors.accentAppleBlue.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                color: TiermetryColors.accentAppleBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'IDENTITY VERIFIED',
                                style: TiermetryTypography.label(
                                  color: TiermetryColors.accentAppleBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Waiting for scheduled start time...',
                            style: TiermetryTypography.bodySmall(
                              color: TiermetryColors.white.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          CheckInSheet.show(context, booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TiermetryColors.positive,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text(
                          'Check In / Show PIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => widget.onCancel(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel Booking'),
                      ),
                    ),
                  ] else if (booking.status == BookingStatus.confirmed) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => widget.onCancel(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel Booking'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSessionTimer extends StatefulWidget {
  final DateTime endTime;
  const _LiveSessionTimer({required this.endTime});

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
    return StreamBuilder<Duration>(
      stream: _timerStream,
      initialData: widget.endTime.difference(DateTime.now()),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        if (duration.inSeconds <= 0) {
          return Text(('00:00:00').toUpperCase(),
            style: TiermetryTypography.title(
              color: TiermetryColors.white,
              fontSize: 32,
            ),
          );
        }
        final h = duration.inHours.toString().padLeft(2, '0');
        final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Text(
          '$h:$m:$s',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: TiermetryColors.white,
          ),
        );
      },
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isCredit ? Colors.amber : TiermetryColors.accentAppleBlue)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isCredit ? Colors.amber : TiermetryColors.accentAppleBlue)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCredit
                  ? Icons.account_balance_wallet_rounded
                  : Icons.swap_horiz_rounded,
              color: isCredit ? Colors.amber : TiermetryColors.accentAppleBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCredit
                    ? 'Your booking was affected. ₹${(amount ?? 0).toStringAsFixed(0)} Tiermetry Credits have been added to your account.'
                    : 'Your assigned station changed because the original station became unavailable. Your booking time and price are unchanged.',
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                  fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund tracked: ₹${booking.refundAmount.toStringAsFixed(0)}',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (booking.refundPercentage > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TiermetryColors.white.withValues(alpha: 0.08),
        ),
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
