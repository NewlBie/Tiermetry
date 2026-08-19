import 'package:flutter/material.dart';

/// A widget that defers building its child until it becomes the active index in a stack or page view.
class DeferredPage extends StatefulWidget {
  final int index;
  final int currentIndex;
  final Widget child;

  const DeferredPage({
    required this.index,
    required this.currentIndex,
    required this.child,
    super.key,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  bool _hasBuilt = false;

  @override
  void didUpdateWidget(DeferredPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasBuilt && widget.currentIndex == widget.index) {
      setState(() => _hasBuilt = true);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.currentIndex == widget.index) {
      _hasBuilt = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBuilt) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
