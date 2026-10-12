import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/alert_model.dart';

class AlertsQueryResult {
  final List<AlertModel> alerts;
  final int total;
  final int totalPages;

  AlertsQueryResult({
    required this.alerts,
    required this.total,
    required this.totalPages,
  });
}

/// Alerts Service for CogniFocus-AI
class AlertsService {
  final ApiClient _apiClient;

  AlertsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch alerts with filter queries
  Future<AlertsQueryResult> getAlerts({
    String? status,
    String? cameraId,
    String? classroomId,
    String? timeframe,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (status != null && status != 'All') {
      queryParams['status'] = status;
    }
    if (cameraId != null && cameraId != 'All') {
      queryParams['camera_id'] = cameraId;
    }
    if (classroomId != null && classroomId != 'All') {
      queryParams['classroom_id'] = classroomId;
    }
    if (timeframe != null && timeframe != 'All') {
      queryParams['timeframe'] = timeframe;
    }

    final response = await _apiClient.get(
      ApiConfig.alertsPath,
      queryParams: queryParams,
    );
    final alertsList = <AlertModel>[];
    int total = 0;
    int totalPages = 1;

    if (response is Map<String, dynamic>) {
      final list = response['alerts'] ?? response['data'];
      if (list is List) {
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            alertsList.add(AlertModel.fromJson(item));
          }
        }
      }
      total = response['total'] is int ? response['total'] : alertsList.length;
      totalPages = response['total_pages'] is int ? response['total_pages'] : 1;
    }

    return AlertsQueryResult(
      alerts: alertsList,
      total: total,
      totalPages: totalPages,
    );
  }

  /// Get alert summary counts
  Future<Map<String, dynamic>> getAlertSummary() async {
    try {
      final response = await _apiClient.get(ApiConfig.alertsSummaryPath);
      if (response is Map<String, dynamic> &&
          response['summary'] is Map<String, dynamic>) {
        return response['summary'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert(int alertId) async {
    final response = await _apiClient.post(
      '${ApiConfig.alertsPath}/$alertId/acknowledge',
    );
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }

  /// Resolve alert
  Future<bool> resolveAlert(int alertId) async {
    final response = await _apiClient.post(
      '${ApiConfig.alertsPath}/$alertId/resolve',
    );
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }

  /// Delete alert (Admin only)
  Future<bool> deleteAlert(int alertId) async {
    final response = await _apiClient.delete(
      '${ApiConfig.alertsPath}/$alertId',
    );
    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return false;
  }
}
