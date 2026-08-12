import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';

/// A fun, premium greeting widget that rotates through Gen-Z and multilingual
/// messages every 5 minutes, with a timer driving the rotation.
class AdventureGreeting extends StatefulWidget {
  final String userName;

  const AdventureGreeting({required this.userName, super.key});

  @override
  State<AdventureGreeting> createState() => _AdventureGreetingState();
}

class _AdventureGreetingState extends State<AdventureGreeting> {
  static const List<String> greetings = [
    "What's good tonight?",
    'The city\'s alive',
    'Let\'s get it going',
    'Tap in somewhere',
    'Full scene tonight',
    'Aaj ka scene?',
    'Scene set hai',
    'Dale, let\'s play',
    'Órale, pull up tonight',
  ];

  late String currentGreeting;
  late Timer _rotationTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with a random greeting
    final random = DateTime.now().microsecond % greetings.length;
    currentGreeting = greetings[random];

    // Start the rotation timer (5 minutes)
    _rotationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _setRandomGreeting(),
    );
  }

  void _setRandomGreeting() {
    final random = DateTime.now().microsecond % greetings.length;
    if (mounted) {
      setState(() {
        currentGreeting = greetings[random];
      });
    }
  }

  @override
  void dispose() {
    _rotationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            currentGreeting,
            style: TiermetryTypography.display(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: TiermetrySpacing.sm),
        Text(
          '${widget.userName}, pick your scene — we’ll handle the rest.',
          style: TiermetryTypography.caption(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
