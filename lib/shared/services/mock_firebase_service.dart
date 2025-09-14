import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart' as app_user;
import '../../core/errors/exceptions.dart';
import 'firebase_service.dart';

/// Mock Firebase service for development/demo purposes
/// This allows the app to work without real Firebase configuration
class MockFirebaseService implements FirebaseService {
  app_user.User? _currentUser;
  final List<Reminder> _reminders = [];
  final Map<String, app_user.User> _users = {};

  @override
  app_user.User? get currentUser => _currentUser;

  @override
  Stream<app_user.User?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<app_user.User?> signInWithGoogle() async {
    // Simulate Google sign-in delay
    await Future.delayed(const Duration(seconds: 1));
    
    final user = app_user.User.create(
      id: 'mock_google_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'demo@gmail.com',
      displayName: 'Demo User (Google)',
      photoUrl: 'https://via.placeholder.com/150',
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) async {
    // Simulate email sign-in delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }
    if (!email.contains('@')) {
      throw const AuthException('Please enter a valid email address');
    }

    final user = app_user.User.create(
      id: 'mock_email_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@')[0], // Use email prefix as display name
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) async {
    // Simulate account creation delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Basic validation
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      throw const AuthException('All fields are required');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }
    if (!email.contains('@')) {
      throw const AuthException('Please enter a valid email address');
    }

    final user = app_user.User.create(
      id: 'mock_new_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    // Simulate sign-out delay
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _reminders.add(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
    } else {
      throw const NetworkException('Reminder not found');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _reminders.where((r) => r.userId == userId).toList();
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _reminders.where((r) => r.userId == userId).toList();
    });
  }

  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 1));
    
    _reminders.clear();
    _reminders.addAll(reminders);
  }

  @override
  Future<void> saveUserData(app_user.User user) async {
    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 200));
    _users[user.id] = user;
  }

  @override
  Future<app_user.User?> getUserData(String userId) async {
    // Simulate fetch delay
    await Future.delayed(const Duration(milliseconds: 200));
    return _users[userId];
  }
}