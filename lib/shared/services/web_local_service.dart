import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart' as app_user;
import '../../core/errors/exceptions.dart';
import 'firebase_service.dart';

// Use universal_html for cross-platform compatibility
import 'package:universal_html/html.dart' as html;

/// Web-specific service that provides local storage functionality
/// without requiring authentication for web applications
class WebLocalService implements FirebaseService {
  static final WebLocalService _instance = WebLocalService._internal();
  factory WebLocalService() => _instance;
  WebLocalService._internal();

  static const String _remindersKey = 'student_reminder_data';
  static const String _userKey = 'student_reminder_user';

  // In-memory storage for web with localStorage persistence
  List<Reminder> _reminders = [];
  final app_user.User _webUser = app_user.User.create(
    id: 'web_user_local',
    email: 'web@local.app',
    displayName: 'Web User',
    photoUrl: null,
  );

  /// Initialize and load data from localStorage
  Future<void> initialize() async {
    await _loadRemindersFromStorage();
    if (_reminders.isEmpty) {
      addDemoReminders();
      // Save demo reminders immediately
      await _saveRemindersToStorage();
    }
    if (kDebugMode) {
      print('Web Local Service initialized with ${_reminders.length} reminders');
    }
  }

  /// Load reminders from browser localStorage
  Future<void> _loadRemindersFromStorage() async {
    try {
      final remindersJson = html.window.localStorage[_remindersKey];
      if (remindersJson != null && remindersJson.isNotEmpty) {
        final List<dynamic> remindersList = jsonDecode(remindersJson);
        _reminders = remindersList
            .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          print('Web Local: Loaded ${_reminders.length} reminders from localStorage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Web Local: Error loading reminders from localStorage: $e');
      }
      _reminders = [];
    }
  }

  /// Save reminders to browser localStorage
  Future<void> _saveRemindersToStorage() async {
    try {
      final remindersJson = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      html.window.localStorage[_remindersKey] = remindersJson;
      if (kDebugMode) {
        print('Web Local: Saved ${_reminders.length} reminders to localStorage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Web Local: Error saving reminders to localStorage: $e');
      }
    }
  }

  // Authentication methods (simplified for web)
  @override
  Stream<app_user.User?> get authStateChanges {
    // For web, always return the local user
    return Stream.value(_webUser);
  }

  @override
  app_user.User? get currentUser => _webUser;

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    // For web, always succeed with local user
    return _webUser;
  }

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) async {
    // For web, always succeed with local user
    return _webUser;
  }

  @override
  Future<app_user.User?> signInWithGoogle() async {
    // For web, not supported but return local user
    return _webUser;
  }

  @override
  Future<void> signOut() async {
    // For web, do nothing
    return;
  }

  // Reminder methods using localStorage persistence
  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      _reminders.add(reminder);
      await _saveRemindersToStorage();
      if (kDebugMode) {
        print('Web Local: Added reminder ${reminder.title}');
      }
    } catch (e) {
      throw NetworkException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
        await _saveRemindersToStorage();
        if (kDebugMode) {
          print('Web Local: Updated reminder ${reminder.title}');
        }
      }
    } catch (e) {
      throw NetworkException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      _reminders.removeWhere((r) => r.id == reminderId);
      await _saveRemindersToStorage();
      if (kDebugMode) {
        print('Web Local: Deleted reminder $reminderId');
      }
    } catch (e) {
      throw NetworkException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      // Return all reminders for web (no user filtering needed)
      return List.from(_reminders);
    } catch (e) {
      throw NetworkException('Failed to get reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    try {
      // Create a stream controller for real-time updates
      late StreamController<List<Reminder>> controller;
      
      controller = StreamController<List<Reminder>>(
        onListen: () {
          // Emit current reminders immediately
          controller.add(List.from(_reminders));
          
          // Set up periodic checks for changes (simulating real-time)
          Timer.periodic(const Duration(seconds: 2), (timer) {
            if (controller.isClosed) {
              timer.cancel();
              return;
            }
            controller.add(List.from(_reminders));
          });
        },
        onCancel: () => controller.close(),
      );
      
      return controller.stream;
    } catch (e) {
      throw NetworkException('Failed to get reminder stream: $e');
    }
  }

  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    try {
      _reminders.clear();
      _reminders.addAll(reminders);
      await _saveRemindersToStorage();
      if (kDebugMode) {
        print('Web Local: Synced ${reminders.length} reminders');
      }
    } catch (e) {
      throw NetworkException('Failed to sync reminders: $e');
    }
  }

  // User data methods (simplified for web)
  @override
  Future<void> saveUserData(app_user.User user) async {
    // For web, do nothing
    return;
  }

  @override
  Future<app_user.User?> getUserData(String userId) async {
    // For web, always return the local user
    return _webUser;
  }

  /// Add some demo reminders for web users
  void addDemoReminders() {
    if (_reminders.isEmpty) {
      final now = DateTime.now();
      
      _reminders.addAll([
        Reminder.create(
          title: 'Welcome to Student Reminder!',
          description: 'This is a demo reminder. You can create, edit, and delete reminders.',
          dateTime: now.add(const Duration(hours: 1)),
          repeatOption: RepeatOption.none,
          userId: _webUser.id,
        ),
        Reminder.create(
          title: 'Study Session',
          description: 'Review notes for upcoming exam',
          dateTime: now.add(const Duration(days: 1)),
          repeatOption: RepeatOption.none,
          userId: _webUser.id,
        ),
        Reminder.create(
          title: 'Assignment Due',
          description: 'Submit final project report',
          dateTime: now.add(const Duration(days: 3)),
          repeatOption: RepeatOption.none,
          userId: _webUser.id,
        ),
      ]);
      
      if (kDebugMode) {
        print('Web Local: Added ${_reminders.length} demo reminders');
      }
    }
  }
}