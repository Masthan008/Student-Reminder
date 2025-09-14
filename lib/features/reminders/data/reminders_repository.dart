import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reminder.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/providers/firebase_provider.dart';
import '../../../core/errors/exceptions.dart';

abstract class RemindersRepository {
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String reminderId);
  Future<List<Reminder>> getReminders(String userId);
  Stream<List<Reminder>> getReminderStream(String userId);
  Future<void> syncReminders(List<Reminder> reminders);
}

class RemindersRepositoryImpl implements RemindersRepository {
  final FirebaseService _firebaseService;

  RemindersRepositoryImpl(this._firebaseService);

  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _firebaseService.addReminder(reminder);
    } catch (e) {
      throw NetworkException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _firebaseService.updateReminder(reminder);
    } catch (e) {
      throw NetworkException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firebaseService.deleteReminder(reminderId);
    } catch (e) {
      throw NetworkException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      return await _firebaseService.getReminders(userId);
    } catch (e) {
      throw NetworkException('Failed to get reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    try {
      return _firebaseService.getReminderStream(userId);
    } catch (e) {
      throw NetworkException('Failed to get reminder stream: $e');
    }
  }

  @override
  Future<void> syncReminders(List<Reminder> reminders) async {
    try {
      await _firebaseService.syncReminders(reminders);
    } catch (e) {
      throw NetworkException('Failed to sync reminders: $e');
    }
  }
}

// Provider for the reminders repository
final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return RemindersRepositoryImpl(firebaseService);
});