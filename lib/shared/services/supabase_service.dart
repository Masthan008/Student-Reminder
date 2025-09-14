import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:flutter/foundation.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart' as app_user;
import '../../core/errors/exceptions.dart';
import 'firebase_service.dart';

class SupabaseService implements FirebaseService {
  static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  SupabaseClient get _client => Supabase.instance.client;
  
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: kDebugMode,
    );
  }

  // Check if Supabase is properly configured
  bool get _isSupabaseConfigured {
    try {
      return _client.auth.currentUser != null || _supabaseUrl != 'YOUR_SUPABASE_URL';
    } catch (e) {
      return false;
    }
  }

  // Authentication methods
  @override
  Stream<app_user.User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return _convertSupabaseUser(user);
    });
  }

  @override
  app_user.User? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _convertSupabaseUser(user);
  }

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      final userData = await getUserData(response.user!.id);
      return userData ?? _convertSupabaseUser(response.user!);
    } catch (e) {
      throw AuthException('Email sign-in failed: $e');
    }
  }

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) return null;

      final user = app_user.User.create(
        id: response.user!.id,
        email: email,
        displayName: displayName,
        photoUrl: response.user!.userMetadata?['avatar_url'],
      );

      await saveUserData(user);
      return user;
    } catch (e) {
      throw AuthException('Account creation failed: $e');
    }
  }

  @override
  Future<app_user.User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Google Sign-In
        final response = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'YOUR_REDIRECT_URL', // Configure this
        );
        return null; // Will be handled by redirect
      } else {
        // Mobile Google Sign-In - requires additional setup
        throw AuthException('Google Sign-In not implemented for mobile in Supabase service');
      }
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  // Reminder methods using Supabase Database
  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _client
          .from('reminders')
          .insert(reminder.toJson());
    } catch (e) {
      throw NetworkException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _client
          .from('reminders')
          .update(reminder.toJson())
          .eq('id', reminder.id);
    } catch (e) {
      throw NetworkException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _client
          .from('reminders')
          .delete()
          .eq('id', reminderId);
    } catch (e) {
      throw NetworkException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .order('date_time');

      return response.map((data) => Reminder.fromJson(data)).toList();
    } catch (e) {
      throw NetworkException('Failed to get reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    try {
      return _client
          .from('reminders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('date_time')
          .map((data) => data.map((item) => Reminder.fromJson(item)).toList());
    } catch (e) {
      throw NetworkException('Failed to get reminder stream: $e');
    }
  }

  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    try {
      // Use upsert to handle both insert and update
      await _client
          .from('reminders')
          .upsert(reminders.map((r) => r.toJson()).toList());
    } catch (e) {
      throw NetworkException('Failed to sync reminders: $e');
    }
  }

  // User data methods
  @override
  Future<void> saveUserData(app_user.User user) async {
    try {
      await _client
          .from('users')
          .upsert(user.toJson());
    } catch (e) {
      throw NetworkException('Failed to save user data: $e');
    }
  }

  @override
  Future<app_user.User?> getUserData(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return app_user.User.fromJson(response);
    } catch (e) {
      throw NetworkException('Failed to get user data: $e');
    }
  }

  // Helper methods
  app_user.User _convertSupabaseUser(User supabaseUser) {
    return app_user.User.create(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['display_name'] ?? 
                   supabaseUser.userMetadata?['full_name'] ?? 
                   'User',
      photoUrl: supabaseUser.userMetadata?['avatar_url'],
    );
  }
}