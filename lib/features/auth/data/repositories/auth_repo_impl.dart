import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final SupabaseClient _supabase;

  AuthRepoImpl(this._supabase);

  @override
  Stream<UserEntity?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        if (user == null) return null;
        return UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['name'] as String?,
        );
      });

  @override
  UserEntity? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserEntity(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );

    return response.session == null;
  }

  @override
  Future<void> verifyOTP({required String email, required String token}) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: token,
    );
  }

  @override
  Future<void> resendOTP({required String email}) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'homies://login-callback',
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'homies://login-callback',
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
