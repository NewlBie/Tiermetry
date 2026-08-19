import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------------
/// TIERMETRY TYPOGRAPHY - Universal Design Tokens
/// ---------------------------------------------------------------------------
/// Central source for all text styles in the app.
/// Established on Geist for a modern, sleek aesthetic.
/// ---------------------------------------------------------------------------
class TiermetryTypography {
  TiermetryTypography._();

  static TextTheme textTheme(TextTheme base) {
    final geist = GoogleFonts.geistTextTheme(base);
    return geist.copyWith(
      bodyMedium: geist.bodyMedium?.copyWith(height: 1.35),
      bodySmall: geist.bodySmall?.copyWith(height: 1.3),
      labelLarge: geist.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      labelMedium: geist.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Large, high-impact display text (Greetings, major headers)
  static TextStyle display({
    required Color color,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w900,
    double letterSpacing = -0.6,
    double height = 1.05,
  }) {
    return GoogleFonts.geist(
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Standard section headers
  static TextStyle title({
    required Color color,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w900,
    double letterSpacing = -0.2,
    double? height,
  }) {
    return GoogleFonts.geist(
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Smaller card titles or sub-headers
  static TextStyle titleSmall({
    required Color color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w900,
    double? height,
  }) {
    return GoogleFonts.geist(
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }

  /// Labels for badges, tags, and categories (Urbanist, Uppercase)
  static TextStyle label({
    required Color color,
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 0.8,
  }) {
    return GoogleFonts.geist(
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
  }

  /// Secondary body text (Inter-based, used for technical labels/stats)
  static TextStyle bodySmall({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// Standard body text / captions
  static TextStyle caption({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0.4,
    double? height,
  }) {
    return GoogleFonts.geist(
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Interactive elements like buttons
  static TextStyle action({
    required Color color,
    double fontSize = 13.5,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 0.4,
  }) {
    return TextStyle(
      fontFamily: 'Geist',
      color: color,
      fontSize: fontSize,
      fontVariations: [
        FontVariation('wght', (fontWeight.value).toDouble()),
      ],
      letterSpacing: letterSpacing,
    );
  }
}
