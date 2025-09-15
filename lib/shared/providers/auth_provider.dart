import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/auth/domain/user.dart' as app_user;

// AuthState class to hold authentication state including loading and error states
class AuthState {
  final app_user.User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    app_user.User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthNotifier(this._auth) : 
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    ),
    super(AuthState()) {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // Convert FirebaseAuth User to our app User
        final appUser = app_user.User.create(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL,
        );
        state = state.copyWith(user: appUser, isLoading: false, error: null);
      } else {
        state = state.copyWith(user: null, isLoading: false, error: null);
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final appUser = app_user.User.create(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? email.split('@')[0],
          photoUrl: userCredential.user!.photoURL,
        );
        state = state.copyWith(user: appUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createAccount(String email, String password, String displayName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateProfile(displayName: displayName);
        
        final appUser = app_user.User.create(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          photoUrl: userCredential.user!.photoURL,
        );
        state = state.copyWith(user: appUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      state = AuthState(); // Reset to initial state
    } catch (e) {
      // Handle error appropriately in your app
      rethrow;
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(FirebaseAuth.instance));