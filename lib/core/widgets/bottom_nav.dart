import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';

class BottomNavItem {
  final Widget Function(double size, Color color) iconBuilder;
  final String label;

  const BottomNavItem({
    required this.iconBuilder,
    required this.label,
  });
}

class BottomNav extends StatefulWidget {
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
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _position;
  double _fromIndex = 0;
  double _toIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex.toDouble();
    _toIndex = _fromIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _position = AlwaysStoppedAnimation(_toIndex);
  }

  @override
  void didUpdateWidget(covariant BottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromIndex = _position.value;
      _toIndex = widget.currentIndex.toDouble();
      _position = Tween<double>(begin: _fromIndex, end: _toIndex).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastLinearToSlowEaseIn),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final surface = AnimatedBuilder(
      animation: _position,
      builder: (context, child) {
        return RepaintBoundary(
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NavSurfacePainter(
                        position: _position.value,
                        itemCount: widget.items.length,
                        accent: widget.accentColor,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(widget.items.length, (index) {
                      return Expanded(
                        child: _NavItemView(
                          item: widget.items[index],
                          index: index,
                          activePosition: _position.value,
                          accent: widget.accentColor,
                          onTap: () => _handleTap(index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (FeatureFlags.disableBlur) return surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: surface,
        ),
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  final BottomNavItem item;
  final int index;
  final double activePosition;
  final Color accent;
  final VoidCallback onTap;

  const _NavItemView({
    required this.item,
    required this.index,
    required this.activePosition,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (index - activePosition).abs().clamp(0.0, 1.0);
    final active = 1 - distance;
    final selected = active > 0.55;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.symmetric(horizontal: selected ? 10 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -2 * active),
                  child: item.iconBuilder(
                    23 + (active * 2),
                    Color.lerp(
                      Colors.white.withValues(alpha: 0.42),
                      Colors.white,
                      active,
                    )!,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TiermetryTypography.caption(
                    color:
                        Color.lerp(
                          Colors.white.withValues(alpha: 0.38),
                          accent,
                          active,
                        )!,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: selected ? 0.55 : 0.2,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
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

class _NavSurfacePainter extends CustomPainter {
  final double position;
  final int itemCount;
  final Color accent;

  const _NavSurfacePainter({
    required this.position,
    required this.itemCount,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount == 0) return;

    final slot = size.width / itemCount;
    final center = Offset(slot * (position + 0.5), size.height / 2);
    final activeRect = Rect.fromCenter(
      center: center,
      width: slot * 0.82,
      height: 56,
    );

    final glowRect = Rect.fromCenter(
      center: center,
      width: slot * 1.7,
      height: size.height * 1.5,
    );

    canvas
      ..drawOval(
        glowRect,
        Paint()
          ..shader = RadialGradient(
            colors: [accent.withValues(alpha: 0.16), Colors.transparent],
          ).createShader(glowRect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(activeRect, const Radius.circular(12)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.035),
            ],
          ).createShader(activeRect),
      );
  }

  @override
  bool shouldRepaint(covariant _NavSurfacePainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.itemCount != itemCount ||
        oldDelegate.accent != accent;
  }
}
