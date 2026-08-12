import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/shadows.dart';

/// A reusable decorative container representing the app's visual language.
/// 
/// It encapsulates the surface color, subtle border, radius, and shadow.
/// Content is automatically clipped to the border radius.
class AppSurface extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadows;
  final Color? color;
  final Border? border;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  
  /// If provided, changes to the surface properties will be animated.
  final Duration? duration;
  final Curve curve;

  const AppSurface({
    required this.child,
    this.borderRadius,
    this.padding,
    this.shadows,
    this.color,
    this.border,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.duration,
    this.curve = Curves.linear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? TiermetryRadii.md;
    final decoration = BoxDecoration(
      color: color ?? TiermetryColors.surface,
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: border ??
          Border.all(
            color: TiermetryColors.cardBorder,
            width: 1,
          ),
      boxShadow: shadows ?? TiermetryShadows.card,
    );

    final container = duration != null
        ? AnimatedContainer(
            duration: duration!,
            curve: curve,
            width: width,
            height: height,
            decoration: decoration,
            child: _buildClippedContent(effectiveRadius),
          )
        : Container(
            width: width,
            height: height,
            decoration: decoration,
            child: _buildClippedContent(effectiveRadius),
          );

    return container;
  }

  Widget _buildClippedContent(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
