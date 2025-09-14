// Firebase Debug Service
// This service helps debug Firebase initialization and connectivity issues

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseDebugService {
  static Future<void> testFirebaseConnection() async {
    try {
      print('=== Firebase Debug Test ===');
      
      // Test Firebase Core
      final app = Firebase.app();
      print('✅ Firebase Core: ${app.name} (${app.options.projectId})');
      
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      print('✅ Firebase Auth: ${currentUser?.email ?? "No user signed in"}');
      
      // Test Firestore (only if not on web or if web is properly configured)
      if (!kIsWeb) {
        final firestore = FirebaseFirestore.instance;
        await firestore.enableNetwork();
        print('✅ Firestore: Connected and network enabled');
      } else {
        print('⚠️ Firestore: Skipped for web platform in debug mode');
      }
      
      print('=== Firebase Debug Complete ===');
      
    } catch (e) {
      print('❌ Firebase Debug Error: $e');
      rethrow;
    }
  }
  
  static void logAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('🔐 Auth State: User signed out');
      } else {
        print('🔐 Auth State: User signed in (${user.email})');
      }
    });
  }
}