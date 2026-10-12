import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/alert_model.dart';
import '../models/camera_model.dart';
import '../models/classroom_model.dart';
import '../models/stats_model.dart';

class EnterClassroomResult {
  final bool success;
  final bool monitoringActive;
  final String classroomId;
  final String classroomName;
  final String classroomCode;
  final List<String> cameras;
  final String message;

  EnterClassroomResult({
    required this.success,
    required this.monitoringActive,
    required this.classroomId,
    required this.classroomName,
    required this.classroomCode,
    required this.cameras,
    required this.message,
  });
}

/// Teacher Workspace Service for CogniFocus-AI
class TeacherService {
  final ApiClient _apiClient;

  TeacherService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Enter classroom and start AI monitoring
  Future<EnterClassroomResult> enterClassroom(String code) async {
    final response = await _apiClient.post(
      ApiConfig.teacherEnterClassroomPath,
      body: {
        'classroom_code': code.trim().toUpperCase(),
        'code': code.trim().toUpperCase(),
      },
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      final camerasList = <String>[];
      if (response['cameras'] is List) {
        for (final c in response['cameras']) {
          camerasList.add(c.toString());
        }
      }

      return EnterClassroomResult(
        success: true,
        monitoringActive:
            response['monitoring_active'] == true ||
            response['monitoring'] == true,
        classroomId: (response['classroom_id'] ?? '').toString(),
        classroomName: (response['classroom_name'] ?? '').toString(),
        classroomCode: (response['classroom_code'] ?? code).toString(),
        cameras: camerasList,
        message: response['message']?.toString() ?? 'Monitoring initialized',
      );
    }

    final msg = response is Map ? response['message']?.toString() : null;
    throw ApiException(message: msg ?? 'Failed to enter classroom.');
  }

  /// Leave classroom and stop monitoring
  Future<bool> leaveClassroom() async {
    final response = await _apiClient.post(ApiConfig.teacherLeaveClassroomPath);
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }

  /// Get current classroom session
  Future<Map<String, dynamic>> getCurrentClassroom() async {
    final response = await _apiClient.get(
      ApiConfig.teacherCurrentClassroomPath,
    );
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'success': false, 'monitoring_active': false};
  }

  /// Get Teacher dashboard statistics
  Future<TeacherStatsModel> getDashboardStats() async {
    final response = await _apiClient.get(ApiConfig.teacherStatsPath);
    if (response is Map) {
      return TeacherStatsModel.fromJson(Map<String, dynamic>.from(response));
    }
    return const TeacherStatsModel();
  }

  /// Get authorized classrooms list
  Future<List<ClassroomModel>> getClassrooms() async {
    final response = await _apiClient.get(ApiConfig.teacherClassroomsPath);
    final results = <ClassroomModel>[];

    if (response is Map && response['classrooms'] is List) {
      for (final item in response['classrooms']) {
        if (item is Map) {
          results.add(ClassroomModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return results;
  }

  /// Get assigned cameras
  Future<List<CameraModel>> getCameras() async {
    try {
      final response = await _apiClient.get(ApiConfig.teacherCamerasPath);
      final list = <CameraModel>[];

      if (response is Map && response['cameras'] is List) {
        for (final item in response['cameras']) {
          if (item is Map) {
            list.add(CameraModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Get teacher alerts
  Future<List<AlertModel>> getAlerts([String? classroomId, int? sinceId]) async {
    try {
      final query = <String, dynamic>{};
      if (classroomId != null && classroomId.isNotEmpty && classroomId != 'All') {
        query['classroom_id'] = classroomId;
      }
      if (sinceId != null) {
        query['since_id'] = sinceId;
      }
      final response = await _apiClient.get(
        ApiConfig.teacherAlertsPath,
        queryParams: query.isNotEmpty ? query : null,
      );
      final list = <AlertModel>[];

      if (response is Map && response['alerts'] is List) {
        for (final item in response['alerts']) {
          if (item is Map) {
            list.add(AlertModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert(int alertId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teacherAlertsPath}/$alertId/acknowledge',
      );
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Resolve alert
  Future<bool> resolveAlert(int alertId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teacherAlertsPath}/$alertId/resolve',
      );
      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
