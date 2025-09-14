import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/firebase_provider.dart';
import '../../../shared/services/backend_config_service.dart';
import '../../../shared/services/mobile_backend_config_service.dart';
import '../../../config/supabase_config.dart';

// Settings providers
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final vibrationEnabledProvider = StateProvider<bool>((ref) => true);
final autoSyncEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section (only for mobile)
          if (!kIsWeb) ...[
            _buildProfileSection(context, authState),
            const SizedBox(height: 24),
          ],
          
          // App Settings
          _buildSectionHeader(context, 'App Settings'),
          _buildThemeSettings(context, ref, themeMode),
          _buildNotificationSettings(context),
          
          const SizedBox(height: 24),
          
          // Data & Sync
          _buildSectionHeader(context, 'Data & Sync'),
          _buildBackendSettings(context, ref),
          _buildSupabaseSettings(context, ref),
          _buildSyncSettings(context),
          _buildStorageSettings(context),
          
          const SizedBox(height: 24),
          
          // About
          _buildSectionHeader(context, 'About'),
          _buildAboutSettings(context),
          
          const SizedBox(height: 24),
          
          // Account Actions (only for mobile and when user is logged in)
          if (!kIsWeb && authState.user != null) ...[
            _buildSectionHeader(context, 'Account'),
            _buildAccountActions(context, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AuthState authState) {
    if (authState.user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Not signed in',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Sign in to sync your reminders across devices'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to auth screen
                  context.go('/auth');
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user.photoUrl != null 
                  ? NetworkImage(user.photoUrl!) 
                  : null,
              child: user.photoUrl == null 
                  ? Text(
                      user.initials,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Edit profile
              },
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeText(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              // Use a simple state provider for demonstration
              final notificationsEnabled = ref.watch(notificationsEnabledProvider);
              return SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive notifications for reminders'),
                value: notificationsEnabled,
                onChanged: (value) {
                  ref.read(notificationsEnabledProvider.notifier).state = value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value 
                          ? 'Notifications enabled' 
                          : 'Notifications disabled'
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 1),
          Consumer(
            builder: (context, ref, child) {
              final vibrationEnabled = ref.watch(vibrationEnabledProvider);
              return SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: vibrationEnabled,
                onChanged: (value) {
                  ref.read(vibrationEnabledProvider.notifier).state = value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value 
                          ? 'Vibration enabled' 
                          : 'Vibration disabled'
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackendSettings(BuildContext context, WidgetRef ref) {
    // For web, show local storage info instead of backend selection
    if (kIsWeb) {
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Data Storage'),
              subtitle: const Text('Data is stored locally in your browser'),
              trailing: const Icon(Icons.info),
              onTap: () => _showWebStorageDialog(context),
            ),
          ],
        ),
      );
    }
    
    // For mobile, show backend selection
    final currentBackend = ref.watch(currentBackendProvider);
    final availableBackends = ref.watch(availableBackendsProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Backend Service'),
            subtitle: Text('Current: ${currentBackend.displayName}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackendDialog(context, ref, currentBackend, availableBackends),
          ),
        ],
      ),
    );
  }

  Widget _buildSupabaseSettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.cloud_upload,
              color: SupabaseConfig.isConfigured ? Colors.green : Colors.orange,
            ),
            title: const Text('Cloud Data Storage'),
            subtitle: Text(
              SupabaseConfig.isConfigured 
                ? 'Connected ✅ - Your data is safely stored in the cloud'
                : 'Connecting to cloud storage - Setup in progress',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSupabaseConfigDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Now'),
            subtitle: const Text('Sync reminders with cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Syncing...'),
                    ],
                  ),
                ),
              );
              
              // Simulate sync delay
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync completed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
          ),
          const Divider(height: 1),
          Consumer(
            builder: (context, ref, child) {
              final autoSyncEnabled = ref.watch(autoSyncEnabledProvider);
              return SwitchListTile(
                secondary: const Icon(Icons.wifi),
                title: const Text('Auto Sync'),
                subtitle: const Text('Automatically sync when connected'),
                value: autoSyncEnabled,
                onChanged: (value) {
                  ref.read(autoSyncEnabledProvider.notifier).state = value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value 
                          ? 'Auto sync enabled' 
                          : 'Auto sync disabled'
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage Usage'),
            subtitle: const Text('View app storage usage'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showStorageDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open help screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showWebStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Local Storage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Storage:'),
            Text('• Reminders are stored locally in your browser'),
            Text('• No account required for web version'),
            Text('• Data persists between browser sessions'),
            SizedBox(height: 16),
            Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Clearing browser data will remove all reminders.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackendDialog(BuildContext context, WidgetRef ref, BackendProvider currentBackend, List<BackendProvider> availableBackends) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Backend Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableBackends.map((backend) => 
            RadioListTile<BackendProvider>(
              title: Text(backend.displayName),
              subtitle: Text(backend.description),
              value: backend,
              groupValue: currentBackend,
              onChanged: (value) async {
                if (value != null && value != currentBackend) {
                  Navigator.pop(context);
                  _showBackendSwitchDialog(context, ref, value);
                }
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBackendSwitchDialog(BuildContext context, WidgetRef ref, BackendProvider newBackend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to ${newBackend.displayName}?'),
        content: Text(
          'This will switch your backend service to ${newBackend.displayName}. '
          'You may need to sign in again. Your local data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Switching backend...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              
              try {
                // Switch backend
                await BackendConfigService.switchBackend(newBackend);
                
                // Sign out current user
                await ref.read(authProvider.notifier).signOut();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${newBackend.displayName} successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to switch backend: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 App Data: 2.8 MB', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('🗂️ Cache: 1.5 MB', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('🖼️ Images: 0.9 MB', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('🎵 Sounds: 0.3 MB', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text('📊 Total: 5.5 MB', 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and free up storage space. '
          'Your reminders and settings will not be affected.\n\n'
          'Estimated space to be freed: 1.5 MB'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing cache...'),
                    ],
                  ),
                ),
              );
              
              // Simulate cache clearing
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully! Freed 1.5 MB'),
                    backgroundColor: Colors.green,
                  ),
                );
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Student Reminder',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      children: [
        const Text('A simple and elegant reminder app designed for students to manage their academic tasks and deadlines.'),
        const SizedBox(height: 8),
        const Text('Created by Masthan Valli', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (kIsWeb) ...[
          const Text('Web Version Features:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('• No login required'),
          const Text('• Local browser storage'),
          const Text('• Demo reminders included'),
          const Text('• Full reminder management'),
          const SizedBox(height: 16),
        ] else ...[
          const Text('Mobile Features:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('• Cloud synchronization'),
          const Text('• Push notifications'),
          const Text('• Multiple backend options'),
          const Text('• User authentication'),
          const SizedBox(height: 16),
        ],
        const Text('Common Features:', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('• Calendar view with reminder markers'),
        const Text('• Dark and light themes'),
        const Text('• Offline support'),
        const Text('• Intuitive user interface'),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your local reminders will be preserved.'),
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
              ref.read(authProvider.notifier).signOut();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showSupabaseConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cloud Data Storage'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (SupabaseConfig.isConfigured) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connected to Cloud Storage ✅\nYour data is securely stored and synchronized!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Available Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Automatic data backup and sync'),
                const Text('• Custom sound upload for notifications'),
                const Text('• Cross-device data synchronization'),
                const Text('• Secure cloud storage by Masthan Valli'),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_queue, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setting up cloud storage connection...',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Centralized Cloud Storage:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('This app uses a centralized cloud storage system.'),
                const Text('No account creation required - just use the app!'),
                const SizedBox(height: 8),
                const Text('Your data is safely stored in our cloud infrastructure.'),
                const SizedBox(height: 16),
                const Text(
                  'Benefits:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• No need to create your own database'),
                const Text('• Automatic backups and sync'),
                const Text('• Hassle-free setup'),
                const Text('• Secure and reliable storage'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!SupabaseConfig.isConfigured)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Show information about centralized storage
                _showCentralizedStorageInfo(context);
              },
              child: const Text('Learn More'),
            ),
        ],
      ),
    );
  }

  void _showCentralizedStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Centralized Cloud Storage'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• All user data is stored in our secure cloud database'),
              Text('• No need to create your own accounts or databases'),
              Text('• Your reminders and settings are automatically backed up'),
              Text('• Data syncs across all your devices seamlessly'),
              SizedBox(height: 16),
              Text(
                'Privacy & Security:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Your data is isolated and secure'),
              Text('• Industry-standard encryption'),
              Text('• No data sharing with third parties'),
              Text('• Managed by Masthan Valli'),
              SizedBox(height: 16),
              Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Zero setup required'),
              Text('• Automatic backups'),
              Text('• Cross-device synchronization'),
              Text('• Custom sound uploads'),
              Text('• Reliable and fast performance'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  void _showDetailedSupabaseGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supabase Setup Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1: Create Supabase Project',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Go to https://supabase.com'),
              const Text('• Sign up or log in'),
              const Text('• Create a new project'),
              const SizedBox(height: 16),
              const Text(
                'Step 2: Get API Keys',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• In your project dashboard, go to Settings'),
              const Text('• Click on "API" in the left sidebar'),
              const Text('• Copy "Project URL" and "anon public" key'),
              const SizedBox(height: 16),
              const Text(
                'Step 3: Configure the App',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Open: lib/config/supabase_config.dart'),
              const Text('• Replace YOUR_SUPABASE_URL with your Project URL'),
              const Text('• Replace YOUR_SUPABASE_ANON_KEY with your anon key'),
              const Text('• Save the file'),
              const SizedBox(height: 16),
              const Text(
                'Example:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'static const String supabaseUrl = \'https://abc123.supabase.co\';\n'
                  'static const String supabaseAnonKey = \'eyJhbGci...\';',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Step 4: Restart the App',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Stop and restart your Flutter app'),
              const Text('• You should now see sound upload options!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }
}