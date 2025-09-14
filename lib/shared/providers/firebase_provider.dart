import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/mock_firebase_service.dart';
import '../../features/reminders/domain/reminder.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  // Use mock service for demo mode (Firebase not configured)
  // Switch to FirebaseServiceImpl() when you have real Firebase configuration
  return MockFirebaseService();
});

// Provider for authentication state
final authStateProvider = StreamProvider((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService.authStateChanges;
});

// Provider for current user
final currentUserProvider = Provider((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService.currentUser;
});

// Provider for reminders stream
final remindersStreamProvider = StreamProvider.family<List<Reminder>, String>((ref, userId) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService.getReminderStream(userId);
});