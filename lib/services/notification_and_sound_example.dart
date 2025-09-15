import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationAndSoundExample {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse);
  }

  // Save remote sound locally
  Future<String> downloadSound(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  // Schedule a notification with callback sound
  Future<void> scheduleNotification(
      int id, String title, String body, DateTime time, String? soundPath) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('reminder_channel', 'Reminders',
            importance: Importance.max, priority: Priority.high);

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Play custom sound if available
    if (soundPath != null && File(soundPath).existsSync()) {
      _audioPlayer.play(DeviceFileSource(soundPath));
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Could trigger sound here if you prefer
    print("Notification clicked: ", response.payload);
  }
}
