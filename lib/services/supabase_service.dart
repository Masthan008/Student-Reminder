import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch reminders for a specific user
  Future<List<Map<String, dynamic>>> fetchReminders(String userId) async {
    final response = await _supabase
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Add a new reminder
  Future<void> addReminder(String userId, String title, DateTime time) async {
    await _supabase.from('reminders').insert({
      'user_id': userId,
      'title': title,
      'time': time.toIso8601String(),
      'completed': false,
    });
  }

  // Mark reminder as completed
  Future<void> markAsCompleted(int reminderId) async {
    await _supabase
        .from('reminders')
        .update({'completed': true}).eq('id', reminderId);
  }

  // Update profile info
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  // Realtime reminders listener
  Stream<List<Map<String, dynamic>>> listenToReminders(String userId) {
    return _supabase
        .from('reminders:user_id=eq.$userId')
        .stream(primaryKey: ['id'])
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
