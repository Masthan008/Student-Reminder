import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/reminder.dart';
import '../../../shared/providers/reminder_provider.dart';
import '../../../shared/widgets/add_reminder_dialog.dart';
import '../../../shared/widgets/edit_reminder_dialog.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final filteredReminders = _filterReminders(reminders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Searching: "$_searchQuery"',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRemindersList(filteredReminders),
                _buildRemindersList(_getTodayReminders(filteredReminders)),
                _buildRemindersList(_getUpcomingReminders(filteredReminders)),
                _buildRemindersList(_getCompletedReminders(filteredReminders)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  List<Reminder> _filterReminders(List<Reminder> reminders) {
    if (_searchQuery.isEmpty) return reminders;
    
    return reminders.where((reminder) {
      return reminder.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             reminder.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Reminder> _getTodayReminders(List<Reminder> reminders) {
    return reminders.where((reminder) => reminder.isDueToday && !reminder.isCompleted).toList();
  }

  List<Reminder> _getUpcomingReminders(List<Reminder> reminders) {
    return reminders.where((reminder) => 
        reminder.dateTime.isAfter(DateTime.now()) && !reminder.isCompleted).toList();
  }

  List<Reminder> _getCompletedReminders(List<Reminder> reminders) {
    return reminders.where((reminder) => reminder.isCompleted).toList();
  }

  Widget _buildRemindersList(List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return _buildEmptyState();
    }

    // Group reminders by date
    final groupedReminders = <String, List<Reminder>>{};
    for (final reminder in reminders) {
      final dateKey = AppDateUtils.getRelativeDateString(reminder.dateTime);
      groupedReminders.putIfAbsent(dateKey, () => []).add(reminder);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedReminders.length,
      itemBuilder: (context, index) {
        final dateKey = groupedReminders.keys.elementAt(index);
        final dayReminders = groupedReminders[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...dayReminders.map((reminder) => _buildReminderCard(reminder)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first reminder to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddReminderDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isOverdue = reminder.isOverdue;
    
    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Mark as complete
          ref.read(remindersProvider.notifier).toggleComplete(reminder.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reminder.title} marked as complete'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(remindersProvider.notifier).toggleComplete(reminder.id);
                },
              ),
            ),
          );
        } else {
          // Delete
          ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reminder.title} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(remindersProvider.notifier).addReminder(reminder);
                },
              ),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: reminder.isCompleted ? 1 : 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: reminder.isCompleted 
                ? Colors.green 
                : isOverdue 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.primary,
            child: Icon(
              reminder.isCompleted 
                  ? Icons.check 
                  : isOverdue 
                      ? Icons.warning 
                      : Icons.schedule,
              color: Colors.white,
            ),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted 
                  ? TextDecoration.lineThrough 
                  : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminder.description.isNotEmpty)
                Text(
                  reminder.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.formatDateTime(reminder.dateTime),
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (reminder.repeatOption != RepeatOption.none) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reminder.repeatOption.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(reminder.isCompleted ? Icons.undo : Icons.check),
                    const SizedBox(width: 8),
                    Text(reminder.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
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
                  _showDeleteConfirmation(reminder);
                  break;
              }
            },
          ),
          onTap: () => _showReminderDetails(reminder),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = _searchQuery;
        return AlertDialog(
          title: const Text('Search Reminders'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = query;
                });
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddReminderDialog(),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => EditReminderDialog(reminder: reminder),
    );
  }

  void _showReminderDetails(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description.isNotEmpty) ...[
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(reminder.description),
              const SizedBox(height: 16),
            ],
            Text(
              'Date & Time:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(AppDateUtils.formatDateTime(reminder.dateTime)),
            const SizedBox(height: 16),
            Text(
              'Repeat:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(reminder.repeatOption.name.toUpperCase()),
            const SizedBox(height: 16),
            Text(
              'Status:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  reminder.isCompleted ? Icons.check_circle : Icons.schedule,
                  color: reminder.isCompleted ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(reminder.isCompleted ? 'Completed' : 'Pending'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditReminderDialog(reminder);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${reminder.title} deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(remindersProvider.notifier).addReminder(reminder);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}