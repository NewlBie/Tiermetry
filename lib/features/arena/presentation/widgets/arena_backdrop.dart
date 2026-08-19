import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/widgets/dot_grid_background.dart';

class ArenaBackdrop extends StatelessWidget {
  const ArenaBackdrop({super.key});

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
                child: _BlurBlob(
                  size: 340,
                  colors: [
                    TiermetryColors.accentPink.withValues(alpha: 0.25),
                    Colors.redAccent.shade400.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
              Positioned(
                right: -140,
                top: 60,
                child: _BlurBlob(
                  size: 320,
                  colors: [
                    TiermetryColors.negative.withValues(alpha: 0.12),
                    Colors.deepOrangeAccent.shade200.withValues(alpha: 0.10),
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

class _BlurBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _BlurBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: TiermetryBlur.filter(TiermetryBlur.lg),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
