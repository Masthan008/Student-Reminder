import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

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
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  Function(String reminderId)? _onNotificationTap;

  @override
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await initializeFCM();
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

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description.isNotEmpty ? reminder.description : 'Reminder notification',
        _convertToTZDateTime(reminder.dateTime),
        notificationDetails,
        payload: reminder.id,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Schedule recurring notifications if needed
      if (reminder.repeatOption != RepeatOption.none) {
        await _scheduleRecurringNotification(reminder);
      }
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
      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

    await _localNotifications.zonedSchedule(
      reminder.id.hashCode + 1000, // Different ID for recurring
      '${reminder.title} (Recurring)',
      reminder.description,
      _convertToTZDateTime(reminder.dateTime),
      notificationDetails,
      payload: reminder.id,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatInterval,
    );
  }

  // Helper method to convert DateTime to TZDateTime
  // Note: In a real app, you'd use the timezone package
  dynamic _convertToTZDateTime(DateTime dateTime) {
    return dateTime; // Simplified for now
  }

  @override
  Future<void> cancelNotification(String reminderId) async {
    try {
      final notificationId = reminderId.hashCode;
      await _localNotifications.cancel(notificationId);
      
      // Also cancel recurring notification if it exists
      await _localNotifications.cancel(notificationId + 1000);
    } catch (e) {
      throw NotificationException('Failed to cancel notification: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
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
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  // In production, you might want to use a proper logging solution
  // ignore: avoid_print
  print('Handling background message: ${message.messageId}');
}