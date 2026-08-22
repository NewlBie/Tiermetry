import 'dart:ui';

import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/features/notification/presentation/screens/notifications_screen.dart';

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
              // Left Side: Logo & Location
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/logo/HomiesTrans.svg',
                    height: 42,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Location selector tap
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          AmazingIconBulk.location(
                            size: 14,
                            color: TiermetryColors.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'New York',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Right Side: Actions
              Row(
                children: [
                  _TopBarButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: AmazingIconBulk.notification(
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TopBarButton(
                    onTap: onMenuTap,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          TiermetryColors.brandGradient.createShader(bounds),
                      child: AmazingIconBulk.category(
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
