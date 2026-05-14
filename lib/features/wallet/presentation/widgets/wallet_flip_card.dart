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
  StreamSubscription<GyroscopeEvent>? _streamSubscription;

  bool _isFront = true;
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _streamSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _tiltX = event.y.clamp(-1.0, 1.0);
        _tiltY = event.x.clamp(-1.0, 1.0);
      });
    });
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (_, __) {
            final value = _flipAnim.value;
            final isBack = value >= 0.5;
            final angle = (pi * value) - (isBack ? pi : 0);
            final transform =
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle)
                  ..rotateX(_tiltY * -0.05)
                  ..rotateZ(_tiltX * 0.05);

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: isBack
                  ? _buildCard(
                    _WalletBackFace(walletData: widget.walletData, isFlipped: isBack),
                  )
                  : _buildCard(
                    _WalletFrontFace(walletData: widget.walletData, onEarnPressed: widget.onEarnPressed),
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TiermetryColors.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
        gradient: const LinearGradient(
          colors: [TiermetryColors.gradientStart, TiermetryColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: 0.7,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(_tiltX * 0.8, _tiltY * 0.8),
                      radius: 1.2,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Transform.translate(
                offset: Offset(_tiltX * 6, _tiltY * 6),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletFrontFace extends StatelessWidget {
  final WalletEntity walletData;
  final VoidCallback onEarnPressed;

  const _WalletFrontFace({required this.walletData, required this.onEarnPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TIERGY WALLET",
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 2,
            color: TiermetryColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Balance",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          walletData.balance,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: TiermetryColors.white,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onEarnPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TiermetryColors.white.withValues(alpha: 0.12),
                foregroundColor: TiermetryColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                "Earn Tiergies",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              "Tap to flip",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: TiermetryColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletBackFace extends StatelessWidget {
  final WalletEntity walletData;
  final bool isFlipped;

  const _WalletBackFace({required this.walletData, required this.isFlipped});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "WALLET DETAILS",
            style: GoogleFonts.inter(
              fontSize: 12,
              letterSpacing: 2,
              color: TiermetryColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AnimatedStat(
              value: "+${walletData.earned}",
              label: "EARNED",
              color: TiermetryColors.positive,
              isVisible: isFlipped,
              delay: const Duration(milliseconds: 100),
            ),
            _AnimatedStat(
              value: "-${walletData.spent}",
              label: "SPENT",
              color: TiermetryColors.negative,
              isVisible: isFlipped,
              delay: const Duration(milliseconds: 200),
            ),
            _AnimatedStat(
              value: walletData.txns,
              label: "TXNS",
              color: TiermetryColors.white,
              isVisible: isFlipped,
              delay: const Duration(milliseconds: 300),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: const [_Badge("Internal"), _Badge("Auto-refill Enabled")],
        ),
        const Spacer(),
        Center(
          child: Text(
            "Tap to flip back",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: TiermetryColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isVisible;
  final Duration delay;

  const _AnimatedStat({
    required this.value,
    required this.label,
    required this.color,
    required this.isVisible,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedPadding(
        padding: EdgeInsets.only(top: isVisible ? 0 : 10),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class WalletShimmerPlaceholder extends StatelessWidget {
  const WalletShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

