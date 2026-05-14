// File: main.dart
import 'package:flutter/material.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/tiermetry_theme.dart';
import 'root.dart'; // New controller page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.minimalBoot) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0E0E0E),
          body: Center(
            child: Text(
              'Tiermetry boot OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Tiermetry',
      debugShowCheckedModeBanner: false,
      theme: TiermetryTheme.dark(),
      home: const Root(),
    );
  }
}
