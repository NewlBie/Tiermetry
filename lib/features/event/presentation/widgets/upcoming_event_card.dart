import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../domain/entities/event_entity.dart';
import '../screens/event_details_screen.dart';

class UpcomingEventCard extends StatefulWidget {
  final EventEntity event;

  const UpcomingEventCard({required this.event, super.key});

  @override
  State<UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<UpcomingEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => EventDetailsScreen(event: widget.event),
            ),
          );
        },
        child: AppSurface(
          borderRadius: TiermetryRadii.xl,
          border: Border.all(
            color: TiermetryColors.cardBorderEmphasis,
            width: 1.5,
          ),
          shadows: TiermetryShadows.upcomingEvent,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- INSET IMAGE (No Overlap) ---
              Expanded(
                flex: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: widget.event.id,
                        child: widget.event.image != null && !widget.event.image!.startsWith('assets/')
                          ? Image.network(
                              widget.event.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: TiermetryColors.surfaceUnderlay,
                                child: const Icon(Icons.broken_image, color: Colors.white24),
                              ),
                            )
                          : Image.asset(
                              widget.event.image ?? 'assets/Hackathon.jpg',
                              fit: BoxFit.cover,
                            ),
                      ),
                      // Top gradient just for top badges clarity if image is bright
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Live Status Blinker inside the image top-left
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, __) {
                                  final t =
                                      sin(_pulse.value * pi * 2) * 0.5 + 0.5;
                                  return Container(
                                    width: 6.5 + t * 2,
                                    height: 6.5 + t * 2,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color.lerp(
                                        TiermetryColors.negative,
                                        TiermetryColors.negative.withValues(
                                          alpha: 0.3,
                                        ),
                                        t,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: TiermetryColors.negative
                                              .withValues(alpha: 0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live soon',
                                style: TiermetryTypography.label(
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Notify Me Button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- SEPARATED TEXT AREA ---
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        widget.event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TiermetryTypography.titleSmall(
                          fontSize: 18,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Date & Time Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: TiermetryColors.accentNeonGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: TiermetryColors.accentNeonGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${DateFormat('MMM d').format(widget.event.startTime)} • ${DateFormat('hh:mm a').format(widget.event.startTime)}',
                              style: TiermetryTypography.caption(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TiermetryTypography.caption(
                                fontSize: 12.5,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
