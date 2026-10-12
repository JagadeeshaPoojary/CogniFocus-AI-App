import 'package:flutter/material.dart';
import '../core/theme/clay_colors.dart';
import '../core/theme/clay_styles.dart';

/// Reusable Tactile Claymorphism Card Widget
///
/// Features rounded corners (18–24px), soft layered shadows, and automatic
/// theme-aware color mapping for Light and Dark modes.
class ClayCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double depth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? border;
  final Gradient? gradient;

  const ClayCard({
    super.key,
    required this.child,
    this.color = ClayColors.clayWhite,
    this.radius = ClayStyles.cardRadius,
    this.depth = 5.0,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.onTap,
    this.border,
    this.gradient,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _isPressed ? widget.depth * 0.35 : widget.depth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = ClayColors.of(context);

    Color effectiveColor = widget.color;
    if (isDark) {
      if (effectiveColor == ClayColors.clayWhite ||
          effectiveColor == ClayColors.card) {
        effectiveColor = palette.card;
      } else if (effectiveColor == ClayColors.surface) {
        effectiveColor = palette.surface;
      } else if (effectiveColor == ClayColors.cardElevated) {
        effectiveColor = palette.cardElevated;
      } else if (effectiveColor == ClayColors.clayLavender ||
          effectiveColor == ClayColors.clayLavenderDark) {
        effectiveColor = palette.clayLavender;
      } else if (effectiveColor == ClayColors.clayBlue) {
        effectiveColor = palette.clayBlue;
      } else if (effectiveColor == ClayColors.clayMint) {
        effectiveColor = palette.clayMint;
      } else if (effectiveColor == ClayColors.clayCoral) {
        effectiveColor = palette.clayCoral;
      } else if (effectiveColor == ClayColors.clayAmber) {
        effectiveColor = palette.clayAmber;
      } else if (effectiveColor == ClayColors.clayCyan) {
        effectiveColor = palette.clayCyan;
      }
    }

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      padding: widget.padding,
      decoration: _isPressed
          ? ClayStyles.pressed(
              color: effectiveColor,
              radius: widget.radius,
              isDark: isDark,
            )
          : ClayStyles.raised(
              color: effectiveColor,
              radius: widget.radius,
              depth: effectiveDepth,
              border: widget.border,
              gradient: widget.gradient,
              isDark: isDark,
            ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
