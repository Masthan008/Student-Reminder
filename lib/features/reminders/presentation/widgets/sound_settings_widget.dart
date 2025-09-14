import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/services/sound_storage_service.dart';
import '../../../../config/supabase_config.dart';

class SoundSettingsWidget extends StatefulWidget {
  final String? selectedSoundUrl;
  final String? selectedSoundName;
  final Function(String? soundUrl, String? soundName) onSoundChanged;
  final String userId;

  const SoundSettingsWidget({
    super.key,
    this.selectedSoundUrl,
    this.selectedSoundName,
    required this.onSoundChanged,
    required this.userId,
  });

  @override
  State<SoundSettingsWidget> createState() => _SoundSettingsWidgetState();
}

class _SoundSettingsWidgetState extends State<SoundSettingsWidget> {
  final SoundStorageService _soundService = SoundStorageService();
  List<String> _userSounds = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeSound();
  }

  Future<void> _initializeSound() async {
    await _soundService.initialize();
    if (SupabaseConfig.isConfigured) {
      await _loadUserSounds();
    }
  }

  Future<void> _loadUserSounds() async {
    if (!SupabaseConfig.isConfigured) return;
    
    setState(() => _isLoading = true);
    try {
      final sounds = await _soundService.getUserSounds(widget.userId);
      setState(() => _userSounds = sounds);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user sounds: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSound() async {
    if (!SupabaseConfig.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    setState(() => _isUploading = true);
    try {
      final file = await _soundService.pickAudioFile();
      if (file != null) {
        final soundUrl = await _soundService.uploadSound(
          file: file,
          userId: widget.userId,
        );
        
        if (soundUrl != null) {
          await _loadUserSounds();
          widget.onSoundChanged(soundUrl, file.name);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sound "${file.name}" uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload sound: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _playSound(String soundUrl) async {
    try {
      await _soundService.playSound(soundUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play sound: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎵 Cloud Storage Setup'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your sounds will be stored in our secure cloud storage.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('We are setting up the cloud connection for you.'),
              const SizedBox(height: 8),
              const Text('No action required on your part!'),
              const SizedBox(height: 16),
              const Text(
                'Cloud Storage Benefits:',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('• Automatic backup of your custom sounds'),
              const Text('• Access sounds from any device'),
              const Text('• Secure and reliable storage'),
              const Text('• No setup required from you'),
            ],
          ),
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

  Widget _buildDefaultSounds() {
    final defaultSounds = _soundService.getDefaultSounds();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Default Sounds',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...defaultSounds.map((sound) => ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(sound['name']!),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSound(sound['path']!),
              ),
              Radio<String?>(
                value: sound['path'],
                groupValue: widget.selectedSoundUrl,
                onChanged: (value) {
                  widget.onSoundChanged(value, sound['name']);
                },
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCustomSounds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom Sounds',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadSound,
              icon: _isUploading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Sound'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!SupabaseConfig.isConfigured)
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_queue, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Cloud Storage Setup',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Setting up cloud storage for your custom sounds...'),
                  const SizedBox(height: 8),
                  const Text('• No action required from you'),
                  const Text('• Your sounds will be automatically backed up'),
                  const Text('• Managed by Masthan Valli'),
                ],
              ),
            ),
          )
        else if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_userSounds.isEmpty)
          const Text('No custom sounds uploaded yet')
        else
          ..._userSounds.map((soundUrl) {
            final soundName = soundUrl.split('/').last;
            return ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(soundName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playSound(soundUrl),
                  ),
                  Radio<String?>(
                    value: soundUrl,
                    groupValue: widget.selectedSoundUrl,
                    onChanged: (value) {
                      widget.onSoundChanged(value, soundName);
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.volume_up),
                SizedBox(width: 8),
                Text(
                  'Notification Sound',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // None option
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('No Sound'),
              trailing: Radio<String?>(
                value: null,
                groupValue: widget.selectedSoundUrl,
                onChanged: (value) {
                  widget.onSoundChanged(null, null);
                },
              ),
            ),
            
            const Divider(),
            
            // Default sounds
            _buildDefaultSounds(),
            
            const Divider(),
            
            // Custom sounds
            _buildCustomSounds(),
            
            if (widget.selectedSoundName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${widget.selectedSoundName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _soundService.stopSound();
    super.dispose();
  }
}