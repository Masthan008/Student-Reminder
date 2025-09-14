import 'package:flutter_test/flutter_test.dart';
import 'package:student_reminder_app/shared/services/firebase_service.dart';
import 'package:student_reminder_app/features/reminders/domain/reminder.dart';
import 'package:student_reminder_app/features/auth/domain/user.dart';
import 'package:student_reminder_app/core/errors/exceptions.dart';

// Mock implementation for testing without Firebase
class MockFirebaseService implements FirebaseService {
  final List<Reminder> _reminders = [];
  final Map<String, User> _users = {};
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<User?> signInWithGoogle() async {
    // Mock successful Google sign-in
    final user = User.create(
      id: 'mock_google_user_id',
      email: 'test@gmail.com',
      displayName: 'Test Google User',
    );
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    // Mock email sign-in validation
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    final user = User.create(
      id: 'mock_email_user_id',
      email: email,
      displayName: 'Test Email User',
    );
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User?> createUserWithEmail(String email, String password, String displayName) async {
    // Mock account creation validation
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      throw const AuthException('All fields are required');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    final user = User.create(
      id: 'mock_new_user_id',
      email: email,
      displayName: displayName,
    );
    _currentUser = user;
    _users[user.id] = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
    } else {
      throw const NetworkException('Reminder not found');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    return _reminders.where((r) => r.userId == userId).toList();
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    return Stream.value(_reminders.where((r) => r.userId == userId).toList());
  }

  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    _reminders.clear();
    _reminders.addAll(reminders);
  }

  @override
  Future<void> saveUserData(User user) async {
    _users[user.id] = user;
  }

  @override
  Future<User?> getUserData(String userId) async {
    return _users[userId];
  }
}

void main() {
  group('FirebaseService', () {
    late MockFirebaseService firebaseService;

    setUp(() {
      firebaseService = MockFirebaseService();
    });

    group('Authentication', () {
      test('should sign in with Google successfully', () async {
        // Act
        final user = await firebaseService.signInWithGoogle();

        // Assert
        expect(user, isNotNull);
        expect(user!.email, 'test@gmail.com');
        expect(user.displayName, 'Test Google User');
        expect(firebaseService.currentUser, isNotNull);
      });

      test('should sign in with email successfully', () async {
        // Act
        final user = await firebaseService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(user, isNotNull);
        expect(user!.email, 'test@example.com');
        expect(firebaseService.currentUser, isNotNull);
      });

      test('should throw exception for invalid email sign-in', () async {
        // Act & Assert
        expect(
          () => firebaseService.signInWithEmail('', 'password'),
          throwsA(isA<AuthException>()),
        );

        expect(
          () => firebaseService.signInWithEmail('test@example.com', '123'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should create account successfully', () async {
        // Act
        final user = await firebaseService.createUserWithEmail(
          'newuser@example.com',
          'password123',
          'New User',
        );

        // Assert
        expect(user, isNotNull);
        expect(user!.email, 'newuser@example.com');
        expect(user.displayName, 'New User');
      });

      test('should throw exception for invalid account creation', () async {
        // Act & Assert
        expect(
          () => firebaseService.createUserWithEmail('', 'password', 'Name'),
          throwsA(isA<AuthException>()),
        );

        expect(
          () => firebaseService.createUserWithEmail('test@example.com', '123', 'Name'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should sign out successfully', () async {
        // Arrange
        await firebaseService.signInWithGoogle();
        expect(firebaseService.currentUser, isNotNull);

        // Act
        await firebaseService.signOut();

        // Assert
        expect(firebaseService.currentUser, isNull);
      });
    });

    group('Reminders', () {
      late User testUser;
      late Reminder testReminder;

      setUp(() async {
        testUser = (await firebaseService.signInWithGoogle())!;
        testReminder = Reminder.create(
          title: 'Test Reminder',
          description: 'Test Description',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          repeatOption: RepeatOption.none,
          userId: testUser.id,
        );
      });

      test('should add reminder successfully', () async {
        // Act
        await firebaseService.addReminder(testReminder);
        final reminders = await firebaseService.getReminders(testUser.id);

        // Assert
        expect(reminders.length, 1);
        expect(reminders.first.title, 'Test Reminder');
      });

      test('should update reminder successfully', () async {
        // Arrange
        await firebaseService.addReminder(testReminder);
        final updatedReminder = testReminder.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
        );

        // Act
        await firebaseService.updateReminder(updatedReminder);
        final reminders = await firebaseService.getReminders(testUser.id);

        // Assert
        expect(reminders.length, 1);
        expect(reminders.first.title, 'Updated Title');
        expect(reminders.first.description, 'Updated Description');
      });

      test('should delete reminder successfully', () async {
        // Arrange
        await firebaseService.addReminder(testReminder);

        // Act
        await firebaseService.deleteReminder(testReminder.id);
        final reminders = await firebaseService.getReminders(testUser.id);

        // Assert
        expect(reminders.length, 0);
      });

      test('should sync reminders successfully', () async {
        // Arrange
        final reminders = [
          testReminder,
          Reminder.create(
            title: 'Second Reminder',
            description: 'Second Description',
            dateTime: DateTime.now().add(const Duration(days: 2)),
            repeatOption: RepeatOption.daily,
            userId: testUser.id,
          ),
        ];

        // Act
        await firebaseService.syncReminders(reminders);
        final syncedReminders = await firebaseService.getReminders(testUser.id);

        // Assert
        expect(syncedReminders.length, 2);
        expect(syncedReminders.any((r) => r.title == 'Test Reminder'), true);
        expect(syncedReminders.any((r) => r.title == 'Second Reminder'), true);
      });

      test('should get reminder stream', () async {
        // Arrange
        await firebaseService.addReminder(testReminder);

        // Act
        final stream = firebaseService.getReminderStream(testUser.id);
        final reminders = await stream.first;

        // Assert
        expect(reminders.length, 1);
        expect(reminders.first.title, 'Test Reminder');
      });
    });

    group('User Data', () {
      test('should save and retrieve user data', () async {
        // Arrange
        final user = User.create(
          id: 'test_user_id',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        // Act
        await firebaseService.saveUserData(user);
        final retrievedUser = await firebaseService.getUserData(user.id);

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.email, 'test@example.com');
        expect(retrievedUser.displayName, 'Test User');
      });

      test('should return null for non-existent user', () async {
        // Act
        final user = await firebaseService.getUserData('non_existent_id');

        // Assert
        expect(user, isNull);
      });
    });
  });
}