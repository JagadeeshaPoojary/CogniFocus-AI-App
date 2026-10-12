import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../models/camera_model.dart';
import '../models/stats_model.dart';
import '../services/alerts_service.dart';
import '../services/monitor_service.dart';

/// AdminProvider: System Metrics & Multi-Camera Management
class AdminProvider extends ChangeNotifier {
  final MonitorService _monitorService;
  final AlertsService _alertsService;

  AdminStatsModel _stats = const AdminStatsModel();
  List<CameraModel> _cameras = [];
  List<AlertModel> _recentAlerts = [];
  bool _isLoading = false;
  bool _isToggling = false;
  String? _errorMessage;

  AdminProvider({
    required MonitorService monitorService,
    required AlertsService alertsService,
  }) : _monitorService = monitorService,
       _alertsService = alertsService;

  AdminStatsModel get stats => _stats;
  List<CameraModel> get cameras => _cameras;
  List<AlertModel> get recentAlerts => _recentAlerts;
  bool get isLoading => _isLoading;
  bool get isToggling => _isToggling;
  String? get errorMessage => _errorMessage;

  /// Fetch live system status, cameras, and recent alerts
  Future<void> fetchAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final s = await _monitorService.getStatus();
      final cams = await _monitorService.getCamerasStatus();
      final alertRes = await _alertsService.getAlerts(limit: 5);

      _stats = s;
      _cameras = cams.isNotEmpty
          ? cams
          : [
              const CameraModel(
                id: 'CAM001',
                name: 'Classroom 301 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM002',
                name: 'Classroom 301 Rear',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM003',
                name: 'Classroom 302 Front',
                status: 'online',
              ),
              const CameraModel(
                id: 'CAM004',
                name: 'Classroom 302 Rear',
                status: 'online',
              ),
            ];
      _recentAlerts = alertRes.alerts;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle global monitoring workers (start all / stop all)
  Future<bool> toggleMonitoring() async {
    _isToggling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success;
      if (_stats.monitoringActive) {
        success = await _monitorService.stopAdminMonitoring();
      } else {
        success = await _monitorService.startAdminMonitoring();
      }

      await fetchAdminData();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }
}
