import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/backend_config_service.dart';
import '../services/mobile_backend_config_service.dart';
import '../../features/reminders/domain/reminder.dart';

// Updated to use backend configuration service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  // Use the configured backend service (Firebase or Supabase)
  return BackendConfigService.getCurrentBackendService();
});

// Provider for current backend type
final currentBackendProvider = Provider<BackendProvider>((ref) {
  return BackendConfigService.currentBackend;
});

// Provider for available backends
final availableBackendsProvider = Provider<List<BackendProvider>>((ref) {
  return BackendConfigService.getAvailableBackends();
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