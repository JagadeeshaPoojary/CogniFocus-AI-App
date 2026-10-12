/// Camera Model for CogniFocus-AI
class CameraModel {
  final String id;
  final String name;
  final String? classroomId;
  final String source;
  final String status;
  final int fps;
  final bool workerRunning;

  const CameraModel({
    required this.id,
    required this.name,
    this.classroomId,
    this.source = '0',
    this.status = 'offline',
    this.fps = 28,
    this.workerRunning = false,
  });

  bool get isOnline =>
      status.toLowerCase() == 'online' ||
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'monitoring' ||
      workerRunning;

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    final cid = (json['camera_id'] ?? json['id'] ?? '').toString();
    final cName = (json['name'] ?? 'Camera $cid').toString();
    final st = (json['status'] ?? 'offline').toString();
    final isRunning =
        json['worker_running'] == true ||
        json['stream_active'] == true ||
        st.toLowerCase() == 'online' ||
        st.toLowerCase() == 'monitoring';

    return CameraModel(
      id: cid,
      name: cName,
      classroomId: json['classroom_id']?.toString(),
      source: (json['source'] ?? '0').toString(),
      status: st,
      fps: json['fps'] is int
          ? json['fps']
          : int.tryParse(json['fps']?.toString() ?? '') ?? 28,
      workerRunning: isRunning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classroom_id': classroomId,
      'source': source,
      'status': status,
      'fps': fps,
      'worker_running': workerRunning,
    };
  }
}
