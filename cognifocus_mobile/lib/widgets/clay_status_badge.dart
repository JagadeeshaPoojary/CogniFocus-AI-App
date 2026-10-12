import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';

/// Claymorphism Soft Status Pill Badge Widget
class ClayStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool showDot;
  final Color? dotColor;

  const ClayStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.showDot = false,
    this.dotColor,
  });

  /// Factory for LIVE camera status badge
  factory ClayStatusBadge.live() {
    return const ClayStatusBadge(
      label: 'LIVE',
      backgroundColor: ClayColors.clayMint,
      textColor: ClayColors.mintGreenDark,
      showDot: true,
      dotColor: ClayColors.mintGreen,
    );
  }

  /// Factory for OFFLINE camera status badge
  factory ClayStatusBadge.offline() {
    return const ClayStatusBadge(
      label: 'OFFLINE',
      backgroundColor: ClayColors.clayCoral,
      textColor: ClayColors.softCoralDark,
      showDot: true,
      dotColor: ClayColors.softCoral,
    );
  }

  /// Factory for ACTIVE status badge
  factory ClayStatusBadge.active() {
    return const ClayStatusBadge(
      label: 'ACTIVE',
      backgroundColor: ClayColors.clayMint,
      textColor: ClayColors.mintGreenDark,
      icon: Icons.check_circle_outline,
    );
  }

  /// Factory for ACKNOWLEDGED status badge
  factory ClayStatusBadge.acknowledged() {
    return const ClayStatusBadge(
      label: 'ACKNOWLEDGED',
      backgroundColor: ClayColors.clayBlue,
      textColor: ClayColors.primaryBlue,
      icon: Icons.done_all,
    );
  }

  /// Factory for RESOLVED status badge
  factory ClayStatusBadge.resolved() {
    return const ClayStatusBadge(
      label: 'RESOLVED',
      backgroundColor: ClayColors.clayMint,
      textColor: ClayColors.mintGreenDark,
      icon: Icons.task_alt,
    );
  }

  /// Factory for HIGH SEVERITY badge
  factory ClayStatusBadge.highSeverity([String text = 'HIGH']) {
    return ClayStatusBadge(
      label: text,
      backgroundColor: ClayColors.clayCoral,
      textColor: ClayColors.softCoralDark,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Factory for MEDIUM SEVERITY badge
  factory ClayStatusBadge.mediumSeverity([String text = 'MEDIUM']) {
    return ClayStatusBadge(
      label: text,
      backgroundColor: ClayColors.clayAmber,
      textColor: ClayColors.warmAmberDark,
      icon: Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    Color effectiveBg = backgroundColor;
    Color effectiveText = textColor;

    if (isDark) {
      if (backgroundColor == ClayColors.clayMint) {
        effectiveBg = palette.clayMint;
      } else if (backgroundColor == ClayColors.clayBlue) {
        effectiveBg = palette.clayBlue;
      } else if (backgroundColor == ClayColors.clayCoral) {
        effectiveBg = palette.clayCoral;
      } else if (backgroundColor == ClayColors.clayAmber) {
        effectiveBg = palette.clayAmber;
      } else if (backgroundColor == ClayColors.canvasDark) {
        effectiveBg = palette.canvasDark;
      }

      if (textColor == ClayColors.mintGreenDark || textColor == ClayColors.mintGreen) {
        effectiveText = palette.success;
      } else if (textColor == ClayColors.primaryBlue || textColor == ClayColors.primaryBlueLight) {
        effectiveText = palette.primaryBlue;
      } else if (textColor == ClayColors.softCoralDark || textColor == ClayColors.softCoral) {
        effectiveText = palette.error;
      } else if (textColor == ClayColors.warmAmberDark || textColor == ClayColors.warmAmber) {
        effectiveText = palette.warning;
      } else if (textColor == ClayColors.textMuted) {
        effectiveText = palette.textMuted;
      }
    }

    Color effectiveDotColor = dotColor ?? effectiveText;
    if (isDark && dotColor != null) {
      if (dotColor == ClayColors.mintGreen) {
        effectiveDotColor = palette.success;
      } else if (dotColor == ClayColors.primaryBlue) {
        effectiveDotColor = palette.primaryBlue;
      } else if (dotColor == ClayColors.softCoral) {
        effectiveDotColor = palette.error;
      } else if (dotColor == ClayColors.warmAmber) {
        effectiveDotColor = palette.warning;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ClayStyles.pill(color: effectiveBg, isDark: isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: effectiveDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveText),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: effectiveText,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
