import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

/// A simple bento tile widget used in the metrics grid.
/// Shows a title with a decorative image positioned in the background.
class BentoTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final double imageRight;
  final double imageBottom;
  final double imageScale;

  const BentoTile({
    required this.title,
    required this.imagePath,
    this.imageRight = -10,
    this.imageBottom = -10,
    this.imageScale = 1.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppSurface(
        height: MediaQuery.of(context).size.width < 360 ? 110 : 140,
        borderRadius: TiermetryRadii.md,
        child: Stack(
          children: [
            // Background image – bottom right
            Positioned(
              right: imageRight,
              bottom: imageBottom,
              child: Transform.scale(
                scale: imageScale,
                alignment: Alignment.bottomRight,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    color: Colors.white.withValues(alpha: 0.85),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
            ),
            // Title on top left
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text((title).toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.title(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
