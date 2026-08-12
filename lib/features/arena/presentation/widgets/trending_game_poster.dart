import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

class TrendingGamePoster extends StatelessWidget {
  final int rank;
  final String title;
  final Color baseColor;

  const TrendingGamePoster({
    required this.rank, required this.title, required this.baseColor, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: 140, // Vertical poster width
      borderRadius: 20,
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      shadows: [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient (acting as a dynamic poster cover)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor.withValues(alpha: 0.8),
                  baseColor.withValues(alpha: 0.2),
                  Colors.black87,
                ],
              ),
            ),
          ),

          // Central Typography (in place of cover art)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TiermetryTypography.display(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
          ),

          // Dark fade at the bottom if needed
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Top Left Rank Badge
          Positioned(
            top: 12,
            left: 12,
            child: AppSurface(
              borderRadius: 12,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.transparent),
              shadows: const [],
              child: BackdropFilter(
                filter: TiermetryBlur.filter(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '#$rank',
                    style: TiermetryTypography.bodySmall(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
