import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cognifocus_mobile/core/config/api_config.dart';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/providers/auth_provider.dart';
import 'package:cognifocus_mobile/screens/auth/login_screen.dart';
import 'package:cognifocus_mobile/services/auth_service.dart';
import 'package:cognifocus_mobile/services/notification_service.dart';
import 'package:cognifocus_mobile/services/storage_service.dart';
import 'package:cognifocus_mobile/services/teacher_service.dart';
import 'package:cognifocus_mobile/widgets/clay_button.dart';
import 'package:cognifocus_mobile/widgets/clay_card.dart';
import 'package:cognifocus_mobile/widgets/clay_input.dart';
import 'package:cognifocus_mobile/widgets/clay_navigation_bar.dart';
import 'package:cognifocus_mobile/widgets/clay_stat_card.dart';
import 'package:cognifocus_mobile/widgets/clay_status_badge.dart';

import 'package:cognifocus_mobile/widgets/server_config_dialog.dart';

void main() {
  group('Claymorphism Reusable Widgets Tests', () {
    testWidgets('ClayCard renders child with 3D raised decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClayCard(child: Text('Clay Card Content'))),
        ),
      );

      expect(find.text('Clay Card Content'), findsOneWidget);
    });

    testWidgets('ClayButton renders text and triggers callback', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayButton(
              text: 'Start Monitoring',
              icon: Icons.play_arrow,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Monitoring'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.text('Start Monitoring'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('ClayButton shows loading spinner when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClayButton(text: 'Submit', isLoading: true)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('ClayInput renders with label, hint, and icons', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayInput(
              controller: controller,
              label: 'Access Code',
              hintText: 'e.g. CSE301',
              prefixIcon: Icons.vpn_key,
            ),
          ),
        ),
      );

      expect(find.text('Access Code'), findsOneWidget);
      expect(find.text('e.g. CSE301'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'CSE301');
      expect(controller.text, 'CSE301');
    });

    testWidgets('ClayStatusBadge renders live, offline, and severity badges', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ClayStatusBadge.live(),
                ClayStatusBadge.offline(),
                ClayStatusBadge.highSeverity('CRITICAL'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('ClayStatCard renders metric title, value, and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayStatCard(
              title: 'Active Cameras',
              value: '2 / 4',
              subtitle: 'Workers Online',
              icon: Icons.videocam,
              iconColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Active Cameras'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Workers Online'), findsOneWidget);
    });

    testWidgets('ClayNavigationBar renders tabs with active pill', (
      tester,
    ) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ClayNavigationBar(
              currentIndex: selected,
              items: const [
                ClayNavTabItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                ),
                ClayNavTabItem(
                  label: 'Alerts',
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                ),
              ],
              onTap: (i) => selected = i,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets(
      'LoginScreen renders CogniFocus branding, fields, and quick demo pills',
      (tester) async {
        final apiClient = ApiClient();
        final storage = StorageService();
        final authService = AuthService(
          apiClient: apiClient,
          storageService: storage,
        );
        final teacherService = TeacherService(apiClient: apiClient);
        final notifService = NotificationService(apiClient: apiClient);

        final authProvider = AuthProvider(
          apiClient: apiClient,
          storageService: storage,
          authService: authService,
          teacherService: teacherService,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              Provider<NotificationService>.value(value: notifService),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Verify branding
        expect(find.text('CogniFocus-AI'), findsOneWidget);
        expect(
          find.text('Classroom AI Monitoring & Focus Intelligence'),
          findsOneWidget,
        );

        // Verify fields & demo pills
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Teacher Demo'), findsOneWidget);
        expect(find.text('Admin Demo'), findsOneWidget);
      },
    );
  });

  group('ServerConfigDialog Widget Tests', () {
    testWidgets('renders dialog header, presets, and input field', (
      tester,
    ) async {
      final apiClient = ApiClient();
      final storage = StorageService();
      final authService = AuthService(
        apiClient: apiClient,
        storageService: storage,
      );
      final teacherService = TeacherService(apiClient: apiClient);
      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
        authService: authService,
        teacherService: teacherService,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ServerConfigDialog()),
          ),
        ),
      );

      expect(find.text('Backend Configuration'), findsOneWidget);
      expect(find.text('Backend Base URL'), findsOneWidget);
      expect(find.text('Test Ping'), findsOneWidget);
      expect(find.text('Wi-Fi LAN (${ApiConfig.laptopLanIp})'), findsOneWidget);
      expect(find.text('USB Reverse (127.0.0.1)'), findsOneWidget);
      expect(find.text('Emulator (10.0.2.2)'), findsOneWidget);

      // Tap preset chip and verify text changes
      await tester.tap(find.text('USB Reverse (127.0.0.1)'));
      await tester.pump();
      expect(find.text('http://127.0.0.1:5000'), findsOneWidget);

      await tester.tap(find.text('Emulator (10.0.2.2)'));
      await tester.pump();
      expect(find.text('http://10.0.2.2:5000'), findsOneWidget);
    });
  });
}

