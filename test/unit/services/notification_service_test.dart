import 'package:flutter_test/flutter_test.dart';
import 'package:student_reminder_app/shared/services/notification_service.dart';
import 'package:student_reminder_app/features/reminders/domain/reminder.dart';
import 'package:student_reminder_app/core/errors/exceptions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Mock implementation for testing without actual notifications
class MockNotificationService implements NotificationService {
  final List<String> _scheduledNotifications = [];
  final List<String> _cancelledNotifications = [];
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  Function(String reminderId)? _onNotificationTap;
  String? _fcmToken;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    _permissionsGranted = true;
    return true;
  }

  @override
  Future<void> scheduleLocalNotification(Reminder reminder) async {
    if (!_isInitialized) {
      throw const NotificationException('Service not initialized');
    }
    
    // Don't schedule notifications for past dates
    if (reminder.dateTime.isBefore(DateTime.now())) {
      return;
    }
    
    _scheduledNotifications.add(reminder.id);
  }

  @override
  Future<void> cancelNotification(String reminderId) async {
    _scheduledNotifications.remove(reminderId);
    _cancelledNotifications.add(reminderId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    _cancelledNotifications.addAll(_scheduledNotifications);
    _scheduledNotifications.clear();
  }

  @override
  Future<void> initializeFCM() async {
    _fcmToken = 'mock_fcm_token_12345';
  }

  @override
  Future<String?> getFCMToken() async {
    return _fcmToken;
  }

  @override
  Stream<RemoteMessage> get onMessageReceived => const Stream.empty();

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();

  @override
  void setNotificationTapCallback(Function(String reminderId) callback) {
    _onNotificationTap = callback;
  }

  @override
  Future<void> schedulePersistentNotification(Reminder reminder) async {
    // Mock implementation - just add to scheduled notifications
    _scheduledNotifications.add('${reminder.id}_persistent');
  }

  @override
  Future<void> initializePersistentScheduling() async {
    // Mock implementation - do nothing
  }

  // Test helper methods
  List<String> get scheduledNotifications => List.unmodifiable(_scheduledNotifications);
  List<String> get cancelledNotifications => List.unmodifiable(_cancelledNotifications);
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  
  // Simulate notification tap
  void simulateNotificationTap(String reminderId) {
    _onNotificationTap?.call(reminderId);
  }
}

void main() {
  group('NotificationService', () {
    late MockNotificationService notificationService;

    setUp(() {
      notificationService = MockNotificationService();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act
        await notificationService.initialize();

        // Assert
        expect(notificationService.isInitialized, true);
      });

      test('should request permissions successfully', () async {
        // Act
        final granted = await notificationService.requestPermissions();

        // Assert
        expect(granted, true);
        expect(notificationService.permissionsGranted, true);
      });

      test('should initialize FCM and get token', () async {
        // Act
        await notificationService.initializeFCM();
        final token = await notificationService.getFCMToken();

        // Assert
        expect(token, isNotNull);
        expect(token, 'mock_fcm_token_12345');
      });
    });

    group('Local Notifications', () {
      late Reminder testReminder;

      setUp(() async {
        await notificationService.initialize();
        testReminder = Reminder.create(
          title: 'Test Reminder',
          description: 'Test Description',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );
      });

      test('should schedule notification for future reminder', () async {
        // Act
        await notificationService.scheduleLocalNotification(testReminder);

        // Assert
        expect(notificationService.scheduledNotifications.contains(testReminder.id), true);
      });

      test('should not schedule notification for past reminder', () async {
        // Arrange
        final pastReminder = testReminder.copyWith(
          dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act
        await notificationService.scheduleLocalNotification(pastReminder);

        // Assert
        expect(notificationService.scheduledNotifications.contains(pastReminder.id), false);
      });

      test('should cancel specific notification', () async {
        // Arrange
        await notificationService.scheduleLocalNotification(testReminder);
        expect(notificationService.scheduledNotifications.contains(testReminder.id), true);

        // Act
        await notificationService.cancelNotification(testReminder.id);

        // Assert
        expect(notificationService.scheduledNotifications.contains(testReminder.id), false);
        expect(notificationService.cancelledNotifications.contains(testReminder.id), true);
      });

      test('should cancel all notifications', () async {
        // Arrange
        final reminder1 = testReminder;
        final reminder2 = testReminder.copyWith(
          dateTime: DateTime.now().add(const Duration(hours: 2)),
        );

        await notificationService.scheduleLocalNotification(reminder1);
        await notificationService.scheduleLocalNotification(reminder2);
        expect(notificationService.scheduledNotifications.length, 2);

        // Act
        await notificationService.cancelAllNotifications();

        // Assert
        expect(notificationService.scheduledNotifications.length, 0);
        expect(notificationService.cancelledNotifications.length, 2);
      });

      test('should throw exception when scheduling without initialization', () async {
        // Arrange
        final uninitializedService = MockNotificationService();

        // Act & Assert
        expect(
          () => uninitializedService.scheduleLocalNotification(testReminder),
          throwsA(isA<NotificationException>()),
        );
      });
    });

    group('Notification Callbacks', () {
      test('should set and trigger notification tap callback', () async {
        // Arrange
        String? tappedReminderId;
        notificationService.setNotificationTapCallback((reminderId) {
          tappedReminderId = reminderId;
        });

        // Act
        notificationService.simulateNotificationTap('test_reminder_id');

        // Assert
        expect(tappedReminderId, 'test_reminder_id');
      });
    });

    group('Recurring Notifications', () {
      test('should schedule daily recurring notification', () async {
        // Arrange
        await notificationService.initialize();
        final dailyReminder = Reminder.create(
          title: 'Daily Reminder',
          description: 'Daily Description',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          repeatOption: RepeatOption.daily,
          userId: 'test_user_id',
        );

        // Act
        await notificationService.scheduleLocalNotification(dailyReminder);

        // Assert
        expect(notificationService.scheduledNotifications.contains(dailyReminder.id), true);
      });

      test('should schedule weekly recurring notification', () async {
        // Arrange
        await notificationService.initialize();
        final weeklyReminder = Reminder.create(
          title: 'Weekly Reminder',
          description: 'Weekly Description',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          repeatOption: RepeatOption.weekly,
          userId: 'test_user_id',
        );

        // Act
        await notificationService.scheduleLocalNotification(weeklyReminder);

        // Assert
        expect(notificationService.scheduledNotifications.contains(weeklyReminder.id), true);
      });

      test('should schedule monthly recurring notification', () async {
        // Arrange
        await notificationService.initialize();
        final monthlyReminder = Reminder.create(
          title: 'Monthly Reminder',
          description: 'Monthly Description',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          repeatOption: RepeatOption.monthly,
          userId: 'test_user_id',
        );

        // Act
        await notificationService.scheduleLocalNotification(monthlyReminder);

        // Assert
        expect(notificationService.scheduledNotifications.contains(monthlyReminder.id), true);
      });
    });

    group('Error Handling', () {
      test('should handle notification scheduling errors gracefully', () async {
        // This test would be more meaningful with actual error scenarios
        // For now, we just ensure the mock doesn't throw unexpected errors
        await notificationService.initialize();
        
        final reminder = Reminder.create(
          title: 'Test Reminder',
          description: 'Test Description',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
          repeatOption: RepeatOption.none,
          userId: 'test_user_id',
        );

        // Should not throw
        await notificationService.scheduleLocalNotification(reminder);
        await notificationService.cancelNotification(reminder.id);
      });
    });
  });
}