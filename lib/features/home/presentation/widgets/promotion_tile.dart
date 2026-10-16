import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:video_player/video_player.dart';

class PromotionTile extends StatefulWidget {
  const PromotionTile({super.key});

  @override
  State<PromotionTile> createState() => _PromotionTileState();
}

class _PromotionTileState extends State<PromotionTile>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  ScrollPosition? _scrollPosition;
  bool _hasError = false;
  bool _surfaceIsActive = true;
  bool _appIsActive = true;
  bool? _lastShouldPlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      'assets/videos/get_pass.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.addListener(_videoListener);
    unawaited(_initializeVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _surfaceIsActive =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);

    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (!identical(nextPosition, _scrollPosition)) {
      _scrollPosition?.removeListener(_syncPlayback);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_syncPlayback);
    }
    _schedulePlaybackSync();
  }

  void _videoListener() {
    if (mounted && _controller.value.hasError && !_hasError) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      if (mounted) {
        setState(() {});
        _lastShouldPlay = null;
        _schedulePlaybackSync();
      }
    } catch (error) {
      debugPrint('VideoPlayer error: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollPosition?.removeListener(_syncPlayback);
    _controller
      ..removeListener(_videoListener)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  void _schedulePlaybackSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlayback();
    });
  }

  void _syncPlayback() {
    if (!mounted || !_controller.value.isInitialized || _hasError) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final viewportHeight =
        View.of(context).physicalSize.height /
        View.of(context).devicePixelRatio;
    final isVisible = top < viewportHeight && bottom > 0;
    final shouldPlay = _surfaceIsActive && _appIsActive && isVisible;
    if (_lastShouldPlay == shouldPlay) return;
    _lastShouldPlay = shouldPlay;

    if (shouldPlay) {
      unawaited(_controller.play());
    } else {
      unawaited(_controller.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          color: TiermetryColors.surfaceUnderlay,
          child:
              _hasError
                  ? Image.asset(
                    'assets/onboard/Main.webp',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                  : _controller.value.isInitialized
                  ? RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                  : const Center(
                    child: CircularProgressIndicator(
                      color: TiermetryColors.accentAppleBlue,
                    ),
                  ),
        ),
      ),
    );
  }
}
