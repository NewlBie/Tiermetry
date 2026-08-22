// lib/features/arena/presentation/widgets/arena_card.dart
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/cupertino.dart';
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
  final ArenaEntity arena;
  final bool isFeatured;

  const ArenaCard({required this.arena, this.isFeatured = false, super.key});

  @override
  Widget build(BuildContext context) {
    return _PremiumTapWrapper(
      onTap: () => _navigateToDetails(context),
      child: RepaintBoundary(
        child: isFeatured ? _buildFeaturedLayout() : _buildNormalLayout(context),
      ),
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    final imageSize = (MediaQuery.of(context).size.width * 0.36).clamp(120.0, 160.0);
    
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
      borderRadius: TiermetryRadii.xl,
      shadows: TiermetryShadows.card,
      gradient: TiermetryColors.brandGradient,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildFeaturedImageHeader(), _buildFeaturedDetailsFooter()],
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
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
        child: Hero(
          tag: 'arena_${arena.id}',
          child: AppImage(
            imagePath: arena.image,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsRight() {
    final tags = ['PS5', 'XBOX', 'PC', 'Nintendo'];
    
    return Padding(
      padding: const EdgeInsets.only(left: TiermetrySpacing.md, top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Location
          Text(
            (arena.name).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.titleSmall(
              color: TiermetryColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            arena.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.caption(
              color: TiermetryColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.sm),
          
          // Tags
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags.take(3).map((tag) => Container(
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
            )).toList(),
          ),
          
          const SizedBox(height: TiermetrySpacing.md),
          
          // Metrics (Left organized, icons instead of text)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildNormalStatColumn('${arena.distance}km', AmazingIconFilled.location),
              const SizedBox(width: TiermetrySpacing.md),
              _buildNormalStatColumn('${arena.screenCount}', AmazingIconFilled.monitor),
              const SizedBox(width: TiermetrySpacing.md),
              _buildNormalStatColumn('${arena.rating}', AmazingIconFilled.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNormalStatColumn(String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: TiermetryColors.accentNeonGreen),
        const SizedBox(width: 4),
        Text(
          value,
          style: TiermetryTypography.caption(
            color: TiermetryColors.white,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FEATURED LAYOUT (Vertical, Premium)
  // ==========================================

  Widget _buildFeaturedImageHeader() {
    return AspectRatio(
      aspectRatio: 16 / 9, // 16:9 aspect ratio
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'arena_featured_${arena.id}',
            child: AppImage(imagePath: arena.image),
          ),
          // Gradient Fade
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0], // Fade starts lower
                  colors: [
                    Colors.transparent,
                    TiermetryColors.black.withValues(alpha: 0.9), // Deep shadow for text readability
                  ],
                ),
              ),
            ),
          ),
          // Text Details (Left)
          Positioned(
            left: TiermetrySpacing.lg,
            bottom: TiermetrySpacing.lg,
            right: TiermetrySpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text((arena.name).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.titleSmall(
                    color: TiermetryColors.white,
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.xs),
                Text(
                  arena.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.caption(
                    color: TiermetryColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDetailsFooter() {
    final tags = ['PS5', 'XBOX', 'PC', 'Nintendo'];

    return Padding(
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags spanning entire width
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: tags.take(3).map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TiermetrySpacing.sm,
                vertical: TiermetrySpacing.xs,
              ),
              decoration: BoxDecoration(
                color: TiermetryColors.surfaceElement,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                tag,
                style: TiermetryTypography.label(
                  color: TiermetryColors.white,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: TiermetrySpacing.md),
          // Divider
          Container(
            height: 1,
            color: TiermetryColors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: TiermetrySpacing.md),
          // Stats and Map Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeaturedStatColumn('${arena.distance}km', 'Distance'),
                    _buildFeaturedStatColumn('${arena.screenCount}', 'Screens'),
                    _buildFeaturedStatColumn('${arena.rating}', 'Rating'),
                  ],
                ),
              ),
              const SizedBox(width: TiermetrySpacing.lg),
              // Map Icon Box
              Container(
                width: 70,
                height: 60,
                decoration: BoxDecoration(
                  color: TiermetryColors.surfaceElement,
                  borderRadius: BorderRadius.circular(TiermetryRadii.md),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.map,
                    color: TiermetryColors.textPrimary.withValues(alpha: 0.6),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TiermetryTypography.caption(
            color: TiermetryColors.white,
          ),
        ),
        const SizedBox(height: TiermetrySpacing.xs),
        Text(
          label,
          style: TiermetryTypography.label(
            color: TiermetryColors.textMuted,
          ),
        ),
      ],
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
