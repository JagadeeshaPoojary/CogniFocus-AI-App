import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/clay_colors.dart';
import '../../core/theme/clay_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/clay_button.dart';
import '../../widgets/clay_card.dart';
import '../../widgets/clay_input.dart';

import '../../widgets/server_config_dialog.dart';

/// LoginScreen for CogniFocus-AI Mobile
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'teacher@classroom.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'teacher123',
  );
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(email, password);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException
              ? e.message
              : 'Login failed: Could not connect to server.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _fillQuickCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  void _showServerConfigDialog() {
    ServerConfigDialog.show(context);
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 18,
              child: Tooltip(
                message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                child: GestureDetector(
                  onTap: () {
                    try {
                      context.read<ThemeProvider>().toggleTheme(context);
                    } catch (_) {}
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: ClayStyles.raised(
                      color: palette.card,
                      radius: 12,
                      depth: 3,
                      isDark: isDark,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                      color: isDark ? ClayColors.warmAmber : ClayColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Logo & Branding
                    Container(
                      width: 80,
                      height: 80,
                      decoration: ClayStyles.raised(
                        color: palette.card,
                        radius: 28,
                        depth: 8,
                        isDark: isDark,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.remove_red_eye_rounded,
                          size: 40,
                          color: ClayColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CogniFocus-AI',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Classroom AI Monitoring & Focus Intelligence',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Clay Card
                    ClayCard(
                      radius: 24,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In to Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your institutional credentials below',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                      // Error message banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? ClayColors.darkClayCoral
                                : ClayColors.clayCoral,
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
                                            _errorMessage!.toLowerCase().contains('unable to reach') ||
                                            _errorMessage!.toLowerCase().contains('connect')
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
                                        fontSize: 12,
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
                              if (_errorMessage!.toLowerCase().contains('timed out') ||
                                  _errorMessage!.toLowerCase().contains('unable to reach') ||
                                  _errorMessage!.toLowerCase().contains('could not connect') ||
                                  _errorMessage!.toLowerCase().contains('connect')) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _isSubmitting ? null : _handleLogin,
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
                                            _handleLogin();
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
                                                'Configure Server',
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      ClayInput(
                        controller: _emailController,
                        label: 'Email Address',
                        hintText: 'teacher@classroom.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      ClayInput(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: ClayColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 22),

                      // Sign In Button
                      ClayButton(
                        text: 'Sign In',
                        icon: Icons.login_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 20),

                      // Quick Demo Login Pills
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.canvasDark.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Demo Accounts:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _fillQuickCredentials(
                                      'teacher@classroom.com',
                                      'teacher123',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      decoration: ClayStyles.raised(
                                        color: palette.card,
                                        radius: 10,
                                        depth: 2,
                                        isDark: isDark,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 14,
                                            color: palette.primaryBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Teacher Demo',
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
                                  child: GestureDetector(
                                    onTap: () => _fillQuickCredentials(
                                      'admin@classroom.com',
                                      'admin123',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      decoration: ClayStyles.raised(
                                        color: palette.card,
                                        radius: 10,
                                        depth: 2,
                                        isDark: isDark,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield_rounded,
                                            size: 14,
                                            color: palette.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Admin Demo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: palette.error,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Server Endpoint Configuration button
                GestureDetector(
                  onTap: _showServerConfigDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.card.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lan_rounded,
                          size: 14,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Server: ${authProvider.serverUrl}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: ClayColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
