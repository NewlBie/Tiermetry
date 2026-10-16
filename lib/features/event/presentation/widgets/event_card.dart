import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/event_entity.dart';
import '../screens/event_details_screen.dart';

class EventCard extends StatelessWidget {
  final EventEntity event;
  final VoidCallback? onAddToCalendar;

  const EventCard({required this.event, super.key, this.onAddToCalendar});

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      borderRadius: 22,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Hero(
            tag: event.id,
            child:
                event.image != null && !event.image!.startsWith('assets/')
                    ? Image.network(
                      event.image!,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 240,
                            width: double.infinity,
                            color: TiermetryColors.surfaceUnderlay,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                            ),
                          ),
                    )
                    : Image.asset(
                      event.image ?? 'assets/Hackathon.jpg',
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
          ),
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time pill + menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppPill(
                        text: DateFormat('hh:mm a').format(event.startTime),
                        color: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white,
                      ),
                      const Icon(Icons.more_horiz, color: Colors.white70),
                    ],
                  ),

                  const Spacer(),

                  // Keep tags in a single rail so variable tag lengths cannot
                  // consume the fixed-height image card's content space.
                  SizedBox(
                    height: 26,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: event.tags.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder:
                          (context, index) => AppPill(
                            text: event.tags[index],
                            color: Colors.white.withValues(alpha: 0.2),
                            textColor: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    (event.title).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.titleSmall(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    event.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.bodySmall(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder<void>(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder:
                              (_, __, ___) => EventDetailsScreen(event: event),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: AppSurface(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      borderRadius: 100,
                      color: Colors.white,
                      border: Border.all(color: Colors.transparent),
                      shadows: const [],
                      child: Center(
                        child: Text(
                          'View Details',
                          style: TiermetryTypography.action(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
