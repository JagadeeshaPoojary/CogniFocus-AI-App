/// Admin Dashboard Statistics Model
class AdminStatsModel {
  final int activeStudents;
  final int activeCameras;
  final int totalCameras;
  final int activeAlerts;
  final int alertsToday;
  final bool monitoringActive;

  const AdminStatsModel({
    this.activeStudents = 24,
    this.activeCameras = 0,
    this.totalCameras = 4,
    this.activeAlerts = 0,
    this.alertsToday = 0,
    this.monitoringActive = false,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    int activeCams = 0;
    int totCams = 4;

    if (json['cameras'] is List) {
      final list = json['cameras'] as List;
      totCams = list.length;
      activeCams = list.where((c) {
        if (c is Map) {
          final st = (c['status'] ?? '').toString().toLowerCase();
          return st == 'online' ||
              st == 'active' ||
              st == 'monitoring' ||
              c['worker_running'] == true;
        }
        return false;
      }).length;
    }

    return AdminStatsModel(
      activeStudents: json['active_students'] is int
          ? json['active_students']
          : int.tryParse(json['active_students']?.toString() ?? '') ?? 24,
      activeCameras: activeCams,
      totalCameras: totCams > 0 ? totCams : 4,
      activeAlerts: json['active_alerts'] is int
          ? json['active_alerts']
          : int.tryParse(json['active_alerts']?.toString() ?? '') ?? 0,
      alertsToday: json['alerts_today'] is int
          ? json['alerts_today']
          : int.tryParse(json['alerts_today']?.toString() ?? '') ?? 0,
      monitoringActive: json['monitoring_active'] == true,
    );
  }
}

/// Teacher Workspace Statistics Model
class TeacherStatsModel {
  final int totalStudents;
  final int activeCameras;
  final int alertsToday;
  final int suspiciousStudents;
  final double avgUsageDuration;
  final bool monitoringActive;
  final String? classroomId;
  final String? classroomName;
  final String? classroomCode;

  const TeacherStatsModel({
    this.totalStudents = 12,
    this.activeCameras = 0,
    this.alertsToday = 0,
    this.suspiciousStudents = 0,
    this.avgUsageDuration = 0.0,
    this.monitoringActive = false,
    this.classroomId,
    this.classroomName,
    this.classroomCode,
  });

  factory TeacherStatsModel.fromJson(Map<String, dynamic> json) {
    String? cId;
    String? cName;
    String? cCode;

    if (json['classroom'] is Map) {
      final cls = json['classroom'] as Map;
      cId = cls['id']?.toString();
      cName = cls['name']?.toString();
      cCode = cls['code']?.toString();
    } else {
      cId = json['classroom_id']?.toString();
      cName = json['classroom_name']?.toString();
      cCode = json['classroom_code']?.toString();
    }

    return TeacherStatsModel(
      totalStudents: json['total_students'] is int
          ? json['total_students']
          : int.tryParse(json['total_students']?.toString() ?? '') ?? 12,
      activeCameras: json['active_cameras'] is int
          ? json['active_cameras']
          : int.tryParse(json['active_cameras']?.toString() ?? '') ?? 0,
      alertsToday: json['alerts_today'] is int
          ? json['alerts_today']
          : int.tryParse(json['alerts_today']?.toString() ?? '') ?? 0,
      suspiciousStudents: json['suspicious_students'] is int
          ? json['suspicious_students']
          : int.tryParse(json['suspicious_students']?.toString() ?? '') ?? 0,
      avgUsageDuration: json['avg_usage_duration'] is num
          ? (json['avg_usage_duration'] as num).toDouble()
          : double.tryParse(json['avg_usage_duration']?.toString() ?? '0.0') ??
                0.0,
      monitoringActive: json['monitoring_active'] == true,
      classroomId: cId,
      classroomName: cName,
      classroomCode: cCode,
    );
  }

  TeacherStatsModel copyWith({
    int? totalStudents,
    int? activeCameras,
    int? alertsToday,
    int? suspiciousStudents,
    double? avgUsageDuration,
    bool? monitoringActive,
    String? classroomId,
    String? classroomName,
    String? classroomCode,
  }) {
    return TeacherStatsModel(
      totalStudents: totalStudents ?? this.totalStudents,
      activeCameras: activeCameras ?? this.activeCameras,
      alertsToday: alertsToday ?? this.alertsToday,
      suspiciousStudents: suspiciousStudents ?? this.suspiciousStudents,
      avgUsageDuration: avgUsageDuration ?? this.avgUsageDuration,
      monitoringActive: monitoringActive ?? this.monitoringActive,
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      classroomCode: classroomCode ?? this.classroomCode,
    );
  }
}
