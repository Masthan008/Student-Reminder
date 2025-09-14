import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) return null;

      final user = _convertFirebaseUser(userCredential.user!);
      await saveUserData(user);
      
      return user;
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      final firebase_auth.UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user == null) return null;

      final userData = await getUserData(userCredential.user!.uid);
      return userData ?? _convertFirebaseUser(userCredential.user!);
    } catch (e) {
      throw AuthException('Email sign-in failed: $e');
    }
  }

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) async {
    try {
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