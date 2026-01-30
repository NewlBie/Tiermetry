import 'dart:ui';
import 'package:flutter/material.dart';

/// A model class for the navigation bar items.
class AppleBottomNavBarItem {
  /// The icon to be displayed.
  final IconData icon;

  const AppleBottomNavBarItem({
    required this.icon,
  });
}

/// A sleek, animated bottom navigation bar with a frosted glass effect,
/// inspired by iOS.
class AppleBottomNavBar extends StatelessWidget {
  /// The list of items to display in the navigation bar.
  final List<AppleBottomNavBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// The callback that is called when an item is tapped.
  final Function(int) onTap;

  /// The background color of the navigation bar.
  ///
  /// Defaults to a semi-transparent black gradient.
  final Gradient? backgroundGradient;

  /// The color of the selected item's icon and indicator.
  final Color selectedItemColor;

  /// The color of the unselected items' icons.
  final Color unselectedItemColor;

  /// The border radius of the navigation bar.
  final BorderRadius borderRadius;

  /// The duration of the selection animation.
  final Duration animationDuration;

  /// The curve of the selection animation.
  final Curve animationCurve;

  /// The size of the icons.
  final double iconSize;

  const AppleBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.selectedItemColor = Colors.white,
    this.unselectedItemColor = Colors.white70,
    this.iconSize = 26.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.animationDuration = const Duration(milliseconds: 350),
    this.animationCurve = Curves.easeOut,
    this.backgroundGradient,
  });

  // Default gradient if none is provided.
  Gradient get _defaultGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.black.withValues(alpha: 0.45),
      Colors.black.withValues(alpha: 0.3),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: backgroundGradient ?? _defaultGradient,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              // Outer shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              // Inner highlight for glass effect
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.02),
                blurRadius: 1,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              return _buildNavItem(items[index], isSelected, index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(AppleBottomNavBarItem item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: animationDuration,
        curve: animationCurve,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(item, isSelected),
            AnimatedContainer(
              duration: animationDuration,
              curve: animationCurve,
              height: 4,
              width: isSelected ? 12 : 0,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: selectedItemColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(AppleBottomNavBarItem item, bool isSelected) {
    return Container(
      // Add a decorative shadow for the selected icon for a "glow" effect.
      decoration: isSelected
          ? BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      )
          : null,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: animationDuration,
        curve: Curves.easeOutBack,
        child: Icon(
          item.icon,
          color: isSelected ? selectedItemColor : unselectedItemColor,
          size: iconSize,
        ),
      ),
    );
  }
}
