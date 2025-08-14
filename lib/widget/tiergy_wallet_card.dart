import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/theme/colors.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class TiergyWalletFlipCard extends StatefulWidget {
  final String balance;
  final String earned;
  final String spent;
  final String txns;
  final VoidCallback onEarnPressed;

  const TiergyWalletFlipCard({
    super.key,
    required this.balance,
    required this.earned,
    required this.spent,
    required this.txns,
    required this.onEarnPressed,
  });

  @override
  State<TiergyWalletFlipCard> createState() => _TiergyWalletFlipCardState();
}

class _TiergyWalletFlipCardState extends State<TiergyWalletFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnim;
  late final StreamSubscription<GyroscopeEvent> _gyroSub;

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

    _flipAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
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
    _gyroSub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const cardHeight = 240.0;

        return Center(
          child: GestureDetector(
            onTap: _flip,
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final value = _flipAnim.value;
                  final isBack = value >= 0.5;
                  final angle = isBack ? pi * (1 - value) : pi * value;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(angle)
                    ..scale(1 - (0.1 * (value - 0.5).abs()));

                  return Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _buildCard(isBack ? _buildBack() : _buildFront()),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: TiermetryColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: TiermetryColors.primary.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  TiermetryColors.gradientStart,
                  TiermetryColors.gradientEnd.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: 0.7,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(_tiltX * 0.8, _tiltY * 0.8),
                      radius: 1.2,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                        Colors.white.withOpacity(0.015),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(22),
            child: Transform.translate(
              offset: Offset(_tiltX * 4, _tiltY * 4),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFront() {
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
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.balance,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: TiermetryColors.white,
            shadows: [
              Shadow(
                blurRadius: 16,
                color: TiermetryColors.glow.withOpacity(0.3),
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onEarnPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TiermetryColors.white.withOpacity(0.12),
                foregroundColor: TiermetryColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 8,
                shadowColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "Earn Tiergies",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              "Tap to flip",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: TiermetryColors.textSecondary,
                letterSpacing: 1,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildBack() {
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
            _stat("+${widget.earned}", "EARNED", TiermetryColors.positive),
            _stat("-${widget.spent}", "SPENT", TiermetryColors.negative),
            _stat("${widget.txns}", "TXNS", TiermetryColors.white),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _badge("Internal"),
            _badge("Auto-refill Enabled"),
            _badge("Last active: 2d ago"),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Tap to flip back",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: TiermetryColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        )
      ],
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: color.withOpacity(0.25),
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }

}
