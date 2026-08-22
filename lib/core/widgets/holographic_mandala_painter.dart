import 'dart:math';
import 'package:flutter/material.dart';

class HolographicMandalaPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final int petalCount;

  HolographicMandalaPainter({
    this.primaryColor = const Color(0xFF00FF87),
    this.secondaryColor = const Color(0xFF60EFFF),
    this.petalCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.2;
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.overlay;

    for (int i = 0; i < petalCount; i++) {
      final angle = (2 * pi / petalCount) * i;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle);
      
      // Draw petal
      final rect = Rect.fromCenter(
        center: Offset(0, radius / 1.5),
        width: radius * 0.9,
        height: radius * 1.5,
      );
      
      // Gradient for each petal to make it holographic
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.5), 
          secondaryColor.withValues(alpha: 0.1)
        ],
      );
      paint.shader = gradient.createShader(rect);
      
      canvas
        ..drawOval(rect, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant HolographicMandalaPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor ||
           oldDelegate.petalCount != petalCount;
  }
}
