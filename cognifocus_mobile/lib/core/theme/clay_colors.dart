import 'package:flutter/material.dart';

/// Complete Claymorphism Theme Palette for CogniFocus-AI Mobile
///
/// Encapsulates theme-aware surface, text, accent, and semantic status colors
/// for both Premium Light and Dark modes.
class ClayThemePalette {
  final bool isDark;
  final Color canvas;
  final Color canvasDark;
  final Color surface;
  final Color card;
  final Color cardElevated;
  final Color clayLavender;
  final Color clayBlue;
  final Color clayMint;
  final Color clayCoral;
  final Color clayAmber;
  final Color clayCyan;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textLight;
  final Color shadowDark;
  final Color shadowLight;
  final Color borderSubtle;
  final Color borderHighlight;
  final Color primaryBlue;
  final Color secondaryLavender;
  final Color accentCyan;
  final Color mintGreen; // Success alias
  final Color softCoral; // Error alias
  final Color warmAmber; // Warning alias
  final Color success;
  final Color warning;
  final Color error;

  const ClayThemePalette({
    required this.isDark,
    required this.canvas,
    required this.canvasDark,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.clayLavender,
    required this.clayBlue,
    required this.clayMint,
    required this.clayCoral,
    required this.clayAmber,
    required this.clayCyan,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textLight,
    required this.shadowDark,
    required this.shadowLight,
    required this.borderSubtle,
    required this.borderHighlight,
    required this.primaryBlue,
    required this.secondaryLavender,
    required this.accentCyan,
    required this.mintGreen,
    required this.softCoral,
    required this.warmAmber,
    required this.success,
    required this.warning,
    required this.error,
  });
}

/// Claymorphism Color Palette for CogniFocus-AI Mobile
class ClayColors {
  ClayColors._();

  // ==========================================
  // Pastel-Purple Claymorphism Light Palette
  // ==========================================
  static const Color canvas = Color(0xFFF5F2FC); // Soft lavender app background
  static const Color canvasDark = Color(0xFFEBE5F7); // Inset lavender surface
  static const Color surface = Color(0xFFFAF8FE); // Primary pale lavender-white surface
  static const Color clayWhite = Color(0xFFFFFFFF); // Crisp white raised cards
  static const Color card = Color(0xFFFFFFFF); // Raised white cards
  static const Color cardElevated = Color(0xFFFFFFFF); // Elevated surface

  // Brand Accents
  static const Color primaryBlue = Color(0xFF7C3AED); // Vibrant purple accent
  static const Color primaryPurple = Color(0xFF7C3AED); // Signature purple
  static const Color primaryBlueLight = Color(0xFF8B5CF6);
  static const Color secondaryLavender = Color(0xFF8B5CF6); // Secondary lavender
  static const Color primaryIndigo = Color(0xFF7C3AED); // Alias for compatibility
  static const Color accentCyan = Color(0xFF06B6D4); // Accent cyan

  // Typography (Deep Indigo)
  static const Color textPrimary = Color(0xFF1E1742); // Deep indigo main text
  static const Color textSecondary = Color(0xFF665C84); // Indigo-slate secondary text
  static const Color textMuted = Color(0xFF8E84AA); // Muted captions
  static const Color textLight = Color(0xFFB5ACCF); // Subdued hints

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald-green
  static const Color mintGreen = Color(0xFF10B981); // Emerald-green Start Monitoring
  static const Color mintGreenDark = Color(0xFF059669);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldGreenDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B); // Warm amber
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color warmAmberDark = Color(0xFFD97706);

  static const Color error = Color(0xFFF43F5E); // Clear red/pink alert & offline
  static const Color softCoral = Color(0xFFF43F5E); // Clear red/pink
  static const Color softCoralDark = Color(0xFFE11D48);

  // Soft Tinted Clay Surfaces
  static const Color clayLavender = Color(0xFFF2EDFD); // Pale lavender squircle
  static const Color clayLavenderDark = Color(0xFFE6DEFA);
  static const Color clayBlue = Color(0xFFECE7FD); // Pale purple-blue
  static const Color clayMint = Color(0xFFE6F7F0); // Pale emerald mint
  static const Color clayCoral = Color(0xFFFEE8EA); // Pale rose-coral
  static const Color clayAmber = Color(0xFFFEF3D8); // Pale warm amber
  static const Color clayCyan = Color(0xFFE6F6FC); // Pale cyan

  // Light Clay Shadows (Layered for 3D raised tactile depth with soft purple diffuse tone)
  static const Color shadowDark = Color(0x1A4F3E76); // Soft purple-tinted ambient shadow
  static const Color shadowLight = Color(0xF0FFFFFF); // Top-left soft white highlight
  static const Color shadowPressed = Color(0x12403264);

  // Inset / Border Reflective highlights
  static const Color borderHighlight = Color(0xF0FFFFFF);
  static const Color borderSubtle = Color(0x288B5CF6); // Subtle lavender-purple border

  // ==========================================
  // Midnight-Navy & Muted Purple Dark Palette
  // ==========================================
  static const Color darkCanvas = Color(0xFF0F0C1E); // Midnight navy-purple background
  static const Color darkCanvasDark = Color(0xFF090715); // Deep inset surface
  static const Color darkSurface = Color(0xFF171329); // Primary dark surface
  static const Color darkCard = Color(0xFF1D1833); // Raised muted purple card
  static const Color darkCardElevated = Color(0xFF251F3F); // Elevated purple surface

  // Dark Brand Accents
  static const Color darkPrimaryBlue = Color(0xFFA78BFA); // Soft lavender purple
  static const Color darkSecondaryLavender = Color(0xFFC4B5FD);
  static const Color darkAccentCyan = Color(0xFF38BDF8);

  // Dark Typography
  static const Color darkTextPrimary = Color(0xFFF5F3FF); // Soft lavender white
  static const Color darkTextSecondary = Color(0xFFB3A7D6); // Secondary violet-slate
  static const Color darkTextMuted = Color(0xFF8D82B2);
  static const Color darkTextLight = Color(0xFF6D6491);

  // Dark Semantic Status Colors
  static const Color darkSuccess = Color(0xFF34D399); // Emerald green
  static const Color darkWarning = Color(0xFFFBBF24); // Warm amber
  static const Color darkError = Color(0xFFFB7185); // Clear red/pink

  // Dark Tinted Pastel Clay Surfaces
  static const Color darkClayLavender = Color(0xFF261D42);
  static const Color darkClayBlue = Color(0xFF221C3E);
  static const Color darkClayMint = Color(0xFF113025);
  static const Color darkClayCoral = Color(0xFF361521);
  static const Color darkClayAmber = Color(0xFF352614);
  static const Color darkClayCyan = Color(0xFF132A3B);

  // Dark Clay Shadows & Highlights
  static const Color darkShadowDark = Color(0x80000000); // Ambient deep shadow
  static const Color darkShadowLight = Color(0x18B8A6FF); // Lavender edge illumination
  static const Color darkBorderSubtle = Color(0x28A78BFA); // Subtle purple border
  static const Color darkBorderHighlight = Color(0x1FA78BFA);

  static const ClayThemePalette _lightPalette = ClayThemePalette(
    isDark: false,
    canvas: canvas,
    canvasDark: canvasDark,
    surface: surface,
    card: clayWhite,
    cardElevated: cardElevated,
    clayLavender: clayLavender,
    clayBlue: clayBlue,
    clayMint: clayMint,
    clayCoral: clayCoral,
    clayAmber: clayAmber,
    clayCyan: clayCyan,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textMuted: textMuted,
    textLight: textLight,
    shadowDark: shadowDark,
    shadowLight: shadowLight,
    borderSubtle: borderSubtle,
    borderHighlight: borderHighlight,
    primaryBlue: primaryBlue,
    secondaryLavender: secondaryLavender,
    accentCyan: accentCyan,
    mintGreen: mintGreen,
    softCoral: softCoral,
    warmAmber: warmAmber,
    success: success,
    warning: warning,
    error: error,
  );

  static const ClayThemePalette _darkPalette = ClayThemePalette(
    isDark: true,
    canvas: darkCanvas,
    canvasDark: darkCanvasDark,
    surface: darkSurface,
    card: darkCard,
    cardElevated: darkCardElevated,
    clayLavender: darkClayLavender,
    clayBlue: darkClayBlue,
    clayMint: darkClayMint,
    clayCoral: darkClayCoral,
    clayAmber: darkClayAmber,
    clayCyan: darkClayCyan,
    textPrimary: darkTextPrimary,
    textSecondary: darkTextSecondary,
    textMuted: darkTextMuted,
    textLight: darkTextLight,
    shadowDark: darkShadowDark,
    shadowLight: darkShadowLight,
    borderSubtle: darkBorderSubtle,
    borderHighlight: darkBorderHighlight,
    primaryBlue: darkPrimaryBlue,
    secondaryLavender: darkSecondaryLavender,
    accentCyan: darkAccentCyan,
    mintGreen: darkSuccess,
    softCoral: darkError,
    warmAmber: darkWarning,
    success: darkSuccess,
    warning: darkWarning,
    error: darkError,
  );

  /// Access dynamic color palette based on current active theme
  static ClayThemePalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkPalette : _lightPalette;
  }

  /// Theme-aware canvas background color
  static Color canvasColor(BuildContext context) => of(context).canvas;

  /// Theme-aware card surface color
  static Color cardColor(BuildContext context) => of(context).card;

  /// Theme-aware primary text color
  static Color textColor(BuildContext context) => of(context).textPrimary;

  /// Theme-aware muted text color
  static Color textMutedColor(BuildContext context) => of(context).textMuted;

  /// Check if the current context brightness is dark
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
