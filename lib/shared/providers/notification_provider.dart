import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});

// Provider for notification initialization
final notificationInitializationProvider = FutureProvider<bool>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.initialize();
  return await notificationService.requestPermissions();
});

// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getFCMToken();
});