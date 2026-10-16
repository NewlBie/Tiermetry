import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';

class BottomNavItem {
  final Widget Function(double size, Color color) iconBuilder;
  final String label;

  const BottomNavItem({required this.iconBuilder, required this.label});
}

/// A compact destination rail whose active state travels between destinations.
///
/// Only the rail, icon lift, label, and press state animate. They all use
/// transforms or opacity so changing destinations stays inexpensive on devices
/// with a busy home feed behind the navigation.
class BottomNav extends StatelessWidget {
  static const _selectionDuration = Duration(milliseconds: 220);
  static const _pressDuration = Duration(milliseconds: 120);
  static const _selectionCurve = Cubic(0.23, 1, 0.32, 1);

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accentColor;

  const BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.accentColor = TiermetryColors.accentNeonGreen,
  }) : assert(items.length > 0),
       assert(currentIndex >= 0 && currentIndex < items.length);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1B1B), Color(0xFF111111)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;

            return Stack(
              fit: StackFit.expand,
              children: [
                _ActiveRail(
                  index: currentIndex,
                  itemWidth: itemWidth,
                  accentColor: accentColor,
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    return SizedBox(
                      width: itemWidth,
                      child: _NavItemView(
                        item: items[index],
                        selected: index == currentIndex,
                        accent: accentColor,
                        selectionDuration: _selectionDuration,
                        pressDuration: _pressDuration,
                        selectionCurve: _selectionCurve,
                        onTap: () {
                          if (index == currentIndex) return;
                          HapticFeedback.selectionClick();
                          onTap(index);
                        },
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActiveRail extends StatelessWidget {
  final int index;
  final double itemWidth;
  final Color accentColor;

  const _ActiveRail({
    required this.index,
    required this.itemWidth,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: index * itemWidth),
      duration: BottomNav._selectionDuration,
      curve: BottomNav._selectionCurve,
      builder: (context, offset, child) {
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: itemWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accentColor.withValues(alpha: 0.18)),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 22,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.48),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemView extends StatefulWidget {
  final BottomNavItem item;
  final bool selected;
  final Color accent;
  final Duration selectionDuration;
  final Duration pressDuration;
  final Curve selectionCurve;
  final VoidCallback onTap;

  const _NavItemView({
    required this.item,
    required this.selected,
    required this.accent,
    required this.selectionDuration,
    required this.pressDuration,
    required this.selectionCurve,
    required this.onTap,
  });

  @override
  State<_NavItemView> createState() => _NavItemViewState();
}

class _NavItemViewState extends State<_NavItemView> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.selected ? widget.accent : Colors.white.withValues(alpha: 0.48);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: widget.pressDuration,
          curve: BottomNav._selectionCurve,
          child: AnimatedSlide(
            offset: widget.selected ? const Offset(0, -0.06) : Offset.zero,
            duration: widget.selectionDuration,
            curve: widget.selectionCurve,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: widget.selected ? 0.92 : 1,
                  duration: widget.selectionDuration,
                  curve: widget.selectionCurve,
                  child: widget.item.iconBuilder(
                    widget.selected ? 23 : 24,
                    iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedOpacity(
                  opacity: widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  curve: widget.selectionCurve,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.caption(
                        color: widget.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
