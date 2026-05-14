import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TiermetryTypography {
  TiermetryTypography._();

  // Base: clean + premium for body/labels.
  static TextTheme textTheme(TextTheme base) {
    final urbanist = GoogleFonts.urbanistTextTheme(base);
    return urbanist.copyWith(
      bodyMedium: urbanist.bodyMedium?.copyWith(height: 1.35),
      bodySmall: urbanist.bodySmall?.copyWith(height: 1.3),
      labelLarge: urbanist.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      labelMedium: urbanist.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  // Display: playful + artsy, used sparingly.
  static TextStyle display({
    required Color color,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = -0.6,
    double height = 1.05,
  }) {
    return GoogleFonts.bricolageGrotesque(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle title({
    required Color color,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.bricolageGrotesque(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle caption({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.4,
  }) {
    return GoogleFonts.urbanist(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}

