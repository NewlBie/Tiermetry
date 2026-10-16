import 'package:flutter/material.dart';

class TicketClipper extends CustomClipper<Path> {
  final double borderRadius;
  final double punchRadius;
  final int punchCount;
  final double edgeInset;

  TicketClipper({
    this.borderRadius = 16.0,
    this.punchRadius = 6.0,
    this.punchCount = 6,
    this.edgeInset = 0.0,
  });

  @override
  Path getClip(Size size) {
    final Path path =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Radius.circular(borderRadius),
            ),
          );

    // If there is an edgeInset, punch holes along that line (perforation)
    // If edgeInset is 0, punch holes on the absolute right edge (half circles)
    final double punchX = size.width - edgeInset;

    // Also punch a top and bottom notch at the perforation line
    if (edgeInset > 0) {
      path
        ..addOval(
          Rect.fromCircle(center: Offset(punchX, 0), radius: punchRadius),
        )
        ..addOval(
          Rect.fromCircle(
            center: Offset(punchX, size.height),
            radius: punchRadius,
          ),
        );
    }

    return path;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.punchRadius != punchRadius ||
        oldClipper.punchCount != punchCount ||
        oldClipper.edgeInset != edgeInset;
  }
}
