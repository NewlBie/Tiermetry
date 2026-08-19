import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/app_typography.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/widgets/custom_progress_bar.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tier', trailing: 'Tutorials'),
          const SizedBox(height: 14),

          Text('$tierName is your current tier', style: AppTypography.xl),
          const SizedBox(height: 6),
          Text('Purple path', style: AppTypography.accent),
          const SizedBox(height: 20),

          TierProgressBar(progress: tierProgress),
          const SizedBox(height: 12),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TierLabel('VII'),
              _PercentText('25%'),
              _PercentText('50%'),
              _PercentText('75%'),
              _TierLabel('VIII'),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('Badges', trailing: 'Open all'),
          const SizedBox(height: 14),

          Text(
            'Opened $openedBadges/$totalBadges badges',
            style: AppTypography.lg,
          ),
          const SizedBox(height: 4),
          Text(
            'From $totalUniqueBadges unique badges',
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 18),

          _BadgeList(badgeTitles: badgeTitles, badgeColors: badgeColors),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.sm),
        if (trailing != null) Text(trailing, style: AppTypography.subtitle),
      ],
    );
  }
}

class _TierLabel extends StatelessWidget {
  final String text;

  const _TierLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TiermetryColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTypography.sm),
    );
  }
}

class _PercentText extends StatelessWidget {
  final String text;

  const _PercentText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.xs);
  }
}

class _BadgeCard extends StatelessWidget {
  final int index;
  final String title;
  final Color color;

  const _BadgeCard({
    required this.index,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}', style: AppTypography.sm),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.xs.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  final List<String> badgeTitles;
  final List<Color> badgeColors;

  const _BadgeList({required this.badgeTitles, required this.badgeColors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // List
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: badgeTitles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _BadgeCard(
                index: index,
                title: badgeTitles[index],
                color: badgeColors[index],
              );
            },
          ),
        ),

        // Left Fade
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TiermetryColors.surface,
                    TiermetryColors.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Fade
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    TiermetryColors.surface,
                    TiermetryColors.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
