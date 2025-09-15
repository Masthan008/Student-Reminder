import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart' as app_user;
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

abstract class FirebaseService {
  // Authentication
  Future<app_user.User?> signInWithGoogle();
  Future<app_user.User?> signInWithEmail(String email, String password);
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName);
  Future<void> signOut();
  Stream<app_user.User?> get authStateChanges;
  app_user.User? get currentUser;
  
  // Reminders
  Future<void> syncReminders(List<Reminder> reminders);
  Stream<List<Reminder>> getReminderStream(String userId);
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String reminderId);
  Future<List<Reminder>> getReminders(String userId);
  
  // User data
  Future<void> saveUserData(app_user.User user);
  Future<app_user.User?> getUserData(String userId);
}

class FirebaseServiceImpl implements FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  FirebaseServiceImpl() {
    // Initialize GoogleSignIn with platform-specific configuration
    if (kIsWeb) {
      // For web, we can skip Google Sign-In or configure it properly later
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // You can add clientId here if you have it: clientId: 'your-web-client-id'
      );
    } else {
      // For mobile platforms
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
    
    // Set persistence for authentication state
    _setAuthPersistence();
  }
  
  // Set authentication persistence to LOCAL for mobile and web
  Future<void> _setAuthPersistence() async {
    try {
      if (kIsWeb) {
        // For web, set persistence to LOCAL (default is LOCAL, but we're being explicit)
        await _auth.setPersistence(firebase_auth.Persistence.LOCAL);
      } else {
        // For mobile, persistence is LOCAL by default, but we can also use SharedPreferences as fallback
        final prefs = await SharedPreferences.getInstance();
        // We'll use this later for additional persistence checks
      }
    } catch (e) {
      // Persistence setting might not be available on all platforms
      if (kDebugMode) {
        print('Warning: Could not set auth persistence: $e');
      }
    }
  }

  // Check if Firebase is properly configured
  bool get _isFirebaseConfigured {
    try {
      // Check if Firebase app is initialized
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Authentication methods
  @override
  Stream<app_user.User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        final userData = await getUserData(firebaseUser.uid);
        return userData ?? _convertFirebaseUser(firebaseUser);
      } catch (e) {
        return _convertFirebaseUser(firebaseUser);
      }
    });
  }

  @override
  app_user.User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _convertFirebaseUser(firebaseUser);
  }

  @override
  Future<app_user.User?> signInWithGoogle() async {
    try {
      if (!_isFirebaseConfigured) {
        throw AuthException('Firebase is not properly configured');
      }

      // Skip Google Sign-In on web if not properly configured
      if (kIsWeb) {
        throw AuthException('Google Sign-In is not configured for web platform. Please use email/password authentication.');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Sign in was cancelled by the user
        return null;
      }

      // Authenticate with Firebase
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) return null;

      final user = _convertFirebaseUser(userCredential.user!);
      await saveUserData(user);
      
      // Update last login time
      await _updateUserLastLogin(user.id);
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException('Google sign-in failed: ${e.message}');
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      if (!_isFirebaseConfigured) {
        throw AuthException('Firebase is not properly configured');
      }

      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user == null) return null;

      final userData = await getUserData(userCredential.user!.uid);
      final user = userData ?? _convertFirebaseUser(userCredential.user!);
      
      // Update last login time
      await _updateUserLastLogin(user.id);
      
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException('Email sign-in failed: ${e.message}');
    } catch (e) {
      throw AuthException('Email sign-in failed: $e');
    }
  }

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) async {
    try {
      if (!_isFirebaseConfigured) {
        throw AuthException('Firebase is not properly configured');
      }

      final firebase_auth.UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user == null) return null;

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      final user = app_user.User.create(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: userCredential.user!.photoURL,
      );

      await saveUserData(user);
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException('Account creation failed: ${e.message}');
    } catch (e) {
      throw AuthException('Account creation failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }
  
  // Helper method to update user's last login time
  Future<void> _updateUserLastLogin(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'lastLoginAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Don't throw error for this, as it's not critical
      if (kDebugMode) {
        print('Warning: Could not update last login time: $e');
      }
    }
  }

  // Reminder methods
  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    try {
      final batch = _firestore.batch();
      
      for (final reminder in reminders) {
        final docRef = _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id);
        batch.set(docRef, reminder.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw NetworkException('Failed to sync reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    try {
      return _firestore
          .collection(AppConstants.remindersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return Reminder.fromJson(doc.data());
          } catch (e) {
            // Skip invalid documents
            return null;
          }
        }).where((reminder) => reminder != null).cast<Reminder>().toList();
      });
    } catch (e) {
      throw NetworkException('Failed to get reminder stream: $e');
    }
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _firestore
          .collection(AppConstants.remindersCollection)
          .doc(reminder.id)
          .set(reminder.toJson());
    } catch (e) {
      throw NetworkException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _firestore
          .collection(AppConstants.remindersCollection)
          .doc(reminder.id)
          .update(reminder.toJson());
    } catch (e) {
      throw NetworkException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore
          .collection(AppConstants.remindersCollection)
          .doc(reminderId)
          .delete();
    } catch (e) {
      throw NetworkException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.remindersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('dateTime')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return Reminder.fromJson(doc.data());
        } catch (e) {
          // Skip invalid documents
          return null;
        }
      }).where((reminder) => reminder != null).cast<Reminder>().toList();
    } catch (e) {
      throw NetworkException('Failed to get reminders: $e');
    }
  }

  // User data methods
  @override
  Future<void> saveUserData(app_user.User user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw NetworkException('Failed to save user data: $e');
    }
  }

  @override
  Future<app_user.User?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      
      return app_user.User.fromJson(doc.data()!);
    } catch (e) {
      throw NetworkException('Failed to get user data: $e');
    }
  }

  // Helper methods
  app_user.User _convertFirebaseUser(firebase_auth.User firebaseUser) {
    return app_user.User.create(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
    );
  }
}