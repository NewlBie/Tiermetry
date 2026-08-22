import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_image.dart';
import 'package:tiermetry/features/event/domain/entities/event_entity.dart';

import '../screens/showdown_details_screen.dart';

/// Showdown event card — dark surface, 16:9 image on top, white tilted
/// time badge at the seam, and compact metric+location block alongside date.
class ShowdownEventCard extends StatelessWidget {
  final EventEntity event;


  const ShowdownEventCard({required this.event, super.key});

  bool get _isOnline {
    final loc = event.location.trim().toLowerCase();
    return loc == 'online' || loc == 'virtual' || loc == 'remote';
  }

  bool get _isFree {
    final c = event.cost.trim().toLowerCase();
    return c == 'free' || c == '₹0' || c == '\$0' || c == '0' || c.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(event.startTime).toUpperCase();
    final month = DateFormat('MMM').format(event.startTime).toUpperCase();
    final day = DateFormat('d').format(event.startTime);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ShowdownDetailsScreen(event: event),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
        child: ColoredBox(
        color: TiermetryColors.surface, // app's standard card grey
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = (constraints.maxWidth / 280.0).clamp(1.0, 2.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 16:9 image ──
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppImage(
                    imagePath: event.image ?? 'assets/Hackathon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                // ── Dark content section with overlapping time badge ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Main content layout ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        TiermetrySpacing.lg * scale,
                        (TiermetrySpacing.xl + 4) * scale,
                        TiermetrySpacing.lg * scale,
                        TiermetrySpacing.sm * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Title ──
                          Text(
                            event.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.geist(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: TiermetryColors.white,
                            ),
                          ),
                          SizedBox(height: TiermetrySpacing.md * scale),
                          
                          // ── Bottom block ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // ── Left: metrics + location ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Metrics row
                                    Row(
                                      children: [
                                        _MetricChip(
                                          icon: _isOnline
                                              ? CupertinoIcons.globe
                                              : CupertinoIcons.location_fill,
                                          label: _isOnline
                                              ? 'Online'
                                              : 'In-person',
                                          scale: scale,
                                        ),
                                        SizedBox(width: 6 * scale),
                                        _MetricChip(
                                          icon: _isFree
                                              ? CupertinoIcons.gift_fill
                                              : CupertinoIcons.creditcard_fill,
                                          label:
                                              _isFree ? 'Free' : event.cost,
                                          highlight: _isFree,
                                          scale: scale,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5 * scale),
                                    // Location
                                    Text(
                                      event.location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TiermetryTypography.caption(
                                        color: TiermetryColors.white
                                            .withValues(alpha: 0.45),
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(
                                        fontSize: 11 * (1 + (scale - 1) * 0.5), 
                                        height: 1.3
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: TiermetrySpacing.sm * scale),

                              // ── Right: date badge ──
                              Container(
                                width: 40 * scale,
                                height: 40 * scale,
                                decoration: BoxDecoration(
                                  color: TiermetryColors.accentNeonGreen,
                                  borderRadius: BorderRadius.circular(10 * scale),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      month,
                                      style: GoogleFonts.geist(
                                        fontSize: 7 * scale,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      day,
                                      style: GoogleFonts.geist(
                                        fontSize: 15 * scale,
                                        height: 1.0,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Tilted WHITE time badge at seam ──
                    Positioned(
                      top: -14 * scale,
                      left: TiermetrySpacing.lg * scale,
                      child: Transform.rotate(
                        angle: -0.04,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 4 * scale,
                          ),
                          color: Colors.white,
                          child: Text(
                            time,
                            style: GoogleFonts.geist(
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.4,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        ),
      ),
    ));
  }
}

/// Compact icon + label chip used for event metrics.
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final double scale;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: highlight
            ? TiermetryColors.accentNeonGreen.withValues(alpha: 0.18)
            : TiermetryColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11 * scale,
            color: highlight
                ? TiermetryColors.accentNeonGreen
                : TiermetryColors.white.withValues(alpha: 0.7),
          ),
          SizedBox(width: 4 * scale),
          Text(
            label,
            style: TiermetryTypography.label(
              color: highlight
                  ? TiermetryColors.accentNeonGreen
                  : TiermetryColors.white.withValues(alpha: 0.85),
            ).copyWith(fontSize: 10 * scale),
          ),
        ],
      ),
    );
  }
}
