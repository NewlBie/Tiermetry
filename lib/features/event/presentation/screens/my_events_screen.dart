import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../domain/entities/event_entity.dart';
import 'event_details_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _eventCtrl = locator.eventCtrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _eventCtrl.loadMyRegistrations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
            sliver: ListenableBuilder(
              listenable: _eventCtrl,
              builder: (context, _) {
                if (_eventCtrl.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: TiermetryColors.accentAppleBlue)),
                  );
                }

                final registrations = _eventCtrl.myRegistrations;

                if (registrations.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: TiermetryColors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No registered events found.',
                          style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TiermetryColors.accentAppleBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Explore Events'),
                        ),
                      ],
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildEventRegistrationCard(registrations[index]);
                    },
                    childCount: registrations.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
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
              'My Registered Events',
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventRegistrationCard(EventEntity event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.lg),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => EventDetailsScreen(event: event)),
        ),
        child: AppSurface(
          padding: EdgeInsets.zero,
          borderRadius: TiermetryRadii.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(TiermetryRadii.lg)),
                    child: Hero(
                      tag: event.id,
                      child: event.image != null && !event.image!.startsWith('assets/')
                          ? Image.network(
                              event.image!,
                              fit: BoxFit.cover,
                              height: 140,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(height: 140, color: TiermetryColors.surfaceUnderlay),
                            )
                          : Image.asset(
                              event.image ?? 'assets/Hackathon.jpg',
                              fit: BoxFit.cover,
                              height: 140,
                              width: double.infinity,
                            ),
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: AppPill(
                      text: 'REGISTERED',
                      color: TiermetryColors.positive,
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
                    Text(
                      event.title,
                      style: TiermetryTypography.title(
                        color: TiermetryColors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: TiermetryColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: TiermetryColors.white),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEE, MMM d • hh:mm a').format(event.startTime),
                              style: TiermetryTypography.bodySmall(color: TiermetryColors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          event.cost,
                          style: TiermetryTypography.title(
                            color: TiermetryColors.accentNeonGreen,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
