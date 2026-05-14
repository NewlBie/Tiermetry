import 'package:flutter/material.dart';

/// Animated list item with fade and slide animation
/// Used for staggered list item animations
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? duration;
  final Duration? delay;

  const AnimatedListItem({
    required this.child,
    required this.index,
    this.duration,
    this.delay,
    super.key,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(curve);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curve);

    final delayMs = widget.delay?.inMilliseconds ?? (widget.index * 100);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}
