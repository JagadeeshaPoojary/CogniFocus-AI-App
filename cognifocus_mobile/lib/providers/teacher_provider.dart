import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/alert_model.dart';
import '../models/camera_model.dart';
import '../models/classroom_model.dart';
import '../models/stats_model.dart';
import '../services/teacher_service.dart';

/// TeacherProvider: Manages Teacher Workspace, Classrooms, and Session Stats
class TeacherProvider extends ChangeNotifier {
  final TeacherService _teacherService;

  TeacherStatsModel _stats = const TeacherStatsModel();
  List<ClassroomModel> _classrooms = [];
  List<CameraModel> _cameras = [];
  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnectionError = false;

  TeacherProvider({required TeacherService teacherService})
    : _teacherService = teacherService;

  TeacherStatsModel get stats => _stats;
  List<ClassroomModel> get classrooms => _classrooms;
  List<CameraModel> get cameras => _cameras;
  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnectionError => _isConnectionError;

  void clearError() {
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }

  void _setError(dynamic e) {
    if (e is ApiException) {
      _errorMessage = e.message;
      _isConnectionError = e.isConnectionError;
    } else {
      _errorMessage = e.toString();
      _isConnectionError = false;
    }
  }

  /// Fetch teacher metrics
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();

    try {
      _stats = await _teacherService.getDashboardStats();
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch authorized classrooms
  Future<void> fetchClassrooms() async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();

    try {
      _classrooms = await _teacherService.getClassrooms();
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch assigned cameras
  Future<void> fetchCameras() async {
    try {
      _cameras = await _teacherService.getCameras();
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch classroom alerts
  Future<void> fetchAlerts([String? classroomId]) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();

    try {
      _alerts = await _teacherService.getAlerts(classroomId);
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all teacher workspace data
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();

    try {
      await Future.wait([
        _teacherService.getDashboardStats().then((s) => _stats = s),
        _teacherService.getClassrooms().then((c) => _classrooms = c),
        _teacherService.getCameras().then((c) => _cameras = c).catchError((_) => <CameraModel>[]),
        _teacherService.getAlerts().then((a) => _alerts = a),
      ]);
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a real-time alert received via SSE or polling
  void addRealtimeAlert(AlertModel alert) {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index >= 0) {
      _alerts[index] = alert;
    } else {
      _alerts.insert(0, alert);
      _stats = _stats.copyWith(
        alertsToday: _stats.alertsToday + 1,
        suspiciousStudents: (alert.studentId != null && alert.studentId!.isNotEmpty)
            ? _stats.suspiciousStudents + 1
            : _stats.suspiciousStudents,
      );
    }
    notifyListeners();
  }
}
