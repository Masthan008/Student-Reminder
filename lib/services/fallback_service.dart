import 'supabase_service.dart';
import 'firebase_service.dart';

class FallbackService {
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseService _firebaseService = FirebaseService();

  /// Try Supabase first, fallback to Firebase
  Future<List<Map<String, dynamic>>> fetchReminders(String userId) async {
    try {
      return await _supabaseService.fetchReminders(userId);
    } catch (e) {
      print("Supabase failed, trying Firebase: $e");
      return await _firebaseService.fetchReminders(userId);
    }
  }

  Future<void> addReminder(String userId, String title, DateTime time) async {
    try {
      await _supabaseService.addReminder(userId, title, time);
    } catch (e) {
      print("Supabase failed, fallback to Firebase: $e");
      await _firebaseService.addReminder(userId, title, time);
    }
  }

  Future<void> markAsCompleted(String reminderIdOrInt) async {
    try {
      if (int.tryParse(reminderIdOrInt) != null) {
        // Supabase IDs are usually ints
        await _supabaseService.markAsCompleted(int.parse(reminderIdOrInt));
      } else {
        // Firebase IDs are strings
        await _firebaseService.markAsCompleted(reminderIdOrInt);
      }
    } catch (e) {
      print("Primary failed, trying fallback: $e");
      // Try the other one
      if (int.tryParse(reminderIdOrInt) != null) {
        await _firebaseService.markAsCompleted(reminderIdOrInt);
      } else {
        await _supabaseService.markAsCompleted(int.parse(reminderIdOrInt));
      }
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabaseService.updateProfile(userId, updates);
    } catch (e) {
      print("Supabase failed, using Firebase: $e");
      await _firebaseService.updateProfile(userId, updates);
    }
  }

  /// Merge realtime streams (Supabase + Firebase)
  Stream<List<Map<String, dynamic>>> listenToReminders(String userId) {
    try {
      return _supabaseService.listenToReminders(userId);
    } catch (_) {
      return _firebaseService.listenToReminders(userId);
    }
  }
}
