import 'package:flutter/material.dart';
import 'clay_colors.dart';

/// AppTheme for CogniFocus-AI Mobile
///
/// Sets up Material 3 Light and Dark theme configurations matching the
/// authentic Claymorphism design system.
class AppTheme {
  AppTheme._();

  /// Premium Light Theme Configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: ClayColors.primaryBlue,
      secondary: ClayColors.secondaryLavender,
      tertiary: ClayColors.accentCyan,
      surface: ClayColors.clayWhite,
      surfaceContainerHighest: ClayColors.canvasDark,
      error: ClayColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ClayColors.textPrimary,
      onError: Colors.white,
      outline: ClayColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ClayColors.primaryBlue,
      scaffoldBackgroundColor: ClayColors.canvas,
      cardColor: ClayColors.clayWhite,
      canvasColor: ClayColors.canvas,
      dialogBackgroundColor: ClayColors.surface,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ClayColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: ClayColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ClayColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ClayColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ClayColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ClayColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: ClayColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: ClayColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ClayColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ClayColors.textPrimary),
        titleTextStyle: TextStyle(
          color: ClayColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: ClayColors.clayWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: ClayColors.borderSubtle,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ClayColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
          color: ClayColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: ClayColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Premium Dark Theme Configuration (Midnight-blue and Indigo Palette)
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: ClayColors.darkPrimaryBlue,
      secondary: ClayColors.darkSecondaryLavender,
      tertiary: ClayColors.darkAccentCyan,
      surface: ClayColors.darkCard,
      surfaceContainerHighest: ClayColors.darkCanvasDark,
      error: ClayColors.darkError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ClayColors.darkTextPrimary,
      onError: Colors.white,
      outline: ClayColors.darkBorderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: ClayColors.darkPrimaryBlue,
      scaffoldBackgroundColor: ClayColors.darkCanvas,
      cardColor: ClayColors.darkCard,
      canvasColor: ClayColors.darkCanvas,
      dialogBackgroundColor: ClayColors.darkCardElevated,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ClayColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: ClayColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ClayColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ClayColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ClayColors.darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ClayColors.darkTextSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: ClayColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: ClayColors.darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ClayColors.darkTextMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ClayColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: ClayColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: ClayColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: ClayColors.darkBorderSubtle,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ClayColors.darkCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
          color: ClayColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: ClayColors.darkTextSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
