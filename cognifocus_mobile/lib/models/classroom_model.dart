/// Classroom Model for CogniFocus-AI
class ClassroomModel {
  final String id;
  final String name;
  final String code;
  final int studentsCount;
  final int camerasCount;
  final int totalAlerts;
  final bool isActive;
  final String status;
  final String? cameraId;

  const ClassroomModel({
    required this.id,
    required this.name,
    required this.code,
    this.studentsCount = 12,
    this.camerasCount = 2,
    this.totalAlerts = 0,
    this.isActive = false,
    this.status = 'READY',
    this.cameraId,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? json['id'] ?? '').toString(),
      studentsCount: json['students_count'] is int
          ? json['students_count']
          : int.tryParse(json['students_count']?.toString() ?? '') ?? 12,
      camerasCount: json['cameras_count'] is int
          ? json['cameras_count']
          : int.tryParse(json['cameras_count']?.toString() ?? '') ?? 2,
      totalAlerts: json['total_alerts'] is int
          ? json['total_alerts']
          : int.tryParse(json['total_alerts']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] == true,
      status: (json['status'] ?? 'READY').toString(),
      cameraId: json['camera_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'students_count': studentsCount,
      'cameras_count': camerasCount,
      'total_alerts': totalAlerts,
      'is_active': isActive,
      'status': status,
      'camera_id': cameraId,
    };
  }
}
