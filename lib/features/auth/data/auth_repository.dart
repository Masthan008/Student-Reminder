import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/providers/firebase_provider.dart';
import '../../../core/errors/exceptions.dart';

abstract class AuthRepository {
  Future<User?> signInWithGoogle();
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> createUserWithEmail(String email, String password, String displayName);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepositoryImpl(this._firebaseService);

  @override
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  @override
  User? get currentUser => _firebaseService.currentUser;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      return await _firebaseService.signInWithGoogle();
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      return await _firebaseService.signInWithEmail(email, password);
    } catch (e) {
      throw AuthException('Email sign-in failed: $e');
    }
  }

  @override
  Future<User?> createUserWithEmail(String email, String password, String displayName) async {
    try {
      return await _firebaseService.createUserWithEmail(email, password, displayName);
    } catch (e) {
      throw AuthException('Account creation failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }
}

// Provider for the auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return AuthRepositoryImpl(firebaseService);
});