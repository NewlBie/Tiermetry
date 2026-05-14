import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/features/home/domain/entities/trending_activity.dart';

class TrendingActivitiesSection extends StatefulWidget {
  final List<TrendingActivity> activities;
  final bool isLoading;
  final Function(String)? onActivitySelected;

  const TrendingActivitiesSection({
    required this.activities,
    this.isLoading = false,
    this.onActivitySelected,
    super.key,
  });

  @override
  State<TrendingActivitiesSection> createState() =>
      _TrendingActivitiesSectionState();
}

class _TrendingActivitiesSectionState extends State<TrendingActivitiesSection> {
  late List<TrendingActivity> _activities;

  @override
  void initState() {
    super.initState();
    _activities = widget.activities;
  }

  @override
  void didUpdateWidget(TrendingActivitiesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activities = widget.activities;
  }

  void _toggleActivity(int index) {
    setState(() {
      _activities[index] = _activities[index].copyWith(
        isSelected: !_activities[index].isSelected,
      );
    });
    if (widget.onActivitySelected != null) {
      widget.onActivitySelected!(_activities[index].id);
    }
  }

  IconData _getActivityIcon(String iconKey) {
    switch (iconKey) {
      case 'bowling':
        return LineIcons.bowlingBall;
      case 'gokart':
        return LineIcons.car;
      case 'football':
        return LineIcons.futbol;
      case 'gaming':
        return LineIcons.gamepad;
      default:
        return LineIcons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (_activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: TiermetrySpacing.listInset,
          right: TiermetrySpacing.listInset,
          top: 4,
          bottom: 0,
        ),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCapsuleCard(_activities[index], index),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: TiermetrySpacing.listInset,
          right: TiermetrySpacing.listInset,
          top: 4,
          bottom: 0,
        ),
        itemCount: 4,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.only(right: TiermetrySpacing.lg),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCapsuleCard(TrendingActivity activity, int index) {
    final isSelected = _activities[index].isSelected;
    final primaryColor = TiermetryColors.accentNeonGreen;

    return GestureDetector(
      onTap: () => _toggleActivity(index),
      child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 105,
            decoration: BoxDecoration(
              color: TiermetryColors.surface,
              borderRadius: BorderRadius.circular(24),
              border:
                  isSelected
                      ? Border.all(color: primaryColor, width: 1.5)
                      : Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                MaterialMorphingShape(
                  isSelected: isSelected,
                  color: primaryColor,
                  child: Icon(
                    _getActivityIcon(activity.icon),
                    color: Colors.black.withAlpha(220),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                // Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Text(
                    activity.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
          .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}

class MaterialMorphingShape extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color color;

  const MaterialMorphingShape({
    required this.child,
    required this.isSelected,
    required this.color,
    super.key,
  });

  @override
  State<MaterialMorphingShape> createState() => _MaterialMorphingShapeState();
}

class _MaterialMorphingShapeState extends State<MaterialMorphingShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<BorderRadius?> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Ultra-smooth slow sequence
    )..repeat();

    // The iconic distinct Google Material morphing shapes
    final squircle = BorderRadius.circular(20);
    // Diagonal Leaf
    final leaf = const BorderRadius.only(
      topLeft: Radius.circular(29),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(29),
    );
    // Off-center Organic Blob
    final blob = const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(29),
      bottomLeft: Radius.circular(26),
      bottomRight: Radius.circular(12),
    );
    // Classic Teardrop
    final tearDrop = const BorderRadius.only(
      topLeft: Radius.circular(29),
      topRight: Radius.circular(29),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(29),
    );
    // Inverted Diagonal Leaf
    final invLeaf = const BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(29),
      bottomLeft: Radius.circular(29),
      bottomRight: Radius.circular(10),
    );

    _morphAnimation = TweenSequence<BorderRadius?>([
      TweenSequenceItem(
        tween: BorderRadiusTween(
          begin: squircle,
          end: leaf,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: BorderRadiusTween(
          begin: leaf,
          end: blob,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: BorderRadiusTween(
          begin: blob,
          end: tearDrop,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: BorderRadiusTween(
          begin: tearDrop,
          end: invLeaf,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: BorderRadiusTween(
          begin: invLeaf,
          end: squircle,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
    ]).animate(_morphController);
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: widget.isSelected ? 1.0 : 0.0),
      builder: (context, selectValue, child) {
        return AnimatedBuilder(
          animation: _morphAnimation,
          builder: (context, _) {
            // Get the current organically morphing border radius
            final organicRadius =
                _morphAnimation.value ?? BorderRadius.circular(20);

            // Interpolate toward a perfect circle (29.0) safely when selected
            final finalRadius =
                BorderRadius.lerp(
                  organicRadius,
                  BorderRadius.circular(29),
                  selectValue,
                )!;

            return Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: finalRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.15 + (0.25 * selectValue),
                    ),
                    blurRadius: 8.0 + (8.0 * selectValue),
                    spreadRadius: 1.0 + (1.0 * selectValue),
                  ),
                ],
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}
