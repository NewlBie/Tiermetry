import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/typography.dart';

/// A dynamic greeting for the Arena tab that rotates through
/// competitive and gaming oriented phrases.
class ArenaGreeting extends StatefulWidget {
  const ArenaGreeting({super.key});

  @override
  State<ArenaGreeting> createState() => _ArenaGreetingState();
}

class _ArenaGreetingState extends State<ArenaGreeting> {
  static const List<String> greetings = [
    "Ready to lock in?",
    "Step into the Arena",
    "Find your battlefield",
    "Who's next?",
    "Prove your rank",
    "Own the lobby tonight",
    "Where legends play",
  ];

  late String currentGreeting;
  late Timer _rotationTimer;

  @override
  void initState() {
    super.initState();
    _setRandomGreeting();
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
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find a match, join a tournament, or watch the pros.',
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
