import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../models/user_model.dart';

/// Persistent local storage service for CogniFocus-AI
class StorageService {
  static const String themeModeStorageKey = 'cognifocus_theme_mode';
  final SharedPreferences? _prefs;

  StorageService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs;
    return await SharedPreferences.getInstance();
  }

  /// Get stored Server URL (falls back to default configured endpoint)
  Future<String> getServerUrl() async {
    if (ApiConfig.hasEnvBaseUrl) {
      return ApiConfig.envBaseUrl;
    }
    final prefs = await _getPrefs();
    final stored = prefs.getString(ApiConfig.serverUrlStorageKey);
    if (stored != null && stored.trim().isNotEmpty) {
      // If stored points to previous temporary hotspot IP (10.134.37.206) or stale emulator IP, reset to current default
      if (stored.contains('10.134.37.206') ||
          (!ApiConfig.isEmulator && stored.contains('10.0.2.2'))) {
        await prefs.remove(ApiConfig.serverUrlStorageKey);
        return ApiConfig.defaultServerUrl;
      }
      final normalized = ApiConfig.normalizeUrl(stored);
      if (normalized != stored) {
        // Persist corrected scheme (e.g. converting https:// to http:// for local Flask server)
        await prefs.setString(ApiConfig.serverUrlStorageKey, normalized);
      }
      return normalized;
    }
    return ApiConfig.defaultServerUrl;
  }

  /// Save Server URL
  Future<void> saveServerUrl(String url) async {
    final prefs = await _getPrefs();
    final normalized = ApiConfig.normalizeUrl(url);
    await prefs.setString(ApiConfig.serverUrlStorageKey, normalized);
  }

  /// Get stored Auth Token
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(ApiConfig.authTokenStorageKey);
  }

  /// Save Auth Token
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(ApiConfig.authTokenStorageKey, token);
  }

  /// Clear Auth Token
  Future<void> clearToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(ApiConfig.authTokenStorageKey);
  }

  /// Get stored User profile
  Future<UserModel?> getUser() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(ApiConfig.authUserStorageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          return UserModel.fromJson(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Save User profile
  Future<void> saveUser(UserModel user) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(user.toJson());
    await prefs.setString(ApiConfig.authUserStorageKey, encoded);
  }

  /// Clear User profile
  Future<void> clearUser() async {
    final prefs = await _getPrefs();
    await prefs.remove(ApiConfig.authUserStorageKey);
  }

  /// Clear entire session (token and user profile), preserving server URL and theme
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(ApiConfig.authTokenStorageKey);
    await prefs.remove(ApiConfig.authUserStorageKey);
  }

  /// Get stored ThemeMode preference (returns null if never set, meaning default to system)
  Future<ThemeMode?> getThemeMode() async {
    final prefs = await _getPrefs();
    final value = prefs.getString(themeModeStorageKey);
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    if (value == 'system') return ThemeMode.system;
    return null;
  }

  /// Save selected ThemeMode preference
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString(themeModeStorageKey, value);
  }
}
