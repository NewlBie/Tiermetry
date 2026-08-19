// File: main.dart
import 'package:flutter/material.dart';

import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/constants/supabase_config.dart';
import 'package:tiermetry/core/theme/tiermetry_theme.dart';
import 'package:tiermetry/features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Initialize high refresh rate globally
  try {
    await FlutterRefreshRateControl().requestHighRefreshRate();
  } catch (e) {
    debugPrint('Global refresh rate initialization failed: $e');
  }

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
      home: const AuthWrapper(),
    );
  }
}
