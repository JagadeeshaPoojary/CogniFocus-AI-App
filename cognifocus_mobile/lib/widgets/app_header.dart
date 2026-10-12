import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';
import '../providers/theme_provider.dart';
import 'clay_theme_switcher.dart';

/// Top App Header with Claymorphism Styling
class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final Widget? trailing;
  final bool showThemeToggle;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.trailing,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    Widget? themeToggleWidget;
    if (showThemeToggle) {
      themeToggleWidget = Tooltip(
        message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        child: GestureDetector(
          onTap: () {
            try {
              context.read<ThemeProvider>().toggleTheme(context);
            } catch (_) {}
          },
          onLongPress: () => ClayThemeSwitcher.showModal(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: ClayStyles.raised(
              color: palette.card,
              radius: 12,
              depth: 4,
              isDark: isDark,
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? ClayColors.warmAmber : ClayColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    Widget? refreshWidget;
    if (onRefresh != null) {
      refreshWidget = Tooltip(
        message: 'Refresh',
        child: GestureDetector(
          onTap: onRefresh,
          child: Container(
            width: 38,
            height: 38,
            decoration: ClayStyles.raised(
              color: palette.card,
              radius: 12,
              depth: 4,
              isDark: isDark,
            ),
            child: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: palette.primaryBlue,
            ),
          ),
        ),
      );
    }

    final List<Widget> actionWidgets = [];
    if (refreshWidget != null) {
      actionWidgets.add(refreshWidget);
    }
    if (themeToggleWidget != null) {
      if (actionWidgets.isNotEmpty) {
        actionWidgets.add(const SizedBox(width: 8));
      }
      actionWidgets.add(themeToggleWidget);
    }
    if (trailing != null) {
      if (actionWidgets.isNotEmpty) {
        actionWidgets.add(const SizedBox(width: 8));
      }
      actionWidgets.add(trailing!);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(
          bottom: BorderSide(
            color: palette.borderSubtle.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionWidgets.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actionWidgets,
              ),
          ],
        ),
      ),
    );
  }
}
