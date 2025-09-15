import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch reminders
  Future<List<Map<String, dynamic>>> fetchReminders(String userId) async {
    final query = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .orderBy('time')
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  // Add reminder
  Future<void> addReminder(String userId, String title, DateTime time) async {
    await _firestore.collection('reminders').add({
      'userId': userId,
      'title': title,
      'time': time.toIso8601String(),
      'completed': false,
    });
  }

  // Mark as completed
  Future<void> markAsCompleted(String reminderId) async {
    await _firestore
        .collection('reminders')
        .doc(reminderId)
        .update({'completed': true});
  }

  // Update profile
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Realtime reminders listener
  Stream<List<Map<String, dynamic>>> listenToReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }
}
