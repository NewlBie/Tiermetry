import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:silky_scroll/silky_scroll.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/home/domain/entities/trending_activity.dart';

class TrendingActivitiesSection extends StatefulWidget {
  final List<TrendingActivity> activities;
  final bool isLoading;
  final void Function(String)? onActivitySelected;

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
        return CupertinoIcons.sportscourt;
      case 'gokart':
        return CupertinoIcons.car_detailed;
      case 'football':
        return CupertinoIcons.sportscourt_fill;
      case 'gaming':
        return CupertinoIcons.game_controller;
      default:
        return CupertinoIcons.star;
    }
  }

  Color _getActivityColor(String iconKey) {
    switch (iconKey) {
      case 'bowling':
        return Colors.deepPurpleAccent.shade200;
      case 'gokart':
        return Colors.redAccent.shade200;
      case 'football':
        return TiermetryColors.accentNeonGreen;
      case 'gaming':
        return Colors.blueAccent.shade200;
      default:
        return Colors.orangeAccent.shade200;
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
      child: SilkyListView.builder(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
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
      child: SilkyListView.builder(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: TiermetrySpacing.listInset,
          right: TiermetrySpacing.listInset,
          top: 4,
          bottom: 0,
        ),
        itemCount: 4,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.only(right: TiermetrySpacing.lg),
              child: AppSurface(
                width: 100,
                borderRadius: TiermetryRadii.md,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.transparent),
                shadows: const [],
                child: const SizedBox.shrink(),
              ),
            ),
      ),
    );
  }

  Widget _buildCapsuleCard(TrendingActivity activity, int index) {
    final isSelected = _activities[index].isSelected;
    final activityColor = _getActivityColor(activity.icon);

    return GestureDetector(
      onTap: () => _toggleActivity(index),
      child: AppSurface(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 105,
            borderRadius: TiermetryRadii.md,
            border: const Border(),
            shadows: const [],
            color: Colors.white.withValues(alpha: 0.05),
            child: RepaintBoundary(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  MaterialMorphingShape(
                    isSelected: isSelected, // true by default visually
                    activeColor: activityColor,
                    inactiveColor: activityColor, // Always colored
                    child: Icon(
                      _getActivityIcon(activity.icon),
                      color: Colors.black,
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
  final Color activeColor;
  final Color inactiveColor;

  const MaterialMorphingShape({
    required this.child,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
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
    const leaf = BorderRadius.only(
      topLeft: Radius.circular(29),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(29),
    );
    // Off-center Organic Blob
    const blob = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(29),
      bottomLeft: Radius.circular(26),
      bottomRight: Radius.circular(12),
    );
    // Classic Teardrop
    const tearDrop = BorderRadius.only(
      topLeft: Radius.circular(29),
      topRight: Radius.circular(29),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(29),
    );
    // Inverted Diagonal Leaf
    const invLeaf = BorderRadius.only(
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
                color: Color.lerp(widget.inactiveColor, widget.activeColor, selectValue),
                borderRadius: finalRadius,
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}
