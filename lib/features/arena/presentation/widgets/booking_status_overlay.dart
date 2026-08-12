import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

class BookingStatusOverlay extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String? bookingId;
  final String? actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTimeout;
  final DateTime? expiresAt;

  const BookingStatusOverlay({
    required this.isSuccess, 
    required this.title, 
    required this.message, 
    required this.onAction, 
    this.onTimeout,
    this.bookingId,
    this.actionLabel,
    this.expiresAt,
    super.key,
  });

  @override
  State<BookingStatusOverlay> createState() => _BookingStatusOverlayState();
}

class _BookingStatusOverlayState extends State<BookingStatusOverlay> {
  late ConfettiController _confettiController;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.isSuccess) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
      
      if (widget.expiresAt != null) {
        _remaining = widget.expiresAt!.difference(DateTime.now());
        _startTimer();
      }
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = widget.expiresAt!.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          _timer?.cancel();
          if (widget.onTimeout != null) {
            widget.onTimeout!();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isSuccess)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.network(
                    widget.isSuccess 
                      ? 'https://raw.githubusercontent.com/Arsh-Siddiqui/Lottie-Animations/master/Success%20Check.json'
                      : 'https://raw.githubusercontent.com/Arsh-Siddiqui/Lottie-Animations/master/Error%20Cross.json',
                    repeat: false,
                    animate: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        widget.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: widget.isSuccess ? Colors.greenAccent : Colors.redAccent,
                        size: 80,
                      );
                    },
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 24),
                
                Text(
                  widget.title,
                  style: TiermetryTypography.title(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TiermetryTypography.bodySmall(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                
                if (widget.expiresAt != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 16),
                     child: AppSurface(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       color: _remaining == Duration.zero ? TiermetryColors.negative : TiermetryColors.negative.withValues(alpha: 0.1),
                       borderRadius: 12,
                       border: Border.all(color: TiermetryColors.negative.withValues(alpha: 0.3)),
                       shadows: const [],
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             _remaining == Duration.zero ? Icons.timer_off_outlined : Icons.timer_outlined, 
                             color: _remaining == Duration.zero ? Colors.white : TiermetryColors.negative, 
                             size: 18
                           ),
                           const SizedBox(width: 8),
                           Text(
                             _remaining == Duration.zero 
                                ? 'HOLD EXPIRED' 
                                : 'Expiring in ${_formatDuration(_remaining)}',
                             style: TiermetryTypography.bodySmall(
                               color: _remaining == Duration.zero ? Colors.white : TiermetryColors.negative,
                               fontWeight: FontWeight.bold,
                               fontSize: 14,
                             ),
                           ),
                         ],
                       ),
                     ).animate(
                       onPlay: (controller) => _remaining != Duration.zero ? controller.repeat(reverse: true) : null
                     ).shimmer(duration: 2.seconds, color: Colors.white10),
                   ),

                const SizedBox(height: 48),
                
                // Final Billing Summary Style Info (for Success)
                if (widget.isSuccess)
                  AppSurface(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: 24,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    shadows: const [],
                    child: Column(
                      children: [
                        _summaryRow('Reference ID', widget.bookingId ?? 'N/A'),
                        const Divider(color: Colors.white10, height: 24),
                        _summaryRow('Payment Status', 'Pending Payment'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isSuccess ? TiermetryColors.accentAppleBlue : Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.actionLabel ?? (widget.isSuccess ? 'View My Ticket' : 'Try Again'),
                      style: TiermetryTypography.action(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TiermetryTypography.bodySmall(color: Colors.white60, fontSize: 13),
        ),
        Text(
          value,
          style: TiermetryTypography.bodySmall(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
