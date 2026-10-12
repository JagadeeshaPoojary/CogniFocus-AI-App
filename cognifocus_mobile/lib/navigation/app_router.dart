import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import '../models/alert_model.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/classrooms/classrooms_screen.dart';
import '../screens/monitoring/live_monitoring_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/teacher/teacher_dashboard_screen.dart';
import '../services/notification_service.dart';
import '../widgets/clay_navigation_bar.dart';
import '../widgets/evidence_modal.dart';
import '../widgets/in_app_alert_banner.dart';

/// AppRouter: Role-Based Navigation & Main Application Scaffold
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _activeTabIndex = 0;
  AlertsProvider? _alertsProvider;

  @override
  void initState() {
    super.initState();
    NotificationService.onNotificationTapped.addListener(_handleNotificationTap);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alertsProvider = context.read<AlertsProvider>();
  }

  @override
  void dispose() {
    NotificationService.onNotificationTapped.removeListener(_handleNotificationTap);
    _alertsProvider?.stopRealtimeSync();
    super.dispose();
  }

  void _handleNotificationTap() {
    final payload = NotificationService.onNotificationTapped.value;
    if (payload == null || payload.isEmpty) return;
    NotificationService.onNotificationTapped.value = null;

    final alertId = int.tryParse(payload);
    if (alertId == null) return;

    if (!mounted) return;
    setState(() {
      _activeTabIndex = 3; // Switch to alerts tab
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final alertsProvider = context.read<AlertsProvider>();
      final authProvider = context.read<AuthProvider>();
      alertsProvider.markAllAsRead();

      final alert = alertsProvider.alerts.cast<AlertModel?>().firstWhere(
            (a) => a?.id == alertId,
            orElse: () => null,
          );
      if (alert != null && mounted) {
        EvidenceModal.show(
          context,
          alert: alert,
          serverUrl: authProvider.serverUrl,
          onAcknowledge: () => alertsProvider.acknowledgeAlert(
            alert.id,
            isTeacher: authProvider.isTeacher,
          ),
          onResolve: () => alertsProvider.resolveAlert(
            alert.id,
            isTeacher: authProvider.isTeacher,
          ),
        );
      }
    });
  }

  void _syncRealtimeIfAuthenticated() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.isTeacher) {
      final alertsProvider = context.read<AlertsProvider>();
      final teacherProvider = context.read<TeacherProvider>();
      alertsProvider.startRealtimeSync(
        baseUrl: authProvider.serverUrl,
        token: authProvider.token,
        classroomId: teacherProvider.stats.classroomId,
        onAlertReceived: (alert) {
          teacherProvider.addRealtimeAlert(alert);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final alertsProvider = context.watch<AlertsProvider>();

    // 1. Initial Loading Splash (Startup session restoration only)
    if (authProvider.isInitializing) {
      debugPrint('[AppRouter] Route decision: SPLASH (Restoring stored session)');
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: ClayStyles.raised(
                  color: ClayColors.of(context).card,
                  radius: 24,
                  depth: 6,
                  isDark: ClayColors.of(context).isDark,
                ),
                child: const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 36,
                  color: ClayColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ClayColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Initializing CogniFocus-AI Mobile...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.of(context).textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Unauthenticated: Render LoginScreen
    if (!authProvider.isAuthenticated) {
      debugPrint('[AppRouter] Route decision: LOGIN (No authenticated session)');
      return const LoginScreen();
    }

    // Trigger real-time alert sync for authenticated user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRealtimeIfAuthenticated();
    });

    final user = authProvider.user!;
    final isAdmin = user.isAdmin;
    final isTeacher = user.isTeacher;

    // 3. Unauthorized User Role
    if (!isAdmin && !isTeacher) {
      debugPrint(
        '[AppRouter] Route decision: UNAUTHORIZED ROLE (${user.role}) for ${user.email}',
      );
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 54,
                  color: ClayColors.softCoral,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unauthorized Role Access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ClayColors.softCoralDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your user account (${user.email}) has role \'${user.role}\', which is not authorized for CogniFocus-AI Mobile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ClayColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClayColors.softCoral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => authProvider.logout(),
                  child: const Text('Return to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 4. Authenticated: Render active tab
    Widget activeScreen;
    switch (_activeTabIndex) {
      case 0:
        activeScreen = isAdmin
            ? AdminDashboardScreen(
                onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
              )
            : TeacherDashboardScreen(
                onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
              );
        break;
      case 1:
        activeScreen = ClassroomsScreen(
          onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
        );
        break;
      case 2:
        activeScreen = const LiveMonitoringScreen();
        break;
      case 3:
        activeScreen = const AlertsScreen();
        break;
      case 4:
        activeScreen = const SettingsScreen();
        break;
      default:
        activeScreen = isAdmin
            ? AdminDashboardScreen(
                onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
              )
            : TeacherDashboardScreen(
                onNavigateTab: (idx) => setState(() => _activeTabIndex = idx),
              );
    }

    final unreadCount = alertsProvider.unreadCount;
    final navItems = [
      const ClayNavTabItem(
        label: 'Dashboard',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      const ClayNavTabItem(
        label: 'Classrooms',
        icon: Icons.school_outlined,
        activeIcon: Icons.school_rounded,
      ),
      const ClayNavTabItem(
        label: 'Live Stream',
        icon: Icons.videocam_outlined,
        activeIcon: Icons.videocam_rounded,
      ),
      ClayNavTabItem(
        label: 'Alerts',
        icon: Icons.warning_amber_rounded,
        activeIcon: Icons.warning_rounded,
        badgeCount: _activeTabIndex == 3 ? 0 : unreadCount,
      ),
      const ClayNavTabItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
      ),
    ];

    final activeBannerAlert = alertsProvider.activeBannerAlert;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          activeScreen,
          if (activeBannerAlert != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InAppAlertBanner(
                alert: activeBannerAlert,
                onTap: () {
                  alertsProvider.clearBannerAlert();
                  setState(() => _activeTabIndex = 3);
                  alertsProvider.markAllAsRead();
                  EvidenceModal.show(
                    context,
                    alert: activeBannerAlert,
                    serverUrl: authProvider.serverUrl,
                    onAcknowledge: () => alertsProvider.acknowledgeAlert(
                      activeBannerAlert.id,
                      isTeacher: isTeacher,
                    ),
                    onResolve: () => alertsProvider.resolveAlert(
                      activeBannerAlert.id,
                      isTeacher: isTeacher,
                    ),
                  );
                },
                onDismiss: () {
                  alertsProvider.clearBannerAlert();
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClayNavigationBar(
        currentIndex: _activeTabIndex,
        items: navItems,
        onTap: (index) {
          if (index == 3) {
            alertsProvider.markAllAsRead();
          }
          setState(() {
            _activeTabIndex = index;
          });
        },
      ),
    );
  }
}
