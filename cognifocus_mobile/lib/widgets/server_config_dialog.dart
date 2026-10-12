import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/theme/clay_colors.dart';
import '../providers/auth_provider.dart';
import 'clay_button.dart';
import 'clay_card.dart';
import 'clay_input.dart';

/// ServerConfigDialog: Modal dialog to inspect, test, and update backend base URL
class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSaved,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  String? _testResult;
  bool _isSuccess = false;
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _controller = TextEditingController(text: authProvider.serverUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _testResult = 'Please enter a server URL to test.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final client = ApiClient(baseUrl: text);
      final res = await client.testConnection();
      if (!mounted) return;

      setState(() {
        _isTesting = false;
        if (res['success'] == true) {
          _isSuccess = true;
          if (res['detected_url'] != null &&
              res['detected_url'] != _controller.text) {
            _controller.text = res['detected_url'] as String;
          }
          _testResult = 'Success: ${res['message']}';
        } else {
          _isSuccess = false;
          _testResult = 'Connection Failed: ${res['message']}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _isSuccess = false;
        _testResult = 'Test error: $e';
      });
    }
  }

  Future<void> _handleSave() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server URL.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final normalized = ApiConfig.normalizeUrl(raw);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateServerUrl(normalized);
      if (!mounted) return;

      widget.onSaved?.call();

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server endpoint updated to: $normalized'),
          backgroundColor: ClayColors.mintGreenDark,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _applyPreset(String url) {
    setState(() {
      _controller.text = url;
      _testResult = null;
    });
  }

  void _toggleProtocol() {
    var text = _controller.text.trim();
    if (text.startsWith('https://')) {
      text = text.replaceFirst('https://', 'http://');
    } else if (text.startsWith('http://')) {
      text = text.replaceFirst('http://', 'https://');
    } else {
      text = 'https://$text';
    }
    setState(() {
      _controller.text = text;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClayCard(
        radius: 24,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ClayColors.darkClayBlue
                          : ClayColors.clayBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_ethernet_rounded,
                      size: 22,
                      color: ClayColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          'Configure Flask server connection',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Informational explanation
              Text(
                'Enter the IP address of your computer running the Flask backend. Phone and laptop must be on the same Wi-Fi.',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Input field
              ClayInput(
                controller: _controller,
                label: 'Backend Base URL',
                hintText: 'http://${ApiConfig.laptopLanIp}:5000',
                prefixIcon: Icons.dns_rounded,
              ),
              const SizedBox(height: 10),

              // Presets wrap
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
                    onPressed: () =>
                        _applyPreset('http://${ApiConfig.laptopLanIp}:5000'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.usb_rounded, size: 14),
                    label: const Text(
                      'USB Reverse (127.0.0.1)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () =>
                        _applyPreset('http://127.0.0.1:5000'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.devices_rounded, size: 14),
                    label: const Text(
                      'Emulator (10.0.2.2)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () =>
                        _applyPreset('http://10.0.2.2:5000'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: Text(
                      _controller.text.startsWith('http://')
                          ? 'Switch to HTTPS'
                          : 'Switch to HTTP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _toggleProtocol,
                  ),
                ],
              ),

              // Diagnostics / Test result display
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? (isDark
                            ? ClayColors.darkClayMint
                            : ClayColors.clayMint)
                        : (isDark
                            ? ClayColors.darkClayCoral
                            : ClayColors.clayCoral),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSuccess
                          ? ClayColors.mintGreen.withOpacity(0.4)
                          : ClayColors.softCoral.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 16,
                        color: _isSuccess
                            ? ClayColors.mintGreenDark
                            : palette.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isSuccess
                                ? ClayColors.mintGreenDark
                                : palette.error,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _isTesting ? null : _handleTestConnection,
                      child: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Test Ping',
                              style: TextStyle(
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
                      height: 44,
                      isLoading: _isSaving,
                      onPressed: _handleSave,
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
}
