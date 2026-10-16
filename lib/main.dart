// File: main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/constants/supabase_config.dart';
import 'package:tiermetry/core/services/analytics_service.dart';
import 'package:tiermetry/core/services/push_notification_service.dart';
import 'package:tiermetry/core/theme/tiermetry_theme.dart';
import 'package:tiermetry/core/widgets/deep_link_handler.dart';
import 'package:tiermetry/core/widgets/network_offline_banner.dart';
import 'package:tiermetry/features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  unawaited(PushNotificationService.instance.initialize());

  // Initialize high refresh rate globally
  try {
    await FlutterRefreshRateControl().requestHighRefreshRate();
  } catch (e) {
    debugPrint('Global refresh rate initialization failed: $e');
  }

  runApp(const MyApp());
  unawaited(AnalyticsService.instance.logAppOpened());
}

class AnalyticsRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name ?? route.runtimeType.toString();
    unawaited(
      AnalyticsService.instance.logEvent('screen_view', {'screen_name': name}),
    );
  }
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
              'HOMIES boot OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return NetworkOfflineBanner(
      child: DeepLinkHandler(
        child: MaterialApp(
          title: 'HOMIES',
          debugShowCheckedModeBanner: false,
          theme: TiermetryTheme.dark(),
          navigatorObservers: [AnalyticsRouteObserver()],
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}
