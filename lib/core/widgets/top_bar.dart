import 'dart:ui';
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';

class TopBar extends StatelessWidget {
  final Animation<double>? menuAnimationProgress;
  final VoidCallback onMenuTap;

  const TopBar({
    required this.onMenuTap,
    super.key,
    this.menuAnimationProgress,
  });

  @override
  Widget build(BuildContext context) {
    final surface = _TopBarSurface(
      menuAnimationProgress: menuAnimationProgress,
      onMenuTap: onMenuTap,
    );

    final glass = FeatureFlags.disableBlur
        ? surface
        : RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
              child: surface,
            ),
          );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TiermetrySpacing.screenPadding,
          vertical: TiermetrySpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: glass,
        ),
      ),
    );
  }
}

class _TopBarSurface extends StatelessWidget {
  final Animation<double>? menuAnimationProgress;
  final VoidCallback onMenuTap;

  const _TopBarSurface({
    required this.menuAnimationProgress,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
      ),
      child: SizedBox(
        height: TiermetrySpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(('TIERMETRY').toUpperCase(),
                style: TiermetryTypography.title(
                  color: TiermetryColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              _TopBarButton(
                onTap: onMenuTap,
                child: menuAnimationProgress == null
                    ? const Icon(
                        AmazingIconOutlined.menu,
                        color: Colors.white,
                        size: 20,
                      )
                    : AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: menuAnimationProgress!,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TopBarButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Center(child: child),
      ),
    );
  }
}
