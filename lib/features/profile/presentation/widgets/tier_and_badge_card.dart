import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/wallet/domain/entities/loyalty_account_entity.dart';
import 'package:tiermetry/features/wallet/domain/entities/vibe_status.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/vibe_xp_status_card.dart';

/// Displays only badges issued by the server-owned Vibe badge lifecycle.
class TierAndBadgeCard extends StatelessWidget {
  final LoyaltyAccountEntity account;
  final VoidCallback? onStatusTap;

  const TierAndBadgeCard({required this.account, this.onStatusTap, super.key});

  @override
  Widget build(BuildContext context) {
    final badges = account.earnedStatusBadges;
    return Column(
      children: [
        VibeXpStatusCard(account: account, onTap: onStatusTap),
        const SizedBox(height: TiermetrySpacing.md),
        AppSurface(
          width: double.infinity,
          padding: const EdgeInsets.all(TiermetrySpacing.lg),
          color: TiermetryColors.surfaceUnderlay,
          borderRadius: TiermetryRadii.lg,
          shadows: const [],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EARNED BADGES',
                style: TiermetryTypography.label(
                  color: TiermetryColors.textMuted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badges.isEmpty
                    ? 'Your first badge is waiting'
                    : '${badges.length} earned',
                style: TiermetryTypography.titleSmall(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: TiermetrySpacing.md),
              if (badges.isEmpty)
                Text(
                  'Complete eligible activities to unlock badges. Achievements are awarded and verified by HOMIES.',
                  style: TiermetryTypography.bodySmall(
                    color: TiermetryColors.textMuted,
                    height: 1.4,
                  ),
                )
              else
                Wrap(
                  spacing: TiermetrySpacing.sm,
                  runSpacing: TiermetrySpacing.sm,
                  children: badges
                      .map((badge) => _BadgeChip(badge: badge))
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final EarnedStatusBadge badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = _colorForRarity(badge.rarity);
    return InkWell(
      borderRadius: BorderRadius.circular(TiermetryRadii.md),
      onTap: () => _showDetail(context, color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TiermetryRadii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(badge.iconName), size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              badge.title,
              style: TiermetryTypography.caption(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Color color) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
              child: AppSurface(
                padding: const EdgeInsets.all(TiermetrySpacing.xl),
                color: TiermetryColors.surface,
                borderRadius: TiermetryRadii.lg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(badge.iconName), size: 38, color: color),
                    const SizedBox(height: TiermetrySpacing.md),
                    Text(
                      badge.title,
                      style: TiermetryTypography.title(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${badge.rarity.toUpperCase()} BADGE',
                      style: TiermetryTypography.label(color: color),
                    ),
                    const SizedBox(height: TiermetrySpacing.md),
                    Text(
                      badge.criterion.isNotEmpty
                          ? badge.criterion
                          : 'Awarded by verified HOMIES activity.',
                      textAlign: TextAlign.center,
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.textMuted,
                      ),
                    ),
                    if (badge.earnedAt != null) ...[
                      const SizedBox(height: TiermetrySpacing.sm),
                      Text(
                        'Earned ${DateFormat.yMMMd().format(badge.earnedAt!)}',
                        style: TiermetryTypography.caption(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: TiermetrySpacing.lg),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  IconData _iconFor(String icon) => switch (icon) {
    'rocket' => Icons.rocket_launch_rounded,
    'explore' => Icons.explore_rounded,
    'calendar' => Icons.calendar_month_rounded,
    'shield' => Icons.shield_rounded,
    'star' => Icons.stars_rounded,
    'diamond' => Icons.diamond_rounded,
    _ => Icons.workspace_premium_rounded,
  };

  Color _colorForRarity(String rarity) => switch (rarity) {
    'common' => TiermetryColors.accentCyan,
    'rare' => TiermetryColors.accentLavender,
    'epic' => const Color(0xFFFF9F43),
    'legendary' => TiermetryColors.accentPink,
    'mythic' => const Color(0xFFFFC857),
    _ => Colors.white70,
  };
}
