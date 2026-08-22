import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';

/// A scroll-responsive gradient overlay that sits at the top of the page.
/// This widget has its own scroll listener and only rebuilds itself,
/// NOT the entire page. This is crucial for smooth scrolling.
class ScrollGradientOverlay extends StatelessWidget {
  const ScrollGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const alphaValue = 0.6; // Static alpha for peak performance

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            height: topPadding + TiermetrySpacing.topBarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TiermetryColors.background.withValues(alpha: alphaValue),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
