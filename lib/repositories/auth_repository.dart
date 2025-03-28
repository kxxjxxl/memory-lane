
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // Expose auth state changes
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Sign in
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(email, password);
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Register
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _authService.registerWithEmailAndPassword(email, password);
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // Get current user
  User? get currentUser => _authService.currentUser;
}