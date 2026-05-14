import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';

class TiermetryTheme {
  TiermetryTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: TiermetryColors.primary,
      secondary: TiermetryColors.accentLavender,
      tertiary: TiermetryColors.accentNeonGreen,
      surface: TiermetryColors.surface,
      onSurface: Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TiermetryColors.background,
      textTheme: TiermetryTypography.textTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

