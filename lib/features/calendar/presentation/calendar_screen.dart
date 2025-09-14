import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/utils/date_utils.dart';
import '../../reminders/domain/reminder.dart';
import '../../../shared/providers/reminder_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.month 
                ? Icons.view_week 
                : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Widget
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Reminder>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: (day) {
                return reminders.where((reminder) => 
                    AppDateUtils.isSameDay(reminder.dateTime, day)).toList();
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                holidayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left),
                rightChevronIcon: Icon(Icons.chevron_right),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          
          // Selected Day Reminders
          Expanded(
            child: _buildSelectedDayReminders(reminders),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddReminderDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSelectedDayReminders(List<Reminder> allReminders) {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a day to view reminders'),
      );
    }

    final dayReminders = allReminders.where((reminder) => 
        AppDateUtils.isSameDay(reminder.dateTime, _selectedDay!)).toList();

    if (dayReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders for ${AppDateUtils.formatDate(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Reminders for ${AppDateUtils.getRelativeDateString(_selectedDay!)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dayReminders.length,
            itemBuilder: (context, index) {
              final reminder = dayReminders[index];
              return _buildReminderCard(reminder);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.isCompleted 
              ? Colors.green 
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            reminder.isCompleted ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description.isNotEmpty)
              Text(reminder.description),
            Text(
              AppDateUtils.formatTime(reminder.dateTime),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(reminder.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'toggle':
                ref.read(remindersProvider.notifier).toggleComplete(reminder.id);
                break;
              case 'edit':
                _showEditReminderDialog(reminder);
                break;
              case 'delete':
                ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => EditReminderDialog(reminder: reminder),
    );
  }
}

// Placeholder dialogs - will be implemented next
class AddReminderDialog extends StatelessWidget {
  final DateTime selectedDate;

  const AddReminderDialog({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Reminder'),
      content: const Text('Add reminder dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class EditReminderDialog extends StatelessWidget {
  final Reminder reminder;

  const EditReminderDialog({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Reminder'),
      content: const Text('Edit reminder dialog coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}