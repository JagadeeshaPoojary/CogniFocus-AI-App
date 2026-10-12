import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import '../models/alert_model.dart';
import 'clay_button.dart';
import 'clay_status_badge.dart';

/// Claymorphism Evidence Modal Dialog Widget
class EvidenceModal extends StatelessWidget {
  final AlertModel alert;
  final String serverUrl;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onClose;

  const EvidenceModal({
    super.key,
    required this.alert,
    required this.serverUrl,
    this.onAcknowledge,
    this.onResolve,
    this.onClose,
  });

  static void show(
    BuildContext context, {
    required AlertModel alert,
    required String serverUrl,
    VoidCallback? onAcknowledge,
    VoidCallback? onResolve,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => EvidenceModal(
        alert: alert,
        serverUrl: serverUrl,
        onAcknowledge: onAcknowledge,
        onResolve: onResolve,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    final evidenceUrl = ApiConfig.getEvidenceUrl(
      baseUrl: serverUrl,
      relativePath: alert.evidenceImage,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: ClayStyles.raised(
          color: palette.card,
          radius: 24,
          depth: 10,
          isDark: isDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: palette.clayLavender,
                  border: Border(
                    bottom: BorderSide(
                      color: palette.borderSubtle,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 20,
                          color: palette.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alert Evidence #${alert.id}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: palette.textMuted,
                      ),
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Evidence Image Viewport
              Container(
                height: 220,
                color: const Color(0xFF0F172A),
                child: evidenceUrl.isNotEmpty
                    ? Image.network(
                        evidenceUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                palette.primaryBlue,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, stack) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.broken_image_rounded,
                                  size: 36,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Evidence frame not accessible\non disk (${alert.cameraId})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported_rounded,
                              size: 36,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'No evidence image saved for this alert',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Metadata Details
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClayStatusBadge.highSeverity(
                          alert.severity.toUpperCase(),
                        ),
                        Text(
                          alert.timestamp.replaceAll('T', ' ').split('.').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      alert.alertType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Details Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: ClayStyles.pressed(
                        color: palette.canvasDark,
                        radius: 14,
                        isDark: isDark,
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Student ID',
                            alert.studentId ?? 'STU-001',
                            palette,
                          ),
                          Divider(
                            height: 12,
                            color: isDark
                                ? ClayColors.darkBorderSubtle
                                : Colors.white,
                          ),
                          _buildDetailRow(
                            'Seat Location',
                            alert.seatId ?? 'B8',
                            palette,
                          ),
                          Divider(
                            height: 12,
                            color: isDark
                                ? ClayColors.darkBorderSubtle
                                : Colors.white,
                          ),
                          _buildDetailRow(
                            'Camera Source',
                            alert.cameraId,
                            palette,
                          ),
                          Divider(
                            height: 12,
                            color: isDark
                                ? ClayColors.darkBorderSubtle
                                : Colors.white,
                          ),
                          _buildDetailRow(
                            'Duration',
                            alert.duration,
                            palette,
                          ),
                          Divider(
                            height: 12,
                            color: isDark
                                ? ClayColors.darkBorderSubtle
                                : Colors.white,
                          ),
                          _buildDetailRow(
                            'AI Confidence',
                            '${(alert.confidence * 100).toStringAsFixed(1)}%',
                            palette,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Actions
                    Row(
                      children: [
                        if (alert.isActive) ...[
                          Expanded(
                            child: ClayButton(
                              text: 'Acknowledge',
                              icon: Icons.done,
                              color: palette.primaryBlue,
                              height: 44,
                              onPressed: () {
                                onAcknowledge?.call();
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (!alert.isResolved) ...[
                          Expanded(
                            child: ClayButton(
                              text: 'Resolve',
                              icon: Icons.task_alt,
                              color: palette.success,
                              height: 44,
                              onPressed: () {
                                onResolve?.call();
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ClayThemePalette palette,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
