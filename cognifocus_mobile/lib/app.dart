import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/admin_provider.dart';
import 'providers/alerts_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/theme_provider.dart';
import 'services/alerts_service.dart';
import 'services/auth_service.dart';
import 'services/monitor_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/teacher_service.dart';

/// Root Application Widget with MultiProvider Dependency Injection
class CogniFocusApp extends StatelessWidget {
  final ApiClient apiClient;
  final StorageService storageService;
  final NotificationService notificationService;

  const CogniFocusApp({
    super.key,
    required this.apiClient,
    required this.storageService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(
      apiClient: apiClient,
      storageService: storageService,
    );
    final teacherService = TeacherService(apiClient: apiClient);
    final monitorService = MonitorService(apiClient: apiClient);
    final alertsService = AlertsService(apiClient: apiClient);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<StorageService>.value(value: storageService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<AuthService>.value(value: authService),
        Provider<TeacherService>.value(value: teacherService),
        Provider<MonitorService>.value(value: monitorService),
        Provider<AlertsService>.value(value: alertsService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(
            storageService: storageService,
          )..initTheme(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            apiClient: apiClient,
            storageService: storageService,
            authService: authService,
            teacherService: teacherService,
            notificationService: notificationService,
          )..initAuth(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(
            monitorService: monitorService,
            alertsService: alertsService,
          ),
        ),
        ChangeNotifierProvider<TeacherProvider>(
          create: (_) => TeacherProvider(teacherService: teacherService),
        ),
        ChangeNotifierProvider<AlertsProvider>(
          create: (_) => AlertsProvider(
            alertsService: alertsService,
            teacherService: teacherService,
            notificationService: notificationService,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CogniFocus-AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 250),
            themeAnimationCurve: Curves.easeInOut,
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}
