import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/clay_colors.dart';
import '../../models/alert_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_status_badge.dart';
import '../../widgets/evidence_modal.dart';

/// AlertsScreen: System AI Monitoring Alert Log & Evidence Review
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<String> _statusFilters = [
    'All',
    'Active',
    'Acknowledged',
    'Resolved',
  ];
  final List<String> _timeframeFilters = [
    'All',
    'Today',
    'Yesterday',
    '7 Days',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isTeacher = context.read<AuthProvider>().isTeacher;
      context.read<AlertsProvider>().fetchAlerts(isTeacher: isTeacher);
    });
  }

  void _onStatusFilterSelected(String filter) {
    final isTeacher = context.read<AuthProvider>().isTeacher;
    context.read<AlertsProvider>().setStatusFilter(
      filter,
      isTeacher: isTeacher,
    );
  }

  void _onTimeframeFilterSelected(String filter) {
    final isTeacher = context.read<AuthProvider>().isTeacher;
    context.read<AlertsProvider>().setTimeframeFilter(
      filter,
      isTeacher: isTeacher,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final isTeacher = authProvider.isTeacher;
    final alerts = alertsProvider.alerts;
    final palette = ClayColors.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Alerts & Incidents',
            subtitle: '${alertsProvider.totalAlerts} Total Detected Events',
            onRefresh: () => alertsProvider.fetchAlerts(isTeacher: isTeacher),
          ),

          // Filters Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: palette.canvas,
              border: Border(
                bottom: BorderSide(
                  color: palette.borderSubtle.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ..._statusFilters.map((st) {
                    final isSelected = alertsProvider.statusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(st),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : palette.textPrimary,
                        ),
                        selectedColor: palette.primaryBlue,
                        backgroundColor: palette.card,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : palette.borderSubtle,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (_) => _onStatusFilterSelected(st),
                      ),
                    );
                  }),
                  Container(
                    width: 1,
                    height: 20,
                    color: palette.borderSubtle,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  ..._timeframeFilters.map((tf) {
                    final isSelected = alertsProvider.timeframeFilter == tf;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(tf),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : palette.textPrimary,
                        ),
                        selectedColor: palette.secondaryLavender,
                        backgroundColor: palette.card,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : palette.borderSubtle,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (_) => _onTimeframeFilterSelected(tf),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Alerts List
          Expanded(
            child: RefreshIndicator(
              color: palette.primaryBlue,
              onRefresh: () => alertsProvider.fetchAlerts(isTeacher: isTeacher),
              child: alertsProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.primaryBlue,
                        ),
                      ),
                    )
                  : alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: palette.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No alerts match selected filters',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      itemCount: alerts.length,
                      itemBuilder: (ctx, index) {
                        final alert = alerts[index];
                        return _buildAlertCard(
                          alert,
                          authProvider.serverUrl,
                          isTeacher,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert, String serverUrl, bool isTeacher) {
    final palette = ClayColors.of(context);
    final evidenceUrl = ApiConfig.getEvidenceUrl(
      baseUrl: serverUrl,
      relativePath: alert.evidenceImage,
    );

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClayStatusBadge.highSeverity(alert.severity.toUpperCase()),
                  const SizedBox(width: 8),
                  if (alert.isResolved)
                    ClayStatusBadge.resolved()
                  else if (alert.isAcknowledged)
                    ClayStatusBadge.acknowledged()
                  else
                    ClayStatusBadge.active(),
                ],
              ),
              Text(
                alert.timestamp.replaceAll('T', ' ').split('.').first,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alert Body Row (Evidence Thumbnail + Meta Details)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Evidence Thumbnail
              GestureDetector(
                onTap: () => EvidenceModal.show(
                  context,
                  alert: alert,
                  serverUrl: serverUrl,
                  onAcknowledge: () => context
                      .read<AlertsProvider>()
                      .acknowledgeAlert(alert.id, isTeacher: isTeacher),
                  onResolve: () => context.read<AlertsProvider>().resolveAlert(
                    alert.id,
                    isTeacher: isTeacher,
                  ),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ClayColors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (evidenceUrl.isNotEmpty)
                        Image.network(
                          evidenceUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 28,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 28,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Metadata Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ClayColors.textColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildMetaLine(
                      icon: Icons.person_outline_rounded,
                      text:
                          'Student: ${alert.studentId ?? "STU-001"} • Seat ${alert.seatId ?? "B8"}',
                    ),
                    _buildMetaLine(
                      icon: Icons.videocam_outlined,
                      text: 'Camera: ${alert.cameraId}',
                    ),
                    _buildMetaLine(
                      icon: Icons.timer_outlined,
                      text:
                          'Duration: ${alert.duration} • ${(alert.confidence * 100).toStringAsFixed(0)}% Conf',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (alert.isActive) ...[
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => context
                      .read<AlertsProvider>()
                      .acknowledgeAlert(alert.id, isTeacher: isTeacher),
                  icon: const Icon(Icons.done, size: 16),
                  label: const Text(
                    'Acknowledge',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!alert.isResolved) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 1,
                  ),
                  onPressed: () => context.read<AlertsProvider>().resolveAlert(
                    alert.id,
                    isTeacher: isTeacher,
                  ),
                  icon: const Icon(Icons.task_alt, size: 14),
                  label: const Text(
                    'Resolve',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaLine({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: ClayColors.of(context).textLight),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ClayColors.textMutedColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
