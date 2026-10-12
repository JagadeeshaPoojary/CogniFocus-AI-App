import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';

/// Reusable 3D Tactile Claymorphism Button Widget
class ClayButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double radius;
  final double depth;

  const ClayButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.color = ClayColors.primaryBlue,
    this.textColor = Colors.white,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50.0,
    this.radius = ClayStyles.buttonRadius,
    this.depth = 4.5,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ClayColors.of(context);
    final isDark = palette.isDark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color buttonBaseColor = widget.color;
    if (widget.color == ClayColors.primaryBlue) {
      buttonBaseColor = palette.primaryBlue;
    } else if (widget.color == ClayColors.softCoral || widget.color == ClayColors.error) {
      buttonBaseColor = palette.error;
    } else if (widget.color == ClayColors.mintGreen || widget.color == ClayColors.success) {
      buttonBaseColor = palette.success;
    }

    final effectiveColor = isEnabled
        ? buttonBaseColor
        : buttonBaseColor.withOpacity(0.5);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _isPressed
          ? ClayStyles.pressed(
              color: effectiveColor,
              radius: widget.radius,
              isDark: isDark,
            )
          : ClayStyles.raised(
              color: effectiveColor,
              radius: widget.radius,
              depth: widget.depth,
              shadowColor: buttonBaseColor.withOpacity(isDark ? 0.45 : 0.32),
              isDark: isDark,
            ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: widget.textColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (widget.isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    if (!isEnabled) {
      return content;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: content,
    );
  }
}
