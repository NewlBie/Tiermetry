// lib/features/arena/presentation/widgets/arena_card.dart
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_image.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

import '../../domain/entities/arena_entity.dart';
import '../screens/arena_details_screen.dart';

class ArenaCard extends StatelessWidget {
  static const double _chipHeight = 23;
  static const double _chipWidth = 68;
  static const EdgeInsets _chipPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double _chipFontSize = 9;
  static const _closedArenaGrayscale = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  final ArenaEntity arena;
  final bool isFeatured;

  const ArenaCard({required this.arena, this.isFeatured = false, super.key});

  @override
  Widget build(BuildContext context) {
    return _PremiumTapWrapper(
      onTap: () => _navigateToDetails(context),
      child: Opacity(
        // Keep closed arenas discoverable and tappable, but make their state
        // immediately distinguishable in a busy discovery list.
        opacity: arena.isOpenNow ? 1.0 : 0.58,
        child: RepaintBoundary(
          child:
              isFeatured ? _buildFeaturedLayout() : _buildNormalLayout(context),
        ),
      ),
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    final imageSize = (MediaQuery.of(context).size.width * 0.36).clamp(
      120.0,
      160.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TiermetrySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageLeft(imageSize),
          Expanded(child: _buildDetailsRight()),
        ],
      ),
    );
  }

  Widget _buildFeaturedLayout() {
    return AppSurface(
      borderRadius: 20,
      shadows: TiermetryShadows.card,
      color: const Color(0xFF111216),
      child: Column(
        children: [
          _buildFeaturedImageHeader(),
          Expanded(child: _buildFeaturedDetailsFooter()),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, _) => ArenaDetailsScreen(arena: arena),
        transitionsBuilder:
            (context, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ==========================================
  // NORMAL LAYOUT (Horizontal)
  // ==========================================

  Widget _buildImageLeft(double size) {
    return SizedBox(
      width: size,
      height: size, // Force square image to prevent layout collapse
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TiermetryRadii.lg),
        child: _buildArenaMedia(
          Hero(
            tag: 'arena_${arena.id}',
            child: AppImage(
              imagePath: arena.image,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsRight() {
    final tags = arena.tags.isEmpty ? ['Gaming'] : arena.tags.take(4).toList();
    final roundedRating = arena.rating.round().clamp(0, 5);
    final ratingLabel =
        arena.reviewCount > 0
            ? '$roundedRating · ${arena.reviewCount}'
            : '$roundedRating';
    final priceLabel =
        arena.priceTier > 0
            ? List.filled(arena.priceTier.clamp(1, 4).toInt(), '₹').join()
            : 'Rates';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 190;
        final titleFontSize = compact ? 14.0 : 16.0;
        final metricFontSize = compact ? 10.0 : 11.0;
        final metricIconSize = compact ? 12.0 : 14.0;
        final metricGap = compact ? 4.0 : TiermetrySpacing.sm;

        return Padding(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.md,
            top: 12,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Location
              Text(
                (arena.name).toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.titleSmall(
                  color: TiermetryColors.white,
                  fontSize: titleFontSize,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                arena.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.caption(
                  color: TiermetryColors.white.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TiermetrySpacing.sm),

              // Tags
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    tags
                        .take(3)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TiermetrySpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TiermetryColors.surfaceElement,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TiermetryTypography.label(
                                color: TiermetryColors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),

              const SizedBox(height: TiermetrySpacing.md),

              // Equal-width metric cells keep distance, availability, and rating
              // visually balanced even when one value is longer than the others.
              Row(
                children: [
                  Expanded(
                    child: _buildNormalStatColumn(
                      arena.isOpenNow ? arena.distanceLabel : 'Closed',
                      arena.isOpenNow
                          ? AmazingIconFilled.location
                          : AmazingIconFilled.clock,
                      fontSize: metricFontSize,
                      iconSize: metricIconSize,
                      color:
                          arena.isOpenNow
                              ? TiermetryColors.accentNeonGreen
                              : const Color(0xFFFF453A),
                    ),
                  ),
                  _buildMetricDivider(metricGap),
                  Expanded(
                    child: _buildNormalStatColumn(
                      ratingLabel,
                      AmazingIconFilled.star,
                      fontSize: metricFontSize,
                      iconSize: metricIconSize,
                    ),
                  ),
                  _buildMetricDivider(metricGap),
                  Expanded(
                    child: _buildNormalStatColumn(
                      priceLabel,
                      Icons.currency_rupee_rounded,
                      fontSize: metricFontSize,
                      iconSize: metricIconSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalStatColumn(
    String value,
    IconData icon, {
    required double fontSize,
    required double iconSize,
    Color color = TiermetryColors.accentNeonGreen,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TiermetryTypography.caption(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(double gap) {
    return SizedBox(
      width: gap,
      child: Center(
        child: Container(
          width: 1,
          height: 16,
          color: TiermetryColors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildArenaMedia(Widget child) {
    if (arena.isOpenNow) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_closedArenaGrayscale),
      child: child,
    );
  }

  // ==========================================
  // FEATURED LAYOUT (Vertical, Premium)
  // ==========================================

  Widget _buildFeaturedImageHeader() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildArenaMedia(
            LayoutBuilder(
              builder:
                  (context, constraints) => AppImage(
                    imagePath: arena.image,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.cover,
                  ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.18, 1.0],
                  colors: [
                    TiermetryColors.black.withValues(alpha: 0.22),
                    TiermetryColors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDetailsFooter() {
    final tags = _featuredTags;
    final address =
        arena.shortAddress.isNotEmpty ? arena.shortAddress : arena.location;
    final description =
        arena.capacity > 0
            ? '${arena.activityLabel} for up to ${arena.capacity} players at a time.'
            : '${arena.activityLabel} experiences near you.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arena.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.titleSmall(
              color: Colors.white,
              fontSize: 18,
              height: 1.04,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$address · ${arena.hours}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.caption(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.bodySmall(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildRatingChip(),
              ...tags.take(2).map(_buildExperienceChip),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _buildFooterMetric(
                icon:
                    arena.isOpenNow
                        ? Icons.location_on_outlined
                        : Icons.schedule_outlined,
                value: arena.isOpenNow ? arena.distanceLabel : 'Closed',
                color: arena.isOpenNow ? null : const Color(0xFFFF6B5F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _experienceLabel =>
      arena.tags.isNotEmpty ? arena.tags.first : arena.activityLabel;

  List<String> get _featuredTags {
    final tags = <String>[_experienceLabel];
    for (final tag in arena.tags) {
      if (!tags.any(
        (existing) => existing.toLowerCase() == tag.toLowerCase(),
      )) {
        tags.add(tag);
      }
      if (tags.length == 3) break;
    }
    return tags;
  }

  Widget _buildFooterMetric({
    required IconData icon,
    required String value,
    Color? color,
  }) {
    final metricColor = color ?? Colors.white.withValues(alpha: 0.78);
    return Container(
      constraints: const BoxConstraints(maxWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color:
            color == null
                ? TiermetryColors.surfaceElement
                : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: metricColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.caption(
                color: metricColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceChip(String tag) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          tag,
          maxLines: 1,
          style: TiermetryTypography.label(
            color: TiermetryColors.white.withValues(alpha: 0.84),
            fontSize: _chipFontSize,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip() {
    return SizedBox(
      width: _chipWidth,
      height: _chipHeight,
      child: Container(
        padding: _chipPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TiermetryColors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AmazingIconFilled.star, size: 11, color: Colors.black),
              const SizedBox(width: 2),
              Text(
                arena.rating.round().clamp(0, 5).toString(),
                style: TiermetryTypography.label(
                  color: Colors.black,
                  fontSize: _chipFontSize,
                  letterSpacing: 0.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '(${arena.reviewCount})',
                style: TiermetryTypography.label(
                  color: Colors.black.withValues(alpha: 0.62),
                  fontSize: 8.5,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTapWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PremiumTapWrapper({required this.child, required this.onTap});

  @override
  State<_PremiumTapWrapper> createState() => _PremiumTapWrapperState();
}

class _PremiumTapWrapperState extends State<_PremiumTapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: FadeTransition(opacity: _opacity, child: widget.child),
      ),
    );
  }
}
