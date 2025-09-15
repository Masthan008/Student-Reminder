// notification_service.dart
// Drop into lib/services/
// Requires dependencies in pubspec.yaml: flutter_local_notifications, audioplayers, path_provider, http, vibration, timezone
// Ensure you have a ServiceManager with markAsCompleted(reminderId) or adapt callback.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

typedef OnNotificationTap = void Function(String? payload);
typedef OnReminderTriggered = Future<void> Function(String reminderId);

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;
  OnNotificationTap? onTapCallback;
  OnReminderTriggered? onReminderTriggered;

  Future<void> init({OnNotificationTap? onTap, OnReminderTriggered? onTriggered}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    onTapCallback = onTap;
    onReminderTriggered = onTriggered;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) async {
        if (onTapCallback != null) onTapCallback!(response.payload);
      },
    );

    // Create channel for Android (one-time)
    const androidChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Channel for reminder notifications',
      importance: Importance.max,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Copy an asset sound into app documents (or cache) and return local path
  Future<String> copyAssetToLocal(String assetRelativePath) async {
    final filename = assetRelativePath.split('/').last;
    final bytes = await rootBundle.load(assetRelativePath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return file.path;
  }

  /// Download remote file to local path and return it
  Future<String> downloadRemoteToLocal(String url, String filename) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) throw Exception('Failed to download file: $url');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  }

  /// Play local audio file immediately (non-notification playback)
  Future<void> playLocalSound(String localFilePath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(localFilePath));
    } catch (e) {
      // ignore errors
      print('playLocalSound error: $e');
    }
  }

  /// Schedule a timezone-aware notification.
  /// reminderId: id string saved in your DB (used to mark completed)
  /// scheduledAt: DateTime in user's local timezone
  /// customSoundLocalPath: path to a local file to play on trigger (if provided).
  /// fallbackAsset: asset path in assets (e.g. 'assets/sounds/default_notification.mp3') used if no custom sound.
  /// vibrate: use app setting boolean to enable/disable vibration at runtime
  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required DateTime scheduledAt,
    String? customSoundLocalPath,
    String fallbackAsset = 'assets/sounds/default_notification.mp3',
    bool vibrate = true,
  }) async {
    if (!_initialized) await init();

    // ensure timezone
    final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);

    // Notification sound on Android requires RawResource name inside res/raw OR we schedule without a raw sound and play the sound ourselves when notification arrives.
    // We will schedule with default system sound, and rely on background callback to play the sound ourselves when notification arrives.
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Student reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // system sound
      enableVibration: vibrate,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      // use unique integer id; here using reminderId.hashCode can be used consistently (but be careful with collisions)
      reminderId.hashCode,
      title,
      'Tap to open reminder',
      tzDate,
      details,
      payload: reminderId,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // We'll ensure user custom sound is cached. Save file path somewhere with reminder in DB.
    if (customSoundLocalPath == null) {
      // ensure fallback asset is copied to local so we can play via audioplayers when needed
      await copyAssetToLocal(fallbackAsset);
    }
  }

  /// Call this when the app receives a notification payload (tap) or when you handle a background event.
  /// It will play a custom/local sound if available, then call onReminderTriggered callback to mark completed.
  Future<void> handleNotificationAction({
    required String reminderId,
    String? customFilePathLocal,
    String fallbackAsset = 'assets/sounds/default_notification.mp3',
    bool vibrate = true,
  }) async {
    // Vibrate if allowed:
    if (vibrate && (await Vibration.hasVibrator() == true)) {
      Vibration.vibrate(duration: 600);
    }

    // Play sound: prefer local custom path, else fallback asset (copied to local)
    try {
      if (customFilePathLocal != null && File(customFilePathLocal).existsSync()) {
        await playLocalSound(customFilePathLocal);
      } else {
        final fallbackFileName = fallbackAsset.split('/').last;
        final fallbackLocalPath = '${(await getApplicationDocumentsDirectory()).path}/$fallbackFileName';
        if (!File(fallbackLocalPath).existsSync()) {
          await copyAssetToLocal(fallbackAsset);
        }
        await playLocalSound(fallbackLocalPath);
      }
    } catch (e) {
      print('handleNotificationAction.play error: $e');
    }

    // Mark as completed in DB via callback if provided
    if (onReminderTriggered != null) {
      try {
        await onReminderTriggered!(reminderId);
      } catch (e) {
        print('onReminderTriggered failed: $e');
      }
    }
  }
}
