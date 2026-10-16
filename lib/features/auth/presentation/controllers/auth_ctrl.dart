import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repo.dart';

class AuthCtrl extends ChangeNotifier {
  final AuthRepo _authRepo;
  UserEntity? _user;
  bool _isLoading = true;
  String? _error;
  bool _needsEmailVerification = false;

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
  bool get needsEmailVerification => _needsEmailVerification;

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepo.signIn(email: email, password: password);
      _error = null;
      _needsEmailVerification = false;
    } catch (e) {
      _needsEmailVerification = _isEmailNotConfirmedError(e);
      _error =
          _needsEmailVerification
              ? 'Please verify your email before logging in.'
              : ErrorMapper.map(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      final requiresEmailVerification = await _authRepo.signUp(
        email: email,
        password: password,
        name: name,
      );
      _error = null;
      _needsEmailVerification = false;
      return requiresEmailVerification;
    } catch (e) {
      _error = ErrorMapper.map(e);
      _needsEmailVerification = false;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String email, String token) async {
    _setLoading(true);
    try {
      await _authRepo.verifyOTP(email: email, token: token);
      _error = null;
      _needsEmailVerification = false;
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendOTP(String email) async {
    _setLoading(true);
    try {
      await _authRepo.resendOTP(email: email);
      _error = null;
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    _setLoading(true);
    try {
      await _authRepo.resetPasswordForEmail(email: email);
      _error = null;
      _needsEmailVerification = false;
    } catch (e) {
      _error = ErrorMapper.map(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authRepo.signInWithGoogle();
      _error = null;
      _needsEmailVerification = false;
    } catch (e) {
      _error = ErrorMapper.map(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _user = null;
    _error = null;
    _needsEmailVerification = false;
    notifyListeners();
  }

  bool _isEmailNotConfirmedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('email not confirmed') ||
        message.contains('email_not_confirmed') ||
        message.contains('email not verified');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
