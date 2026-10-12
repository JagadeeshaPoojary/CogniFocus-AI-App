import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Centralized Theme Provider for CogniFocus-AI
///
/// Manages application-wide ThemeMode (Light, Dark, System), persists user
/// preferences across restarts, and enables instantaneous theme switching.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeProvider({required StorageService storageService})
      : _storageService = storageService;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Determines if the current rendered surface is dark
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Initialize and restore stored theme preference
  Future<void> initTheme() async {
    try {
      final savedMode = await _storageService.getThemeMode();
      if (savedMode != null) {
        _themeMode = savedMode;
      }
    } catch (e) {
      debugPrint('[ThemeProvider] Error loading theme: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Update theme mode and save to persistent storage
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(mode);
    debugPrint('[ThemeProvider] Theme mode set to: $mode');
  }

  /// Quick toggle between Light and Dark mode
  Future<void> toggleTheme([BuildContext? context]) async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      if (context != null) {
        final platformIsDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        await setThemeMode(platformIsDark ? ThemeMode.light : ThemeMode.dark);
      } else {
        await setThemeMode(ThemeMode.dark);
      }
    }
  }
}
