import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';
import 'sound_storage_service.dart';

enum BackendProvider {
  firebase,
  supabase,
}

class MobileBackendConfigService {
  static const String _backendKey = 'selected_backend';
  static BackendProvider _currentBackend = BackendProvider.firebase;

  static BackendProvider get currentBackend => _currentBackend;

  /// Initialize the selected backend service
  static Future<void> initialize() async {
    // You can load this from shared preferences
    // For now, defaulting to Firebase
    _currentBackend = BackendProvider.firebase;
    
    if (_currentBackend == BackendProvider.supabase) {
      await SupabaseService.initialize();
    }
    
    // Initialize sound storage service
    final soundService = SoundStorageService();
    await soundService.initialize();
  }

  /// Switch backend provider
  static Future<void> switchBackend(BackendProvider backend) async {
    _currentBackend = backend;
    // Save to shared preferences for persistence
    // await _saveBackendPreference(backend);
    
    if (backend == BackendProvider.supabase) {
      await SupabaseService.initialize();
    }
  }

  /// Get the current backend service instance (mobile only)
  static FirebaseService getCurrentBackendService() {
    // For mobile platforms, use configured backend
    switch (_currentBackend) {
      case BackendProvider.firebase:
        return FirebaseServiceImpl();
      case BackendProvider.supabase:
        return SupabaseService();
    }
  }

  /// Check if current backend is available
  static bool isCurrentBackendAvailable() {
    switch (_currentBackend) {
      case BackendProvider.firebase:
        try {
          // Check Firebase availability
          return true; // You can add more specific checks
        } catch (e) {
          return false;
        }
      case BackendProvider.supabase:
        try {
          // Check Supabase availability
          return true; // You can add more specific checks
        } catch (e) {
          return false;
        }
    }
  }

  /// Get available backends
  static List<BackendProvider> getAvailableBackends() {
    final List<BackendProvider> available = [];
    
    // Always add Firebase (it's configured)
    available.add(BackendProvider.firebase);
    
    // Add Supabase if configured
    // You can add configuration checks here
    available.add(BackendProvider.supabase);
    
    return available;
  }
}

// Extension for better display names
extension BackendProviderExtension on BackendProvider {
  String get displayName {
    switch (this) {
      case BackendProvider.firebase:
        return 'Firebase';
      case BackendProvider.supabase:
        return 'Supabase';
    }
  }

  String get description {
    switch (this) {
      case BackendProvider.firebase:
        return 'Google Firebase - Current backend';
      case BackendProvider.supabase:
        return 'Supabase - PostgreSQL backend';
    }
  }
}