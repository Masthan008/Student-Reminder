import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/reminders/data/hybrid_reminders_repository.dart';
import '../services/notification_service.dart';
import '../providers/firebase_provider.dart';
import '../providers/storage_provider.dart';
import '../services/local_storage_service.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  final NotificationService _notificationService;
  final HybridRemindersRepository _remindersRepository;
  
  ReminderNotifier(this._notificationService, this._remindersRepository) : super([]);
  
  // Load reminders from local storage when initialized
  Future<void> loadReminders(String userId) async {
    try {
      // Initialize local reminders for immediate display
      await _remindersRepository.initializeLocalReminders(userId);
      
      // Load reminders from local storage
      final localStorageService = HiveLocalStorageService();
      await localStorageService.initialize();
      final localReminders = await localStorageService.getReminders();
      final userReminders = localReminders.where((r) => r.userId == userId).toList();
      
      state = userReminders;
      
      if (kDebugMode) {
        print('Loaded ${userReminders.length} reminders from local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reminders: $e');
      }
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    state = [...state, reminder];
    
    // Add to repository (handles both local and cloud storage)
    await _remindersRepository.addReminder(reminder);
    
    // Schedule notification for the reminder
    try {
      await _notificationService.scheduleLocalNotification(reminder);
      if (kDebugMode) {
        print('📅 Notification scheduled for: ${reminder.title} at ${reminder.dateTime}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to schedule notification: $e');
      }
    }
  }

  Future<void> updateReminder(Reminder updatedReminder) async {
    // Cancel existing notification
    try {
      await _notificationService.cancelNotification(updatedReminder.id);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel existing notification: $e');
      }
    }
    
    state = [
      for (final reminder in state)
        if (reminder.id == updatedReminder.id)
          updatedReminder
        else
          reminder,
    ];
    
    // Update in repository (handles both local and cloud storage)
    await _remindersRepository.updateReminder(updatedReminder);
    
    // Schedule new notification if not completed
    if (!updatedReminder.isCompleted) {
      try {
        await _notificationService.scheduleLocalNotification(updatedReminder);
        if (kDebugMode) {
          print('📅 Notification rescheduled for: ${updatedReminder.title} at ${updatedReminder.dateTime}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to reschedule notification: $e');
        }
      }
    }
  }

  Future<void> deleteReminder(String id) async {
    // Cancel notification for the reminder
    try {
      await _notificationService.cancelNotification(id);
      if (kDebugMode) {
        print('❌ Notification cancelled for reminder: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cancel notification: $e');
      }
    }
    
    state = state.where((reminder) => reminder.id != id).toList();
    
    // Delete from repository (handles both local and cloud storage)
    await _remindersRepository.deleteReminder(id);
  }

  void toggleComplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: !reminder.isCompleted)
        else
          reminder,
    ];
  }

  void markComplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: true)
        else
          reminder,
    ];
  }

  void markIncomplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: false)
        else
          reminder,
    ];
  }

  List<Reminder> getRemindersByDate(DateTime date) {
    return state.where((reminder) {
      final reminderDate = DateTime(
        reminder.dateTime.year,
        reminder.dateTime.month,
        reminder.dateTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return reminderDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<Reminder> getTodayReminders() {
    final today = DateTime.now();
    return getRemindersByDate(today);
  }

  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    return state.where((reminder) => 
        reminder.dateTime.isAfter(now) && !reminder.isCompleted).toList();
  }

  List<Reminder> getOverdueReminders() {
    final now = DateTime.now();
    return state.where((reminder) => 
        reminder.dateTime.isBefore(now) && !reminder.isCompleted).toList();
  }

  List<Reminder> getCompletedReminders() {
    return state.where((reminder) => reminder.isCompleted).toList();
  }
  
  // Method to sync reminders with cloud
  Future<void> syncWithCloud(String userId) async {
    await _remindersRepository.syncRemindersWithCloud(userId);
  }
}

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});

// Hybrid reminders repository provider
final hybridRemindersRepositoryProvider = Provider<HybridRemindersRepository>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  final localStorageService = ref.read(localStorageServiceProvider);
  return HybridRemindersRepositoryImpl(firebaseService, localStorageService);
});

final remindersProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  final remindersRepository = ref.read(hybridRemindersRepositoryProvider);
  return ReminderNotifier(notificationService, remindersRepository);
});

// Computed providers for different reminder categories
final todayRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final today = DateTime.now();
  return reminders.where((reminder) {
    final reminderDate = DateTime(
      reminder.dateTime.year,
      reminder.dateTime.month,
      reminder.dateTime.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return reminderDate.isAtSameMomentAs(todayDate) && !reminder.isCompleted;
  }).toList();
});

final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final now = DateTime.now();
  return reminders.where((reminder) => 
      reminder.dateTime.isAfter(now) && !reminder.isCompleted).toList();
});

final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final now = DateTime.now();
  return reminders.where((reminder) => 
      reminder.dateTime.isBefore(now) && !reminder.isCompleted).toList();
});

final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.where((reminder) => reminder.isCompleted).toList();
});