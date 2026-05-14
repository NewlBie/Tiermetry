import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/theme/colors.dart';

/// Animated rolling digit for number displays
class RollingDigit extends StatefulWidget {
  final int digit;
  final double height;
  final double width;
  final TextStyle? textStyle;

  const RollingDigit({
    required this.digit,
    this.height = 40,
    this.width = 24,
    this.textStyle,
    super.key,
  });

  @override
  State<RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<RollingDigit> {
  late double animatedValue = 10;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          animatedValue = widget.digit.toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? GoogleFonts.urbanist(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: TiermetryColors.positive,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 10, end: animatedValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return ClipRect(
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(10, (i) {
                return Positioned(
                  top: (i - value) * widget.height,
                  child: Text('$i', style: style),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Rolling counter that displays a number with animated digits
class RollingCounter extends StatelessWidget {
  final int number;
  final double digitHeight;
  final double digitWidth;
  final TextStyle? textStyle;

  const RollingCounter({
    required this.number,
    this.digitHeight = 40,
    this.digitWidth = 24,
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final digits = number.toString().split('').map(int.parse).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: digits.map((digit) {
        return RollingDigit(
          digit: digit,
          height: digitHeight,
          width: digitWidth,
          textStyle: textStyle,
        );
      }).toList(),
    );
  }
}
