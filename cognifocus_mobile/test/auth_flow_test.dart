import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/navigation/app_router.dart';
import 'package:cognifocus_mobile/providers/admin_provider.dart';
import 'package:cognifocus_mobile/providers/alerts_provider.dart';
import 'package:cognifocus_mobile/providers/auth_provider.dart';
import 'package:cognifocus_mobile/providers/teacher_provider.dart';
import 'package:cognifocus_mobile/screens/admin/admin_dashboard_screen.dart';
import 'package:cognifocus_mobile/screens/auth/login_screen.dart';
import 'package:cognifocus_mobile/screens/teacher/teacher_dashboard_screen.dart';
import 'package:cognifocus_mobile/services/alerts_service.dart';
import 'package:cognifocus_mobile/services/auth_service.dart';
import 'package:cognifocus_mobile/services/monitor_service.dart';
import 'package:cognifocus_mobile/services/storage_service.dart';
import 'package:cognifocus_mobile/services/teacher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider State Transitions', () {
    test('initAuth without stored session leaves user unauthenticated and isInitializing false', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      expect(authProvider.isInitializing, isTrue);
      await authProvider.initAuth();

      expect(authProvider.isInitializing, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
    });

    test('initAuth with stored session restores user and verifies via getMe', () async {
      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'saved_token_123',
        'cognifocus_auth_user': jsonEncode({
          'id': 2,
          'email': 'teacher@classroom.com',
          'name': 'Prof. Jenkins',
          'role': 'TEACHER',
        }),
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'user': {
                'id': 2,
                'email': 'teacher@classroom.com',
                'name': 'Prof. Sarah Jenkins',
                'role': 'TEACHER',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/teacher/classroom/current') {
          return http.Response(
            jsonEncode({'success': true, 'monitoring_active': false, 'classroom': null}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await authProvider.initAuth();

      expect(authProvider.isInitializing, isFalse);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isTeacher, isTrue);
      expect(authProvider.user?.name, 'Prof. Sarah Jenkins');
    });

    test('initAuth clears session when /api/auth/me responds with 401 Unauthorized', () async {
      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'expired_token_123',
        'cognifocus_auth_user': jsonEncode({
          'id': 2,
          'email': 'teacher@classroom.com',
          'name': 'Prof. Jenkins',
          'role': 'TEACHER',
        }),
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Token expired'}),
            401,
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await authProvider.initAuth();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
      expect(await storage.getToken(), isNull);
    });

    test('login does not toggle isInitializing and sets authenticated user directly', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'token': 'new_teacher_jwt',
              'user': {
                'id': 10,
                'email': 'teacher@classroom.com',
                'name': 'Prof. Smith',
                'role': 'TEACHER',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/teacher/classroom/current') {
          return http.Response(
            jsonEncode({'success': true, 'monitoring_active': false, 'classroom': null}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      // Finish startup initialization
      await authProvider.initAuth();
      expect(authProvider.isInitializing, isFalse);
      expect(authProvider.isAuthenticated, isFalse);

      // Execute login
      await authProvider.login('teacher@classroom.com', 'teacher123');

      expect(authProvider.isInitializing, isFalse);
      expect(authProvider.isLoggingIn, isFalse);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isTeacher, isTrue);
      expect(authProvider.user?.email, 'teacher@classroom.com');
      expect(authProvider.token, 'new_teacher_jwt');
    });
  });

  group('AppRouter Navigation Decision Tests', () {
    Widget buildTestApp(AuthProvider authProvider, ApiClient apiClient) {
      final teacherService = TeacherService(apiClient: apiClient);
      final monitorService = MonitorService(apiClient: apiClient);
      final alertsService = AlertsService(apiClient: apiClient);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TeacherProvider>(
            create: (_) => TeacherProvider(teacherService: teacherService),
          ),
          ChangeNotifierProvider<AdminProvider>(
            create: (_) => AdminProvider(
              monitorService: monitorService,
              alertsService: alertsService,
            ),
          ),
          ChangeNotifierProvider<AlertsProvider>(
            create: (_) => AlertsProvider(
              alertsService: alertsService,
              teacherService: teacherService,
            ),
          ),
        ],
        child: const MaterialApp(
          home: AppRouter(),
        ),
      );
    }

    testWidgets('AppRouter shows Splash ONLY when isInitializing is true', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final apiClient = ApiClient(client: MockClient((_) async => http.Response('{}', 200)));
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      expect(authProvider.isInitializing, isTrue);

      await tester.pumpWidget(buildTestApp(authProvider, apiClient));

      expect(find.text('Initializing CogniFocus-AI Mobile...'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('AppRouter routes to LoginScreen when unauthenticated and initialized', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final apiClient = ApiClient(client: MockClient((_) async => http.Response('{}', 200)));
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await authProvider.initAuth();

      await tester.pumpWidget(buildTestApp(authProvider, apiClient));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);
      expect(find.byType(TeacherDashboardScreen), findsNothing);
    });

    testWidgets('AppRouter routes to TeacherDashboardScreen when user has role TEACHER', (tester) async {
      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'teacher_token_456',
        'cognifocus_auth_user': jsonEncode({
          'id': 2,
          'email': 'teacher@classroom.com',
          'name': 'Prof. Jenkins',
          'role': 'TEACHER',
        }),
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'user': {
                'id': 2,
                'email': 'teacher@classroom.com',
                'name': 'Prof. Jenkins',
                'role': 'TEACHER',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/teacher/classroom/current') {
          return http.Response(
            jsonEncode({'success': true, 'monitoring_active': false, 'classroom': null}),
            200,
          );
        }
        if (request.url.path == '/api/teacher/dashboard/stats') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        if (request.url.path == '/api/teacher/classrooms') {
          return http.Response(jsonEncode({'success': true, 'classrooms': []}), 200);
        }
        if (request.url.path == '/api/teacher/cameras') {
          return http.Response(jsonEncode({'success': true, 'cameras': []}), 200);
        }
        if (request.url.path == '/api/teacher/alerts') {
          return http.Response(jsonEncode({'success': true, 'alerts': []}), 200);
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await authProvider.initAuth();

      await tester.pumpWidget(buildTestApp(authProvider, apiClient));
      await tester.pumpAndSettle();

      expect(find.byType(TeacherDashboardScreen), findsOneWidget);
      expect(find.text('Teacher Workspace'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(AdminDashboardScreen), findsNothing);
    });

    testWidgets('AppRouter routes to AdminDashboardScreen when user has role ADMIN', (tester) async {
      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'admin_token_789',
        'cognifocus_auth_user': jsonEncode({
          'id': 1,
          'email': 'admin@classroom.com',
          'name': 'System Admin',
          'role': 'ADMIN',
        }),
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'user': {
                'id': 1,
                'email': 'admin@classroom.com',
                'name': 'System Admin',
                'role': 'ADMIN',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/monitor/status') {
          return http.Response(jsonEncode({'monitoring_active': true, 'status': 'ONLINE'}), 200);
        }
        if (request.url.path == '/api/cameras/status') {
          return http.Response(jsonEncode({'cameras': []}), 200);
        }
        if (request.url.path == '/api/alerts') {
          return http.Response(jsonEncode({'alerts': [], 'total': 0}), 200);
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final storage = StorageService();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await authProvider.initAuth();

      await tester.pumpWidget(buildTestApp(authProvider, apiClient));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('Admin Overview'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(TeacherDashboardScreen), findsNothing);
    });
  });
}
