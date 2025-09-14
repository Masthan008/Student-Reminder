import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:student_reminder_app/shared/services/local_storage_service.dart';
import 'package:student_reminder_app/features/reminders/domain/reminder.dart';
import 'package:student_reminder_app/features/auth/domain/user.dart';
import 'package:student_reminder_app/core/models/offline_action.dart';

void main() {
  group('HiveLocalStorageService', () {
    late HiveLocalStorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('./test/hive_test_db');
    });

    setUp(() async {
      storageService = HiveLocalStorageService();
      await storageService.initialize();
    });

    tearDown(() async {
      await storageService.clearAllData();
      await storageService.close();
    });

    group('Reminder Operations', () {
      test('should save and retrieve reminders', () async {
        // Arrange
        final reminder = Reminder.create(
          title: 'Test Reminder',
          description: 'Test Description',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        // Act
        await storageService.addReminder(reminder);
        final retrievedReminders = await storageService.getReminders();

        // Assert
        expect(retrievedReminders.length, 1);
        expect(retrievedReminders.first.title, 'Test Reminder');
        expect(retrievedReminders.first.description, 'Test Description');
      });

      test('should update existing reminder', () async {
        // Arrange
        final reminder = Reminder.create(
          title: 'Original Title',
          description: 'Original Description',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        await storageService.addReminder(reminder);

        // Act
        final updatedReminder = reminder.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
        );
        await storageService.updateReminder(updatedReminder);

        final retrievedReminders = await storageService.getReminders();

        // Assert
        expect(retrievedReminders.length, 1);
        expect(retrievedReminders.first.title, 'Updated Title');
        expect(retrievedReminders.first.description, 'Updated Description');
      });

      test('should delete reminder', () async {
        // Arrange
        final reminder = Reminder.create(
          title: 'Test Reminder',
          description: 'Test Description',
          dateTime: DateTime.now().add(const Duration(days: 1)),
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        await storageService.addReminder(reminder);

        // Act
        await storageService.deleteReminder(reminder.id);
        final retrievedReminders = await storageService.getReminders();

        // Assert
        expect(retrievedReminders.length, 0);
      });

      test('should get reminders by date', () async {
        // Arrange
        final today = DateTime(2024, 1, 15, 10, 0); // Fixed date for testing
        final tomorrow = DateTime(2024, 1, 16, 14, 30); // Different date

        final todayReminder = Reminder.create(
          title: 'Today Reminder',
          description: 'Today Description',
          dateTime: today,
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        await storageService.addReminder(todayReminder);
        
        // Add a small delay to ensure different IDs
        await Future.delayed(const Duration(milliseconds: 10));

        final tomorrowReminder = Reminder.create(
          title: 'Tomorrow Reminder',
          description: 'Tomorrow Description',
          dateTime: tomorrow,
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        await storageService.addReminder(tomorrowReminder);

        // Act
        final todayReminders = await storageService.getRemindersByDate(today);

        // Assert
        expect(todayReminders.length, 1);
        expect(todayReminders.first.title, 'Today Reminder');
      });
    });

    group('User Operations', () {
      test('should save and retrieve user', () async {
        // Arrange
        final user = User.create(
          id: 'test_user_id',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        // Act
        await storageService.saveUser(user);
        final retrievedUser = await storageService.getUser();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.email, 'test@example.com');
        expect(retrievedUser.displayName, 'Test User');
      });

      test('should clear user', () async {
        // Arrange
        final user = User.create(
          id: 'test_user_id',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        await storageService.saveUser(user);

        // Act
        await storageService.clearUser();
        final retrievedUser = await storageService.getUser();

        // Assert
        expect(retrievedUser, isNull);
      });
    });

    group('Offline Queue Operations', () {
      test('should save and retrieve offline actions', () async {
        // Arrange
        final action = OfflineAction.create(
          type: ActionType.create,
          data: {'test': 'data'},
          entityType: 'reminder',
          entityId: 'test_id',
        );

        // Act
        await storageService.addOfflineAction(action);
        final retrievedActions = await storageService.getOfflineQueue();

        // Assert
        expect(retrievedActions.length, 1);
        expect(retrievedActions.first.type, ActionType.create);
        expect(retrievedActions.first.entityType, 'reminder');
      });

      test('should remove offline action', () async {
        // Arrange
        final action = OfflineAction.create(
          type: ActionType.create,
          data: {'test': 'data'},
          entityType: 'reminder',
          entityId: 'test_id',
        );

        await storageService.addOfflineAction(action);

        // Act
        await storageService.removeOfflineAction(action.id);
        final retrievedActions = await storageService.getOfflineQueue();

        // Assert
        expect(retrievedActions.length, 0);
      });

      test('should clear offline queue', () async {
        // Arrange
        final action1 = OfflineAction.create(
          type: ActionType.create,
          data: {'test': 'data1'},
          entityType: 'reminder',
          entityId: 'test_id_1',
        );

        final action2 = OfflineAction.create(
          type: ActionType.update,
          data: {'test': 'data2'},
          entityType: 'reminder',
          entityId: 'test_id_2',
        );

        await storageService.addOfflineAction(action1);
        await storageService.addOfflineAction(action2);

        // Act
        await storageService.clearOfflineQueue();
        final retrievedActions = await storageService.getOfflineQueue();

        // Assert
        expect(retrievedActions.length, 0);
      });
    });

    group('Settings Operations', () {
      test('should save and retrieve settings', () async {
        // Act
        await storageService.saveSetting('test_key', 'test_value');
        final retrievedValue = await storageService.getSetting<String>('test_key');

        // Assert
        expect(retrievedValue, 'test_value');
      });

      test('should save and retrieve theme mode', () async {
        // Act
        await storageService.saveThemeMode('dark');
        final retrievedThemeMode = await storageService.getThemeMode();

        // Assert
        expect(retrievedThemeMode, 'dark');
      });

      test('should return null for non-existent setting', () async {
        // Act
        final retrievedValue = await storageService.getSetting<String>('non_existent_key');

        // Assert
        expect(retrievedValue, isNull);
      });
    });
  });
}