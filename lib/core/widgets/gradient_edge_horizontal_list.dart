import 'package:flutter/material.dart';

/// A horizontal scrollable list with premium fade-out gradient on edges
/// that responds to scroll position - fades in/out as user scrolls
class GradientEdgeHorizontalList extends StatefulWidget {
  final ScrollController? controller;
  final List<Widget> children;
  final double gradientWidth; // Width of fade effect (typically 20-40px)
  final double fadeStartThreshold; // Distance to start fading in (in px)
  final EdgeInsets padding;
  final ScrollPhysics physics;

  const GradientEdgeHorizontalList({
    required this.children,
    this.controller,
    this.gradientWidth = 32.0,
    this.fadeStartThreshold = 50.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.physics = const BouncingScrollPhysics(),
    super.key,
  });

  @override
  State<GradientEdgeHorizontalList> createState() =>
      _GradientEdgeHorizontalListState();
}

class _GradientEdgeHorizontalListState
    extends State<GradientEdgeHorizontalList> {
  late ScrollController _scrollController;
  bool _isScrollable = false;
  double _maxScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_updateScrollState);

    // Calculate if content is scrollable after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _maxScroll = _scrollController.position.maxScrollExtent;
          _isScrollable = _maxScroll > 0;
        });
      }
    });
  }

  void _updateScrollState() {
    if (mounted) {
      setState(() {
        _maxScroll = _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_updateScrollState);
    }
    super.dispose();
  }

  /// Calculates opacity for left gradient based on scroll position
  /// Returns 0 at start, 1 when scrolled past threshold
  double _getLeftFadeOpacity() {
    if (!_isScrollable) return 0;

    final double offset = _scrollController.offset;

    // Smoothly fade in as user scrolls past threshold
    if (offset < widget.fadeStartThreshold) {
      return offset / widget.fadeStartThreshold;
    }
    return 1.0;
  }

  /// Calculates opacity for right gradient based on scroll position
  /// Returns 0 at end, 1 when scrolled away from end
  double _getRightFadeOpacity() {
    if (!_isScrollable) return 0;

    final double offset = _scrollController.offset;
    final double remainingScroll = _maxScroll - offset;

    // Smoothly fade in as user scrolls away from end
    if (remainingScroll < widget.fadeStartThreshold) {
      return remainingScroll / widget.fadeStartThreshold;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final double leftOpacity = _getLeftFadeOpacity();
        final double rightOpacity = _getRightFadeOpacity();

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                // Left side: fade from dark to transparent based on scroll
                Colors.black.withValues(alpha: leftOpacity * 0.6),
                Colors.transparent, // Middle: fully transparent
                Colors.transparent, // Middle: fully transparent
                // Right side: fade from transparent to dark based on scroll
                Colors.black.withValues(alpha: rightOpacity * 0.6),
              ],
              stops: [
                0.0, // Stop 1: Left edge
                widget.gradientWidth / bounds.width, // Stop 2: Fade width
                1.0 -
                    (widget.gradientWidth /
                        bounds.width), // Stop 3: Fade width from right
                1.0, // Stop 4: Right edge
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.darken, // Darkens edges without showing overlay
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: widget.physics,
            padding: widget.padding,
            child: Row(
              children: [
                ...widget.children.map((child) {
                  return child;
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
