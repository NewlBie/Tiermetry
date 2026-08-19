import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:silky_scroll/silky_scroll.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/scroll_fade_overlay.dart';

/// ---------------------------------------------------------------------------
/// "LIVE AROUND YOU" - horizontally scrollable activity cards
/// ---------------------------------------------------------------------------

class LiveAroundYouSection extends StatefulWidget {
  const LiveAroundYouSection({super.key});

  @override
  State<LiveAroundYouSection> createState() => _LiveAroundYouSectionState();
}

class _LiveAroundYouSectionState extends State<LiveAroundYouSection> {
  late ScrollController _scrollController;
  double _maxScroll = 0;
  double _leftFadeOpacity = 0;
  double _rightFadeOpacity = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Use throttled listener instead of on every pixel
    _scrollController.addListener(_throttledScrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _maxScroll = _scrollController.position.maxScrollExtent);
        _updateFadeOpacity();
      }
    });
  }

  void _throttledScrollListener() {
    _updateFadeOpacity();
  }

  void _updateFadeOpacity() {
    if (_maxScroll == 0) return;

    final double offset = _scrollController.offset;
    final double remaining = _maxScroll - offset;

    // Simple linear fade: 0-50px fade range
    final double leftOp = (offset / 50).clamp(0, 1);
    final double rightOp = (remaining / 50).clamp(0, 1);

    if (mounted &&
        ((_leftFadeOpacity - leftOp).abs() > 0.03 ||
            (_rightFadeOpacity - rightOp).abs() > 0.03)) {
      setState(() {
        _leftFadeOpacity = leftOp;
        _rightFadeOpacity = rightOp;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Dummy data - replace with real data later
  static const List<_LiveActivity> _activities = [
    _LiveActivity(
      image: 'assets/images/bowling.png',
      title: 'Bowling Night',
      location: 'Downtown Alley',
      playersPlaying: 12,
      distance: '1.2 km',
      temperature: '24 C',
      priceDisplay: '₹1200',
    ),
    _LiveActivity(
      image: 'assets/images/football.png',
      title: 'Street Football',
      location: 'Central Park',
      playersPlaying: 18,
      distance: '0.8 km',
      temperature: '19 C',
      priceDisplay: 'Free',
    ),
    _LiveActivity(
      image: 'assets/images/gaming.png',
      title: 'Gaming Lounge',
      location: 'Cyber Cafe',
      playersPlaying: 8,
      distance: '2.5 km',
      temperature: '21 C',
      priceDisplay: '₹800/hr',
    ),
    _LiveActivity(
      image: 'assets/images/racing.png',
      title: 'Go-Kart Racing',
      location: 'Speedway Track',
      playersPlaying: 6,
      distance: '3.1 km',
      temperature: '28 C',
      priceDisplay: '₹2000',
    ),
    _LiveActivity(
      image: 'assets/images/pool.png',
      title: 'Pool Party',
      location: 'Rooftop Bar',
      playersPlaying: 24,
      distance: '4.0 km',
      temperature: '30 C',
      priceDisplay: 'Free',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: TiermetrySpacing.pagePadding,
          child: Row(
            children: [
              // Pulsing live dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: TiermetryColors.accentNeonGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TiermetryColors.accentNeonGreen.withValues(
                        alpha: 0.5,
                      ),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(('Live Around You').toUpperCase(),
                style: TiermetryTypography.title(color: Colors.white),
              ),
            ],
          ),
        ),

        const SizedBox(height: TiermetrySpacing.lg),

        // Horizontally scrollable cards with lightweight fade overlay
        SizedBox(
          height: 320,
          child: Stack(
            children: [
              SilkyListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: TiermetrySpacing.pagePadding,
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: _LiveActivityCard(activity: _activities[index]),
                  );
                },
              ),
              ScrollFadeOverlay(opacity: _rightFadeOpacity),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// SINGLE LIVE ACTIVITY CARD
/// Refined design matching the specific reference image:
/// - Large image top with rounded corners
/// - Overlays: Temperature pill (top), Avatars (bottom-left), Stats pill (bottom-right)
/// - Bottom content: Large title, location subtitle, stats row container
/// ---------------------------------------------------------------------------

class _LiveActivityCard extends StatefulWidget {
  final _LiveActivity activity;

  const _LiveActivityCard({required this.activity});

  @override
  State<_LiveActivityCard> createState() => _LiveActivityCardState();
}

class _LiveActivityCardState extends State<_LiveActivityCard> {
  bool _showFullTemp = true;
  Timer? _tempTimer;

  @override
  void initState() {
    super.initState();
    // Show full "Temperature Currently" for 3 seconds, then shrink to circle
    _tempTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showFullTemp = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tempTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: 240,
      border: const Border(),
      borderRadius: TiermetryRadii.md,
      shadows: TiermetryShadows.liveActivity,
      child: Column(
        children: [
          // --- Image Section (65%) ---
          Expanded(
            flex: 65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main Image with Rounded Corners on All Sides
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8), // vertical shadow
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.activity.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Top Left Overlay: Animated Temperature Pill -> Circle
                Positioned(
                  left: 24,
                  top: 24,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastOutSlowIn,
                    padding:
                        _showFullTemp
                            ? const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            )
                            : const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.activity.temperature,
                          style: TiermetryTypography.caption(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        // Collapse the text width to 0
                        AnimatedSize(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.fastOutSlowIn,
                          child:
                              _showFullTemp
                                  ? Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'Currently',
                                      style: TiermetryTypography.label(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pagination Dots
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(true),
                      const SizedBox(width: 4),
                      _buildDot(false),
                      const SizedBox(width: 4),
                      _buildDot(false),
                    ],
                  ),
                ),

              ],
            ),
          ),

          // --- Content Section (35%) ---
          Expanded(
            flex: 35,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCardContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Use a helper method for the static content to reduce build nesting clutter
  Widget _buildCardContent() {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text((widget.activity.title).toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TiermetryTypography.title(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        // Subtitle / Location
        Text(
          widget.activity.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TiermetryTypography.caption(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(height: 8),

        // Stats Pill (Bottom Container)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: TiermetryColors.surfaceElement,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatIcon(
                CupertinoIcons.person_2,
                '${widget.activity.playersPlaying}',
              ),
              Container(
                width: 1,
                height: 10,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildStatIcon(CupertinoIcons.location_solid, widget.activity.distance),
              Container(
                width: 1,
                height: 10,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildStatIcon(CupertinoIcons.ticket, widget.activity.priceDisplay),
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TiermetryTypography.caption(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Data model for a live activity
class _LiveActivity {
  final String image;
  final String title;
  final String location;
  final int playersPlaying;
  final String distance;
  final String temperature;
  final String priceDisplay;

  const _LiveActivity({
    required this.image,
    required this.title,
    required this.location,
    required this.playersPlaying,
    required this.distance,
    required this.temperature,
    required this.priceDisplay,
  });
}
