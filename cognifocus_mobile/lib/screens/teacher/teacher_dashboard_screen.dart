import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/clay_colors.dart';
import '../../core/theme/clay_styles.dart';
import '../../models/alert_model.dart';
import '../../models/classroom_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';
import '../../widgets/clay_stat_card.dart';
import '../../widgets/clay_status_badge.dart';
import '../../widgets/clay_theme_switcher.dart';
import '../../widgets/evidence_modal.dart';
import '../../widgets/server_config_dialog.dart';

/// TeacherDashboardScreen: Complete Teacher Classroom Monitoring & Focus Workspace
class TeacherDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const TeacherDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final TextEditingController _codeController = TextEditingController(
    text: 'CSE301',
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRefresh();
    });
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
    await Future.wait([
      context.read<TeacherProvider>().refreshAll(),
      context.read<AuthProvider>().checkTeacherSession(),
    ]);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleStartMonitoring([String? codeToUse]) async {
    final code = (codeToUse ?? _codeController.text).trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a classroom access code.');
      return;
    }

    if (codeToUse != null) {
      _codeController.text = codeToUse;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final teacherProvider = context.read<TeacherProvider>();
      final messenger = ScaffoldMessenger.of(context);

      await authProvider.enterClassroom(code);
      if (mounted) {
        setState(() => _errorMessage = null);
        await teacherProvider.refreshAll();
        messenger.showSnackBar(
          SnackBar(
            content: Text('AI monitoring started for classroom $code!'),
            backgroundColor: ClayColors.mintGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException ? e.message : e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleStopMonitoring() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final teacherProvider = context.read<TeacherProvider>();
      final messenger = ScaffoldMessenger.of(context);

      await authProvider.stopMonitoring();
      if (mounted) {
        setState(() => _errorMessage = null);
        await teacherProvider.refreshAll();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Classroom monitoring session stopped.'),
            backgroundColor: ClayColors.textPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException ? e.message : e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClayCard(
          radius: 20,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: ClayColors.softCoral,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign Out of Session',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to end your current teacher monitoring session and return to Sign In?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ClayColors.textSecondary,
                        side: const BorderSide(color: ClayColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClayButton(
                      text: 'Sign Out',
                      icon: Icons.logout_rounded,
                      color: ClayColors.softCoral,
                      height: 42,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.read<AuthProvider>().logout();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final stats = teacherProvider.stats;
    final isMonitoring = authProvider.monitoringActive;
    final activeClassroom = authProvider.activeClassroom;
    final user = authProvider.user;
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactScreen = screenWidth < 360;
    final actionButtonSize = isCompactScreen ? 34.0 : 38.0;
    final actionButtonGap = isCompactScreen ? 6.0 : 8.0;
    final actionIconSize = isCompactScreen ? 17.0 : 19.0;

    return Container(
      decoration: BoxDecoration(
        gradient: ClayStyles.canvasGradient(isDark),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 66,
        titleSpacing: isCompactScreen ? 14 : 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Teacher Workspace',
              style: TextStyle(
                fontSize: isCompactScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              activeClassroom != null
                  ? 'Active: ${activeClassroom.name} (${activeClassroom.code})'
                  : 'Assigned Classroom Monitoring',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: palette.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Server Connection Settings Button
          _buildHeaderActionButton(
            tooltip: 'Server Connection Settings',
            icon: Icons.dns_rounded,
            iconColor: palette.primaryBlue,
            onPressed: () => ServerConfigDialog.show(
              context,
              onSaved: () {
                _handleRefresh();
              },
            ),
            palette: palette,
            isDark: isDark,
            size: actionButtonSize,
            iconSize: actionIconSize,
          ),
          SizedBox(width: actionButtonGap),
          // Refresh Button
          _buildHeaderActionButton(
            tooltip: 'Refresh Workspace',
            icon: Icons.refresh_rounded,
            iconColor: palette.primaryBlue,
            onPressed: _handleRefresh,
            palette: palette,
            isDark: isDark,
            size: actionButtonSize,
            iconSize: actionIconSize,
          ),
          SizedBox(width: actionButtonGap),
          // Visible Sun/Moon Theme Toggle Button
          _buildHeaderActionButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            iconColor: isDark ? ClayColors.warmAmber : ClayColors.primaryBlue,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(context),
            onLongPress: () => ClayThemeSwitcher.showModal(context),
            palette: palette,
            isDark: isDark,
            size: actionButtonSize,
            iconSize: actionIconSize,
          ),
          SizedBox(width: actionButtonGap),
          // Sign Out Button
          _buildHeaderActionButton(
            tooltip: 'Sign Out',
            icon: Icons.logout_rounded,
            iconColor: ClayColors.softCoral,
            onPressed: () => _showLogoutConfirmation(context),
            palette: palette,
            isDark: isDark,
            size: actionButtonSize,
            iconSize: actionIconSize,
          ),
          SizedBox(width: isCompactScreen ? 12 : 16),
        ],
      ),
      body: RefreshIndicator(
        color: ClayColors.primaryBlue,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Connection Error Banner
              if (teacherProvider.errorMessage != null) ...[
                ClayCard(
                  padding: const EdgeInsets.all(16),
                  color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              teacherProvider.isConnectionError
                                  ? Icons.wifi_off_rounded
                                  : Icons.error_outline_rounded,
                              size: 20,
                              color: palette.error,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacherProvider.isConnectionError
                                      ? 'Backend Connection Failed'
                                      : 'Workspace Sync Notice',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: palette.error,
                                  ),
                                ),
                                Text(
                                  'Server: ${authProvider.serverUrl}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: palette.textMuted,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => teacherProvider.clearError(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        teacherProvider.errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClayButton(
                              text: 'Retry Connection',
                              icon: Icons.refresh_rounded,
                              height: 38,
                              color: ClayColors.clayBlue,
                              textColor: ClayColors.primaryBlue,
                              isLoading: teacherProvider.isLoading,
                              onPressed: _handleRefresh,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClayButton(
                              text: 'Change Server IP',
                              icon: Icons.settings_ethernet_rounded,
                              height: 38,
                              color: ClayColors.clayMint,
                              textColor: ClayColors.mintGreenDark,
                              onPressed: () => ServerConfigDialog.show(
                                context,
                                onSaved: () {
                                  _handleRefresh();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Compact Teacher Profile Card
              ClayCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Squircle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: ClayStyles.raised(
                        color: isDark ? ClayColors.darkClayBlue : ClayColors.clayBlue,
                        radius: 14,
                        depth: 3,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: Text(
                          (user != null && user.name.isNotEmpty
                                  ? user.name[0]
                                  : 'T')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: ClayColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Profile Information Column (Name, TEACHER badge, Email)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                user?.name ?? 'Teacher Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? ClayColors.darkClayMint
                                      : ClayColors.clayMint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TEACHER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: ClayColors.mintGreenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? 'teacher@classroom.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

                    // Classroom Access Code Entry Card
                    ClayCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? ClayColors.darkClayBlue : ClayColors.clayBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.vpn_key_rounded,
                                  size: 20,
                                  color: palette.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Classroom Access Code',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Enter code (e.g. CSE301) to start AI session',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Remove duplicate connection-error banner if dashboard top banner already shows it
                          if (_errorMessage != null &&
                              !(teacherProvider.errorMessage != null &&
                                  (_errorMessage == teacherProvider.errorMessage ||
                                      (teacherProvider.isConnectionError &&
                                          (_errorMessage!.toLowerCase().contains('timed out') ||
                                              _errorMessage!.toLowerCase().contains('unable to reach') ||
                                              _errorMessage!.toLowerCase().contains('connection')))))) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: palette.error.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _errorMessage!.toLowerCase().contains('timed out') ||
                                                _errorMessage!.toLowerCase().contains('unable to reach')
                                            ? Icons.wifi_off_rounded
                                            : Icons.error_outline_rounded,
                                        size: 18,
                                        color: palette.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: palette.error,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: palette.error,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => setState(() => _errorMessage = null),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: _isSubmitting
                                              ? null
                                              : () {
                                                  if (isMonitoring) {
                                                    _handleStopMonitoring();
                                                  } else {
                                                    _handleStartMonitoring();
                                                  }
                                                },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: palette.card,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: palette.primaryBlue.withOpacity(0.4)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.refresh_rounded, size: 14, color: palette.primaryBlue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: palette.primaryBlue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => ServerConfigDialog.show(
                                            context,
                                            onSaved: () {
                                              setState(() => _errorMessage = null);
                                              if (isMonitoring) {
                                                _handleStopMonitoring();
                                              } else {
                                                _handleStartMonitoring();
                                              }
                                            },
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: palette.card,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: ClayColors.mintGreenDark.withOpacity(0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.settings_ethernet_rounded, size: 14, color: ClayColors.mintGreenDark),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Change Server',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: ClayColors.mintGreenDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],


                          ClayInput(
                            controller: _codeController,
                            hintText: 'Enter Classroom Code (e.g. CSE301)',
                            prefixIcon: Icons.vpn_key_rounded,
                            textCapitalization: TextCapitalization.characters,
                            enabled: !isMonitoring,
                          ),
                          const SizedBox(height: 12),
                          if (isMonitoring)
                            ClayButton(
                              text: 'Stop Monitoring Session',
                              icon: Icons.stop_circle_rounded,
                              color: ClayColors.softCoral,
                              height: 48,
                              isFullWidth: true,
                              isLoading: _isSubmitting,
                              onPressed: _handleStopMonitoring,
                            )
                          else
                            ClayButton(
                              text: 'Start Monitoring',
                              icon: Icons.play_arrow_rounded,
                              color: ClayColors.emeraldGreen,
                              height: 48,
                              isFullWidth: true,
                              isLoading: _isSubmitting,
                              onPressed: () => _handleStartMonitoring(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Monitoring & Camera Online/Offline Status Banner
                    ClayCard(
                      color: isMonitoring
                          ? (isDark ? ClayColors.darkClayMint : ClayColors.clayMint)
                          : (isDark ? ClayColors.darkCard : palette.card),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMonitoring
                                  ? (isDark ? ClayColors.darkClayMint : ClayColors.clayMint)
                                  : (isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMonitoring
                                  ? Icons.sensors_rounded
                                  : Icons.sensors_off_rounded,
                              size: 22,
                              color: isMonitoring
                                  ? palette.success
                                  : ClayColors.softCoral,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMonitoring
                                      ? 'Monitoring Session Active: ${activeClassroom?.name ?? "CSE-301"}'
                                      : 'No Active Monitoring Session',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isMonitoring
                                      ? 'Cameras CAM001 & CAM002 streaming with real-time YOLO pose analysis.'
                                      : 'Enter classroom code above or select an authorized hall below.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMonitoring)
                            ClayStatusBadge.live()
                          else
                            ClayStatusBadge.offline(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Telemetry Stat Metrics Header
                    Text(
                      'Session Telemetry Metrics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Metrics 2x2 Grid + Duration Row
                    Row(
                      children: [
                        Expanded(
                          child: ClayStatCard(
                            title: 'Total Students',
                            value: stats.totalStudents,
                            icon: Icons.people_outline_rounded,
                            iconColor: ClayColors.primaryBlue,
                            subtitle: 'Enrolled in Hall',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClayStatCard(
                            title: 'Active Cameras',
                            value: isMonitoring ? '2 Online' : 'Idle',
                            icon: Icons.videocam_outlined,
                            iconColor: ClayColors.mintGreen,
                            subtitle: 'Classroom Feeds',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClayStatCard(
                            title: 'Alerts Today',
                            value: stats.alertsToday,
                            icon: Icons.notifications_active_outlined,
                            iconColor: ClayColors.warmAmber,
                            subtitle: 'Triggered Events',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ClayStatCard(
                            title: 'Suspicious Students',
                            value: stats.suspiciousStudents,
                            icon: Icons.person_search_outlined,
                            iconColor: ClayColors.softCoral,
                            subtitle: 'Unique Student IDs',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClayCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? ClayColors.darkClayBlue : ClayColors.clayBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: palette.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Suspicious-Behavior Duration',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                                Text(
                                  '${stats.avgUsageDuration.toStringAsFixed(1)} seconds',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onNavigateTab != null)
                            TextButton(
                              onPressed: () =>
                                  widget.onNavigateTab!(2), // Live Stream
                              child: const Text(
                                'View Feeds →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // MY AUTHORIZED CLASSROOMS SECTION
                    ClayCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark ? ClayColors.darkClayBlue : ClayColors.clayBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        size: 16,
                                        color: ClayColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'MY AUTHORIZED CLASSROOMS',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                          letterSpacing: 0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${teacherProvider.classrooms.length} Assigned',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (teacherProvider.classrooms.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: palette.canvasDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No authorized classrooms found. Enter code above to begin monitoring.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...teacherProvider.classrooms.map(
                              (cls) => _buildClassroomItem(
                                cls,
                                activeClassroom?.code == cls.code ||
                                    activeClassroom?.id == cls.id,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CLASSROOM ALERTS & HISTORY SECTION
                    ClayCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_rounded,
                                        size: 16,
                                        color: ClayColors.softCoral,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Classroom Alerts & History',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.onNavigateTab != null) ...[
                                const SizedBox(width: 8),
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
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (teacherProvider.alerts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: palette.canvasDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No alerts detected for this classroom session.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...teacherProvider.alerts
                                .take(5)
                                .map(
                                  (alert) => _buildAlertItem(
                                    alert,
                                    authProvider.serverUrl,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildClassroomItem(ClassroomModel cls, bool isActive) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? ClayColors.darkClayMint : ClayColors.clayMint).withOpacity(0.5)
            : palette.canvasDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? ClayColors.mintGreen.withOpacity(0.5)
              : palette.borderSubtle,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cls.code.isNotEmpty ? cls.code : cls.id,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? ClayColors.darkClayMint : ClayColors.clayMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: palette.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: palette.success,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? ClayColors.darkClayLavender : ClayColors.clayLavender,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'HISTORICAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cls.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isActive)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: ClayColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _handleStartMonitoring(cls.code),
                  child: const Text(
                    'Select →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildClassroomStatPill(
                'Students',
                cls.studentsCount.toString(),
                Icons.people_outline,
                palette,
              ),
              const SizedBox(width: 8),
              _buildClassroomStatPill(
                'Cameras',
                cls.camerasCount.toString(),
                Icons.videocam_outlined,
                palette,
              ),
              const SizedBox(width: 8),
              _buildClassroomStatPill(
                'Alerts',
                cls.totalAlerts.toString(),
                Icons.warning_amber_rounded,
                palette,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomStatPill(
    String label,
    String value,
    IconData icon,
    ClayThemePalette palette,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: palette.card.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: palette.textMuted),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 10,
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: palette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(AlertModel alert, String serverUrl) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return GestureDetector(
      onTap: () => EvidenceModal.show(
        context,
        alert: alert,
        serverUrl: serverUrl,
        onAcknowledge: () async {
          final alertsProvider = context.read<AlertsProvider>();
          final teacherProvider = context.read<TeacherProvider>();
          await alertsProvider.acknowledgeAlert(alert.id, isTeacher: true);
          await teacherProvider.refreshAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Alert #${alert.id} acknowledged.'),
                backgroundColor: ClayColors.primaryBlue,
              ),
            );
          }
        },
        onResolve: () async {
          final alertsProvider = context.read<AlertsProvider>();
          final teacherProvider = context.read<TeacherProvider>();
          await alertsProvider.resolveAlert(alert.id, isTeacher: true);
          await teacherProvider.refreshAll();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Alert #${alert.id} marked resolved.'),
                backgroundColor: palette.success,
              ),
            );
          }
        },
      ),
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
                    '${alert.studentId ?? "STU-001"} • Seat ${alert.seatId ?? "B8"} • ${alert.duration}',
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

  Widget _buildHeaderActionButton({
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    required ClayThemePalette palette,
    required bool isDark,
    double size = 38,
    double iconSize = 19,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: ClayStyles.raised(
          color: palette.card,
          radius: size > 36 ? 12 : 10,
          depth: 3,
          isDark: isDark,
        ),
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          splashRadius: size / 2,
          icon: Icon(icon, size: iconSize, color: iconColor),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
