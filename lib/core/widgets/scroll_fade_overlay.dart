import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A subtle gradient overlay used to indicate scrolling content.
class ScrollFadeOverlay extends StatelessWidget {
  final double opacity;
  final bool isRight;
  final double width;

  const ScrollFadeOverlay({
    required this.opacity,
    this.isRight = true,
    this.width = 28,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: isRight ? 0 : null,
      left: isRight ? null : 0,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isRight ? Alignment.centerLeft : Alignment.centerRight,
              end: isRight ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.transparent,
                TiermetryColors.background.withValues(
                  alpha: opacity * 0.3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
