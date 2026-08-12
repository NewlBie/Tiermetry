import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';

/// A scroll-responsive gradient overlay that sits at the top of the page.
/// This widget has its own scroll listener and only rebuilds itself,
/// NOT the entire page. This is crucial for smooth scrolling.
class ScrollGradientOverlay extends StatefulWidget {
  final ScrollController scrollController;

  const ScrollGradientOverlay({
    required this.scrollController,
    super.key,
  });

  @override
  State<ScrollGradientOverlay> createState() => _ScrollGradientOverlayState();
}

class _ScrollGradientOverlayState extends State<ScrollGradientOverlay> {
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      final newOffset = widget.scrollController.offset;
      if (newOffset != _scrollOffset) {
        setState(() {
          _scrollOffset = newOffset;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final alphaValue = (0.3 + (_scrollOffset / 500) * 0.3).clamp(0.3, 0.6);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            height: topPadding + 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TiermetryColors.background.withValues(alpha: alphaValue),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
