import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/supabase_config.dart';
import '../services/backend_config_service.dart';

class SoundStorageService {
  static final SoundStorageService _instance = SoundStorageService._internal();
  factory SoundStorageService() => _instance;
  SoundStorageService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  SupabaseClient? _supabaseClient;

  /// Initialize with Supabase credentials from config
  Future<void> initialize() async {
    try {
      if (!SupabaseConfig.isConfigured) {
        if (kDebugMode) {
          print('Sound Storage Service: Supabase not configured');
          print(SupabaseConfig.configurationMessage);
        }
        return;
      }

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _supabaseClient = Supabase.instance.client;
      
      // Create sounds bucket if it doesn't exist
      await _createSoundsBucket();
      
      if (kDebugMode) {
        print('Sound Storage Service initialized with Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Sound Storage Service: $e');
      }
    }
  }

  /// Create the sounds bucket in Supabase
  Future<void> _createSoundsBucket() async {
    try {
      // Check if bucket exists first
      final buckets = await _supabaseClient?.storage.listBuckets();
      final soundsBucketExists = buckets?.any((bucket) => bucket.name == SupabaseConfig.soundsBucketName) ?? false;
      
      if (!soundsBucketExists) {
        await _supabaseClient?.storage.createBucket(
          SupabaseConfig.soundsBucketName,
          BucketOptions(
            public: true,
            allowedMimeTypes: ['audio/mpeg', 'audio/wav', 'audio/mp3', 'audio/ogg', 'audio/aac', 'audio/webm'],
          ),
        );
        if (kDebugMode) {
          print('✅ Created sounds bucket in Supabase');
        }
      } else {
        if (kDebugMode) {
          print('✅ Sounds bucket already exists in Supabase');
        }
      }
    } catch (e) {
      // Don't fail initialization if bucket creation fails
      // The bucket might already exist or need manual setup
      if (kDebugMode) {
        print('⚠️ Could not create sounds bucket (may already exist): $e');
        print('💡 If upload fails, please run the SUPABASE_STORAGE_SETUP.sql script in your Supabase dashboard');
      }
    }
  }

  /// Pick an audio file from device
  Future<PlatformFile?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking audio file: $e');
      }
    }
    return null;
  }

  /// Upload sound file to Supabase Storage
  Future<String?> uploadSound({
    required PlatformFile file,
    required String userId,
    String? customName,
  }) async {
    try {
      if (_supabaseClient == null) {
        throw Exception('Supabase not initialized');
      }

      // Sanitize file name to avoid invalid characters
      String sanitizedFileName = customName ?? file.name;
      
      // Remove or replace invalid characters for cloud storage
      sanitizedFileName = sanitizedFileName
          .replaceAll(RegExp(r'[^\w\s-_\.]'), '') // Keep only word chars, spaces, hyphens, underscores, dots
          .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
          .replaceAll(RegExp(r'_{2,}'), '_'); // Replace multiple underscores with single
      
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final filePath = 'user_sounds/$userId/$fileName';

      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        if (file.path != null) {
          fileBytes = await File(file.path!).readAsBytes();
        }
      }

      if (fileBytes == null) {
        throw Exception('Could not read file data');
      }

      // Upload to Supabase Storage
      await _supabaseClient!.storage
          .from(SupabaseConfig.soundsBucketName)
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final publicUrl = _supabaseClient!.storage
          .from(SupabaseConfig.soundsBucketName)
          .getPublicUrl(filePath);

      if (kDebugMode) {
        print('Sound uploaded successfully: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading sound: $e');
      }
      return null;
    }
  }

  /// Download and cache sound locally for mobile
  Future<String?> downloadAndCacheSound({
    required String soundUrl,
    required String soundId,
  }) async {
    try {
      if (kIsWeb) {
        return soundUrl; // Web can play directly from URL
      }

      final directory = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${directory.path}/sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final localPath = '${soundsDir.path}/$soundId.mp3';
      final localFile = File(localPath);

      if (await localFile.exists()) {
        return localPath; // Already cached
      }

      // Download from Supabase
      final response = await _supabaseClient!.storage
          .from(SupabaseConfig.soundsBucketName)
          .download(soundUrl.split('/sounds/').last);

      await localFile.writeAsBytes(response);

      if (kDebugMode) {
        print('Sound cached locally: $localPath');
      }

      return localPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading sound: $e');
      }
      return null;
    }
  }

  /// Play sound file
  Future<void> playSound(String soundPath) async {
    try {
      // Handle system sounds
      if (soundPath.startsWith('system_')) {
        // For system sounds, just use a simple beep or notification sound
        // This would be the default notification sound on the device
        if (kDebugMode) {
          print('Playing system sound: $soundPath');
        }
        return; // System will handle notification sound
      }
      
      if (kIsWeb) {
        await _audioPlayer.play(UrlSource(soundPath));
      } else {
        await _audioPlayer.play(DeviceFileSource(soundPath));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }

  /// Stop playing sound
  Future<void> stopSound() async {
    await _audioPlayer.stop();
  }

  /// Get list of uploaded sounds for user
  Future<List<String>> getUserSounds(String userId) async {
    try {
      if (_supabaseClient == null) return [];

      final files = await _supabaseClient!.storage
          .from(SupabaseConfig.soundsBucketName)
          .list(path: 'user_sounds/$userId');

      return files.map((file) => 
        _supabaseClient!.storage
            .from(SupabaseConfig.soundsBucketName)
            .getPublicUrl('user_sounds/$userId/${file.name}')
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user sounds: $e');
      }
      return [];
    }
  }

  /// Delete sound from storage
  Future<bool> deleteSound({
    required String soundUrl,
    required String userId,
  }) async {
    try {
      if (_supabaseClient == null) return false;

      final filePath = soundUrl.split('/sounds/').last;
      await _supabaseClient!.storage
          .from(SupabaseConfig.soundsBucketName)
          .remove([filePath]);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting sound: $e');
      }
      return false;
    }
  }

  /// Get default notification sounds
  List<Map<String, String>> getDefaultSounds() {
    return [
      {'name': 'Default System', 'path': 'system_default'},
      {'name': 'Notification Tone', 'path': 'system_notification'},
      {'name': 'Alert Tone', 'path': 'system_alert'},
      {'name': 'Gentle Chime', 'path': 'system_chime'},
    ];
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}