import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/colors.dart';

class TopBar extends StatelessWidget {
  final Widget title;

  // Kept for backwards compatibility; this widget previously animated the menu
  // icon. The current TopBar uses a static icon.
  final Animation<double>? menuAnimationProgress;

  final bool hasNotification;
  final VoidCallback onMenuTap;

  const TopBar({
    super.key,
    required this.title,
    this.menuAnimationProgress,
    required this.hasNotification,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = _TopBarSurface(
      title: title,
      menuAnimationProgress: menuAnimationProgress,
      hasNotification: hasNotification,
      onMenuTap: onMenuTap,
    );

    final glass =
        FeatureFlags.disableBlur
            ? surface
            : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: surface,
            );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Frosted Matte Glass Zone ---
        ClipRect(child: glass),

        // --- Luminous Separator ---
        Container(
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.05),
                TiermetryColors.accentLavender.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ),

        // --- Fade-out Gradient (no blur, pure paint) ---
        Container(
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TiermetryColors.background.withValues(alpha: 0.5),
                TiermetryColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBarSurface extends StatelessWidget {
  final Widget title;
  final Animation<double>? menuAnimationProgress;
  final bool hasNotification;
  final VoidCallback onMenuTap;

  const _TopBarSurface({
    required this.title,
    required this.menuAnimationProgress,
    required this.hasNotification,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TiermetryColors.background.withValues(alpha: 0.72),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            bottom: 12,
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TopBarButton(
                  onTap: onMenuTap,
                  child:
                      menuAnimationProgress == null
                          ? const Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                          : AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress: menuAnimationProgress!,
                            color: Colors.white,
                            size: 22,
                          ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      key: title.key ?? ValueKey(title.runtimeType),
                      child: title,
                    ),
                  ),
                ),
                _TopBarButton(
                  onTap: () {
                    // TODO: implement notifications
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      if (hasNotification)
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: TiermetryColors.accentLavender,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: TiermetryColors.accentLavender
                                      .withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
