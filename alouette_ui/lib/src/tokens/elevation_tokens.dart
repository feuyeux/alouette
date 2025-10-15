import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// Design Tokens - Elevation & Shadows
///
/// Provides consistent elevation levels and shadow definitions
/// following Material Design 3 elevation guidelines.
class ElevationTokens {
  const ElevationTokens._();

  // ============================================================================
  // ELEVATION LEVELS
  // ============================================================================

  /// Level 0 - No elevation (flat surfaces)
  static const double level0 = 0.0;

  /// Level 1 - Subtle elevation (cards, buttons)
  static const double level1 = 1.0;

  /// Level 2 - Low elevation (app bars, tabs)
  static const double level2 = 3.0;

  /// Level 3 - Medium elevation (FAB, snackbars)
  static const double level3 = 6.0;

  /// Level 4 - High elevation (navigation drawer)
  static const double level4 = 8.0;

  /// Level 5 - Very high elevation (modal dialogs)
  static const double level5 = 12.0;

  // ============================================================================
  // SHADOW DEFINITIONS
  // ============================================================================

  /// No shadow
  static const List<BoxShadow> shadowNone = [];

  /// Subtle shadow (level 1)
  static final List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Low shadow (level 2)
  static final List<BoxShadow> shadowLow = [
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  /// Medium shadow (level 3)
  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  /// High shadow (level 4)
  static final List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 16),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  /// Very high shadow (level 5)
  static final List<BoxShadow> shadowVeryHigh = [
    BoxShadow(
      color: ColorTokens.shadowStrong,
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 24),
      blurRadius: 48,
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // SPECIALIZED SHADOWS
  // ============================================================================

  /// Inset shadow (for pressed states)
  static final List<BoxShadow> shadowInset = [
    BoxShadow(
      color: ColorTokens.shadow,
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
      blurStyle: BlurStyle.inner,
    ),
  ];

  /// Glow effect (for focus states)
  static final List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: ColorTokens.primary.withValues(alpha: 0.3),
      offset: const Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 2,
    ),
  ];

  /// Strong glow effect (for active states)
  static final List<BoxShadow> shadowGlowStrong = [
    BoxShadow(
      color: ColorTokens.primary.withValues(alpha: 0.5),
      offset: const Offset(0, 0),
      blurRadius: 12,
      spreadRadius: 4,
    ),
  ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get shadow for elevation level
  static List<BoxShadow> getShadowForLevel(double elevation) {
    if (elevation <= level0) return shadowNone;
    if (elevation <= level1) return shadowSubtle;
    if (elevation <= level2) return shadowLow;
    if (elevation <= level3) return shadowMedium;
    if (elevation <= level4) return shadowHigh;
    return shadowVeryHigh;
  }

  /// Create custom shadow with color
  static List<BoxShadow> createShadow({
    required Color color,
    required Offset offset,
    required double blurRadius,
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: offset,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// Create colored glow effect
  static List<BoxShadow> createGlow({
    required Color color,
    double opacity = 0.3,
    double blurRadius = 8,
    double spreadRadius = 2,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        offset: const Offset(0, 0),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}
