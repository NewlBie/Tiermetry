import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
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

  Widget _buildActivityIcon(String iconKey, double size, Color color) {
    switch (iconKey) {
      case 'bowling':
      case 'football':
      case 'gaming':
        return AmazingIconBulk.game(size: size, color: color);
      case 'gokart':
        return AmazingIconBulk.discover(size: size, color: color);
      default:
        return AmazingIconBulk.category(size: size, color: color);
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
      child: ListView.builder(
        addRepaintBoundaries: false,
        cacheExtent: 160,
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: TiermetrySpacing.listInset,
          right: TiermetrySpacing.listInset,
          top: TiermetrySpacing.xs,
          bottom: 0,
        ),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: TiermetrySpacing.cardGap),
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
        addRepaintBoundaries: false,
        cacheExtent: 160,
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: TiermetrySpacing.listInset,
          right: TiermetrySpacing.listInset,
          top: TiermetrySpacing.xs,
          bottom: 0,
        ),
        itemCount: 4,
        itemBuilder:
            (_, __) => Padding(
              padding: const EdgeInsets.only(right: TiermetrySpacing.cardGap),
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
                isSelected: isSelected,
                activeColor: activityColor,
                inactiveColor: activityColor,
                child: _buildActivityIcon(activity.icon, 26.0, Colors.black),
              ),
              const SizedBox(height: TiermetrySpacing.md),
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
      ),
    );
  }
}

class MaterialMorphingShape extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: activeColor,
        // Preserve the organic silhouette without a continuously repainting
        // controller. Selection only changes the shape on interaction.
        borderRadius:
            isSelected
                ? BorderRadius.circular(29)
                : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(29),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(24),
                ),
      ),
      child: child,
    );
  }
}
