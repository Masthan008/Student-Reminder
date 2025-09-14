import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';
import 'sound_storage_service.dart';
import 'mobile_backend_config_service.dart' show MobileBackendConfigService, BackendProvider, BackendProviderExtension;

// Conditional import: use web service for web, stub for mobile
import 'web_local_service.dart' if (dart.library.io) 'web_local_service_stub.dart';

class BackendConfigService {
  static const String _backendKey = 'selected_backend';
  static BackendProvider _currentBackend = BackendProvider.firebase;

  static BackendProvider get currentBackend => _currentBackend;

  /// Initialize the selected backend service
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web platform initialization
      _currentBackend = BackendProvider.firebase;
      
      // Initialize sound storage service
      final soundService = SoundStorageService();
      await soundService.initialize();
    } else {
      // Mobile platform initialization
      await MobileBackendConfigService.initialize();
      _currentBackend = MobileBackendConfigService.currentBackend;
    }
  }

  /// Switch backend provider
  static Future<void> switchBackend(BackendProvider backend) async {
    if (kIsWeb) {
      // Web platforms don't support backend switching
      return;
    } else {
      // Mobile platform backend switching
      await MobileBackendConfigService.switchBackend(backend);
      _currentBackend = backend;
    }
  }

  /// Get the current backend service instance
  static dynamic getCurrentBackendService() {
    // For web platform, always use local storage (no authentication)
    if (kIsWeb) {
      // Create web service directly
      return WebLocalService();
    }
    
    // For mobile platforms, delegate to mobile backend service
    return MobileBackendConfigService.getCurrentBackendService();
  }

  /// Check if current backend is available
  static bool isCurrentBackendAvailable() {
    if (kIsWeb) {
      return true; // Web local storage is always available
    } else {
      return MobileBackendConfigService.isCurrentBackendAvailable();
    }
  }

  /// Get available backends
  static List<BackendProvider> getAvailableBackends() {
    if (kIsWeb) {
      // Web only supports local storage (shown as Firebase)
      return [BackendProvider.firebase];
    } else {
      return MobileBackendConfigService.getAvailableBackends();
    }
  }
}