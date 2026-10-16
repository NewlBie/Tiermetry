import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/features/auth/presentation/screens/splash_screen.dart';
import 'package:tiermetry/features/auth/presentation/screens/update_password_screen.dart';
import 'package:tiermetry/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:tiermetry/root.dart';
import 'get_started_screen.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = locator.supabase.auth.onAuthStateChange.listen(
      _onSupabaseAuthStateChange,
    );
    _checkOnboardingStatus();
  }

  void _onSupabaseAuthStateChange(AuthState state) {
    if (state.event != AuthChangeEvent.passwordRecovery) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const UpdatePasswordScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    final authCtrl = locator.authCtrl;

    return ListenableBuilder(
      listenable: authCtrl,
      builder: (context, _) {
        if (authCtrl.isLoading) {
          return const SplashScreen();
        }

        if (authCtrl.isAuthenticated) {
          return const _ProfileSetupGate();
        } else {
          return const GetStartedScreen();
        }
      },
    );
  }
}

class _ProfileSetupGate extends StatefulWidget {
  const _ProfileSetupGate();

  @override
  State<_ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends State<_ProfileSetupGate> {
  final _profileCtrl = locator.profileCtrl;
  final _authCtrl = locator.authCtrl;

  /// Track whether we had a session so we can detect expiry.
  bool _wasAuthenticated = true;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _syncProfileForCurrentUser();
    // Detect session expiry: Supabase emits a null user when the JWT expires.
    // The authCtrl stream already handles this; we listen here to show the user
    // a "session expired" message before they land on the login screen.
    _authCtrl.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_wasAuthenticated && !_authCtrl.isAuthenticated) {
      _loadedUserId = null;
      _profileCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session expired. Please sign in again.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    if (_authCtrl.isAuthenticated) {
      _syncProfileForCurrentUser();
    }
    _wasAuthenticated = _authCtrl.isAuthenticated;
  }

  void _syncProfileForCurrentUser() {
    final userId = _authCtrl.user?.id;
    if (userId == null) return;
    if (_loadedUserId == userId &&
        (_profileCtrl.profileUserId == userId ||
            _profileCtrl.isLoading ||
            _profileCtrl.errorMessage != null)) {
      return;
    }

    if (_loadedUserId != null && _loadedUserId != userId) {
      _profileCtrl.clear();
    }
    _loadedUserId = userId;
    _profileCtrl.loadProfile();
  }

  @override
  void dispose() {
    _authCtrl.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profileCtrl,
      builder: (context, _) {
        if (_profileCtrl.isLoading && _profileCtrl.profile == null) {
          return const SplashScreen();
        }

        final profile = _profileCtrl.profile;
        if (profile == null && _profileCtrl.errorMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _profileCtrl.errorMessage ??
                          'Unable to load your profile details.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _profileCtrl.loadProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Retry Connection',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _authCtrl.signOut(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Sign Out / Switch Account'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (profile == null || !profile.profileSetupCompleted) {
          return const ProfileSetupScreen();
        }

        return const Root();
      },
    );
  }
}
