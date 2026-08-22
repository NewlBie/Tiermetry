

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_image.dart';

import '../../domain/entities/event_entity.dart';
import '../screens/event_details_screen.dart';

/// A tall portrait (9:16) event card — the entire card is the image
/// with overlaid title, meta info, optional FREE tag, and date badge.
class UpcomingEventCard extends StatelessWidget {
  final EventEntity event;

  const UpcomingEventCard({required this.event, super.key});

  bool get _isFree {
    final c = event.cost.trim().toLowerCase();
    return c == 'free' || c == '₹0' || c == '\$0' || c == '0' || c.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMM').format(event.startTime).toUpperCase();
    final day = DateFormat('d').format(event.startTime);
    final time = DateFormat('h:mm a').format(event.startTime);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
        },
        child: SizedBox.expand(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TiermetryRadii.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Base width of the card designed for 225
                final double scale = (constraints.maxWidth / 225.0).clamp(1.0, 2.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Full-bleed sharp image ──
                    SizedBox.expand(
                      child: AppImage(
                        imagePath: event.image ?? 'assets/Hackathon.jpg',
                      ),
                    ),

                    // ── High-Performance Dark Gradient Fade ──
                    // Replaces the expensive GPU blur with a smooth, 120fps-friendly gradient
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: const [0.0, 0.35, 0.60, 1.0],
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.75),
                                Colors.black.withValues(alpha: 0.20),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Dark gradient (bottom ~35%) ──
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: const [0.0, 0.20, 0.40, 1.0],
                              colors: [
                                Colors.black.withValues(alpha: 0.92),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom content ──
                    Positioned(
                      left: TiermetrySpacing.lg * scale,
                      right: TiermetrySpacing.lg * scale,
                      bottom: TiermetrySpacing.lg * scale,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // FREE tag (only when free)
                          if (_isFree)
                            Container(
                              margin: EdgeInsets.only(bottom: 10 * scale),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: TiermetryColors.accentNeonGreen,
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                              child: Text(
                                'FREE',
                                style: GoogleFonts.geist(
                                  fontSize: 9 * scale,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                          // Title (wraps to 2 lines)
                          Padding(
                            padding: EdgeInsets.only(right: 12 * scale),
                            child: Text(
                              event.title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.geist(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: TiermetrySpacing.md * scale),

                          // Meta row: time + location on left, date badge on right
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Time & location
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      time,
                                      style: TiermetryTypography.caption(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ).copyWith(fontSize: 12 * scale),
                                    ),
                                    SizedBox(height: 3 * scale),
                                    Text(
                                      event.location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TiermetryTypography.caption(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ).copyWith(
                                        // Use a smaller scale factor for location to show more insights
                                        fontSize: 11 * (1 + (scale - 1) * 0.5), 
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 10 * scale),

                              // Date badge (square)
                              _DateBadge(
                                month: month, 
                                day: day, 
                                scale: scale,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}

/// Green square date badge with month + day stacked.
class _DateBadge extends StatelessWidget {
  final String month;
  final String day;
  final double scale;

  const _DateBadge({
    required this.month, 
    required this.day, 
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42 * scale,
      height: 42 * scale,
      decoration: BoxDecoration(
        color: TiermetryColors.accentNeonGreen,
        borderRadius: BorderRadius.circular(11 * scale),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: GoogleFonts.geist(
              fontSize: 8 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.black,
            ),
          ),
          Text(
            day,
            style: GoogleFonts.geist(
              fontSize: 17 * scale,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
