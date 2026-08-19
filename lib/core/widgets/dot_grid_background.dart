import 'dart:math';
import 'package:flutter/material.dart';

class DotGridBackground extends StatelessWidget {
  final Color dotColor;
  final double opacity;
  final double spacing;
  final double radius;

  const DotGridBackground({
    required this.dotColor,
    super.key,
    this.opacity = 0.06,
    this.spacing = 22,
    this.radius = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DotGridPainter(
          dotColor: dotColor,
          opacity: opacity,
          spacing: spacing,
          radius: radius,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double opacity;
  final double spacing;
  final double radius;

  _DotGridPainter({
    required this.dotColor,
    required this.opacity,
    required this.spacing,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor.withValues(alpha: opacity);
    final xCount = (size.width / spacing).ceil();
    final yCount = (size.height / spacing).ceil();

    // Slight jitter to avoid the grid looking too "engineered".
    final rng = Random(7);

    for (int y = 0; y <= yCount; y++) {
      for (int x = 0; x <= xCount; x++) {
        final dx = x * spacing + (rng.nextDouble() - 0.5) * 1.4;
        final dy = y * spacing + (rng.nextDouble() - 0.5) * 1.4;
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.opacity != opacity ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
