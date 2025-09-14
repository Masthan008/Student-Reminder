import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return HiveLocalStorageService();
});

// Provider for initializing storage
final storageInitializationProvider = FutureProvider<void>((ref) async {
  final storageService = ref.read(localStorageServiceProvider);
  await storageService.initialize();
});

// Provider for theme mode from storage
final storedThemeModeProvider = FutureProvider<String?>((ref) async {
  final storageService = ref.read(localStorageServiceProvider);
  return await storageService.getThemeMode();
});