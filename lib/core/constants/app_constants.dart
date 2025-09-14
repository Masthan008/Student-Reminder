class AppConstants {
  // App Information
  static const String appName = 'Student Reminder';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String reminderBoxName = 'reminders';
  static const String userBoxName = 'user';
  static const String settingsBoxName = 'settings';
  static const String offlineQueueBoxName = 'offline_queue';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String remindersCollection = 'reminders';
  
  // Shared Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';
  
  // Notification
  static const String notificationChannelId = 'reminder_notifications';
  static const String notificationChannelName = 'Reminder Notifications';
  static const String notificationChannelDescription = 'Notifications for student reminders and deadlines';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
}