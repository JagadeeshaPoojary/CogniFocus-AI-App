import 'dart:convert';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/core/theme/app_theme.dart';
import 'package:cognifocus_mobile/core/theme/clay_colors.dart';
import 'package:cognifocus_mobile/providers/alerts_provider.dart';
import 'package:cognifocus_mobile/providers/auth_provider.dart';
import 'package:cognifocus_mobile/providers/teacher_provider.dart';
import 'package:cognifocus_mobile/providers/theme_provider.dart';
import 'package:cognifocus_mobile/screens/settings/settings_screen.dart';
import 'package:cognifocus_mobile/screens/teacher/teacher_dashboard_screen.dart';
import 'package:cognifocus_mobile/services/alerts_service.dart';
import 'package:cognifocus_mobile/services/auth_service.dart';
import 'package:cognifocus_mobile/services/notification_service.dart';
import 'package:cognifocus_mobile/services/storage_service.dart';
import 'package:cognifocus_mobile/services/teacher_service.dart';
import 'package:cognifocus_mobile/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Theme Persistence Tests', () {
    test('getThemeMode returns null when no theme is stored (defaults to system)', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      final mode = await storage.getThemeMode();
      expect(mode, isNull);
    });

    test('saveThemeMode persists light, dark, and system correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      await storage.saveThemeMode(ThemeMode.dark);
      expect(await storage.getThemeMode(), equals(ThemeMode.dark));

      await storage.saveThemeMode(ThemeMode.light);
      expect(await storage.getThemeMode(), equals(ThemeMode.light));

      await storage.saveThemeMode(ThemeMode.system);
      expect(await storage.getThemeMode(), equals(ThemeMode.system));
    });

    test('clearAll does NOT erase saved theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      await storage.saveThemeMode(ThemeMode.dark);
      await storage.saveToken('jwt-sample-token');

      // Logout / session clear
      await storage.clearAll();

      expect(await storage.getToken(), isNull);
      expect(await storage.getThemeMode(), equals(ThemeMode.dark));
    });
  });

  group('ThemeProvider Unit Tests', () {
    test('initializes with system mode and loads saved preference', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.themeModeStorageKey: 'dark',
      });
      final storage = StorageService();
      final provider = ThemeProvider(storageService: storage);

      expect(provider.themeMode, equals(ThemeMode.system));

      await provider.initTheme();

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
      expect(provider.isLightMode, isFalse);
      expect(provider.isSystemMode, isFalse);
    });

    test('setThemeMode updates state, notifies listeners, and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final provider = ThemeProvider(storageService: storage);

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isLightMode, isTrue);
      expect(notified, isTrue);
      expect(await storage.getThemeMode(), equals(ThemeMode.light));
    });

    test('toggleTheme alternates between light and dark modes', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final provider = ThemeProvider(storageService: storage);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, equals(ThemeMode.light));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.dark));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.light));
    });
  });

  group('AppTheme Configuration Tests', () {
    test('lightTheme has light brightness, correct canvas and card colors', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(ClayColors.canvas));
      expect(theme.cardColor, equals(ClayColors.clayWhite));
      expect(theme.colorScheme.primary, equals(ClayColors.primaryBlue));
    });

    test('darkTheme has dark brightness, deep navy canvas and slate cards', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(ClayColors.darkCanvas));
      expect(theme.cardColor, equals(ClayColors.darkCard));
      expect(theme.colorScheme.surface, equals(ClayColors.darkCard));
    });
  });

  group('Theme Widget Integration Tests', () {
    testWidgets('AppHeader renders theme toggle button and sun/moon icon', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final themeProvider = ThemeProvider(storageService: storage);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const Scaffold(
              body: AppHeader(
                title: 'Test Header',
                subtitle: 'Theme Test',
              ),
            ),
          ),
        ),
      );

      // In light mode, moon icon is rendered to allow switching to dark mode
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('SettingsScreen renders Appearance & Theme controls', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final themeProvider = ThemeProvider(storageService: storage);
      final apiClient = ApiClient();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);
      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );
      final notifService = NotificationService(apiClient: apiClient);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            Provider<StorageService>.value(value: storage),
            Provider<NotificationService>.value(value: notifService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Theme Preference'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsNWidgets(2)); // switch title + chip label

      // Tap Dark Mode option chip
      await tester.tap(find.text('Dark Mode').last);
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('TeacherDashboardScreen renders theme toggle in AppBar and Profile Card', (tester) async {
      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'test_teacher_token',
        'cognifocus_auth_user': jsonEncode({
          'id': 1,
          'email': 'teacher@classroom.com',
          'name': 'Prof. Smith',
          'role': 'TEACHER',
        }),
      });
      final storage = StorageService();
      final themeProvider = ThemeProvider(storageService: storage);
      await themeProvider.setThemeMode(ThemeMode.light);

      final apiClient = ApiClient();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);
      final alertsService = AlertsService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );
      await authProvider.initAuth();

      final teacherProvider = TeacherProvider(teacherService: teacherService);
      final alertsProvider = AlertsProvider(
        alertsService: alertsService,
        teacherService: teacherService,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<TeacherProvider>.value(value: teacherProvider),
            ChangeNotifierProvider<AlertsProvider>.value(value: alertsProvider),
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const TeacherDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherDashboardScreen), findsOneWidget);
      expect(find.text('Teacher Workspace'), findsOneWidget);

      // Verify Theme Toggle in AppBar
      final appbarToggle = find.byTooltip('Switch to Dark Mode');
      expect(appbarToggle, findsOneWidget);

      // Verify Profile Card is clean and compact (no internal theme toggle pill)
      expect(find.text('Dark'), findsNothing);

      // Tap AppBar theme toggle
      await tester.tap(appbarToggle);
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('TeacherDashboardScreen renders responsive header & compact profile card on narrow screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'cognifocus_auth_token': 'test_teacher_token',
        'cognifocus_auth_user': jsonEncode({
          'id': 2,
          'email': 'alexander.montgomery-smith@cognifocus.ai',
          'name': 'Professor Alexander Montgomery-Smith',
          'role': 'TEACHER',
        }),
      });
      final storage = StorageService();
      final themeProvider = ThemeProvider(storageService: storage);
      await themeProvider.setThemeMode(ThemeMode.light);

      final apiClient = ApiClient();
      final authService = AuthService(apiClient: apiClient, storageService: storage);
      final teacherService = TeacherService(apiClient: apiClient);
      final alertsService = AlertsService(apiClient: apiClient);

      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );
      await authProvider.initAuth();

      final teacherProvider = TeacherProvider(teacherService: teacherService);
      final alertsProvider = AlertsProvider(
        alertsService: alertsService,
        teacherService: teacherService,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<TeacherProvider>.value(value: teacherProvider),
            ChangeNotifierProvider<AlertsProvider>.value(value: alertsProvider),
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const TeacherDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & appbar actions
      expect(find.text('Teacher Workspace'), findsOneWidget);
      expect(find.byTooltip('Refresh Workspace'), findsOneWidget);
      expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);
      expect(find.byTooltip('Sign Out'), findsOneWidget);

      // Verify long teacher name and email in compact profile card
      expect(find.text('Professor Alexander Montgomery-Smith'), findsOneWidget);
      expect(find.text('TEACHER'), findsOneWidget);
      expect(find.text('alexander.montgomery-smith@cognifocus.ai'), findsOneWidget);

      // Verify profile card does not contain theme toggle or sign out buttons
      expect(find.text('Mode'), findsNothing);

      // Tap Sign Out in AppBar to ensure it triggers confirmation dialog
      await tester.tap(find.byTooltip('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out of Session'), findsOneWidget);
      expect(find.textContaining('end your current teacher monitoring session'), findsOneWidget);
    });
  });
}
