// lib/features/auth/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Expose the auth state changes stream
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  AuthProvider() {
    // Listen to auth state changes
    _authRepository.authStateChanges.listen((User? user) {
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _authRepository.signIn(email, password);
      _error = null;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Register with email and password
  Future<void> register(String email, String password) async {
    try {
      await _authRepository.register(email, password);
      _error = null;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
