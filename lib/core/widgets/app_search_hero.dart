import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_surface.dart';

/// A consistent hero-style search bar used at the top of feature screens.
class AppSearchHero extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;

  const AppSearchHero({
    required this.controller,
    required this.hintText,
    this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppSurface(
        borderRadius: 28,
        shadows: TiermetryShadows.searchBar,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: controller,
                hintText: hintText,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: TiermetrySpacing.sm),
              GestureDetector(
                onTap: onClear,
                child: AppSurface(
                  width: 48,
                  height: 48,
                  color: TiermetryColors.surfaceElement,
                  borderRadius: TiermetryRadii.md,
                  border: Border.all(color: Colors.transparent),
                  shadows: const [],
                  child: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _SearchField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.58),
          ),
          const SizedBox(width: TiermetrySpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: TiermetryTypography.caption(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: TiermetryColors.accentNeonGreen,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TiermetryTypography.caption(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
