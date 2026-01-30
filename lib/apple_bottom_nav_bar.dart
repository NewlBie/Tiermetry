import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// MODEL
/// ---------------------------------------------------------------------------

class AppleBottomNavBarItem {
  final IconData icon;
  const AppleBottomNavBarItem({required this.icon});
}

/// ---------------------------------------------------------------------------
/// NAV BAR
/// ---------------------------------------------------------------------------

class AppleBottomNavBar extends StatefulWidget {
  final List<AppleBottomNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppleBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppleBottomNavBar> createState() => _AppleBottomNavBarState();
}

class _AppleBottomNavBarState extends State<AppleBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _fromIndex;
  late double _toIndex;

  static const Color _accentColor = Color(0xFF8B7CFF); // Purple accent

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex.toDouble();
    _toIndex = widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AppleBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromIndex = _toIndex;
      _toIndex = widget.currentIndex.toDouble();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E11),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final double t =
              Curves.easeOutCubic.transform(_controller.value);

              final double activeIndex =
              lerpDouble(_fromIndex, _toIndex, t)!;

              return CustomPaint(
                painter: _DotMatrixPainter(),
                foregroundPainter: _EnergyFieldPainter(
                  itemCount: widget.items.length,
                  position: activeIndex,
                  accent: _accentColor,
                  progress: t,
                ),
                child: Row(
                  children: List.generate(
                    widget.items.length,
                        (i) => Expanded(
                      child: _NavItem(
                        icon: widget.items[i].icon,
                        index: i,
                        activeIndex: activeIndex,
                        progress: t,
                        accent: _accentColor,
                        onTap: () => widget.onTap(i),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// NAV ITEM (ICON + LIFE RIPPLE)
/// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final double activeIndex;
  final double progress;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.activeIndex,
    required this.progress,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double distance = (index - activeIndex).abs();
    final double influence = max(0.0, 1.0 - distance);

    final double life =
    Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Revival ripple
            CustomPaint(
              painter: _RevivalRipplePainter(
                progress: life * influence,
                color: accent,
              ),
              size: const Size(48, 48),
            ),

            // Icon
            Transform.translate(
              offset: Offset(0, -4 * influence * life),
              child: Transform.scale(
                scale: 1.0 + 0.22 * influence * life,
                child: Icon(
                  icon,
                  size: 26,
                  color: Color.lerp(
                    Colors.white54,
                    accent,
                    influence,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENERGY FIELD (BACKGROUND SLIDER)
/// ---------------------------------------------------------------------------

class _EnergyFieldPainter extends CustomPainter {
  final int itemCount;
  final double position;
  final Color accent;
  final double progress;

  _EnergyFieldPainter({
    required this.itemCount,
    required this.position,
    required this.accent,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double slotWidth = size.width / itemCount;
    final double centerX =
        (slotWidth * position) + (slotWidth / 2.0);

    final double intensity =
    lerpDouble(0.10, 0.18, progress)!;

    final Rect fieldRect = Rect.fromLTWH(
      centerX - slotWidth / 2,
      10,
      slotWidth,
      size.height - 20,
    );

    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: intensity),
          Colors.transparent,
        ],
      ).createShader(fieldRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        fieldRect,
        const Radius.circular(22),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyFieldPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.progress != progress;
  }
}

/// ---------------------------------------------------------------------------
/// REVIVAL RIPPLE (ICON LIFE EFFECT)
/// ---------------------------------------------------------------------------

class _RevivalRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RevivalRipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final double radius = lerpDouble(6, 24, progress)!;
    final double alpha = (1 - progress) * 0.25;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: alpha);

    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RevivalRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// ---------------------------------------------------------------------------
/// DOT MATRIX (NOTHING OS TEXTURE)
/// ---------------------------------------------------------------------------

class _DotMatrixPainter extends CustomPainter {
  static final Paint _paint = Paint()
    ..color = Colors.white.withValues(alpha: 0.025);

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 10;

    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(
          Offset(x, y),
          0.6,
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
