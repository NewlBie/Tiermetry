import 'package:flutter/material.dart';
import 'colors.dart';

/// ---------------------------------------------------------------------------
/// TIERMETRY SHADOWS - Universal Design Tokens
/// ---------------------------------------------------------------------------
/// Central source for all shadow effects in the app.
/// Following the "Deep Surface" aesthetic with soft, vertical offsets.
/// ---------------------------------------------------------------------------
class TiermetryShadows {
  TiermetryShadows._();

  /// Standard card shadow used for most tiles (Bento, grid items)
  static List<BoxShadow> get card => [
        BoxShadow(
          color: TiermetryColors.shadowColor,
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  /// More intense shadow for larger, high-emphasis cards
  static List<BoxShadow> get highEmphasis => [
        BoxShadow(
          color: TiermetryColors.shadowColorEmphasis,
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ];

  /// Specific shadow for featured skill cards
  static List<BoxShadow> get featuredSkill => [
        BoxShadow(
          color: TiermetryColors.shadowColorEmphasis,
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ];

  /// Shadow for live activity cards
  static List<BoxShadow> get liveActivity => [
        BoxShadow(
          color: TiermetryColors.shadowColorEmphasis,
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ];

  /// Shadow for search bars and similar hero elements
  static List<BoxShadow> get searchBar => [
        BoxShadow(
          color: TiermetryColors.shadowColor,
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ];

  /// Shadow for activity capsules
  static List<BoxShadow> get capsule => [
        BoxShadow(
          color: TiermetryColors.shadowColorEmphasis,
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  /// Shadow for venue/arena listing tiles
  static List<BoxShadow> get venueTile => [
        BoxShadow(
          color: TiermetryColors.shadowColor,
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  /// Shadow for upcoming event cards
  static List<BoxShadow> get upcomingEvent => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4), // Slightly darker for events
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ];
}
