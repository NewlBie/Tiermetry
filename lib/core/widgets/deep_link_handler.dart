import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/locator.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({required this.child, super.key});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  static const _pendingReferralKey = 'pending_referral_code';

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.signedIn) {
        unawaited(_claimStoredReferral());
      }
    });
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial deep link: $e');
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(_handleDeepLink(uri));
      },
      onError: (dynamic err) {
        debugPrint('Failed to handle deep link stream: $err');
      },
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('Received deep link: $uri');
    if (_isSupabaseAuthCallback(uri)) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } on AuthException catch (e) {
        debugPrint('Failed to process auth deep link: ${e.message}');
      } catch (e) {
        debugPrint('Failed to process auth deep link: $e');
      }
      return;
    }

    final referralCode = _referralCode(uri);
    if (referralCode != null) {
      await _handleReferral(referralCode);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deep link received: ${uri.path}')),
      );
    }
  }

  String? _referralCode(Uri uri) {
    if (uri.scheme != 'homies' || uri.host != 'invite') return null;
    if (uri.pathSegments.length != 1) return null;
    final code = uri.pathSegments.single.trim();
    return code.isEmpty ? null : code;
  }

  Future<void> _handleReferral(String code) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingReferralKey, code);
    if (Supabase.instance.client.auth.currentUser == null) {
      _showMessage('Referral saved. Create or sign in to your HOMIES account.');
      return;
    }
    await _claimStoredReferral();
  }

  Future<void> _claimStoredReferral() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_pendingReferralKey);
    if (code == null || code.isEmpty) return;

    try {
      await locator.loyaltyCtrl.claimReferralCode(code);
      await preferences.remove(_pendingReferralKey);
      _showMessage('Referral connected to your account.');
    } catch (error) {
      debugPrint('Failed to claim referral: $error');
      _showMessage('This referral link could not be applied.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSupabaseAuthCallback(Uri uri) {
    final params = uri.queryParameters;
    final raw = uri.toString();
    return uri.scheme == 'homies' &&
        uri.host == 'login-callback' &&
        (params.containsKey('code') ||
            params.containsKey('error') ||
            raw.contains('access_token=') ||
            raw.contains('refresh_token='));
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
