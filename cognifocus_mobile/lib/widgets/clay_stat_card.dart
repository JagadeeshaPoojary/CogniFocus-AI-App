import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';

/// Claymorphism Stat Metric Card Widget
class ClayStatCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? surfaceColor;
  final VoidCallback? onTap;

  const ClayStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.surfaceColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    Color effectiveSurface = surfaceColor ?? palette.card;
    if (isDark && surfaceColor != null) {
      if (surfaceColor == ClayColors.clayWhite) {
        effectiveSurface = palette.card;
      } else if (surfaceColor == ClayColors.clayLavender ||
          surfaceColor == ClayColors.clayLavenderDark) {
        effectiveSurface = palette.clayLavender;
      } else if (surfaceColor == ClayColors.clayBlue) {
        effectiveSurface = palette.clayBlue;
      } else if (surfaceColor == ClayColors.clayMint) {
        effectiveSurface = palette.clayMint;
      } else if (surfaceColor == ClayColors.clayCoral) {
        effectiveSurface = palette.clayCoral;
      } else if (surfaceColor == ClayColors.clayAmber) {
        effectiveSurface = palette.clayAmber;
      }
    }

    Color effectiveIconColor = iconColor;
    if (isDark) {
      if (iconColor == ClayColors.primaryBlue) {
        effectiveIconColor = palette.primaryBlue;
      } else if (iconColor == ClayColors.mintGreen || iconColor == ClayColors.success) {
        effectiveIconColor = palette.success;
      } else if (iconColor == ClayColors.softCoral || iconColor == ClayColors.error) {
        effectiveIconColor = palette.error;
      } else if (iconColor == ClayColors.warmAmber || iconColor == ClayColors.warning) {
        effectiveIconColor = palette.warning;
      } else if (iconColor == ClayColors.accentCyan) {
        effectiveIconColor = palette.accentCyan;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: ClayStyles.raised(
          color: effectiveSurface,
          radius: 18,
          depth: 5,
          isDark: isDark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isDark
                          ? ClayColors.darkBorderHighlight
                          : Colors.white,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(icon, size: 18, color: effectiveIconColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: palette.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
