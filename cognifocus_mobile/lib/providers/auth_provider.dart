import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/classroom_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/teacher_service.dart';

/// AuthProvider: Central Authentication & Session State Management
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storageService;
  final AuthService _authService;
  final TeacherService _teacherService;
  final dynamic _notificationService;

  UserModel? _user;
  String? _token;
  String _serverUrl = ApiConfig.defaultServerUrl;
  bool _isInitializing = true;
  bool _isLoggingIn = false;
  bool _monitoringActive = false;
  ClassroomModel? _activeClassroom;
  String? _errorMessage;

  AuthProvider({
    required ApiClient apiClient,
    required StorageService storageService,
    required AuthService authService,
    required TeacherService teacherService,
    dynamic notificationService,
  }) : _apiClient = apiClient,
       _storageService = storageService,
       _authService = authService,
       _teacherService = teacherService,
       _notificationService = notificationService,
       _serverUrl = apiClient.baseUrl;

  UserModel? get user => _user;
  String? get token => _token;
  String get serverUrl => _serverUrl;
  bool get isInitializing => _isInitializing;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoading => _isInitializing || _isLoggingIn;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get monitoringActive => _monitoringActive;
  ClassroomModel? get activeClassroom => _activeClassroom;
  String? get errorMessage => _errorMessage;

  /// Initialize and restore stored session
  Future<void> initAuth() async {
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('[AuthProvider] Session initialization started.');

    try {
      _serverUrl = await _storageService.getServerUrl();
      _apiClient.updateBaseUrl(_serverUrl);
      debugPrint('[AuthProvider] Configured server endpoint: $_serverUrl');

      final savedToken = await _storageService.getToken();
      final savedUser = await _storageService.getUser();

      if (savedToken != null && savedToken.isNotEmpty && savedUser != null) {
        _token = savedToken;
        _user = savedUser;
        _apiClient.setAuthToken(savedToken);
        debugPrint(
          '[AuthProvider] Cached session restored: user=${savedUser.email}, role=${savedUser.role}. Token attached.',
        );

        // Verify session validity with backend
        try {
          debugPrint('[AuthProvider] Validating cached session with /api/auth/me...');
          final currentUser = await _authService.getMe();
          if (currentUser != null) {
            _user = currentUser;
            debugPrint('[AuthProvider] Session verified and refreshed. Role: ${currentUser.role}');
            if (currentUser.isTeacher) {
              _notificationService?.syncTokenWithBackend();
              await checkTeacherSession();
            }
          }
        } on ApiException catch (err) {
          if (err.isUnauthorized) {
            debugPrint(
              '[AuthProvider] Session expired (401). Clearing cached session.',
            );
            await logout();
          } else {
            debugPrint(
              '[AuthProvider] Network warning verifying session (retaining offline session): $err',
            );
          }
        } catch (err) {
          debugPrint(
            '[AuthProvider] Generic session verification warning: $err',
          );
        }
      } else {
        debugPrint('[AuthProvider] No saved session found.');
      }
    } catch (e) {
      debugPrint('[AuthProvider] Init error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
      debugPrint(
        '[AuthProvider] Session initialization completed. Authenticated: $isAuthenticated, Role: ${_user?.role}',
      );
    }
  }

  /// Check active teacher session
  Future<void> checkTeacherSession() async {
    try {
      final sess = await _teacherService.getCurrentClassroom();
      if (sess['success'] == true) {
        _monitoringActive = sess['monitoring_active'] == true;
        if (sess['classroom'] is Map) {
          _activeClassroom = ClassroomModel.fromJson(
            Map<String, dynamic>.from(sess['classroom'] as Map),
          );
        } else if (sess['classroom_id'] != null) {
          _activeClassroom = ClassroomModel(
            id: sess['classroom_id'].toString(),
            name:
                sess['classroom_name']?.toString() ??
                'Classroom ${sess['classroom_id']}',
            code:
                sess['classroom_code']?.toString() ??
                sess['classroom_id'].toString(),
          );
        }
        debugPrint(
          '[AuthProvider] Teacher session synced: monitoringActive=$_monitoringActive, classroom=${_activeClassroom?.name} (${_activeClassroom?.code})',
        );
        notifyListeners();
      }
    } catch (err) {
      debugPrint('[AuthProvider] Background teacher session sync warning: $err');
    }
  }

  /// Login user with credentials
  Future<void> login(String email, String password) async {
    _isLoggingIn = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('[AuthProvider] Processing login for: ${email.trim().toLowerCase()}');

    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _token = result.token;
      _errorMessage = null;

      debugPrint(
        '[AuthProvider] Authenticated state set. ID: ${_user!.id}, Role: ${_user!.role}, Email: ${_user!.email}',
      );

      // Trigger background sync for teacher session without blocking dashboard navigation
      if (_user!.isTeacher) {
        _notificationService?.syncTokenWithBackend();
        checkTeacherSession().catchError((err) {
          debugPrint('[AuthProvider] Background teacher session sync warning: $err');
        });
      }
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      debugPrint('[AuthProvider] Login failed: $_errorMessage');
      rethrow;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  /// Logout user and clear memory state
  Future<void> logout() async {
    debugPrint('[AuthProvider] Logging out user.');
    try {
      await _notificationService?.unregisterDeviceToken();
      await _authService.logout();
    } finally {
      _user = null;
      _token = null;
      _monitoringActive = false;
      _activeClassroom = null;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[AuthProvider] Logout completed. Session cleared.');
    }
  }

  /// Update backend server base URL
  Future<void> updateServerUrl(String newUrl) async {
    final normalized = ApiConfig.normalizeUrl(newUrl);
    _serverUrl = normalized;
    _apiClient.updateBaseUrl(normalized);
    await _storageService.saveServerUrl(normalized);
    notifyListeners();
  }

  /// Teacher enters classroom
  Future<void> enterClassroom(String code) async {
    _errorMessage = null;
    final result = await _teacherService.enterClassroom(code);
    if (result.success) {
      _monitoringActive = result.monitoringActive;
      _activeClassroom = ClassroomModel(
        id: result.classroomId,
        name: result.classroomName,
        code: result.classroomCode,
        isActive: true,
      );
      notifyListeners();
    }
  }

  /// Teacher stops monitoring
  Future<void> stopMonitoring() async {
    _errorMessage = null;
    final ok = await _teacherService.leaveClassroom();
    if (ok) {
      _monitoringActive = false;
      notifyListeners();
    }
  }

  /// Admin updates monitoring state
  void setMonitoringActive(bool active) {
    _monitoringActive = active;
    notifyListeners();
  }
}
