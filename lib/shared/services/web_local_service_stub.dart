// Stub implementation for mobile platforms
import 'firebase_service.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart' as app_user;

/// Stub implementation of WebLocalService for mobile platforms
/// This should never be used since mobile platforms use the mobile backend service
class WebLocalService implements FirebaseService {
  WebLocalService() {
    throw UnsupportedError('WebLocalService is only available on web platforms');
  }

  @override
  Stream<app_user.User?> get authStateChanges => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  app_user.User? get currentUser => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<app_user.User?> signInWithEmail(String email, String password) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<app_user.User?> createUserWithEmail(String email, String password, String displayName) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<app_user.User?> signInWithGoogle() => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> signOut() => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> addReminder(Reminder reminder) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> updateReminder(Reminder reminder) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> deleteReminder(String reminderId) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<List<Reminder>> getReminders(String userId) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Stream<List<Reminder>> getReminderStream(String userId) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> syncReminders(List<Reminder> reminders) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<void> saveUserData(app_user.User user) => throw UnsupportedError('WebLocalService is only available on web platforms');

  @override
  Future<app_user.User?> getUserData(String userId) => throw UnsupportedError('WebLocalService is only available on web platforms');
}