import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

/// A premium promotion tile with accelerometer-driven parallax floating stickers,
/// shake detection, and idle idle animations.
class PromotionTile extends StatefulWidget {
  const PromotionTile({super.key});

  @override
  State<PromotionTile> createState() => _PromotionTileState();
}

class _PromotionTileState extends State<PromotionTile>
    with TickerProviderStateMixin {
  static const List<String> _stickerPaths = [
    'assets/images/bowling.png',
    'assets/images/football.png',
    'assets/images/gaming.png',
    'assets/sticks/starbucks.png',
    'assets/sticks/steering.png',
    'assets/images/racing.png',
  ];

  late final List<_StickerData> _stickers;
  final _rng = Random(42);

  // Lightweight tilt notifier - only sticker layer rebuilds, not the whole tile
  final _tilt = _TiltNotifier();

  // Shake detection
  double _lastMagnitude = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Shake animation
  late final AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late List<Offset> _shakeOffsets;

  // Idle floating - stickers gently bob even when the phone is still
  late final AnimationController _idleCtrl;

  @override
  void initState() {
    super.initState();

    const positions = <List<double>>[
      [0.45, 0.18], // bowling - center-right, top
      [0.75, 0.10], // football - right, top
      [0.90, 0.48], // gamepad - far right, mid
      [0.50, 0.72], // starbucks - center, bottom
      [0.68, 0.55], // steering - right-center, lower-mid
      [0.85, 0.80], // sunglass - right, bottom
    ];

    _stickers = List.generate(_stickerPaths.length, (i) {
      final pos = positions[i % positions.length];
      return _StickerData(
        path: _stickerPaths[i],
        baseX: pos[0] + (_rng.nextDouble() - 0.5) * 0.12,
        baseY: pos[1] + (_rng.nextDouble() - 0.5) * 0.12,
        size: 40.0 + _rng.nextDouble() * 20,
        rotation: (_rng.nextDouble() - 0.5) * 0.4,
        depth: 0.3 + _rng.nextDouble() * 0.5,
        opacity: 0.4 + _rng.nextDouble() * 0.2,
        idlePhase: _rng.nextDouble() * 2 * pi, // unique phase per sticker
      );
    });

    _shakeOffsets = List.generate(
      _stickerPaths.length,
      (_) => Offset(
        (_rng.nextDouble() - 0.5) * 40,
        (_rng.nextDouble() - 0.5) * 40,
      ),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut);

    // Slow looping animation - drives the idle bob for each sticker
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Accelerometer at ~15 Hz - enough for smooth parallax, less battery drain
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 66),
    ).listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!mounted) return;

    // Update the lightweight notifier (NO setState here)
    _tilt.update(event.x, event.y);

    // Shake detection
    final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if ((mag - _lastMagnitude).abs() > 15 && !_shakeCtrl.isAnimating) {
      for (int i = 0; i < _shakeOffsets.length; i++) {
        _shakeOffsets[i] = Offset(
          (_rng.nextDouble() - 0.5) * 50,
          (_rng.nextDouble() - 0.5) * 50,
        );
      }
      _shakeCtrl.forward(from: 0);
    }
    _lastMagnitude = mag;
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _shakeCtrl.dispose();
    _idleCtrl.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: AppSurface(
        width: double.infinity,
        borderRadius: TiermetryRadii.md,
        shadows: TiermetryShadows.highEmphasis,
        child: Stack(
          children: [
            // --- Floating sticker layer -------------------------
              // RepaintBoundary isolates repaints from the rest of the UI.
              // Single LayoutBuilder -> one constraints pass for all 6 stickers.
              // Listenable.merge -> one rebuild trigger for tilt + shake + idle.
              Positioned.fill(
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return AnimatedBuilder(
                        animation: Listenable.merge([
                          _tilt,
                          _shakeAnim,
                          _idleCtrl,
                        ]),
                        builder: (_, __) {
                          final tiltX = _tilt.x;
                          final tiltY = _tilt.y;
                          final idleT = _idleCtrl.value * 2 * pi;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(_stickers.length, (i) {
                              final s = _stickers[i];

                              // Tilt parallax
                              final px = tiltX * s.depth * 3;
                              final py = tiltY * s.depth * 3;

                              // Gentle idle bob (sine/cosine with unique phase)
                              final idleX =
                                  sin(idleT + s.idlePhase) * 2 * s.depth;
                              final idleY =
                                  cos(idleT + s.idlePhase * 1.3) * 3 * s.depth;

                              // Shake burst (decays via elasticOut)
                              final sx =
                                  _shakeOffsets[i].dx * (1 - _shakeAnim.value);
                              final sy =
                                  _shakeOffsets[i].dy * (1 - _shakeAnim.value);

                              // Clamp so stickers stay inside the tile
                              final rawX =
                                  s.baseX * w + px + sx + idleX - s.size / 2;
                              final rawY =
                                  s.baseY * h + py + sy + idleY - s.size / 2;
                              final x = rawX.clamp(0.0, w - s.size);
                              final y = rawY.clamp(0.0, h - s.size);

                              return Positioned(
                                left: x,
                                top: y,
                                child: Transform.rotate(
                                  angle:
                                      s.rotation +
                                      tiltX * 0.01 +
                                      sin(idleT + s.idlePhase) * 0.02,
                                  // Image color+blend avoids the expensive
                                  // Opacity compositing layer per sticker.
                                  child: Image.asset(
                                    s.path,
                                    width: s.size,
                                    height: s.size,
                                    fit: BoxFit.contain,
                                    color: Colors.white.withValues(
                                      alpha: s.opacity,
                                    ),
                                    colorBlendMode: BlendMode.modulate,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // --- Foreground content -----------------------------
              Padding(
                padding: TiermetrySpacing.pagePadding, // 20px padding matches grid gap vibe
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Unlock Premium Access',
                        style: TiermetryTypography.titleSmall(
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    const SizedBox(height: TiermetrySpacing.xs),
                    Flexible(
                      child: Text(
                        'Get exclusive access to premium events, priority bookings, and special perks',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TiermetryTypography.caption(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ).copyWith(height: 1.35),
                      ),
                    ),
                    const SizedBox(height: TiermetrySpacing.md),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Premium upgrade coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TiermetrySpacing.lg,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              TiermetryColors.gradientStart,
                              TiermetryColors.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            TiermetryRadii.pill,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TiermetryColors.gradientStart.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Upgrade Now',
                              style: TiermetryTypography.action(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

/// Lightweight notifier - replaces setState so only the sticker layer rebuilds
class _TiltNotifier extends ChangeNotifier {
  double _x = 0;
  double _y = 0;

  double get x => _x;
  double get y => _y;

  void update(double rawX, double rawY) {
    const smoothing = 0.15;
    _x = _x + (rawX * smoothing - _x * smoothing);
    _y = _y + (rawY * smoothing - _y * smoothing);
    notifyListeners();
  }
}

/// Data for each floating sticker
class _StickerData {
  final String path;
  final double baseX;
  final double baseY;
  final double size;
  final double rotation;
  final double depth;
  final double opacity;
  final double idlePhase;

  const _StickerData({
    required this.path,
    required this.baseX,
    required this.baseY,
    required this.size,
    required this.rotation,
    required this.depth,
    required this.opacity,
    required this.idlePhase,
  });
}
