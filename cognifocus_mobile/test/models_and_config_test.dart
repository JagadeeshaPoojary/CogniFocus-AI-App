import 'package:flutter_test/flutter_test.dart';
import 'package:cognifocus_mobile/core/config/api_config.dart';
import 'package:cognifocus_mobile/models/user_model.dart';
import 'package:cognifocus_mobile/models/classroom_model.dart';
import 'package:cognifocus_mobile/models/camera_model.dart';
import 'package:cognifocus_mobile/models/alert_model.dart';
import 'package:cognifocus_mobile/models/stats_model.dart';

void main() {
  group('ApiConfig Tests', () {
    test(
      'normalizeUrl handles trailing slashes, spaces, and missing protocol',
      () {
        expect(
          ApiConfig.normalizeUrl('  http://192.168.1.5:5000/  '),
          'http://192.168.1.5:5000',
        );
        expect(
          ApiConfig.normalizeUrl('192.168.1.5:5000///'),
          'http://192.168.1.5:5000',
        );
        expect(
          ApiConfig.normalizeUrl('https://api.cognifocus.ai/'),
          'https://api.cognifocus.ai',
        );
        // Prevents inadvertent HTTPS override on local non-TLS development endpoints
        expect(
          ApiConfig.normalizeUrl('https://10.223.8.206:5000'),
          'http://10.223.8.206:5000',
        );
        expect(
          ApiConfig.normalizeUrl('https://10.134.37.206:5000'),
          'http://10.134.37.206:5000',
        );
        expect(
          ApiConfig.normalizeUrl('https://127.0.0.1:5000'),
          'http://127.0.0.1:5000',
        );
        expect(
          ApiConfig.normalizeUrl('https://10.0.2.2:5000'),
          'http://10.0.2.2:5000',
        );
        expect(ApiConfig.isLocalAddress('http://10.223.8.206:5000'), isTrue);
        expect(ApiConfig.isLocalAddress('http://10.134.37.206:5000'), isTrue);
        expect(ApiConfig.isLocalAddress('https://api.cognifocus.ai'), isFalse);
        expect(ApiConfig.normalizeUrl(''), ApiConfig.defaultServerUrl);
        expect(ApiConfig.laptopLanIp, '10.223.8.206');
        expect(ApiConfig.physicalPhoneServerUrl, 'http://10.223.8.206:5000');
        expect(ApiConfig.emulatorServerUrl, 'http://10.0.2.2:5000');
        expect(ApiConfig.defaultServerUrl, 'http://10.223.8.206:5000');
      },
    );

    test(
      'getCameraFrameUrl constructs valid frame url with token and timestamp',
      () {
        final url = ApiConfig.getCameraFrameUrl(
          baseUrl: 'http://10.0.2.2:5000',
          cameraId: 'CAM001',
          token: 'sample_jwt_token',
        );
        expect(
          url,
          contains('http://10.0.2.2:5000/api/cameras/CAM001/frame.jpg'),
        );
        expect(url, contains('token=sample_jwt_token'));
        expect(url, contains('t='));
      },
    );

    test('getEvidenceUrl builds absolute and relative URL correctly', () {
      expect(
        ApiConfig.getEvidenceUrl(
          baseUrl: 'http://10.0.2.2:5000',
          relativePath: '/evidence/CAM001/snap.jpg',
        ),
        'http://10.0.2.2:5000/evidence/CAM001/snap.jpg',
      );
      expect(
        ApiConfig.getEvidenceUrl(
          baseUrl: 'http://10.0.2.2:5000',
          relativePath: 'evidence/CAM001/snap.jpg',
        ),
        'http://10.0.2.2:5000/evidence/CAM001/snap.jpg',
      );
      expect(
        ApiConfig.getEvidenceUrl(
          baseUrl: 'http://10.0.2.2:5000',
          relativePath: null,
        ),
        '',
      );
    });
  });

  group('UserModel Tests', () {
    test('parses Admin user from JSON and normalizes role', () {
      final user = UserModel.fromJson({
        'id': 1,
        'email': 'admin@classroom.com',
        'name': 'System Admin',
        'role': 'admin',
      });
      expect(user.id, 1);
      expect(user.email, 'admin@classroom.com');
      expect(user.role, 'ADMIN');
      expect(user.isAdmin, isTrue);
      expect(user.isTeacher, isFalse);
    });

    test('parses Teacher user from JSON', () {
      final user = UserModel.fromJson({
        'id': '2',
        'email': 'teacher@classroom.com',
        'name': 'Prof. Jenkins',
        'role': 'TEACHER',
      });
      expect(user.id, '2');
      expect(user.role, 'TEACHER');
      expect(user.isAdmin, isFalse);
      expect(user.isTeacher, isTrue);
    });
  });

  group('ClassroomModel Tests', () {
    test('parses classroom with default counts', () {
      final cls = ClassroomModel.fromJson({
        'id': 'CSE-301',
        'name': 'Computer Science Hall 301',
        'code': 'CSE301',
        'students_count': 24,
        'cameras_count': 2,
        'total_alerts': 5,
        'is_active': true,
      });
      expect(cls.id, 'CSE-301');
      expect(cls.code, 'CSE301');
      expect(cls.studentsCount, 24);
      expect(cls.camerasCount, 2);
      expect(cls.totalAlerts, 5);
      expect(cls.isActive, isTrue);
    });
  });

  group('CameraModel Tests', () {
    test('correctly identifies online status', () {
      const cam1 = CameraModel(
        id: 'CAM001',
        name: 'Front Cam',
        status: 'online',
      );
      expect(cam1.isOnline, isTrue);

      const cam2 = CameraModel(
        id: 'CAM002',
        name: 'Rear Cam',
        status: 'offline',
      );
      expect(cam2.isOnline, isFalse);

      final cam3 = CameraModel.fromJson({
        'camera_id': 'CAM003',
        'name': 'Side Cam',
        'status': 'monitoring',
        'worker_running': true,
      });
      expect(cam3.isOnline, isTrue);
    });
  });

  group('AlertModel Tests', () {
    test('parses AlertModel and formats duration', () {
      final alert = AlertModel.fromJson({
        'id': 42,
        'student_id': 'STU-001',
        'seat_id': 'B8',
        'camera_id': 'CAM001',
        'alert_type': 'Cell Phone Detected Near Body',
        'confidence': 0.94,
        'duration': 10,
        'status': 'Active',
        'severity': 'High',
        'evidence_image': '/evidence/CAM001/snap.jpg',
        'timestamp': '2026-10-10T11:00:00',
      });
      expect(alert.id, 42);
      expect(alert.studentId, 'STU-001');
      expect(alert.seatId, 'B8');
      expect(alert.duration, '10s');
      expect(alert.isActive, isTrue);
      expect(alert.isHighSeverity, isTrue);
    });
  });

  group('StatsModel Tests', () {
    test('parses AdminStatsModel correctly', () {
      final stats = AdminStatsModel.fromJson({
        'active_students': 20,
        'active_alerts': 3,
        'alerts_today': 7,
        'monitoring_active': true,
        'cameras': [
          {'id': 'CAM001', 'status': 'online'},
          {'id': 'CAM002', 'status': 'offline'},
        ],
      });
      expect(stats.activeStudents, 20);
      expect(stats.activeAlerts, 3);
      expect(stats.alertsToday, 7);
      expect(stats.monitoringActive, isTrue);
      expect(stats.activeCameras, 1);
      expect(stats.totalCameras, 2);
    });

    test('parses TeacherStatsModel correctly', () {
      final stats = TeacherStatsModel.fromJson({
        'total_students': 12,
        'active_cameras': 2,
        'alerts_today': 4,
        'suspicious_students': 2,
        'avg_usage_duration': 8.5,
        'monitoring_active': true,
        'classroom': {'id': 'CSE-301', 'name': 'Hall 301', 'code': 'CSE301'},
      });
      expect(stats.totalStudents, 12);
      expect(stats.activeCameras, 2);
      expect(stats.alertsToday, 4);
      expect(stats.avgUsageDuration, 8.5);
      expect(stats.monitoringActive, isTrue);
      expect(stats.classroomCode, 'CSE301');
    });
  });
}
