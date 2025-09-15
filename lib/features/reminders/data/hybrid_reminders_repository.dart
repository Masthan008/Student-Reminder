import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../domain/reminder.dart';
import '../../../shared/services/firebase_service.dart';
import '../../../shared/services/local_storage_service.dart';
import '../../../shared/providers/firebase_provider.dart';
import '../../../shared/providers/storage_provider.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/models/offline_action.dart';

abstract class HybridRemindersRepository {
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String reminderId);
  Future<List<Reminder>> getReminders(String userId);
  Stream<List<Reminder>> getReminderStream(String userId);
  Future<void> syncRemindersWithCloud(String userId);
  Future<void> initializeLocalReminders(String userId);
}

class HybridRemindersRepositoryImpl implements HybridRemindersRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  HybridRemindersRepositoryImpl(this._firebaseService, this._localStorageService);

  @override
  Future<void> addReminder(Reminder reminder) async {
    try {
      // Save to local storage first (offline-first approach)
      await _localStorageService.addReminder(reminder);
      
      // Try to save to cloud
      try {
        await _firebaseService.addReminder(reminder);
      } catch (e) {
        // If cloud save fails, add to offline queue
        final action = OfflineAction.create(
          type: ActionType.create,
          data: reminder.toJson(),
          entityType: 'reminder',
          entityId: reminder.id,
        );
        await _localStorageService.addOfflineAction(action);
        
        if (kDebugMode) {
          print('Added reminder to offline queue: ${reminder.title}');
        }
      }
    } catch (e) {
      throw NetworkException('Failed to add reminder: $e');
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    try {
      // Update in local storage first
      await _localStorageService.updateReminder(reminder);
      
      // Try to update in cloud
      try {
        await _firebaseService.updateReminder(reminder);
      } catch (e) {
        // If cloud update fails, add to offline queue
        final action = OfflineAction.create(
          type: ActionType.update,
          data: reminder.toJson(),
          entityType: 'reminder',
          entityId: reminder.id,
        );
        await _localStorageService.addOfflineAction(action);
        
        if (kDebugMode) {
          print('Updated reminder added to offline queue: ${reminder.title}');
        }
      }
    } catch (e) {
      throw NetworkException('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    try {
      // Delete from local storage first
      await _localStorageService.deleteReminder(reminderId);
      
      // Try to delete from cloud
      try {
        await _firebaseService.deleteReminder(reminderId);
      } catch (e) {
        // If cloud delete fails, add to offline queue
        final action = OfflineAction.create(
          type: ActionType.delete,
          data: {'id': reminderId},
          entityType: 'reminder',
          entityId: reminderId,
        );
        await _localStorageService.addOfflineAction(action);
        
        if (kDebugMode) {
          print('Delete reminder added to offline queue: $reminderId');
        }
      }
    } catch (e) {
      throw NetworkException('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      // First, try to get from local storage (for fast initial load)
      List<Reminder> localReminders = [];
      try {
        localReminders = await _localStorageService.getReminders();
        // Filter by user ID
        localReminders = localReminders.where((r) => r.userId == userId).toList();
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not load local reminders: $e');
        }
      }
      
      // Then try to get from cloud
      try {
        final cloudReminders = await _firebaseService.getReminders(userId);
        
        // Update local storage with cloud data
        await _localStorageService.saveReminders(cloudReminders);
        
        return cloudReminders;
      } catch (e) {
        // If cloud fails, return local data
        if (kDebugMode) {
          print('Warning: Could not load cloud reminders, using local data: $e');
        }
        return localReminders;
      }
    } catch (e) {
      throw NetworkException('Failed to get reminders: $e');
    }
  }

  @override
  Stream<List<Reminder>> getReminderStream(String userId) {
    try {
      // Return cloud stream, but also update local storage
      return _firebaseService.getReminderStream(userId).map((reminders) {
        // Update local storage with latest data
        _localStorageService.saveReminders(reminders).catchError((e) {
          if (kDebugMode) {
            print('Warning: Could not update local reminders: $e');
          }
        });
        return reminders;
      });
    } catch (e) {
      throw NetworkException('Failed to get reminder stream: $e');
    }
  }

  @override
  Future<void> syncRemindersWithCloud(String userId) async {
    try {
      // Get local reminders
      final localReminders = await _localStorageService.getReminders();
      final userReminders = localReminders.where((r) => r.userId == userId).toList();
      
      // Sync with cloud
      await _firebaseService.syncReminders(userReminders);
      
      // Process offline queue
      await _processOfflineQueue();
      
      if (kDebugMode) {
        print('Successfully synced ${userReminders.length} reminders with cloud');
      }
    } catch (e) {
      throw NetworkException('Failed to sync reminders with cloud: $e');
    }
  }

  @override
  Future<void> initializeLocalReminders(String userId) async {
    try {
      // Load reminders from local storage first for immediate display
      final localReminders = await _localStorageService.getReminders();
      
      // Then sync with cloud in background
      try {
        final cloudReminders = await _firebaseService.getReminders(userId);
        
        // If cloud has more recent data, update local storage
        if (_hasMoreRecentData(cloudReminders, localReminders)) {
          await _localStorageService.saveReminders(cloudReminders);
        }
      } catch (e) {
        // Cloud sync failed, continue with local data
        if (kDebugMode) {
          print('Warning: Could not sync with cloud during initialization: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not initialize local reminders: $e');
      }
    }
  }

  // Helper method to process offline actions
  Future<void> _processOfflineQueue() async {
    try {
      final actions = await _localStorageService.getOfflineQueue();
      
      for (final action in actions) {
        try {
          switch (action.type) {
            case ActionType.create:
              final reminder = Reminder.fromJson(action.data as Map<String, dynamic>);
              await _firebaseService.addReminder(reminder);
              break;
            case ActionType.update:
              final reminder = Reminder.fromJson(action.data as Map<String, dynamic>);
              await _firebaseService.updateReminder(reminder);
              break;
            case ActionType.delete:
              final id = action.data['id'] as String;
              await _firebaseService.deleteReminder(id);
              break;
          }
          
          // Remove action from queue if successful
          await _localStorageService.removeOfflineAction(action.id);
        } catch (e) {
          // Keep action in queue for retry
          if (kDebugMode) {
            print('Failed to process offline action ${action.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not process offline queue: $e');
      }
    }
  }

  // Helper method to check if cloud data is more recent
  bool _hasMoreRecentData(List<Reminder> cloudReminders, List<Reminder> localReminders) {
    if (cloudReminders.isEmpty && localReminders.isEmpty) return false;
    if (cloudReminders.isEmpty) return false;
    if (localReminders.isEmpty) return true;
    
    // Compare the most recent update times
    final latestCloudUpdate = cloudReminders
        .map((r) => r.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
        
    final latestLocalUpdate = localReminders
        .map((r) => r.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
        
    return latestCloudUpdate.isAfter(latestLocalUpdate);
  }
}

// Provider for the hybrid reminders repository
final hybridRemindersRepositoryProvider = Provider<HybridRemindersRepository>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  final localStorageService = ref.read(localStorageServiceProvider);
  return HybridRemindersRepositoryImpl(firebaseService, localStorageService);
});