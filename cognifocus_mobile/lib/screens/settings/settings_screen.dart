import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/clay_colors.dart';
import '../../core/theme/clay_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';

/// SettingsScreen: Account, API Connection Diagnostics & Notifications
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTestingConn = false;
  String? _connDiagnostic;
  bool _emailNotifs = true;
  bool _smsNotifs = true;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _urlController = TextEditingController(text: authProvider.serverUrl);
    _loadNotificationPrefs();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPrefs() async {
    final notifService = context.read<NotificationService>();
    final prefs = await notifService.getPreferences();
    if (mounted && prefs.isNotEmpty) {
      setState(() {
        _emailNotifs = prefs['email_notifications_enabled'] == true;
        _smsNotifs = prefs['sms_notifications_enabled'] == true;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConn = true;
      _connDiagnostic = null;
    });

    final targetUrl = _urlController.text.trim();
    final client = ApiClient(baseUrl: targetUrl);
    final result = await client.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConn = false;
        _connDiagnostic = result['success'] == true
            ? 'Success: ${result['message']}'
            : 'Diagnostic Warning: ${result['message']}';
      });
    }
  }

  Future<void> _saveServerUrl() async {
    final auth = context.read<AuthProvider>();
    await auth.updateServerUrl(_urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server endpoint saved successfully.'),
          backgroundColor: ClayColors.mintGreenDark,
        ),
      );
    }
  }

  Future<void> _toggleEmailNotifs(bool val) async {
    setState(() => _emailNotifs = val);
    await context.read<NotificationService>().updatePreferences(
      emailEnabled: val,
    );
  }

  Future<void> _toggleSmsNotifs(bool val) async {
    setState(() => _smsNotifs = val);
    await context.read<NotificationService>().updatePreferences(
      smsEnabled: val,
    );
  }

  Future<void> _triggerTestNotification() async {
    final notifService = context.read<NotificationService>();
    await notifService.showLocalAlert(
      title: 'CogniFocus-AI Alert',
      body:
          'High Priority: Unauthorized cell phone detected in CSE-301 (Seat B8)',
      id: 101,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local alert notification dispatched!'),
          backgroundColor: ClayColors.primaryBlue,
        ),
      );
    }
  }

  void _confirmLogout() {
    final palette = ClayColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to end your current session and release active camera workers?',
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: palette.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.softCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Settings & Account',
            subtitle: 'System Configuration & User Profile',
            trailing: GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: ClayStyles.raised(
                  color: isDark ? ClayColors.darkClayCoral : ClayColors.clayCoral,
                  radius: 12,
                  depth: 2,
                  isDark: isDark,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: ClayColors.softCoral,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ClayColors.softCoral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Summary Card
                  ClayCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark
                                ? ClayColors.darkClayBlue
                                : ClayColors.clayBlue,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? ClayColors.darkBorderHighlight
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: ClayColors.primaryBlueLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Authorized User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'user@classroom.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: user?.isAdmin == true
                                      ? (isDark
                                          ? ClayColors.darkClayCoral
                                          : ClayColors.clayCoral)
                                      : (isDark
                                          ? ClayColors.darkClayMint
                                          : ClayColors.clayMint),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${user?.role ?? "TEACHER"} ROLE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: user?.isAdmin == true
                                        ? ClayColors.softCoral
                                        : ClayColors.mintGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appearance & Theme Card
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
                                color: isDark
                                    ? ClayColors.darkClayBlue
                                    : ClayColors.clayBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                size: 20,
                                color: isDark
                                    ? ClayColors.warmAmber
                                    : ClayColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appearance & Theme',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Dark Mode & Light Mode preferences',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Clearly labeled Light/Dark theme switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            isDark
                                ? 'Dark Mode: ACTIVE (CogniFocus deep navy dashboard theme)'
                                : 'Light Mode: ACTIVE (CogniFocus crisp high-contrast theme)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: palette.textMuted,
                            ),
                          ),
                          secondary: Icon(
                            isDark
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded,
                            color: isDark
                                ? ClayColors.warmAmber
                                : ClayColors.primaryBlue,
                            size: 24,
                          ),
                          value: themeProvider.isDark(context),
                          activeColor: palette.primaryBlue,
                          onChanged: (bool enabled) {
                            themeProvider.setThemeMode(
                              enabled ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        ),

                        Divider(
                          height: 20,
                          color: isDark
                              ? ClayColors.darkBorderSubtle
                              : ClayColors.borderSubtle,
                        ),

                        // Theme Mode Selector Chips: System / Light / Dark
                        Text(
                          'Theme Preference',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThemeOption(
                                context: context,
                                title: 'System',
                                icon: Icons.settings_brightness_rounded,
                                isSelected: themeProvider.themeMode ==
                                    ThemeMode.system,
                                onTap: () => themeProvider.setThemeMode(
                                  ThemeMode.system,
                                ),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOption(
                                context: context,
                                title: 'Light Mode',
                                icon: Icons.wb_sunny_rounded,
                                isSelected: themeProvider.themeMode ==
                                    ThemeMode.light,
                                onTap: () => themeProvider.setThemeMode(
                                  ThemeMode.light,
                                ),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOption(
                                context: context,
                                title: 'Dark Mode',
                                icon: Icons.nightlight_round,
                                isSelected: themeProvider.themeMode ==
                                    ThemeMode.dark,
                                onTap: () => themeProvider.setThemeMode(
                                  ThemeMode.dark,
                                ),
                                palette: palette,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Backend Connection Settings Card
                  ClayCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.router_rounded,
                              size: 20,
                              color: ClayColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Backend Endpoint Settings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Configure host IP where your Python/Flask backend is running.',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClayInput(
                          controller: _urlController,
                          label: 'Base Server URL',
                          hintText: ApiConfig.physicalPhoneServerUrl,
                          prefixIcon: Icons.dns_rounded,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.wifi_rounded, size: 14),
                              label: Text(
                                'Wi-Fi LAN (${ApiConfig.laptopLanIp})',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                setState(() {
                                  _urlController.text = ApiConfig.physicalPhoneServerUrl;
                                  _connDiagnostic = null;
                                });
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.usb_rounded, size: 14),
                              label: const Text(
                                'USB Reverse (127.0.0.1)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                setState(() {
                                  _urlController.text = 'http://127.0.0.1:5000';
                                  _connDiagnostic = null;
                                });
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.devices_rounded, size: 14),
                              label: const Text(
                                'Emulator (10.0.2.2)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                setState(() {
                                  _urlController.text = 'http://10.0.2.2:5000';
                                  _connDiagnostic = null;
                                });
                              },
                            ),
                          ],
                        ),

                        if (_connDiagnostic != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _connDiagnostic!.startsWith('Success')
                                  ? (isDark
                                      ? ClayColors.darkClayMint
                                      : ClayColors.clayMint)
                                  : (isDark
                                      ? ClayColors.darkClayCoral
                                      : ClayColors.clayCoral),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _connDiagnostic!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _connDiagnostic!.startsWith('Success')
                                    ? ClayColors.mintGreen
                                    : ClayColors.softCoral,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.textSecondary,
                                  side: BorderSide(
                                    color: palette.borderSubtle,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _isTestingConn
                                    ? null
                                    : _testConnection,
                                child: Text(
                                  _isTestingConn ? 'Testing...' : 'Test Ping',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClayButton(
                                text: 'Save Endpoint',
                                height: 42,
                                onPressed: _saveServerUrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Guidance note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.canvasDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '• Android Emulator: http://10.0.2.2:5000\n• Physical Phone: http://<laptop_ip>:5000 (Ensure laptop and phone are on the same Wi-Fi and port 5000 is open in Windows Firewall)',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications Configuration Card
                  ClayCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 20,
                              color: ClayColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alerts & Notifications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Local Notifications Test
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Local Notifications',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Verify notification banner and sound',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ClayColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: _triggerTestNotification,
                              child: const Text(
                                'Test Alert',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: palette.borderSubtle,
                        ),

                        // Email Notifications Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Email Notifications',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Send incident email alerts to registered address',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                          value: _emailNotifs,
                          activeThumbColor: ClayColors.primaryBlue,
                          onChanged: _toggleEmailNotifs,
                        ),

                        // SMS Notifications Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'SMS Mobile Alerts',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Send SMS text alerts for critical phone usage',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                          value: _smsNotifs,
                          activeThumbColor: ClayColors.primaryBlue,
                          onChanged: _toggleSmsNotifs,
                        ),

                        Divider(
                          height: 24,
                          color: palette.borderSubtle,
                        ),

                        // Backend dispatch triggers
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.textSecondary,
                                  side: BorderSide(
                                    color: palette.borderSubtle,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final notif = context
                                      .read<NotificationService>();
                                  final msg = await notif.testEmail();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                },
                                icon: const Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Test Email',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.textSecondary,
                                  side: BorderSide(
                                    color: palette.borderSubtle,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final notif = context
                                      .read<NotificationService>();
                                  final msg = await notif.testSms();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                },
                                icon: const Icon(Icons.sms_outlined, size: 14),
                                label: const Text(
                                  'Test SMS',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ClayThemePalette palette,
  }) {
    final isDark = palette.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: isSelected
            ? ClayStyles.pressed(
                color: isDark
                    ? ClayColors.darkClayBlue
                    : ClayColors.clayBlue,
                radius: 12,
                isDark: isDark,
              )
            : ClayStyles.raised(
                color: palette.card,
                radius: 12,
                depth: 2,
                isDark: isDark,
              ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? palette.primaryBlue : palette.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? palette.primaryBlue
                    : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
