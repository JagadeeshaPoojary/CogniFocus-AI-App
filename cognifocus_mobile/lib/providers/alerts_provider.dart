import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/alert_model.dart';
import '../services/alerts_service.dart';
import '../services/notification_service.dart';
import '../services/teacher_service.dart';

/// AlertsProvider: Alert Filtering, Actions, Modal State & Real-Time Sync
class AlertsProvider extends ChangeNotifier {
  final AlertsService _alertsService;
  final TeacherService _teacherService;
  final NotificationService? _notificationService;

  List<AlertModel> _alerts = [];
  final Set<int> _knownAlertIds = {};
  int _lastSeenAlertId = 0;
  int _unreadCount = 0;
  AlertModel? _activeBannerAlert;

  bool _isLoading = false;
  String _statusFilter = 'All';
  String _timeframeFilter = 'All';
  AlertModel? _selectedAlert;
  String? _errorMessage;
  int _totalAlerts = 0;

  // Real-time synchronization state
  http.Client? _sseClient;
  StreamSubscription<String>? _sseSubscription;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  bool _isSyncing = false;
  String? _syncBaseUrl;
  String? _syncToken;
  String? _syncClassroomId;
  void Function(AlertModel)? _onAlertCallback;

  AlertsProvider({
    required AlertsService alertsService,
    required TeacherService teacherService,
    NotificationService? notificationService,
  })  : _alertsService = alertsService,
        _teacherService = teacherService,
        _notificationService = notificationService;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;
  String get timeframeFilter => _timeframeFilter;
  AlertModel? get selectedAlert => _selectedAlert;
  String? get errorMessage => _errorMessage;
  int get totalAlerts => _totalAlerts;
  int get unreadCount => _unreadCount;
  AlertModel? get activeBannerAlert => _activeBannerAlert;

  void selectAlert(AlertModel? alert) {
    _selectedAlert = alert;
    notifyListeners();
  }

  void clearBannerAlert() {
    _activeBannerAlert = null;
    notifyListeners();
  }

  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void setStatusFilter(String filter, {bool isTeacher = false}) {
    _statusFilter = filter;
    fetchAlerts(isTeacher: isTeacher);
  }

  void setTimeframeFilter(String filter, {bool isTeacher = false}) {
    _timeframeFilter = filter;
    fetchAlerts(isTeacher: isTeacher);
  }

  /// Start real-time alert synchronization (SSE + Polling fallback)
  void startRealtimeSync({
    required String baseUrl,
    String? token,
    String? classroomId,
    void Function(AlertModel)? onAlertReceived,
  }) {
    if (_isSyncing &&
        _syncBaseUrl == baseUrl &&
        _syncToken == token &&
        _syncClassroomId == classroomId) {
      return;
    }
    stopRealtimeSync();

    _isSyncing = true;
    _syncBaseUrl = baseUrl;
    _syncToken = token;
    _syncClassroomId = classroomId;
    _onAlertCallback = onAlertReceived;

    // Seed known alert IDs
    for (final a in _alerts) {
      _knownAlertIds.add(a.id);
      if (a.id > _lastSeenAlertId) {
        _lastSeenAlertId = a.id;
      }
    }

    _connectSse();
    _startPollingFallback();
  }

  /// Stop real-time synchronization
  void stopRealtimeSync() {
    _isSyncing = false;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.close();
    _sseClient = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Connect to backend Server-Sent Events stream
  Future<void> _connectSse() async {
    if (!_isSyncing || _syncBaseUrl == null) return;

    try {
      _sseSubscription?.cancel();
      _sseClient?.close();
      _sseClient = http.Client();

      final uri = Uri.parse('$_syncBaseUrl/api/teacher/notifications/stream');
      final request = http.Request('GET', uri);
      if (_syncToken != null && _syncToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_syncToken';
      }
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _sseClient!.send(request);
      if (response.statusCode == 200) {
        debugPrint('[AlertsProvider] SSE connection established to $uri');
        _sseSubscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            _handleSseLine(line);
          },
          onError: (err) {
            debugPrint('[AlertsProvider] SSE stream error: $err');
            _reconnectSseLater();
          },
          onDone: () {
            debugPrint('[AlertsProvider] SSE stream closed');
            _reconnectSseLater();
          },
          cancelOnError: true,
        );
      } else {
        debugPrint('[AlertsProvider] SSE returned status ${response.statusCode}');
        _reconnectSseLater();
      }
    } catch (e) {
      debugPrint('[AlertsProvider] SSE connection failed: $e');
      _reconnectSseLater();
    }
  }

  void _reconnectSseLater() {
    if (!_isSyncing) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (_isSyncing) {
        _connectSse();
      }
    });
  }

  void _handleSseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return;
    final payload = trimmed.substring(5).trim();
    if (payload.isEmpty || payload == 'ping') return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('alert_id') ||
            decoded['event'] == 'mobile_phone_detected' ||
            decoded['event'] == 'alert') {
          final alert = AlertModel(
            id: decoded['alert_id'] is int
                ? decoded['alert_id']
                : int.tryParse(decoded['alert_id']?.toString() ?? '') ??
                    (decoded['id'] is int
                        ? decoded['id']
                        : DateTime.now().millisecondsSinceEpoch),
            studentId: decoded['student_id']?.toString(),
            seatId: (decoded['seat_id'] ?? decoded['seat'])?.toString(),
            cameraId: (decoded['camera_id'] ?? 'CAM_01').toString(),
            alertType: (decoded['alert_type'] ??
                    'Suspected Mobile Phone Usage: Active Handhold')
                .toString(),
            confidence: (decoded['confidence'] as num?)?.toDouble() ?? 0.88,
            duration: (decoded['duration'] ?? '3s').toString(),
            status: 'Active',
            severity: (decoded['severity'] ?? 'High').toString(),
            evidenceImage: decoded['evidence_image']?.toString(),
            timestamp: (decoded['timestamp'] ??
                    DateTime.now().toIso8601String())
                .toString(),
            classroomId:
                decoded['classroom_id']?.toString() ?? _syncClassroomId,
          );
          handleIncomingAlert(alert);
        }
      }
    } catch (e) {
      debugPrint('[AlertsProvider] Error parsing SSE event: $e');
    }
  }

  /// Start incremental polling fallback (guarantees delivery on network drops)
  void _startPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isSyncing) return;
      try {
        final newAlerts = await _teacherService.getAlerts(
          _syncClassroomId,
          _lastSeenAlertId > 0 ? _lastSeenAlertId : null,
        );
        for (final alert in newAlerts.reversed) {
          handleIncomingAlert(alert);
        }
      } catch (e) {
        // Silent catch for background polling
      }
    });
  }

  /// Ingest and process a real-time alert event
  void handleIncomingAlert(AlertModel alert) {
    if (_knownAlertIds.contains(alert.id)) {
      return;
    }
    _knownAlertIds.add(alert.id);
    if (alert.id > _lastSeenAlertId) {
      _lastSeenAlertId = alert.id;
    }

    _alerts.insert(0, alert);
    _totalAlerts = _alerts.length;
    _unreadCount++;
    _activeBannerAlert = alert;

    // Trigger local system notification on device
    _notificationService?.showPhoneDetectionNotification(
      alertId: alert.id,
      classroom: alert.classroomId ?? 'Active Classroom',
      seat: alert.seatId ?? 'Seat',
      duration: alert.duration,
      alertType: alert.alertType,
    );

    // Notify teacher workspace provider
    _onAlertCallback?.call(alert);

    notifyListeners();
  }

  /// Fetch alerts with active filters
  Future<void> fetchAlerts({bool isTeacher = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isTeacher) {
        final teacherAlerts = await _teacherService.getAlerts();
        for (final a in teacherAlerts) {
          _knownAlertIds.add(a.id);
          if (a.id > _lastSeenAlertId) {
            _lastSeenAlertId = a.id;
          }
        }
        var filtered = teacherAlerts;
        if (_statusFilter != 'All') {
          filtered = filtered
              .where(
                (a) => a.status.toLowerCase() == _statusFilter.toLowerCase(),
              )
              .toList();
        }
        _alerts = filtered;
        _totalAlerts = filtered.length;
      } else {
        final res = await _alertsService.getAlerts(
          status: _statusFilter,
          timeframe: _timeframeFilter,
        );
        for (final a in res.alerts) {
          _knownAlertIds.add(a.id);
          if (a.id > _lastSeenAlertId) {
            _lastSeenAlertId = a.id;
          }
        }
        _alerts = res.alerts;
        _totalAlerts = res.total;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Acknowledge an alert
  Future<bool> acknowledgeAlert(int id, {bool isTeacher = false}) async {
    try {
      final success = isTeacher
          ? await _teacherService.acknowledgeAlert(id)
          : await _alertsService.acknowledgeAlert(id);
      if (success) {
        final idx = _alerts.indexWhere((a) => a.id == id);
        if (idx >= 0) {
          final cur = _alerts[idx];
          _alerts[idx] = AlertModel(
            id: cur.id,
            studentId: cur.studentId,
            seatId: cur.seatId,
            cameraId: cur.cameraId,
            alertType: cur.alertType,
            confidence: cur.confidence,
            duration: cur.duration,
            status: 'Acknowledged',
            severity: cur.severity,
            evidenceImage: cur.evidenceImage,
            timestamp: cur.timestamp,
            classroomId: cur.classroomId,
          );
          notifyListeners();
        } else {
          await fetchAlerts(isTeacher: isTeacher);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Resolve an alert
  Future<bool> resolveAlert(int id, {bool isTeacher = false}) async {
    try {
      final success = isTeacher
          ? await _teacherService.resolveAlert(id)
          : await _alertsService.resolveAlert(id);
      if (success) {
        final idx = _alerts.indexWhere((a) => a.id == id);
        if (idx >= 0) {
          final cur = _alerts[idx];
          _alerts[idx] = AlertModel(
            id: cur.id,
            studentId: cur.studentId,
            seatId: cur.seatId,
            cameraId: cur.cameraId,
            alertType: cur.alertType,
            confidence: cur.confidence,
            duration: cur.duration,
            status: 'Resolved',
            severity: cur.severity,
            evidenceImage: cur.evidenceImage,
            timestamp: cur.timestamp,
            classroomId: cur.classroomId,
          );
          notifyListeners();
        } else {
          await fetchAlerts(isTeacher: isTeacher);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an alert (Admin only)
  Future<bool> deleteAlert(int id, {bool isTeacher = false}) async {
    try {
      final success = await _alertsService.deleteAlert(id);
      if (success) {
        await fetchAlerts(isTeacher: isTeacher);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    stopRealtimeSync();
    super.dispose();
  }
}
