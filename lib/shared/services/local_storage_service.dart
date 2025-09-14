import 'package:hive_flutter/hive_flutter.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/auth/domain/user.dart';
import '../../core/models/offline_action.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

abstract class LocalStorageService {
  // Reminder operations
  Future<void> saveReminders(List<Reminder> reminders);
  Future<List<Reminder>> getReminders();
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<List<Reminder>> getRemindersByDate(DateTime date);
  
  // User operations
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> clearUser();
  
  // Offline queue operations
  Future<void> saveOfflineQueue(List<OfflineAction> actions);
  Future<List<OfflineAction>> getOfflineQueue();
  Future<void> addOfflineAction(OfflineAction action);
  Future<void> removeOfflineAction(String actionId);
  Future<void> clearOfflineQueue();
  
  // Settings operations
  Future<void> saveThemeMode(String themeMode);
  Future<String?> getThemeMode();
  Future<void> saveSetting(String key, dynamic value);
  Future<T?> getSetting<T>(String key);
  
  // Initialization and cleanup
  Future<void> initialize();
  Future<void> close();
  Future<void> clearAllData();
}

class HiveLocalStorageService implements LocalStorageService {
  Box<Reminder>? _reminderBox;
  Box<User>? _userBox;
  Box<OfflineAction>? _offlineQueueBox;
  Box? _settingsBox;

  @override
  Future<void> initialize() async {
    try {
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(RepeatOptionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ReminderAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ActionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(OfflineActionAdapter());
      }

      // Open boxes
      _reminderBox = await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      _userBox = await Hive.openBox<User>(AppConstants.userBoxName);
      _offlineQueueBox = await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    } catch (e) {
      throw StorageException('Failed to initialize local storage: $e');
    }
  }

  // Reminder operations
  @override
  Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      final box = _reminderBox ?? await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      await box.clear();
      for (final reminder in reminders) {
        await box.put(reminder.id, reminder);
      }
    } catch (e) {
      throw StorageException('Failed to save reminders: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders() async {
    try {
      final box = _reminderBox ?? await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      return box.values.toList();
    } catch (e) {
      throw StorageException('Failed to get reminders: $e');
    }
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      final box = _reminderBox ?? await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      await box.put(reminder.id, reminder);
    } catch (e) {
      throw StorageException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final box = _reminderBox ?? await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      await box.put(reminder.id, reminder);
    } catch (e) {
      throw StorageException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    try {
      final box = _reminderBox ?? await Hive.openBox<Reminder>(AppConstants.reminderBoxName);
      await box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    try {
      final allReminders = await getReminders();
      final targetDate = DateTime(date.year, date.month, date.day);
      
      return allReminders.where((reminder) {
        final reminderDate = DateTime(
          reminder.dateTime.year,
          reminder.dateTime.month,
          reminder.dateTime.day,
        );
        return reminderDate.year == targetDate.year &&
               reminderDate.month == targetDate.month &&
               reminderDate.day == targetDate.day;
      }).toList();
    } catch (e) {
      throw StorageException('Failed to get reminders by date: $e');
    }
  }

  // User operations
  @override
  Future<void> saveUser(User user) async {
    try {
      final box = _userBox ?? await Hive.openBox<User>(AppConstants.userBoxName);
      await box.put('current_user', user);
    } catch (e) {
      throw StorageException('Failed to save user: $e');
    }
  }

  @override
  Future<User?> getUser() async {
    try {
      final box = _userBox ?? await Hive.openBox<User>(AppConstants.userBoxName);
      return box.get('current_user');
    } catch (e) {
      throw StorageException('Failed to get user: $e');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      final box = _userBox ?? await Hive.openBox<User>(AppConstants.userBoxName);
      await box.clear();
    } catch (e) {
      throw StorageException('Failed to clear user: $e');
    }
  }

  // Offline queue operations
  @override
  Future<void> saveOfflineQueue(List<OfflineAction> actions) async {
    try {
      final box = _offlineQueueBox ?? await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      await box.clear();
      for (final action in actions) {
        await box.put(action.id, action);
      }
    } catch (e) {
      throw StorageException('Failed to save offline queue: $e');
    }
  }

  @override
  Future<List<OfflineAction>> getOfflineQueue() async {
    try {
      final box = _offlineQueueBox ?? await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      return box.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      throw StorageException('Failed to get offline queue: $e');
    }
  }

  @override
  Future<void> addOfflineAction(OfflineAction action) async {
    try {
      final box = _offlineQueueBox ?? await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      await box.put(action.id, action);
    } catch (e) {
      throw StorageException('Failed to add offline action: $e');
    }
  }

  @override
  Future<void> removeOfflineAction(String actionId) async {
    try {
      final box = _offlineQueueBox ?? await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      await box.delete(actionId);
    } catch (e) {
      throw StorageException('Failed to remove offline action: $e');
    }
  }

  @override
  Future<void> clearOfflineQueue() async {
    try {
      final box = _offlineQueueBox ?? await Hive.openBox<OfflineAction>(AppConstants.offlineQueueBoxName);
      await box.clear();
    } catch (e) {
      throw StorageException('Failed to clear offline queue: $e');
    }
  }

  // Settings operations
  @override
  Future<void> saveThemeMode(String themeMode) async {
    await saveSetting(AppConstants.themeKey, themeMode);
  }

  @override
  Future<String?> getThemeMode() async {
    return await getSetting<String>(AppConstants.themeKey);
  }

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = _settingsBox ?? await Hive.openBox(AppConstants.settingsBoxName);
      await box.put(key, value);
    } catch (e) {
      throw StorageException('Failed to save setting: $e');
    }
  }

  @override
  Future<T?> getSetting<T>(String key) async {
    try {
      final box = _settingsBox ?? await Hive.openBox(AppConstants.settingsBoxName);
      return box.get(key) as T?;
    } catch (e) {
      throw StorageException('Failed to get setting: $e');
    }
  }

  // Cleanup operations
  @override
  Future<void> close() async {
    try {
      await _reminderBox?.close();
      await _userBox?.close();
      await _offlineQueueBox?.close();
      await _settingsBox?.close();
    } catch (e) {
      throw StorageException('Failed to close storage: $e');
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await _reminderBox?.clear();
      await _userBox?.clear();
      await _offlineQueueBox?.clear();
      await _settingsBox?.clear();
    } catch (e) {
      throw StorageException('Failed to clear all data: $e');
    }
  }
}