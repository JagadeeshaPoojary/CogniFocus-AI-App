import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/clay_colors.dart';
import '../../models/alert_model.dart';
import '../../models/camera_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_stat_card.dart';
import '../../widgets/clay_status_badge.dart';
import '../../widgets/evidence_modal.dart';

/// AdminDashboardScreen: Multi-Camera System Control & Metrics
class AdminDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const AdminDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final stats = adminProvider.stats;
    final palette = ClayColors.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Admin Overview',
            subtitle: 'System Status & Multi-Camera Control',
            onRefresh: () => adminProvider.fetchAdminData(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: ClayColors.primaryBlue,
              onRefresh: () => adminProvider.fetchAdminData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Monitoring Control Banner
                    ClayCard(
                      color: stats.monitoringActive
                          ? ClayColors.clayMint
                          : ClayColors.clayLavender,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: stats.monitoringActive
                                  ? palette.success
                                  : palette.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Global Monitoring: ${stats.monitoringActive ? "ACTIVE" : "STOPPED"}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stats.monitoringActive
                                      ? 'AI Pose & Object workers are actively running.'
                                      : 'Hardware cameras are released and idle.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClayButton(
                            text: stats.monitoringActive ? 'Stop All' : 'Start All',
                            icon: stats.monitoringActive
                                ? Icons.stop_circle_rounded
                                : Icons.play_arrow_rounded,
                            color: stats.monitoringActive
                                ? palette.error
                                : palette.primaryBlue,
                            height: 38,
                            isFullWidth: false,
                            isLoading: adminProvider.isToggling,
                            onPressed: () => adminProvider.toggleMonitoring(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Section Header
                    Text(
                      'System Metrics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics 2x2 Grid
                    Row(
                      children: [
                        Expanded(
                          child: ClayStatCard(
                            title: 'Total Students',
                            value: stats.activeStudents,
                            icon: Icons.people_alt_rounded,
                            iconColor: ClayColors.primaryBlue,
                            subtitle: 'Seated & Detected',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClayStatCard(
                            title: 'Active Cameras',
                            value:
                                '${stats.activeCameras} / ${stats.totalCameras}',
                            icon: Icons.videocam_rounded,
                            iconColor: ClayColors.mintGreen,
                            subtitle: 'Workers Online',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClayStatCard(
                            title: 'Active Alerts',
                            value: stats.activeAlerts,
                            icon: Icons.warning_rounded,
                            iconColor: ClayColors.softCoral,
                            subtitle: 'Requires Attention',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClayStatCard(
                            title: 'Alerts Today',
                            value: stats.alertsToday,
                            icon: Icons.today_rounded,
                            iconColor: ClayColors.warmAmber,
                            subtitle: 'Total Recorded Today',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Connected Cameras Card
                    ClayCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Connected Camera Workers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (widget.onNavigateTab != null)
                                GestureDetector(
                                  onTap: () => widget.onNavigateTab!(
                                    2,
                                  ), // Live Stream tab
                                  child: const Text(
                                    'View Streams →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ClayColors.primaryBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...adminProvider.cameras.map(
                            (cam) => _buildCameraItem(cam),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Alerts Card
                    ClayCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent System Alerts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (widget.onNavigateTab != null)
                                GestureDetector(
                                  onTap: () =>
                                      widget.onNavigateTab!(3), // Alerts tab
                                  child: const Text(
                                    'All Alerts →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ClayColors.primaryBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (adminProvider.recentAlerts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  'No recent alerts recorded.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ClayColors.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...adminProvider.recentAlerts.map(
                              (alert) => _buildAlertItem(
                                alert,
                                authProvider.serverUrl,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraItem(CameraModel cam) {
    final palette = ClayColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.canvasDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.videocam_rounded,
            size: 20,
            color: cam.isOnline
                ? palette.success
                : palette.textLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cam.id} • ${cam.name}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'FPS: ${cam.fps} • Source ${cam.source}',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (cam.isOnline)
            ClayStatusBadge.live()
          else
            ClayStatusBadge.offline(),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AlertModel alert, String serverUrl) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return GestureDetector(
      onTap: () =>
          EvidenceModal.show(context, alert: alert, serverUrl: serverUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.canvasDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 16,
                color: palette.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.alertType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${alert.cameraId} • Seat ${alert.seatId ?? "N/A"} • ${alert.duration}',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            ClayStatusBadge.highSeverity(alert.severity),
          ],
        ),
      ),
    );
  }
}
