import 'package:flutter/material.dart';
import 'dart:math';

class TierProgressBar extends StatefulWidget {
  final double progress;

  const TierProgressBar({super.key, required this.progress});

  @override
  State<TierProgressBar> createState() => _TierProgressBarState();
}

class _TierProgressBarState extends State<TierProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Loops infinitely

    _shimmerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int segments = 24;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        final shimmerPhase = _shimmerAnimation.value * 2 * pi;
        final filledSegments =
        (segments * widget.progress.clamp(0.0, 1.0)).round();

        return Row(
          children: List.generate(segments, (i) {
            final shimmer = 0.5 + 0.5 * sin(shimmerPhase + i * 0.3);

            final bool isFilled = i < filledSegments;
            final Color baseColor =
            isFilled ? const Color(0xFFED64F5) : Colors.white12;

            final Color animatedColor = isFilled
                ? Color.lerp(baseColor, Colors.white, 0.1 * shimmer)!
                : baseColor;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                height: 8,
                decoration: BoxDecoration(
                  color: animatedColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isFilled
                      ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.2 * shimmer),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    )
                  ]
                      : [],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

