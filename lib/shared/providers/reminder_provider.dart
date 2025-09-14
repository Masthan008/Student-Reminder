import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/reminders/domain/reminder.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  ReminderNotifier() : super([]) {
    _loadSampleData();
  }

  void _loadSampleData() {
    // Add some sample reminders for demonstration
    final now = DateTime.now();
    final sampleReminders = [
      Reminder.create(
        title: 'Math Assignment Due',
        description: 'Complete calculus homework chapter 5',
        dateTime: now.add(const Duration(hours: 2)),
        repeatOption: RepeatOption.none,
        userId: 'demo_user',
      ),
      Reminder.create(
        title: 'Study for Physics Exam',
        description: 'Review chapters 1-3 for midterm exam',
        dateTime: now.add(const Duration(days: 1)),
        repeatOption: RepeatOption.none,
        userId: 'demo_user',
      ),
      Reminder.create(
        title: 'Weekly Team Meeting',
        description: 'Project discussion and progress update',
        dateTime: now.add(const Duration(days: 2)),
        repeatOption: RepeatOption.weekly,
        userId: 'demo_user',
      ),
      Reminder.create(
        title: 'Library Books Return',
        description: 'Return borrowed books to avoid late fees',
        dateTime: now.add(const Duration(days: 3)),
        repeatOption: RepeatOption.none,
        userId: 'demo_user',
      ),
      Reminder.create(
        title: 'Daily Exercise',
        description: '30 minutes of cardio workout',
        dateTime: now.add(const Duration(hours: 1)),
        repeatOption: RepeatOption.daily,
        userId: 'demo_user',
      ),
    ];

    state = sampleReminders;
  }

  void addReminder(Reminder reminder) {
    state = [...state, reminder];
  }

  void updateReminder(Reminder updatedReminder) {
    state = [
      for (final reminder in state)
        if (reminder.id == updatedReminder.id)
          updatedReminder
        else
          reminder,
    ];
  }

  void deleteReminder(String id) {
    state = state.where((reminder) => reminder.id != id).toList();
  }

  void toggleComplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: !reminder.isCompleted)
        else
          reminder,
    ];
  }

  void markComplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: true)
        else
          reminder,
    ];
  }

  void markIncomplete(String id) {
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(isCompleted: false)
        else
          reminder,
    ];
  }

  List<Reminder> getRemindersByDate(DateTime date) {
    return state.where((reminder) {
      final reminderDate = DateTime(
        reminder.dateTime.year,
        reminder.dateTime.month,
        reminder.dateTime.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return reminderDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<Reminder> getTodayReminders() {
    final today = DateTime.now();
    return getRemindersByDate(today);
  }

  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    return state.where((reminder) => 
        reminder.dateTime.isAfter(now) && !reminder.isCompleted).toList();
  }

  List<Reminder> getOverdueReminders() {
    final now = DateTime.now();
    return state.where((reminder) => 
        reminder.dateTime.isBefore(now) && !reminder.isCompleted).toList();
  }

  List<Reminder> getCompletedReminders() {
    return state.where((reminder) => reminder.isCompleted).toList();
  }
}

final remindersProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  return ReminderNotifier();
});

// Computed providers for different reminder categories
final todayRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final today = DateTime.now();
  return reminders.where((reminder) {
    final reminderDate = DateTime(
      reminder.dateTime.year,
      reminder.dateTime.month,
      reminder.dateTime.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return reminderDate.isAtSameMomentAs(todayDate) && !reminder.isCompleted;
  }).toList();
});

final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final now = DateTime.now();
  return reminders.where((reminder) => 
      reminder.dateTime.isAfter(now) && !reminder.isCompleted).toList();
});

final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  final now = DateTime.now();
  return reminders.where((reminder) => 
      reminder.dateTime.isBefore(now) && !reminder.isCompleted).toList();
});

final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider);
  return reminders.where((reminder) => reminder.isCompleted).toList();
});