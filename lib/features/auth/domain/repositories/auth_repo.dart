import '../entities/user_entity.dart';

abstract class AuthRepo {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<void> signIn({required String email, required String password});

  /// Returns true only when the project requires email OTP confirmation.
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  });
  Future<void> verifyOTP({required String email, required String token});
  Future<void> resendOTP({required String email});
  Future<void> resetPasswordForEmail({required String email});
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
