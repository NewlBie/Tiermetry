import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/event_entity.dart';

class ShowdownDetailsScreen extends StatefulWidget {
  final EventEntity event;

  const ShowdownDetailsScreen({required this.event, super.key});

  @override
  State<ShowdownDetailsScreen> createState() => _ShowdownDetailsScreenState();
}

class _ShowdownDetailsScreenState extends State<ShowdownDetailsScreen>
    with RefreshRateMixin {
  final _eventCtrl = locator.eventCtrl;
  bool _isRegistered = false;
  bool _isLoadingStatus = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    try {
      final status = await _eventCtrl.checkRegistrationStatus(widget.event.id);
      if (mounted) {
        setState(() {
          _isRegistered = status;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!widget.event.isRegistrationOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration is currently closed.')),
      );
      return;
    }

    if (widget.event.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This showdown is already full.')),
      );
      return;
    }

    setState(() => _isRegistering = true);
    try {
      await _eventCtrl.registerForEvent(widget.event.id);
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isRegistering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldColor = Color(0xFF060606); // Extremely dark for contrast
    const accentColor = TiermetryColors.accentNeonGreen;

    return Scaffold(
      backgroundColor: scaffoldColor,
      extendBody: true,
      body: Stack(
        children: [
          // Hardcore gradient fade
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.network(
                widget.event.image ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scaffoldColor.withValues(alpha: 0.2),
                    scaffoldColor.withValues(alpha: 0.9),
                    scaffoldColor,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Main content
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, widget.event, accentColor),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TiermetrySpacing.screenPadding,
                  ),
                  child: widget.event.startTime.isBefore(DateTime.now())
                      ? _buildLeaderboardSection(accentColor)
                      : _buildEventDetailsSection(accentColor),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(context, widget.event, accentColor),
    );
  }

  Widget _buildHeader(BuildContext context, EventEntity event, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.lg,
            right: TiermetrySpacing.lg,
            top: 60, 
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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TiermetrySpacing.screenPadding,
            vertical: TiermetrySpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'COMPETITIVE SHOWDOWN',
                  style: TiermetryTypography.label(color: accentColor)
                      .copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event.title.toUpperCase(),
                style: TiermetryTypography.displayLarge(
                  color: TiermetryColors.white,
                ).copyWith(
                  height: 1.0,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic, // Aggressive style
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.trophy, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'PRIZE POOL: 50,000 PTS',
                    style: TiermetryTypography.titleSmall(color: Colors.amber)
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.clock, size: 14, color: TiermetryColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d').format(event.startTime)} • Ends ${DateFormat('MMM d').format(event.endTime)}',
                    style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailsSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TiermetrySpacing.xl),
        Text(
          'TOURNAMENT DETAILS',
          style: TiermetryTypography.title(color: TiermetryColors.white)
              .copyWith(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: TiermetrySpacing.lg),
        
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.locationDot, size: 16, color: TiermetryColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.event.location,
                style: TiermetryTypography.bodySmall(color: TiermetryColors.white)
                    .copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: TiermetrySpacing.md),
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.ticket, size: 16, color: TiermetryColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.event.cost,
                style: TiermetryTypography.bodySmall(color: accentColor)
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: TiermetrySpacing.xl),
        Text(
          'ABOUT THE SHOWDOWN',
          style: TiermetryTypography.label(color: TiermetryColors.textMuted).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: TiermetrySpacing.md),
        Text(
          widget.event.description ?? 'Prepare for the ultimate competitive showdown. Register now to secure your spot on the leaderboard.',
          style: TiermetryTypography.bodySmall(
            height: 1.5,
            fontSize: 14,
            color: TiermetryColors.white.withValues(alpha: 0.8),
          ),
        ),
        
        if (widget.event.perks.isNotEmpty) ...[
          const SizedBox(height: TiermetrySpacing.xl),
          Text(
            'PERKS & FEATURES',
            style: TiermetryTypography.label(color: TiermetryColors.textMuted).copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: TiermetrySpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.event.perks.map((perk) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TiermetryColors.surfaceElement,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                perk.name.toUpperCase(),
                style: TiermetryTypography.caption(color: TiermetryColors.white)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLeaderboardSection(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TiermetrySpacing.xl),
        Text(
          'LIVE LEADERBOARD',
          style: TiermetryTypography.title(color: TiermetryColors.white)
              .copyWith(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 32),
        // Podium
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPodiumBar('2', 'Alex G.', 1450, 100, const Color(0xFFC0C0C0)), // Silver
            _buildPodiumBar('1', 'NeonNinja', 1800, 140, const Color(0xFFFFD700)), // Gold
            _buildPodiumBar('3', 'Samurai99', 1320, 80, const Color(0xFFCD7F32)), // Bronze
          ],
        ),
        const SizedBox(height: 32),
        // Ranks 4 and 5
        _buildListRank(4, 'ShadowKiller', 1100),
        const SizedBox(height: 8),
        _buildListRank(5, 'PixelQueen', 1050),
        const SizedBox(height: 24),
        // Your Standing Sticky
        Container(
          padding: const EdgeInsets.all(TiermetrySpacing.md),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor, width: 2),
          ),
          child: Row(
            children: [
              Text(
                '#12',
                style: TiermetryTypography.title(color: accentColor).copyWith(fontWeight: FontWeight.w900, fontSize: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR STANDING',
                      style: TiermetryTypography.label(color: accentColor),
                    ),
                    Text(
                      '850 PTS',
                      style: TiermetryTypography.titleSmall(color: TiermetryColors.white).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.angleUp, color: TiermetryColors.positive, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumBar(String rank, String name, int points, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            rank,
            style: TiermetryTypography.title(color: color).copyWith(fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TiermetryTypography.bodySmall(color: TiermetryColors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          '$points PTS',
          style: TiermetryTypography.label(color: color).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top: BorderSide(color: color, width: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListRank(int rank, String name, int points) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.5),
      borderRadius: 12,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: TiermetryTypography.titleSmall(color: TiermetryColors.textMuted).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TiermetryTypography.bodySmall(color: TiermetryColors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$points PTS',
            style: TiermetryTypography.bodySmall(color: TiermetryColors.accentAppleBlue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, EventEntity event, Color accentColor) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.screenPadding,
            right: TiermetrySpacing.screenPadding,
            top: TiermetrySpacing.md,
            bottom: 32,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF060606).withValues(alpha: 0.75),
          ),
          child: _buildCTAButton(event, accentColor),
        ),
      ),
    );
  }

  Widget _buildCTAButton(EventEntity event, Color accentColor) {
    if (_isLoadingStatus) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(color: TiermetryColors.primary),
        ),
      );
    }

    if (_isRegistered) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: TiermetryColors.surfaceElement,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TiermetryRadii.md),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
        child: Text(
          'Already Entered',
          style: TiermetryTypography.action(
            fontSize: 16,
            color: TiermetryColors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final bool isOpen = event.isRegistrationOpen;
    final bool isFull = event.isFull;

    String label = 'ENTER TOURNAMENT';
    if (!isOpen) {
      final now = DateTime.now();
      if (now.isBefore(event.registrationStart)) {
        label = 'Opens ${DateFormat('MMM d').format(event.registrationStart)}';
      } else {
        label = 'Registration Closed';
      }
    } else if (isFull) {
      label = 'Tournament Full';
    }

    return ElevatedButton(
      onPressed: (isOpen && !isFull && !_isRegistering) ? _handleRegister : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOpen && !isFull ? accentColor : TiermetryColors.surfaceElement,
        foregroundColor: Colors.black, // Dark text on bright neon button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Sharper corners for gamer vibe
        ),
        minimumSize: const Size.fromHeight(56),
      ),
      child: _isRegistering
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: TiermetryTypography.action(
                fontSize: 16,
                color: isOpen && !isFull ? Colors.black : TiermetryColors.white.withValues(alpha: 0.5),
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
    );
  }
}
