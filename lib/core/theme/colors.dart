import 'package:flutter/material.dart';

class TiermetryColors {
  // Brand Violets
  static const primary = Color(0xFF9733FF);
  static const violet100 = Color(0xFF2420A9);
  static const violet200 = Color(0xFF2E26BB);
  static const violet300 = Color(0xFF170C33);

  // Gradient
  static const gradientStart = Color(0xFF9733FF);
  static const gradientEnd = Color(0xFF00C6FF); // cyan-blue

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const gray100 = Color(0xFF999999);
  static const gray200 = Color(0xFF333333);
  static const black = Color(0xFF000000);

  // Alerts
  static const positive = Color(0xFF7DFCC3);
  static const negative = Color(0xFFF58EB9);

  // Text (reusing from neutral)
  static const textPrimary = white;
  static const textSecondary = gray100;

  // Surface System (Requested UI Overhaul)
  static const background = Color(0xFF080808);
  static const surface = Color(0xFF151515);
  static const surfaceElement = Color(0xFF212121);
  static const surfaceUnderlay = Color(0xFF101010); // for deeper elements like map backings

  // Feature Accents
  static const accentNeonGreen = Color(0xFFB6FF00);
  static const accentLavender = Color(0xFF8B7CFF);
  static const accentCyan = Color(0xFF4FD1C5);
  static const accentAppleBlue = Color(0xFF0A84FF);
  static const accentPink = Color(0xFFED64F5);

  // Status/Interactive
  static const activeIcon = white;
  static const inactiveIcon = gray100;
  static const borderSubtle = Color(0xFF212121); // matches surface element
  static const textMuted = Color(0xFF8E8E93); // subtle secondary text

  // Semantic Surface Tokens
  static Color get cardBorder => white.withValues(alpha: 0.06);
  static Color get cardBorderEmphasis => white.withValues(alpha: 0.08);
  static Color get shadowColor => black.withValues(alpha: 0.28);
  static Color get shadowColorEmphasis => black.withValues(alpha: 0.35);

  // Glow
  static const glow = Color(0xFFB388FF); // For softness if needed
}
