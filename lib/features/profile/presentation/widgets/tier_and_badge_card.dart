import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/theme/colors.dart';

class TierAndBadgeCard extends StatelessWidget {
  final String tierName;
  final double tierProgress;
  final int openedBadges;
  final int totalBadges;
  final int totalUniqueBadges;
  final List<String> badgeTitles;
  final List<Color> badgeColors;

  const TierAndBadgeCard({
    required this.tierName,
    required this.tierProgress,
    required this.openedBadges,
    required this.totalBadges,
    required this.totalUniqueBadges,
    required this.badgeTitles,
    required this.badgeColors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIER',
            style: GoogleFonts.geist(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),

          // Current Tier
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                tierName,
                style: GoogleFonts.geist(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Path',
                style: GoogleFonts.geist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TiermetryColors.accentNeonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Animated Progress Bar
          _AnimatedProgressBar(progress: tierProgress),
          const SizedBox(height: 14),
          
          // Steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _TierStep('VII', isActive: true),
              _StepDot(isActive: tierProgress >= 0.25),
              _StepDot(isActive: tierProgress >= 0.50),
              _StepDot(isActive: tierProgress >= 0.75),
              const _TierStep('VIII', isActive: false),
            ],
          ),
          const SizedBox(height: 24),

          // Badges Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BADGES',
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$openedBadges / $totalBadges Opened',
                    style: GoogleFonts.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                'Open All',
                style: GoogleFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TiermetryColors.accentNeonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Badges List
          _BadgeList(
            badgeTitles: badgeTitles, 
            badgeColors: badgeColors,
            openedBadges: openedBadges,
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;

  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutExpo, // Duolingo style super-smooth pop
            builder: (context, value, child) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TiermetryColors.accentNeonGreen.withValues(alpha: 0.7),
                          TiermetryColors.accentNeonGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  // Shine highlight on the bar
                  if (value > 0.08)
                    Positioned(
                      top: 4,
                      right: 12,
                      child: Container(
                        width: 14,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TierStep extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TierStep(this.label, {required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? TiermetryColors.accentNeonGreen.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? TiermetryColors.accentNeonGreen.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.geist(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: isActive ? TiermetryColors.accentNeonGreen : Colors.white54,
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;

  const _StepDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        color: isActive ? TiermetryColors.accentNeonGreen : Colors.white24,
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(
            color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.6),
            blurRadius: 8,
          )
        ] : null,
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  final List<String> badgeTitles;
  final List<Color> badgeColors;
  final int openedBadges;

  const _BadgeList({
    required this.badgeTitles, 
    required this.badgeColors,
    required this.openedBadges,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: badgeTitles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final isAchieved = index < openedBadges;
          final color = isAchieved ? badgeColors[index] : Colors.grey;
          final opacity = isAchieved ? 1.0 : 0.25;

          // We alternate between verified bulk icons to ensure compilation
          final List<Widget Function(double, Color)> icons = [
            (size, c) => AmazingIconBulk.profile(size: size, color: c),
            (size, c) => AmazingIconBulk.game(size: size, color: c),
            (size, c) => AmazingIconBulk.discover(size: size, color: c),
            (size, c) => AmazingIconBulk.category(size: size, color: c),
          ];
          final iconBuilder = icons[index % icons.length];
          
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: opacity,
            child: Container(
              width: 86,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconBuilder(34.0, color),
                  const Spacer(),
                  Text(
                    badgeTitles[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
