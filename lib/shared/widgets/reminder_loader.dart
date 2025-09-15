import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/reminder_provider.dart';

class ReminderLoader extends ConsumerStatefulWidget {
  final Widget child;
  
  const ReminderLoader({super.key, required this.child});

  @override
  ConsumerState<ReminderLoader> createState() => _ReminderLoaderState();
}

class _ReminderLoaderState extends ConsumerState<ReminderLoader> {
  bool _remindersLoaded = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Load reminders when user is authenticated and not already loaded
    if (authState.user != null && !_remindersLoaded && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReminders(authState.user!.id);
      });
    }

    // Reset loaded state when user logs out
    if (authState.user == null && _remindersLoaded) {
      setState(() {
        _remindersLoaded = false;
      });
    }

    return Stack(
      children: [
        widget.child,
        if (!_remindersLoaded && authState.user != null)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Future<void> _loadReminders(String userId) async {
    setState(() {
      _loading = true;
    });
    try {
      final reminderNotifier = ref.read(remindersProvider.notifier);
      await reminderNotifier.loadReminders(userId);
      setState(() {
        _remindersLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load reminders'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}