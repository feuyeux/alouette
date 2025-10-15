import 'package:flutter/material.dart';

/// Design Tokens - Colors
///
/// Provides semantic color definitions based on a systematic color palette.
/// Uses HSL-based color generation for consistent and accessible colors.
class ColorTokens {
  const ColorTokens._();

  // ============================================================================
  // BASE PALETTE
  // ============================================================================

  /// Primary brand colors (Blue family)
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6); // Primary
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  /// Secondary colors (Green family)
  static const Color green50 = Color(0xFFECFDF5);
  static const Color green100 = Color(0xFFD1FAE5);
  static const Color green200 = Color(0xFFA7F3D0);
  static const Color green300 = Color(0xFF6EE7B7);
  static const Color green400 = Color(0xFF34D399);
  static const Color green500 = Color(0xFF10B981); // Secondary
  static const Color green600 = Color(0xFF059669);
  static const Color green700 = Color(0xFF047857);
  static const Color green800 = Color(0xFF065F46);
  static const Color green900 = Color(0xFF064E3B);

  /// Accent colors (Amber family)
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B); // Accent
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  /// Neutral colors (Gray family)
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  /// Error colors (Red family)
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);

  /// Warning colors (Yellow family)
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow200 = Color(0xFFFEF08A);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308);
  static const Color yellow600 = Color(0xFFCA8A04);
  static const Color yellow700 = Color(0xFFA16207);
  static const Color yellow800 = Color(0xFF854D0E);
  static const Color yellow900 = Color(0xFF713F12);

  // ============================================================================
  // SEMANTIC COLORS - LIGHT THEME
  // ============================================================================

  /// Primary semantic colors
  static const Color primary = blue500;
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = blue100;
  static const Color onPrimaryContainer = blue900;

  /// Secondary semantic colors
  static const Color secondary = green500;
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = green100;
  static const Color onSecondaryContainer = green900;

  /// Tertiary semantic colors
  static const Color tertiary = amber500;
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = amber100;
  static const Color onTertiaryContainer = amber900;

  /// Error semantic colors
  static const Color error = red500;
  static const Color onError = Colors.white;
  static const Color errorContainer = red100;
  static const Color onErrorContainer = red900;

  /// Surface semantic colors
  static const Color surface = Colors.white;
  static const Color onSurface = gray900;
  static const Color surfaceVariant = gray50;
  static const Color onSurfaceVariant = gray700;

  /// Background semantic colors
  static const Color background = gray50;
  static const Color onBackground = gray900;

  /// Outline colors
  static const Color outline = gray300;
  static const Color outlineVariant = gray200;

  // ============================================================================
  // SEMANTIC COLORS - DARK THEME
  // ============================================================================

  /// Dark theme primary colors
  static const Color darkPrimary = blue400;
  static const Color darkOnPrimary = blue900;
  static const Color darkPrimaryContainer = blue800;
  static const Color darkOnPrimaryContainer = blue100;

  /// Dark theme secondary colors
  static const Color darkSecondary = green400;
  static const Color darkOnSecondary = green900;
  static const Color darkSecondaryContainer = green800;
  static const Color darkOnSecondaryContainer = green100;

  /// Dark theme tertiary colors
  static const Color darkTertiary = amber400;
  static const Color darkOnTertiary = amber900;
  static const Color darkTertiaryContainer = amber800;
  static const Color darkOnTertiaryContainer = amber100;

  /// Dark theme error colors
  static const Color darkError = red400;
  static const Color darkOnError = red900;
  static const Color darkErrorContainer = red800;
  static const Color darkOnErrorContainer = red100;

  /// Dark theme surface colors
  static const Color darkSurface = gray900;
  static const Color darkOnSurface = gray100;
  static const Color darkSurfaceVariant = gray800;
  static const Color darkOnSurfaceVariant = gray300;

  /// Dark theme background colors
  static const Color darkBackground = Colors.black;
  static const Color darkOnBackground = gray100;

  /// Dark theme outline colors
  static const Color darkOutline = gray600;
  static const Color darkOutlineVariant = gray700;

  // ============================================================================
  // FUNCTIONAL COLORS
  // ============================================================================

  /// Success colors
  static const Color success = green500;
  static const Color successContainer = green100;
  static const Color onSuccess = Colors.white;
  static const Color onSuccessContainer = green900;

  /// Warning colors
  static const Color warning = yellow500;
  static const Color warningContainer = yellow100;
  static const Color onWarning = Colors.white;
  static const Color onWarningContainer = yellow900;

  /// Info colors
  static const Color info = blue500;
  static const Color infoContainer = blue100;
  static const Color onInfo = Colors.white;
  static const Color onInfoContainer = blue900;

  // ============================================================================
  // OPACITY VARIANTS
  // ============================================================================

  /// Semi-transparent overlay colors
  static Color get scrim => Colors.black.withValues(alpha: 0.6);
  static Color get backdrop => Colors.black.withValues(alpha: 0.4);
  static Color get shadow => Colors.black.withValues(alpha: 0.1);
  static Color get shadowStrong => Colors.black.withValues(alpha: 0.25);

  /// Hover and focus states
  static Color get primaryHover => primary.withValues(alpha: 0.08);
  static Color get primaryFocus => primary.withValues(alpha: 0.12);
  static Color get primaryPressed => primary.withValues(alpha: 0.16);

  static Color get surfaceHover => onSurface.withValues(alpha: 0.04);
  static Color get surfaceFocus => onSurface.withValues(alpha: 0.08);
  static Color get surfacePressed => onSurface.withValues(alpha: 0.12);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get appropriate text color for a given background
  static Color getOnColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? gray900 : Colors.white;
  }

  /// Create a disabled version of a color
  static Color disabled(Color color) => color.withValues(alpha: 0.38);

  /// Create a muted version of a color
  static Color muted(Color color) => color.withValues(alpha: 0.6);
}
