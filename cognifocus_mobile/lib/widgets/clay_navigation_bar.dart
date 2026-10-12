import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';

class ClayNavTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;

  const ClayNavTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
  });
}

/// Tactile Claymorphism Bottom Navigation Bar
class ClayNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClayNavTabItem> items;

  const ClayNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;

    return Container(
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(
          top: BorderSide(
            color: palette.borderSubtle,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadowDark.withOpacity(isDark ? 0.35 : 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 8,
                  vertical: 6,
                ),
                decoration: isSelected
                    ? ClayStyles.raised(
                        color: palette.card,
                        radius: 20,
                        depth: 4,
                        border: Border.all(
                          color: isDark
                              ? ClayColors.darkBorderHighlight
                              : ClayColors.borderHighlight,
                          width: 1.2,
                        ),
                        isDark: isDark,
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    item.badgeCount > 0
                        ? Badge(
                            label: Text(
                              item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: palette.warmAmber,
                            textColor: Colors.white,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 20,
                              color: isSelected
                                  ? palette.primaryBlue
                                  : palette.textMuted,
                            ),
                          )
                        : Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 20,
                            color: isSelected
                                ? palette.primaryBlue
                                : palette.textMuted,
                          ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? palette.primaryBlue
                            : palette.textMuted,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
