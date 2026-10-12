import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cognifocus_mobile/models/alert_model.dart';
import 'package:cognifocus_mobile/models/stats_model.dart';
import 'package:cognifocus_mobile/providers/teacher_provider.dart';
import 'package:cognifocus_mobile/providers/alerts_provider.dart';
import 'package:cognifocus_mobile/services/teacher_service.dart';
import 'package:cognifocus_mobile/services/alerts_service.dart';
import 'package:cognifocus_mobile/core/network/api_client.dart';
import 'package:cognifocus_mobile/widgets/in_app_alert_banner.dart';
import 'package:cognifocus_mobile/widgets/clay_navigation_bar.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://127.0.0.1:5000');
}

void main() {
  group('Real-Time Alert Models & Provider Tests', () {
    test('TeacherStatsModel copyWith creates modified instance', () {
      const stats = TeacherStatsModel(
        totalStudents: 15,
        alertsToday: 2,
        suspiciousStudents: 1,
      );

      final updated = stats.copyWith(
        alertsToday: 3,
        suspiciousStudents: 2,
      );

      expect(updated.totalStudents, 15);
      expect(updated.alertsToday, 3);
      expect(updated.suspiciousStudents, 2);
    });

    test('TeacherProvider addRealtimeAlert updates list and increments alertsToday', () {
      final apiClient = MockApiClient();
      final teacherService = TeacherService(apiClient: apiClient);
      final provider = TeacherProvider(teacherService: teacherService);

      const alert = AlertModel(
        id: 99,
        studentId: 'STU-007',
        seatId: 'A2',
        cameraId: 'CAM_01',
        alertType: 'Suspected Mobile Phone Usage: Active Handhold',
        confidence: 0.92,
        duration: '4s',
        status: 'Active',
        severity: 'High',
        timestamp: '2026-10-11T12:00:00Z',
      );

      expect(provider.alerts.length, 0);
      expect(provider.stats.alertsToday, 0);

      provider.addRealtimeAlert(alert);

      expect(provider.alerts.length, 1);
      expect(provider.alerts.first.id, 99);
      expect(provider.stats.alertsToday, 1);
      expect(provider.stats.suspiciousStudents, 1);

      // Duplicate addition should replace without incrementing counter
      provider.addRealtimeAlert(alert);
      expect(provider.alerts.length, 1);
      expect(provider.stats.alertsToday, 1);
    });

    test('AlertsProvider handleIncomingAlert deduplicates and sets active banner', () {
      final apiClient = MockApiClient();
      final alertsService = AlertsService(apiClient: apiClient);
      final teacherService = TeacherService(apiClient: apiClient);
      final provider = AlertsProvider(
        alertsService: alertsService,
        teacherService: teacherService,
      );

      const alert1 = AlertModel(
        id: 101,
        studentId: 'STU-001',
        seatId: 'B4',
        cameraId: 'CAM_01',
        alertType: 'Suspected Mobile Phone Usage: Active Handhold',
        confidence: 0.91,
        duration: '3s',
        status: 'Active',
        severity: 'High',
        timestamp: '2026-10-11T12:00:00Z',
      );

      provider.handleIncomingAlert(alert1);

      expect(provider.alerts.length, 1);
      expect(provider.unreadCount, 1);
      expect(provider.activeBannerAlert?.id, 101);

      // Identical alert ID must be ignored (deduplicated)
      provider.handleIncomingAlert(alert1);
      expect(provider.alerts.length, 1);
      expect(provider.unreadCount, 1);

      // Clear banner
      provider.clearBannerAlert();
      expect(provider.activeBannerAlert, isNull);

      // Mark all read
      provider.markAllAsRead();
      expect(provider.unreadCount, 0);
    });
  });

  group('InAppAlertBanner Widget Tests', () {
    testWidgets('InAppAlertBanner renders details and triggers callbacks', (tester) async {
      bool tapped = false;
      bool dismissed = false;

      const alert = AlertModel(
        id: 202,
        classroomId: 'ROOM_101',
        studentId: 'STU-002',
        seatId: 'C3',
        cameraId: 'CAM_02',
        alertType: 'Suspected Mobile Phone Usage',
        confidence: 0.89,
        duration: '5s',
        status: 'Active',
        severity: 'High',
        timestamp: '2026-10-11T12:00:00Z',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppAlertBanner(
              alert: alert,
              onTap: () => tapped = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Suspected Mobile Phone Usage'), findsOneWidget);
      expect(find.textContaining('Classroom: ROOM_101'), findsOneWidget);
      expect(find.textContaining('Seat: C3'), findsOneWidget);

      // Tap View button
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Tap Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  });

  group('ClayNavigationBar Badge Tests', () {
    testWidgets('ClayNavigationBar displays badge when badgeCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ClayNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                ClayNavTabItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                  activeIcon: Icons.dashboard,
                ),
                ClayNavTabItem(
                  label: 'Alerts',
                  icon: Icons.warning,
                  activeIcon: Icons.warning,
                  badgeCount: 3,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });
  });
}
