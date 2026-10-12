import 'package:flutter/material.dart';
import 'clay_colors.dart';

/// Claymorphism Style Utilities & Box Decorations
///
/// Implements authentic raised and inset clay surfaces with double-shadow
/// layering for both Premium Light and Dark visual modes.
class ClayStyles {
  ClayStyles._();

  /// Default rounded border radii matching 18–24px cards and 14–18px buttons
  static const double cardRadius = 20.0;
  static const double defaultRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double pillRadius = 30.0;
  static const double inputRadius = 16.0;

  /// Raised Clay Box Decoration (Soft Dimensional 3D Tactile Look)
  static BoxDecoration raised({
    Color color = ClayColors.clayWhite,
    double radius = defaultRadius,
    BorderRadius? customBorderRadius,
    double depth = 5.0,
    Color? shadowColor,
    Color? highlightColor,
    Border? border,
    Gradient? gradient,
    bool isDark = false,
  }) {
    final effectiveRadius = customBorderRadius ?? BorderRadius.circular(radius);
    final darkShadow =
        shadowColor ?? (isDark ? ClayColors.darkShadowDark : ClayColors.shadowDark);
    final lightShadow = highlightColor ??
        (isDark ? ClayColors.darkShadowLight : ClayColors.shadowLight);

    final defaultBorder = border ??
        Border.all(
          color: isDark ? ClayColors.darkBorderHighlight : ClayColors.borderHighlight,
          width: isDark ? 1.0 : 1.2,
        );

    // Subtle gradient for dark mode elevated surfaces if no gradient is specified
    Gradient? effectiveGradient = gradient;
    if (isDark && gradient == null && (color == ClayColors.darkCard || color == ClayColors.darkCardElevated)) {
      effectiveGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF231C3D),
          Color(0xFF19142D),
        ],
      );
    }

    return BoxDecoration(
      color: effectiveGradient == null ? color : null,
      gradient: effectiveGradient,
      borderRadius: effectiveRadius,
      border: defaultBorder,
      boxShadow: [
        // Bottom-Right Dark Shadow (Diffuse outer shadow)
        BoxShadow(
          color: darkShadow,
          offset: Offset(depth * 0.9, depth * 0.9),
          blurRadius: depth * 2.2,
          spreadRadius: 0,
        ),
        // Top-Left Light Highlight (Emboss illumination)
        BoxShadow(
          color: lightShadow,
          offset: Offset(-depth * 0.7, -depth * 0.7),
          blurRadius: depth * 1.8,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Pressed / Sunken Clay Decoration (For active tab pills and pressed buttons)
  static BoxDecoration pressed({
    Color color = ClayColors.clayLavender,
    double radius = defaultRadius,
    BorderRadius? customBorderRadius,
    Border? border,
    bool isDark = false,
  }) {
    final effectiveRadius = customBorderRadius ?? BorderRadius.circular(radius);
    final defaultBorder = border ??
        Border.all(
          color: isDark ? ClayColors.darkBorderSubtle : ClayColors.borderSubtle,
          width: 1.0,
        );

    return BoxDecoration(
      color: color,
      borderRadius: effectiveRadius,
      border: defaultBorder,
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0x66000000)
              : ClayColors.shadowDark.withOpacity(0.09),
          offset: const Offset(1.5, 1.5),
          blurRadius: 3.5,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? const Color(0x0EFFFFFF) : Colors.white.withOpacity(0.7),
          offset: const Offset(-1.5, -1.5),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Inset Clay Decoration (For text inputs and well containers)
  static BoxDecoration inset({
    Color color = ClayColors.canvasDark,
    double radius = inputRadius,
    BorderRadius? customBorderRadius,
    bool isDark = false,
    bool isFocused = false,
    bool hasError = false,
  }) {
    final effectiveRadius = customBorderRadius ?? BorderRadius.circular(radius);

    Color borderColor;
    double borderWidth = 1.0;
    if (hasError) {
      borderColor = isDark ? ClayColors.darkError : ClayColors.error;
      borderWidth = 1.5;
    } else if (isFocused) {
      borderColor = isDark ? ClayColors.darkPrimaryBlue : ClayColors.primaryBlue;
      borderWidth = 1.5;
    } else {
      borderColor = isDark ? ClayColors.darkBorderSubtle : ClayColors.borderSubtle;
    }

    return BoxDecoration(
      color: color,
      borderRadius: effectiveRadius,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0x70000000)
              : ClayColors.shadowDark.withOpacity(0.07),
          offset: const Offset(2, 2),
          blurRadius: 5,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: isDark ? const Color(0x0CFFFFFF) : Colors.white.withOpacity(0.75),
          offset: const Offset(-1.5, -1.5),
          blurRadius: 3.5,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Subtle Clay Status Pill Decoration
  static BoxDecoration pill({
    required Color color,
    BorderRadius? borderRadius,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(pillRadius),
      border: Border.all(
        color: isDark ? const Color(0x22FFFFFF) : Colors.white.withOpacity(0.6),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? color.withOpacity(0.16) : color.withOpacity(0.22),
          offset: const Offset(1.5, 2.5),
          blurRadius: 5,
        ),
        BoxShadow(
          color: isDark ? const Color(0x0EFFFFFF) : Colors.white.withOpacity(0.7),
          offset: const Offset(-1, -1),
          blurRadius: 3,
        ),
      ],
    );
  }

  /// Soft Pastel Lavender (Light) / Midnight Navy (Dark) Canvas Background Gradient
  static LinearGradient canvasGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF130E26),
              Color(0xFF0F0C1E),
              Color(0xFF0A0716),
            ]
          : const [
              Color(0xFFF9F6FE),
              Color(0xFFF5F2FC),
              Color(0xFFEFEAF8),
            ],
    );
  }
}
