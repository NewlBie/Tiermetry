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
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/reservation_hold_entity.dart';

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

  void _onCancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TiermetryColors.surface,
        title: Text('Cancel Booking', style: TiermetryTypography.title(color: TiermetryColors.white)),
        content: Text('Are you sure you want to cancel this booking?', style: TiermetryTypography.bodySmall(color: TiermetryColors.white, fontSize: 14)),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'My Bookings',
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
                if (_bookingCtrl.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: TiermetryColors.accentNeonGreen)),
                  );
                }
                
                // Filter out pending bookings (we use reservation holds now)
                final bookings = _bookingCtrl.bookings.where((b) => b.status != BookingStatus.pending).toList();
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
                      ...bookings.map((booking) => _buildBookingItem(context, booking)),
                    ],
                  ]),
                );
              },
            ),
          ),
        ],
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
        border: Border.all(color: TiermetryColors.accentAppleBlue.withValues(alpha: 0.2)),
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
              child: const Icon(Icons.timer_outlined, color: TiermetryColors.accentAppleBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporary Hold',
                    style: TiermetryTypography.title(fontSize: 16, color: TiermetryColors.white),
                  ),
                  Text(
                    'Expires at ${DateFormat('hh:mm a').format(hold.expiresAt)}',
                    style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: TiermetryColors.accentAppleBlue,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                // Navigate back to arena or show payment
                // For now, we'll just show a message. In a real app, this could reopen the payment flow.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please complete payment from the Arena screen.')),
                );
              },
              child: Text('PAY NOW', style: TiermetryTypography.action(fontSize: 12, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, BookingEntity booking) {
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => TiermetryColors.positive,
      BookingStatus.pending => Colors.amberAccent,
      BookingStatus.cancelled => Colors.redAccent,
      BookingStatus.completed => TiermetryColors.accentLavender,
      BookingStatus.expired => Colors.grey,
    };

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
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: TiermetryColors.surfaceElement,
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: AppPill(
                    text: booking.status.name.toUpperCase(),
                    color: statusColor,
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
                            Text(
                              booking.title,
                              style: TiermetryTypography.title(
                                color: TiermetryColors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'ID: ${booking.id.split('-').first.toUpperCase()}',
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${booking.totalAmount.toInt()}',
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
                      const Icon(Icons.location_on_rounded, size: 14, color: TiermetryColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        booking.location,
                        style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: TiermetryColors.white),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, MMM d • hh:mm a').format(booking.dateTime),
                        style: TiermetryTypography.bodySmall(color: TiermetryColors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (booking.status == BookingStatus.confirmed) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _onCancelBooking(booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
