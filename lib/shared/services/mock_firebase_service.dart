import '../services/firebase_service.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart';

/// Mock Firebase service for demo/offline mode
class MockFirebaseService implements FirebaseService {
  User? _currentUser;
  final List<Reminder> _reminders = [];
  final Map<String, User> _users = {};

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<User?> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = User.create(
      id: 'demo_google_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'demo.user@gmail.com',
      displayName: 'Demo Google User',
      photoUrl: null,
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    final user = User.create(
      id: 'demo_email_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@')[0].replaceAll('.', ' ').toUpperCase(),
      photoUrl: null,
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User?> createUserWithEmail(String email, String password, String displayName) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Basic validation
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      throw Exception('All fields are required');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    final user = User.create(
      id: 'demo_new_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      photoUrl: null,
    );
    
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    _reminders.add(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    _reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _reminders.clear();
    _reminders.addAll(reminders);
  }

  @override
  Future<void> saveUserData(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    _users[user.id] = user;
  }

  @override
  Future<User?> getUserData(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    return _users[userId];
  }
}