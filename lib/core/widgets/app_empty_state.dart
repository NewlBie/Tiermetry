import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_surface.dart';

/// A consistent empty state widget for lists and sections.
class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const AppEmptyState({
    required this.message,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TiermetrySpacing.pagePadding,
      child: AppSurface(
        width: double.infinity,
        padding: const EdgeInsets.all(TiermetrySpacing.lg),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white24, size: 48),
              const SizedBox(height: TiermetrySpacing.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TiermetryTypography.caption(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
