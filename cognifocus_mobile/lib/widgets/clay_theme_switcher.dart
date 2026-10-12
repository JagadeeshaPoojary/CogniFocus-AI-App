import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import '../providers/theme_provider.dart';

/// Premium 3-Option Claymorphism Theme Switcher
///
/// Supports Light, Dark, and System Default with smooth animated state transitions
/// and immediate centralized persistence.
class ClayThemeSwitcher extends StatelessWidget {
  final bool isCompact;
  final EdgeInsetsGeometry? padding;

  const ClayThemeSwitcher({
    super.key,
    this.isCompact = false,
    this.padding,
  });

  /// Show a quick Claymorphism modal bottom sheet to switch themes
  static Future<void> showModal(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? ClayColors.darkBorderHighlight : ClayColors.borderHighlight,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x99000000) : const Color(0x22283854),
              offset: const Offset(0, -6),
              blurRadius: 18,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Theme Preference',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose Light, Dark, or sync with System Default',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              const ClayThemeSwitcher(isCompact: false),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;
    final currentMode = themeProvider.themeMode;

    return Container(
      padding: padding ?? const EdgeInsets.all(4),
      decoration: ClayStyles.inset(
        color: palette.canvasDark,
        radius: 16,
        isDark: isDark,
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _buildSegment(
            context: context,
            title: 'Light',
            icon: Icons.wb_sunny_rounded,
            mode: ThemeMode.light,
            isSelected: currentMode == ThemeMode.light,
            palette: palette,
            isDark: isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context: context,
            title: 'Dark',
            icon: Icons.nightlight_round,
            mode: ThemeMode.dark,
            isSelected: currentMode == ThemeMode.dark,
            palette: palette,
            isDark: isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context: context,
            title: isCompact ? 'Auto' : 'System',
            icon: Icons.brightness_auto_rounded,
            mode: ThemeMode.system,
            isSelected: currentMode == ThemeMode.system,
            palette: palette,
            isDark: isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    required ClayThemePalette palette,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: 8,
      ),
      decoration: isSelected
          ? ClayStyles.raised(
              color: palette.card,
              radius: 12,
              depth: 3.5,
              border: Border.all(
                color: isDark
                    ? palette.primaryBlue.withOpacity(0.5)
                    : Colors.white,
                width: 1.2,
              ),
              isDark: isDark,
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? palette.primaryBlue : palette.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? palette.textPrimary : palette.textMuted,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (!isCompact) {
      content = Expanded(child: content);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
