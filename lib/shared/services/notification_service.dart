import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import 'sound_storage_service.dart';

// Helper method to create notification details with proper sound handling
Future<NotificationDetails> _createNotificationDetails({
  required bool hasCustomSound,
  String? soundUrl,
  String? soundName,
}) async {
  AndroidNotificationDetails androidDetails;
  
  if (hasCustomSound && soundUrl != null && soundUrl.isNotEmpty) {
    // Handle custom sound
    String? soundPath;
    
    // For custom sounds, we need to download and cache locally
    if (!kIsWeb) {
      try {
        final soundService = SoundStorageService();
        // Extract sound ID from URL for caching
        final soundId = soundUrl.split('/').last.split('.').first;
        soundPath = await soundService.downloadAndCacheSound(
          soundUrl: soundUrl,
          soundId: soundId,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to download/cache custom sound: $e');
        }
      }
    }
    
    // Use custom sound if available, otherwise fallback to default
    if (soundPath != null && soundPath.isNotEmpty) {
      androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        sound: UriAndroidNotificationSound(soundPath),
      );
    } else {
      // Fallback to default sound
      androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );
    }
  } else {
    // Use default sound
    androidDetails = const AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
  }

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  return NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
}

abstract class NotificationService {
  // Initialization
  Future<void> initialize();
  Future<bool> requestPermissions();
  
  // Local notifications
  Future<void> scheduleLocalNotification(Reminder reminder);
  Future<void> cancelNotification(String reminderId);
  Future<void> cancelAllNotifications();
  
  // Push notifications (FCM)
  Future<void> initializeFCM();
  Future<String?> getFCMToken();
  Stream<RemoteMessage> get onMessageReceived;
  Stream<RemoteMessage> get onMessageOpenedApp;
  
  // Notification handling
  void setNotificationTapCallback(Function(String reminderId) callback);
  
  // Persistent scheduling
  Future<void> schedulePersistentNotification(Reminder reminder);
  Future<void> initializePersistentScheduling();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  Function(String reminderId)? _onNotificationTap;

  @override
  Future<void> initialize() async {
    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      
      await _initializeLocalNotifications();
      await initializeFCM();
      await initializePersistentScheduling();
    } catch (e) {
      throw NotificationException('Failed to initialize notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && _onNotificationTap != null) {
      _onNotificationTap!(payload);
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      
      // Request iOS specific permissions
      final iosPermissions = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? true;

      // Request FCM permissions
      final fcmSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return notificationStatus.isGranted && 
             iosPermissions && 
             fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      throw NotificationException('Failed to request permissions: $e');
    }
  }

  @override
  Future<void> scheduleLocalNotification(Reminder reminder) async {
    try {
      final notificationId = reminder.id.hashCode;
      
      // Don't schedule notifications for past dates
      if (reminder.dateTime.isBefore(DateTime.now())) {
        return;
      }

      // Handle custom sound
      final NotificationDetails notificationDetails = await _createNotificationDetails(
        hasCustomSound: reminder.soundUrl != null && reminder.soundUrl!.isNotEmpty,
        soundUrl: reminder.soundUrl,
        soundName: reminder.soundName,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description.isNotEmpty ? reminder.description : 'Reminder notification',
        _convertToTZDateTime(reminder.dateTime),
        notificationDetails,
        payload: reminder.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Schedule recurring notifications if needed
      if (reminder.repeatOption != RepeatOption.none) {
        await _scheduleRecurringNotification(reminder);
      }
      
      // Schedule persistent notification for app restart support
      await schedulePersistentNotification(reminder);
    } catch (e) {
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  Future<void> _scheduleRecurringNotification(Reminder reminder) async {
    late DateTimeComponents repeatInterval;
    
    switch (reminder.repeatOption) {
      case RepeatOption.daily:
        repeatInterval = DateTimeComponents.time;
        break;
      case RepeatOption.weekly:
        repeatInterval = DateTimeComponents.dayOfWeekAndTime;
        break;
      case RepeatOption.monthly:
        repeatInterval = DateTimeComponents.dayOfMonthAndTime;
        break;
      case RepeatOption.yearly:
        repeatInterval = DateTimeComponents.dateAndTime;
        break;
      case RepeatOption.none:
        return;
    }
    
    // Handle custom sound for recurring notifications
    final NotificationDetails notificationDetails = await _createNotificationDetails(
      hasCustomSound: reminder.soundUrl != null && reminder.soundUrl!.isNotEmpty,
      soundUrl: reminder.soundUrl,
      soundName: reminder.soundName,
    );

    await _localNotifications.zonedSchedule(
      reminder.id.hashCode + 1000, // Different ID for recurring
      '${reminder.title} (Recurring)',
      reminder.description,
      _convertToTZDateTime(reminder.dateTime),
      notificationDetails,
      payload: reminder.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeatInterval,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Helper method to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      // Initialize timezone database if not already done
      if (tz.timeZoneDatabase.locations.isEmpty) {
        tz.initializeTimeZones();
      }
      
      final location = tz.getLocation('UTC');
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      if (kDebugMode) {
        print('Timezone conversion error: $e');
      }
      // Fallback to UTC if timezone fails
      return tz.TZDateTime.utc(dateTime.year, dateTime.month, dateTime.day, 
                               dateTime.hour, dateTime.minute, dateTime.second);
    }
  }

  @override
  Future<void> cancelNotification(String reminderId) async {
    try {
      final notificationId = reminderId.hashCode;
      await _localNotifications.cancel(notificationId);
      
      // Also cancel recurring notification if it exists
      await _localNotifications.cancel(notificationId + 1000);
      
      // Cancel persistent notification
      await Workmanager().cancelByUniqueName(reminderId);
    } catch (e) {
      throw NotificationException('Failed to cancel notification: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await Workmanager().cancelAll();
    } catch (e) {
      throw NotificationException('Failed to cancel all notifications: $e');
    }
  }

  // FCM Implementation
  @override
  Future<void> initializeFCM() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      throw NotificationException('Failed to initialize FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showForegroundNotification(message);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle notification tap
    final reminderId = message.data['reminderId'];
    if (reminderId != null && _onNotificationTap != null) {
      _onNotificationTap!(reminderId);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Handle custom sound for foreground notifications
    final soundUrl = message.data['soundUrl'] as String?;
    final soundName = message.data['soundName'] as String?;
    final NotificationDetails notificationDetails = await _createNotificationDetails(
      hasCustomSound: soundUrl != null && soundUrl.isNotEmpty,
      soundUrl: soundUrl,
      soundName: soundName,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Reminder',
      message.notification?.body ?? 'You have a reminder',
      notificationDetails,
      payload: message.data['reminderId'],
    );
  }

  @override
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      throw NotificationException('Failed to get FCM token: $e');
    }
  }

  @override
  Stream<RemoteMessage> get onMessageReceived => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  @override
  void setNotificationTapCallback(Function(String reminderId) callback) {
    _onNotificationTap = callback;
  }
  
  // Persistent scheduling implementation using WorkManager only
  @override
  Future<void> schedulePersistentNotification(Reminder reminder) async {
    if (kIsWeb) return; // Not supported on web
    
    try {
      // Use WorkManager for Android
      final now = DateTime.now();
      final delay = reminder.dateTime.difference(now);
      
      if (delay.isNegative) return; // Don't schedule past reminders
      
      // Schedule with WorkManager
      await Workmanager().registerOneOffTask(
        reminder.id, // unique name
        "reminder_task", // task name
        initialDelay: delay,
        inputData: {
          'reminderId': reminder.id,
          'title': reminder.title,
          'description': reminder.description,
          'dateTime': reminder.dateTime.toIso8601String(),
          'soundUrl': reminder.soundUrl,
          'soundName': reminder.soundName,
        },
      );
      
      if (kDebugMode) {
        print('Scheduled persistent notification for: ${reminder.title} at ${reminder.dateTime}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule persistent notification: $e');
      }
    }
  }
  
  @override
  Future<void> initializePersistentScheduling() async {
    if (kIsWeb) return; // Not supported on web
    
    try {
      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher, // Callback function
      );
      
      if (kDebugMode) {
        print('WorkManager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize WorkManager: $e');
      }
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  // In production, you might want to use a proper logging solution
  // ignore: avoid_print
  print('Handling background message: ${message.messageId}');
}

// WorkManager callback dispatcher (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Handle the scheduled task
      if (task == "reminder_task" && inputData != null) {
        final reminderId = inputData['reminderId'] as String;
        final title = inputData['title'] as String;
        final description = inputData['description'] as String;
        final soundUrl = inputData['soundUrl'] as String?;
        final soundName = inputData['soundName'] as String?;
        
        // Show notification
        final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
        
        // Android initialization settings
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        
        // iOS initialization settings
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const initializationSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await localNotifications.initialize(initializationSettings);
        
        // Create notification channel for Android
        const androidChannel = AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          playSound: true,
        );

        await localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
        
        // Show notification with custom sound if available
        final NotificationDetails notificationDetails = await _createNotificationDetails(
          hasCustomSound: soundUrl != null && soundUrl.isNotEmpty,
          soundUrl: soundUrl,
          soundName: soundName,
        );
        
        await localNotifications.show(
          reminderId.hashCode,
          title,
          description.isNotEmpty ? description : 'Reminder notification',
          notificationDetails,
          payload: reminderId,
        );
        
        if (kDebugMode) {
          print('Persistent notification shown for: $title');
        }
      }
      
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Error in callback dispatcher: $e');
      }
      return Future.value(false);
    }
  });
}