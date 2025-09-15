import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'shared/services/local_storage_service.dart';
import 'shared/services/firebase_debug_service.dart';
import 'shared/services/backend_config_service.dart';
import 'shared/services/mobile_backend_config_service.dart';
import 'shared/services/web_local_service.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized successfully');
  
  // Initialize Backend Configuration (Firebase + Supabase support)
  await BackendConfigService.initialize();
  print('Backend configuration initialized: ${BackendConfigService.currentBackend.displayName}');
  
  // Initialize web service if on web platform
  if (kIsWeb) {
    final webService = WebLocalService();
    await webService.initialize();
    print('Web Local Service initialized');
  }
  
  // Test Firebase connection
  if (kDebugMode) {
    await FirebaseDebugService.testFirebaseConnection();
    FirebaseDebugService.logAuthState();
  }
  
  // Initialize Firebase App Check (skip for web in debug mode to avoid JS errors)
  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      print('Firebase App Check activated for mobile platforms');
    } catch (e) {
      print('Firebase App Check initialization failed, continuing without it: $e');
    }
  } else {
    print('Firebase App Check skipped for web platform in debug mode');
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize local storage service
  final storageService = HiveLocalStorageService();
  await storageService.initialize();
  
  // Initialize notification service (for mobile platforms)
  if (!kIsWeb) {
    try {
      final notificationService = NotificationServiceImpl();
      await notificationService.initialize();
      await notificationService.requestPermissions();
      print('Notification service initialized and permissions requested');
    } catch (e) {
      print('Notification service initialization failed: $e');
    }
  } else {
    print('Notification service skipped for web platform');
  }
  
  runApp(
    const ProviderScope(
      child: StudentReminderApp(),
    ),
  );
}