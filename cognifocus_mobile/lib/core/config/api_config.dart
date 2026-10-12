/// Centralized API Configuration for CogniFocus-AI Mobile
///
/// Supports configurable base URL for:
/// - Android Emulator: `http://10.0.2.2:5000`
/// - Physical Android Phone on same Wi-Fi: `http://192.168.x.x:5000`
/// - Production / HTTPS deployment: `https://your-domain.com`
class ApiConfig {
  ApiConfig._();

  static const String serverUrlStorageKey = 'cognifocus_server_url';
  static const String authTokenStorageKey = 'cognifocus_auth_token';
  static const String authUserStorageKey = 'cognifocus_auth_user';

  /// Laptop's actual LAN IPv4 address (configurable via build environment or defaults to 10.223.8.206)
  static const String laptopLanIp = String.fromEnvironment(
    'LAPTOP_LAN_IP',
    defaultValue: '10.223.8.206',
  );

  /// Default server URL for local Flask development without TLS on physical Android phones
  static const String physicalPhoneServerUrl = 'http://$laptopLanIp:5000';

  /// Standard Android emulator loopback alias
  static const String emulatorServerUrl = 'http://10.0.2.2:5000';

  /// Compile-time configurable API base URL via `--dart-define=API_BASE_URL=http://<ip>:5000`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Compile-time flag for emulator builds via `--dart-define=USE_EMULATOR=true`
  static const bool isEmulator =
      bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

  /// Default server URL:
  /// - Prioritizes `--dart-define=API_BASE_URL=...` when provided at build/run time.
  /// - For Android emulator builds (when USE_EMULATOR=true), uses `http://10.0.2.2:5000`.
  /// - For physical devices (default), uses `http://10.223.8.206:5000`.
  static const String defaultServerUrl = _envBaseUrl != ''
      ? _envBaseUrl
      : (isEmulator ? emulatorServerUrl : physicalPhoneServerUrl);

  static bool get hasEnvBaseUrl => _envBaseUrl.trim().isNotEmpty;
  static String get envBaseUrl => normalizeUrl(_envBaseUrl);

  /// Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 12);

  // Auth Endpoints
  static const String loginPath = '/api/auth/login';
  static const String mePath = '/api/auth/me';
  static const String logoutPath = '/api/auth/logout';

  // Admin Endpoints
  static const String adminStartMonitoringPath = '/api/admin/start-monitoring';
  static const String adminStopMonitoringPath = '/api/admin/stop-monitoring';
  static const String monitorStatusPath = '/api/monitor/status';
  static const String camerasPath = '/api/cameras';
  static const String camerasStatusPath = '/api/cameras/status';

  // Teacher Endpoints
  static const String teacherEnterClassroomPath =
      '/api/teacher/classroom/enter';
  static const String teacherLeaveClassroomPath =
      '/api/teacher/classroom/leave';
  static const String teacherCurrentClassroomPath =
      '/api/teacher/classroom/current';
  static const String teacherStatsPath = '/api/teacher/dashboard/stats';
  static const String teacherClassroomsPath = '/api/teacher/classrooms';
  static const String teacherCamerasPath = '/api/teacher/cameras';
  static const String teacherAlertsPath = '/api/teacher/alerts';

  // Alerts Endpoints
  static const String alertsPath = '/api/alerts';
  static const String alertsSummaryPath = '/api/alerts/summary';

  // Classrooms Endpoints
  static const String classroomsPath = '/api/classrooms';

  // Notifications Endpoints
  static const String notificationsPreferencesPath =
      '/api/notifications/preferences';
  static const String testEmailNotificationPath =
      '/api/notifications/test-email';
  static const String testSmsNotificationPath = '/api/notifications/test-sms';
  static const String registerDevicePath =
      '/api/notifications/register-device';
  static const String unregisterDevicePath =
      '/api/notifications/unregister-device';
  static const String testPushNotificationPath =
      '/api/notifications/test-push';
  static const String fcmStatusPath =
      '/api/notifications/fcm-status';

  /// Returns true if the host is a local loopback, LAN IP, or emulator alias
  static bool isLocalAddress(String url) {
    final lower = url.toLowerCase();
    return lower.contains('10.134.37.206') ||
        lower.contains('127.0.0.1') ||
        lower.contains('10.0.2.2') ||
        lower.contains('localhost') ||
        lower.contains('10.223.8.206') ||
        lower.contains('192.168.') ||
        lower.contains('10.');
  }

  /// Clean, normalize, and format server URL input
  static String normalizeUrl(String input) {
    var cleaned = input.trim();
    if (cleaned.isEmpty) {
      return defaultServerUrl;
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    // Prevent HTTPS override for local development endpoints without TLS:
    // Local Flask server runs plain HTTP on port 5000. Any HTTPS attempt to a local IP hangs on TLS handshake.
    if (cleaned.startsWith('https://') && isLocalAddress(cleaned)) {
      cleaned = cleaned.replaceFirst('https://', 'http://');
    }
    return cleaned;
  }

  /// Construct camera frame JPEG URL
  static String getCameraFrameUrl({
    required String baseUrl,
    required String cameraId,
    String? token,
  }) {
    final cleanBase = normalizeUrl(baseUrl);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tokenParam = token != null && token.isNotEmpty
        ? '&token=${Uri.encodeComponent(token)}'
        : '';
    return '$cleanBase/api/cameras/$cameraId/frame.jpg?t=$timestamp$tokenParam';
  }

  /// Construct evidence image URL
  static String getEvidenceUrl({
    required String baseUrl,
    required String? relativePath,
  }) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final cleanBase = normalizeUrl(baseUrl);
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath
        : '/$relativePath';
    return '$cleanBase$normalizedPath';
  }
}
