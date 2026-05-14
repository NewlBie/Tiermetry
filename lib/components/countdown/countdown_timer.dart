import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/theme/colors.dart';

/// Countdown timer widget displaying days, hours, and minutes
class CountdownTimer extends StatefulWidget {
  final DateTime eventDate;
  final TextStyle? textStyle;

  const CountdownTimer({
    required this.eventDate,
    this.textStyle,
    super.key,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _timeLeft;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.eventDate.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;

    return Text(
      '$days Days : $hours Hrs : $minutes Min',
      style: widget.textStyle ?? GoogleFonts.urbanist(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: TiermetryColors.textSecondary,
      ),
    );
  }
}
