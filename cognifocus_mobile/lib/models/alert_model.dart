/// Alert Model for CogniFocus-AI
class AlertModel {
  final int id;
  final String? studentId;
  final String? seatId;
  final String cameraId;
  final String alertType;
  final double confidence;
  final String duration;
  final String status; // 'Active' | 'Acknowledged' | 'Resolved'
  final String severity; // 'High' | 'Medium' | 'Low'
  final String? evidenceImage;
  final String timestamp;
  final String? classroomId;

  const AlertModel({
    required this.id,
    this.studentId,
    this.seatId,
    required this.cameraId,
    required this.alertType,
    this.confidence = 0.9,
    this.duration = '10s',
    this.status = 'Active',
    this.severity = 'High',
    this.evidenceImage,
    required this.timestamp,
    this.classroomId,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isAcknowledged => status.toLowerCase() == 'acknowledged';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isHighSeverity => severity.toLowerCase() == 'high';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    // Parse duration cleanly
    String durStr = '0s';
    final rawDur = json['duration'];
    if (rawDur != null) {
      durStr = rawDur.toString();
      if (!durStr.endsWith('s') && !durStr.endsWith('S')) {
        durStr = '${durStr}s';
      }
    }

    return AlertModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      studentId: json['student_id']?.toString(),
      seatId: (json['seat_id'] ?? json['seat'])?.toString(),
      cameraId: (json['camera_id'] ?? json['camera'] ?? 'CAM001').toString(),
      alertType: (json['alert_type'] ?? 'Suspicious Activity Detected')
          .toString(),
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence']?.toString() ?? '0.9') ?? 0.9,
      duration: durStr,
      status: (json['status'] ?? 'Active').toString(),
      severity: (json['severity'] ?? 'High').toString(),
      evidenceImage: json['evidence_image']?.toString(),
      timestamp: (json['timestamp'] ?? DateTime.now().toIso8601String())
          .toString(),
      classroomId: json['classroom_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'seat_id': seatId,
      'camera_id': cameraId,
      'alert_type': alertType,
      'confidence': confidence,
      'duration': duration,
      'status': status,
      'severity': severity,
      'evidence_image': evidenceImage,
      'timestamp': timestamp,
      'classroom_id': classroomId,
    };
  }
}
