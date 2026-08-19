import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/typography.dart';

/// A small semantic badge or pill used for labels and status indicators.
class AppPill extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;

  const AppPill({required this.text, this.color, this.textColor, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.pill),
      ),
      child: Text(
        text,
        style: TiermetryTypography.label(
          color: textColor ?? Colors.white.withValues(alpha: 0.74),
          fontSize: 10.5,
        ),
      ),
    );
  }
}
