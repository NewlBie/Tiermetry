import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// TIERMETRY SPACING - Universal Design Tokens
/// ---------------------------------------------------------------------------
/// A single source of truth for every spacing value in the app.
/// Designed on a 4-pt grid system for pixel-perfect visual rhythm.
///
/// Usage:
///   TiermetrySpacing.screenPadding   -> horizontal page margins
///   TiermetrySpacing.sectionGap      -> vertical space between sections
///   TiermetrySpacing.headerToContent -> space between a title and its content
///   TiermetrySpacing.cardGap         -> space between cards in a list
///   TiermetrySpacing.pagePadding     -> symmetric EdgeInsets for page margins
/// ---------------------------------------------------------------------------

class TiermetrySpacing {
  TiermetrySpacing._(); // Prevents instantiation

  // --- 4-pt Grid Base -------------------------------------------------------

  /// The atomic unit. Every value below is a multiple of this.
  static const double unit = 4.0;

  // --- Micro Spacing (within components) ------------------------------------

  /// 4px - tightest inner gap (icon-to-text, dot rows)
  static const double xs = unit; // 4

  /// 8px - compact inner gap (between related inline elements)
  static const double sm = unit * 2; // 8

  /// 12px - standard inner gap (header to content, label to field)
  static const double md = unit * 3; // 12

  // --- Structural Spacing (between components & sections) -------------------

  /// 16px - tight structural gap (between stacked cards)
  static const double lg = unit * 4; // 16

  /// 20px - standard screen edge inset / horizontal page margins
  static const double screenPadding = unit * 5; // 20

  /// 24px - breathable gap between major surface groups
  static const double xl = unit * 6; // 24

  /// 32px - the universal gap between top-level page sections
  static const double sectionGap = unit * 8; // 32

  // --- Semantic Aliases -----------------------------------------------------
  // Use these for clarity at the call site.

  /// 12px - space between a section title and its scrollable content
  static const double headerToContent = md;

  /// 12px - space between cards laid out in a grid row
  static const double gridGap = md;

  /// 16px - space between cards in a horizontal ListView
  static const double cardGap = lg;

  /// 20px - horizontal padding for full-width scrolling lists
  static const double listInset = screenPadding;

  // --- Pre-built EdgeInsets (convenience) -----------------------------------

  /// Symmetric horizontal padding for the page body (20px each side)
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: screenPadding);

  /// Padding for horizontally-scrolling ListViews (20px left & right)
  static const EdgeInsets listPadding =
      EdgeInsets.symmetric(horizontal: listInset);

  // --- Bottom safe area / scroll overrun ------------------------------------

  /// Large bottom pad so the last section clears a floating nav bar
  static const double bottomSafeArea = 140.0;
}
