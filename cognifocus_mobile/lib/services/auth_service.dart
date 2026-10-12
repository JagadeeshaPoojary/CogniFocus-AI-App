import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class LoginResult {
  final UserModel user;
  final String token;
  final String message;

  LoginResult({required this.user, required this.token, required this.message});
}

/// Authentication Service for CogniFocus-AI
class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  /// Login with email and password
  Future<LoginResult> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    debugPrint('[AuthService] Login request initiated for $cleanEmail');

    final response = await _apiClient.post(
      ApiConfig.loginPath,
      body: {'email': cleanEmail, 'password': password},
    );

    if (response is Map) {
      final success = response['success'] == true;
      final token = response['token']?.toString();
      final userMap = response['user'];

      if (!success ||
          token == null ||
          token.isEmpty ||
          userMap is! Map) {
        final msg =
            response['message']?.toString() ??
            'Invalid response from authentication server.';
        debugPrint('[AuthService] Login response invalid or unsuccessful: $msg');
        throw ApiException(message: msg);
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(userMap));

      // Save token in memory and local storage
      _apiClient.setAuthToken(token);
      await _storageService.saveToken(token);
      await _storageService.saveUser(user);

      debugPrint(
        '[AuthService] Login successful. User: ${user.email}, Role: ${user.role}, TokenSaved: ${token.isNotEmpty}',
      );

      return LoginResult(
        user: user,
        token: token,
        message: response['message']?.toString() ?? 'Login successful',
      );
    }

    throw ApiException(
      message: 'Unexpected server response format during login.',
    );
  }

  /// Verify existing session with /api/auth/me
  Future<UserModel?> getMe() async {
    debugPrint('[AuthService] Verifying active session via ${ApiConfig.mePath}');
    try {
      final response = await _apiClient.get(ApiConfig.mePath);
      if (response is Map && response['success'] == true) {
        final userMap = response['user'];
        if (userMap is Map) {
          final user = UserModel.fromJson(Map<String, dynamic>.from(userMap));
          await _storageService.saveUser(user);
          debugPrint(
            '[AuthService] /api/auth/me verified. User: ${user.email}, Role: ${user.role}',
          );
          return user;
        }
      }
      return null;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // Explicit 401: Token has expired or is invalid
        debugPrint(
          '[AuthService] /api/auth/me returned 401 Unauthorized. Clearing local tokens.',
        );
        await _storageService.clearAll();
        _apiClient.setAuthToken(null);
      }
      rethrow;
    }
  }

  /// Logout user and release server leases
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.logoutPath);
    } catch (_) {
      // Backend logout best-effort
    } finally {
      _apiClient.setAuthToken(null);
      await _storageService.clearAll();
    }
  }
}
