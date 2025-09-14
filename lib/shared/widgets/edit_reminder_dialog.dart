import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/validation_utils.dart';
import '../providers/reminder_provider.dart';

class EditReminderDialog extends ConsumerStatefulWidget {
  final Reminder reminder;

  const EditReminderDialog({super.key, required this.reminder});

  @override
  ConsumerState<EditReminderDialog> createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends ConsumerState<EditReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatOption _repeatOption;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);
    _selectedDate = widget.reminder.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.reminder.dateTime);
    _repeatOption = widget.reminder.repeatOption;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Reminder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter reminder title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => ValidationUtils.getReminderTitleError(value ?? ''),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) => ValidationUtils.getReminderDescriptionError(value ?? ''),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(AppDateUtils.formatDate(_selectedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDate,
                ),
                const Divider(),

                // Time Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectTime,
                ),
                const Divider(),

                // Repeat Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.repeat),
                  title: const Text('Repeat'),
                  subtitle: Text(_getRepeatText(_repeatOption)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectRepeatOption,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateReminder,
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _selectRepeatOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RepeatOption.values.map((option) {
            return RadioListTile<RepeatOption>(
              title: Text(_getRepeatText(option)),
              value: option,
              groupValue: _repeatOption,
              onChanged: (value) {
                setState(() {
                  _repeatOption = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRepeatText(RepeatOption option) {
    switch (option) {
      case RepeatOption.none:
        return 'Never';
      case RepeatOption.daily:
        return 'Daily';
      case RepeatOption.weekly:
        return 'Weekly';
      case RepeatOption.monthly:
        return 'Monthly';
      case RepeatOption.yearly:
        return 'Yearly';
    }
  }

  void _updateReminder() {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedReminder = widget.reminder.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: dateTime,
      repeatOption: _repeatOption,
    );

    ref.read(remindersProvider.notifier).updateReminder(updatedReminder);

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder "${updatedReminder.title}" updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}