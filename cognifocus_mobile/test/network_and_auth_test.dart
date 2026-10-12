import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cognifocus_mobile/core/config/api_config.dart';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/services/auth_service.dart';
import 'package:cognifocus_mobile/services/storage_service.dart';
import 'package:cognifocus_mobile/services/teacher_service.dart';
import 'package:cognifocus_mobile/services/alerts_service.dart';
import 'package:cognifocus_mobile/providers/teacher_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    test('saves and retrieves token, user, and server url', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      expect(await storage.getServerUrl(), ApiConfig.defaultServerUrl);

      await storage.saveServerUrl('http://192.168.1.100:5000');
      expect(await storage.getServerUrl(), 'http://192.168.1.100:5000');

      await storage.saveToken('test_jwt_123');
      expect(await storage.getToken(), 'test_jwt_123');

      await storage.clearToken();
      expect(await storage.getToken(), isNull);
    });

    test('auto-migrates legacy stale IP 10.134.37.206 to default', () async {
      SharedPreferences.setMockInitialValues({
        ApiConfig.serverUrlStorageKey: 'http://10.134.37.206:5000',
      });
      final storage = StorageService();

      final resolved = await storage.getServerUrl();
      expect(resolved, ApiConfig.defaultServerUrl);
      expect(resolved.contains('10.134.37.206'), isFalse);
    });

    test('auto-migrates stale emulator IP 10.0.2.2 to physical LAN IP when not in emulator mode', () async {
      SharedPreferences.setMockInitialValues({
        ApiConfig.serverUrlStorageKey: 'https://10.0.2.2:5000',
      });
      final storage = StorageService();

      final resolved = await storage.getServerUrl();
      if (!ApiConfig.isEmulator) {
        expect(resolved, ApiConfig.physicalPhoneServerUrl);
        expect(resolved.contains('10.0.2.2'), isFalse);
      }
    });

    test('normalizes and updates stored https local LAN URL to http to prevent TLS hang', () async {
      SharedPreferences.setMockInitialValues({
        ApiConfig.serverUrlStorageKey: 'https://10.223.8.206:5000',
      });
      final storage = StorageService();

      final resolved = await storage.getServerUrl();
      expect(resolved, 'http://10.223.8.206:5000');
    });
  });

  group('AuthService Tests', () {
    test('successful login parses token and user', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'token': 'mocked_jwt_token_xyz',
              'user': {
                'id': 1,
                'email': 'teacher@classroom.com',
                'name': 'Prof. Jenkins',
                'role': 'TEACHER',
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(
        apiClient: apiClient,
        storageService: storage,
      );

      final result = await authService.login(
        'teacher@classroom.com',
        'teacher123',
      );
      expect(result.token, 'mocked_jwt_token_xyz');
      expect(result.user.email, 'teacher@classroom.com');
      expect(result.user.isTeacher, isTrue);
      expect(await storage.getToken(), 'mocked_jwt_token_xyz');
    });

    test(
      'failed login throws ApiException with server error message',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid email or password',
            }),
            401,
          );
        });

        final apiClient = ApiClient(client: mockClient);
        final storage = StorageService();
        final authService = AuthService(
          apiClient: apiClient,
          storageService: storage,
        );

        expect(
          () => authService.login('wrong@classroom.com', 'badpass'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid email or password'),
            ),
          ),
        );
      },
    );
  });

  group('TeacherService Tests', () {
    test('enterClassroom parses cameras and session state', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/teacher/classroom/enter') {
          return http.Response(
            jsonEncode({
              'success': true,
              'monitoring_active': true,
              'classroom_id': 'CSE-301',
              'classroom_name': 'Computer Science Hall 301',
              'classroom_code': 'CSE301',
              'cameras': ['CAM001', 'CAM002'],
              'message': 'Monitoring started',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final teacherService = TeacherService(apiClient: apiClient);

      final result = await teacherService.enterClassroom('CSE301');
      expect(result.success, isTrue);
      expect(result.monitoringActive, isTrue);
      expect(result.classroomCode, 'CSE301');
      expect(result.cameras, ['CAM001', 'CAM002']);
    });

    test('leaveClassroom stops monitoring successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'monitoring_active': false}),
          200,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final teacherService = TeacherService(apiClient: apiClient);

      final ok = await teacherService.leaveClassroom();
      expect(ok, isTrue);
    });
  });

  group('AlertsService Tests', () {
    test('acknowledge and resolve send proper requests', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/acknowledge') ||
            request.url.path.endsWith('/resolve')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final alertsService = AlertsService(apiClient: apiClient);

      expect(await alertsService.acknowledgeAlert(10), isTrue);
      expect(await alertsService.resolveAlert(10), isTrue);
    });
  });

  group('TeacherProvider Connection Error Tests', () {
    test('captures connection error and enables clearError', () async {
      final mockClient = MockClient((request) async {
        throw ApiException(
          message: 'Connection timed out while contacting https://10.223.8.206:5000',
          isConnectionError: true,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final teacherService = TeacherService(apiClient: apiClient);
      final provider = TeacherProvider(teacherService: teacherService);

      expect(provider.errorMessage, isNull);
      expect(provider.isConnectionError, isFalse);

      await provider.fetchDashboardStats();

      expect(provider.errorMessage, contains('Connection timed out'));
      expect(provider.isConnectionError, isTrue);

      provider.clearError();
      expect(provider.errorMessage, isNull);
      expect(provider.isConnectionError, isFalse);
    });
  });
}

