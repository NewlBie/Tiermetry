// lib/theme/app_typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'font_sizes.dart';
import 'font_weights.dart';
import 'colors.dart'; // <- your existing TiermetryColors

class AppTypography {
  static final TextStyle xs = GoogleFonts.inter(
    fontSize: FontSizes.xs,
    fontWeight: FontWeights.medium,
    color: TiermetryColors.textSecondary,
  );

  static final TextStyle sm = GoogleFonts.inter(
    fontSize: FontSizes.sm,
    fontWeight: FontWeights.regular,
    color: TiermetryColors.textSecondary,
  );

  static final TextStyle base = GoogleFonts.inter(
    fontSize: FontSizes.base,
    fontWeight: FontWeights.regular,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle md = GoogleFonts.inter(
    fontSize: FontSizes.md,
    fontWeight: FontWeights.medium,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle lg = GoogleFonts.plusJakartaSans(
    fontSize: FontSizes.lg,
    fontWeight: FontWeights.semiBold,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle xl = GoogleFonts.plusJakartaSans(
    fontSize: FontSizes.xl,
    fontWeight: FontWeights.bold,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle xxl = GoogleFonts.plusJakartaSans(
    fontSize: FontSizes.xxl,
    fontWeight: FontWeights.bold,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle hero = GoogleFonts.plusJakartaSans(
    fontSize: FontSizes.hero,
    fontWeight: FontWeights.bold,
    color: TiermetryColors.textPrimary,
  );

  static final TextStyle accent = GoogleFonts.inter(
    fontSize: FontSizes.sm,
    fontWeight: FontWeights.medium,
    color: Colors.purpleAccent,
  );

  static final TextStyle subtitle = GoogleFonts.inter(
    fontSize: FontSizes.sm,
    fontWeight: FontWeights.regular,
    color: TiermetryColors.textSecondary,
  );

  static final TextStyle stat = GoogleFonts.plusJakartaSans(
    fontSize: FontSizes.lg,
    fontWeight: FontWeights.bold,
    color: TiermetryColors.textPrimary,
  );
}
