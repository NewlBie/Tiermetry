import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';

class WalletFlipCard extends StatefulWidget {
  final WalletEntity walletData;
  final VoidCallback onEarnPressed;

  const WalletFlipCard({
    required this.walletData,
    required this.onEarnPressed,
    super.key,
  });

  @override
  State<WalletFlipCard> createState() => _WalletFlipCardState();
}

class _WalletFlipCardState extends State<WalletFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnim;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final ValueNotifier<Offset> _shineOffset = ValueNotifier(Offset.zero);
  bool _isFront = true;

  // Smoothing parameters
  double _rawShineX = 0.0;
  double _rawShineY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!mounted) return;

      // Update raw values (accumulate velocity)
      _rawShineX = (_rawShineX + event.y * 0.09).clamp(-1.2, 1.2);
      _rawShineY = (_rawShineY + event.x * 0.09).clamp(-1.0, 1.0);

      // Apply centering force (spring-back effect)
      _rawShineX *= 0.95;
      _rawShineY *= 0.95;

      // Apply EMA smoothing (Exponential Moving Average)
      const double emaAlpha = 0.12;
      final double smoothX =
          (emaAlpha * _rawShineX) + (1 - emaAlpha) * _shineOffset.value.dx;
      final double smoothY =
          (emaAlpha * _rawShineY) + (1 - emaAlpha) * _shineOffset.value.dy;

      _shineOffset.value = Offset(smoothX, smoothY);
    });
  }

  void _flip() {
    if (_controller.isAnimating) return;
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _controller.dispose();
    _shineOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (context, child) {
            final t = _flipAnim.value;
            final isBack = t >= 0.5;
            final angle = pi * t;

            return Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
              child:
                  isBack
                      ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _CardShell(
                          shineOffset: _shineOffset,
                          child: _WalletBackFace(
                            walletData: widget.walletData,
                            isVisible: isBack,
                          ),
                        ),
                      )
                      : _CardShell(
                        shineOffset: _shineOffset,
                        child: _WalletFrontFace(
                          walletData: widget.walletData,
                          onEarnPressed: widget.onEarnPressed,
                        ),
                      ),
            );
          },
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Card Shell
// ────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  final ValueNotifier<Offset> shineOffset;

  const _CardShell({required this.child, required this.shineOffset});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Deep matte base
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF111827),
                        Color(0xFF1F2937),
                        Color(0xFF111827),
                      ],
                    ),
                  ),
                ),
              ),

              // Dynamic shine (gyro)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: shineOffset,
                    builder: (context, offset, _) {
                      return RepaintBoundary(
                        child: CustomPaint(
                          painter: _ShinePainter(
                            shineX: offset.dx,
                            shineY: offset.dy,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Soft edge vignette
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.15,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Shine Painter
// ────────────────────────────────────────────────
class _ShinePainter extends CustomPainter {
  final double shineX;
  final double shineY;

  _ShinePainter({required this.shineX, required this.shineY});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.5 + shineX * 0.32),
      size.height * (0.38 + shineY * 0.22),
    );

    // Soft specular
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.5),
          );

    canvas.drawCircle(center, size.width * 0.5, paint);

    // Thin light streak
    final streak =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(shineX - 0.7, shineY - 0.5),
            end: Alignment(shineX + 0.7, shineY + 0.5),
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.09),
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), streak);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) =>
      old.shineX != shineX || old.shineY != shineY;
}

// ────────────────────────────────────────────────
// FRONT FACE
// ────────────────────────────────────────────────
class _WalletFrontFace extends StatelessWidget {
  final WalletEntity walletData;
  final VoidCallback onEarnPressed;

  const _WalletFrontFace({
    required this.walletData,
    required this.onEarnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIERGY',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.8,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              // Chip
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8C872),
                      Color(0xFFC9A227),
                      Color(0xFFB8860B),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 26,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.5),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.22),
                        width: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(flex: 2),

          // Balance
          Text(
            'AVAILABLE BALANCE',
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            walletData.balance,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),

          const Spacer(flex: 3),

          // Bottom actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onEarnPressed();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    'Earn Tiergies',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.contactless_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TIER',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// BACK FACE  (clear & readable)
// ────────────────────────────────────────────────
class _WalletBackFace extends StatelessWidget {
  final WalletEntity walletData;
  final bool isVisible;

  const _WalletBackFace({required this.walletData, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Magnetic stripe
          Container(
            height: 36,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Signature + CVV look
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '•••',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'CVV',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats — clear & readable
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '+${walletData.earned}',
                  label: 'EARNED',
                  color: TiermetryColors.positive,
                  visible: isVisible,
                  delay: 60,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: '-${walletData.spent}',
                  label: 'SPENT',
                  color: TiermetryColors.negative,
                  visible: isVisible,
                  delay: 120,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: walletData.txns,
                  label: 'TXNS',
                  color: Colors.white,
                  visible: isVisible,
                  delay: 180,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Badges
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [_Badge('Internal'), _Badge('Auto-refill')],
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Tap to flip back',
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.0,
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool visible;
  final int delay;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.visible,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.2),
        duration: Duration(milliseconds: 360 + delay),
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Shimmer
// ────────────────────────────────────────────────
class WalletShimmerPlaceholder extends StatelessWidget {
  const WalletShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1F2937),
      highlightColor: const Color(0xFF374151),
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
