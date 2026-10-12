import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/camera_model.dart';
import '../models/classroom_model.dart';
import '../models/stats_model.dart';

/// Monitor & System Management Service for CogniFocus-AI
class MonitorService {
  final ApiClient _apiClient;

  MonitorService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get Admin monitoring status & metrics
  Future<AdminStatsModel> getStatus() async {
    final response = await _apiClient.get(ApiConfig.monitorStatusPath);
    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return AdminStatsModel.fromJson(data);
    }
    return const AdminStatsModel();
  }

  /// Get all classrooms in the database
  Future<List<ClassroomModel>> getAllClassrooms() async {
    final response = await _apiClient.get(ApiConfig.classroomsPath);
    final results = <ClassroomModel>[];

    if (response is Map<String, dynamic>) {
      final list = response['data'] ?? response['classrooms'];
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            results.add(ClassroomModel.fromJson(item));
          }
        }
      }
    }
    return results;
  }

  /// Start all system cameras (Admin only)
  Future<bool> startAdminMonitoring() async {
    final response = await _apiClient.post(ApiConfig.adminStartMonitoringPath);
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }

  /// Stop all system cameras (Admin only)
  Future<bool> stopAdminMonitoring() async {
    final response = await _apiClient.post(ApiConfig.adminStopMonitoringPath);
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }

  /// Get status of all cameras
  Future<List<CameraModel>> getCamerasStatus() async {
    try {
      final response = await _apiClient.get(ApiConfig.camerasStatusPath);
      final list = <CameraModel>[];

      if (response is Map<String, dynamic> && response['cameras'] is List) {
        for (final item in response['cameras']) {
          if (item is Map<String, dynamic>) {
            list.add(CameraModel.fromJson(item));
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }
}
