import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:video_player/video_player.dart';

class PromotionTile extends StatefulWidget {
  const PromotionTile({super.key});

  @override
  State<PromotionTile> createState() => _PromotionTileState();
}

class _PromotionTileState extends State<PromotionTile> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/homies.mp4')
      ..initialize().then((_) {
        _controller
          ..setLooping(true)
          ..setVolume(0) // Mute for looping background
          ..play();
        setState(() {});
      }).catchError((Object error) {
        debugPrint('VideoPlayer error: $error');
        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: _hasError
              ? Center(
                  child: Text(
                    'Failed to load video\n(Try Hot Restart)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TiermetryColors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                )
              : _controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
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
