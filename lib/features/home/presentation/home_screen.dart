import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/reminder_provider.dart';
import '../../../shared/widgets/bottom_navigation.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _hasSynced = false;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const RemindersScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    // Sync reminders with cloud when home screen loads (only once)
    if (!_hasSynced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncRemindersWithCloud();
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _syncRemindersWithCloud() async {
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        final reminderNotifier = ref.read(remindersProvider.notifier);
        await reminderNotifier.syncWithCloud(authState.user!.id);
        
        setState(() {
          _hasSynced = true;
        });
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminders synced with cloud'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Handle sync error silently or show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync reminders with cloud'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}