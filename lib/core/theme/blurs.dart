import 'dart:ui';

/// ---------------------------------------------------------------------------
/// TIERMETRY BLURS - Universal Design Tokens
/// ---------------------------------------------------------------------------
class TiermetryBlur {
  TiermetryBlur._();

  /// Subtle background blur for glass effects
  static const double sm = 10.0;

  /// Standard section blur
  static const double md = 20.0;

  /// Heavy backdrop blur for ambient blobs
  static const double lg = 34.0;

  static ImageFilter filter(double sigma) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
}
