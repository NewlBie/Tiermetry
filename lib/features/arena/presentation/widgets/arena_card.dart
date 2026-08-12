// lib/features/arena/presentation/widgets/arena_card.dart
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../domain/entities/arena_entity.dart';
import '../screens/arena_details_screen.dart';

class ArenaCard extends StatelessWidget {
  final ArenaEntity arena;

  const ArenaCard({required this.arena, super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _PremiumTapWrapper(
        onTap: () => _navigateToDetails(context),
        child: AppSurface(
          borderRadius: TiermetryRadii.xl,
          shadows: TiermetryShadows.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildImageHeader(), _buildDetailsFooter()],
          ),
        ),
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

  Widget _buildImageHeader() {
    return AspectRatio(
      aspectRatio: 16 / 9, // 16:9 aspect ratio
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'arena_${arena.id}',
            child: Image.asset(arena.image, fit: BoxFit.cover),
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
                    TiermetryColors.black.withValues(
                      alpha: 0.9,
                    ), // Deep shadow for text readability
                  ],
                ),
              ),
            ),
          ),
          // Text Details (Left)
          Positioned(
            left: 20,
            bottom: 20,
            right: 150, // Space for button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  arena.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.titleSmall(
                    color: TiermetryColors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arena.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.bodySmall(
                    color: TiermetryColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // "Directions" Button (Right)
          Positioned(
            right: 20,
            bottom: 20,
            child: AppSurface(
              borderRadius: TiermetryRadii.md,
              color: TiermetryColors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.transparent),
              shadows: const [],
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: TiermetryBlur.filter(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    'Directions',
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsFooter() {
    // Mock tags - can be replaced with arena.tags when available
    final tags = ['PS5', 'XBOX', 'PC', 'Nintendo'];

    return Padding(
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      child: SizedBox(
        height: 70, // Match the map container height
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side - tags and stats in a column, matching the height of the map icon
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags section
                  Wrap(
                    spacing: 5,
                    runSpacing: 0,
                    children:
                        tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TiermetryColors.surfaceElement,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  tag,
                                  style: TiermetryTypography.bodySmall(
                                    color: TiermetryColors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  // Divider
                  Container(
                    height: 1,
                    color: TiermetryColors.white.withValues(alpha: 0.1),
                  ),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('${arena.distance}km', 'Distance'),
                      _buildStatColumn('${arena.screenCount}', 'Screens'),
                      _buildStatColumn('${arena.rating}', 'Rating'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: TiermetrySpacing.lg),
            // Right side map shape
            Container(
              width: 70,
              height: 60,
              decoration: BoxDecoration(
                color: TiermetryColors.surfaceElement,
                borderRadius: BorderRadius.circular(TiermetryRadii.md),
              ),
              child: Center(
                child: Icon(
                  LineIcons.map,
                  color: TiermetryColors.textPrimary.withValues(alpha: 0.6),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TiermetryTypography.caption(
            color: TiermetryColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TiermetryTypography.bodySmall(
            color: TiermetryColors.textMuted,
            fontSize: 10,
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
