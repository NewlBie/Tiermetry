import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/widgets/dot_grid_background.dart';

class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              const DotGridBackground(dotColor: Colors.white),
              Positioned(
                left: -120,
                top: -140,
                child: _AmbientBlob(
                  size: 340,
                  colors: [
                    TiermetryColors.accentLavender.withValues(alpha: 0.35),
                    TiermetryColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
              Positioned(
                right: -140,
                top: 60,
                child: _AmbientBlob(
                  size: 320,
                  colors: [
                    TiermetryColors.accentNeonGreen.withValues(alpha: 0.12),
                    TiermetryColors.accentCyan.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft radial wash that gives the same ambient-light impression as the
/// previous blurred circle without allocating an offscreen blur layer.
class _AmbientBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AmbientBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(stops: const [0, 0.42, 1], colors: colors),
      ),
    );
  }
}
