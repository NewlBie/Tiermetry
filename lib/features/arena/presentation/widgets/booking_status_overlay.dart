import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tiermetry/core/theme/colors.dart';

class BookingStatusOverlay extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback onAction;

  const BookingStatusOverlay({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.onAction,
  });

  @override
  State<BookingStatusOverlay> createState() => _BookingStatusOverlayState();
}

class _BookingStatusOverlayState extends State<BookingStatusOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.isSuccess) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 48),
                
                // Final Billing Summary Style Info (for Success)
                if (widget.isSuccess)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow("Reference ID", "#TM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}"),
                        const Divider(color: Colors.white10, height: 24),
                        _summaryRow("Payment Status", "Paid via Tiermetry Wallet"),
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
                      widget.isSuccess ? "View My Ticket" : "Try Again",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
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
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
