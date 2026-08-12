import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repo.dart';

class AuthCtrl extends ChangeNotifier {
  final AuthRepo _authRepo;
  UserEntity? _user;
  bool _isLoading = true;
  String? _error;

  AuthCtrl(this._authRepo) {
    _user = _authRepo.currentUser;
    _isLoading = false;
    _authRepo.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  UserEntity? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepo.signIn(email: email, password: password);
      _error = null;
    } catch (e) {
      _error = _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authRepo.signUp(email: email, password: password, name: name);
      _error = null;
    } catch (e) {
      _error = _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _handleError(dynamic e) {
    // DEVELOPMENT LOGGING
    debugPrint('--- SUPABASE AUTH FAILURE ---');
    debugPrint('Exception type: ${e.runtimeType}');
    debugPrint('Error details: $e');
    if (e is AuthException) {
      debugPrint('Status code: ${e.statusCode}');
      debugPrint('Message: ${e.message}');
    }
    debugPrint('-----------------------------');

    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    return 'Authentication failed: $e';
  }
}
