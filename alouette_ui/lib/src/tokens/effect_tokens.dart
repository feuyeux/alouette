import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'dimension_tokens.dart';

/// Design Tokens - Visual Effects
///
/// Provides consistent visual effects like gradients, borders,
/// overlays, and other decorative elements.
class EffectTokens {
  const EffectTokens._();

  // ============================================================================
  // GRADIENTS
  // ============================================================================

  /// Primary gradient (light to dark primary)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.blue400, ColorTokens.blue600],
  );

  /// Secondary gradient (light to dark secondary)
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.green400, ColorTokens.green600],
  );

  /// Accent gradient (warm colors)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.amber400, ColorTokens.amber600],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.green400, ColorTokens.green600],
  );

  /// Warning gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.yellow400, ColorTokens.yellow600],
  );

  /// Error gradient
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorTokens.red400, ColorTokens.red600],
  );

  /// Neutral gradient (for backgrounds)
  static const LinearGradient neutralGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColorTokens.gray50, ColorTokens.gray100],
  );

  /// Dark gradient (for dark theme backgrounds)
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ColorTokens.gray900, ColorTokens.gray800],
  );

  /// Shimmer gradient (for loading states)
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
    stops: [0.0, 0.5, 1.0],
  );

  // ============================================================================
  // BORDERS
  // ============================================================================

  /// Default border
  static const BorderSide borderDefault = BorderSide(
    color: ColorTokens.outline,
    width: 1.0,
  );

  /// Thick border
  static const BorderSide borderThick = BorderSide(
    color: ColorTokens.outline,
    width: 2.0,
  );

  /// Primary border
  static const BorderSide borderPrimary = BorderSide(
    color: ColorTokens.primary,
    width: 1.0,
  );

  /// Primary thick border
  static const BorderSide borderPrimaryThick = BorderSide(
    color: ColorTokens.primary,
    width: 2.0,
  );

  /// Error border
  static const BorderSide borderError = BorderSide(
    color: ColorTokens.error,
    width: 1.0,
  );

  /// Success border
  static const BorderSide borderSuccess = BorderSide(
    color: ColorTokens.success,
    width: 1.0,
  );

  /// Warning border
  static const BorderSide borderWarning = BorderSide(
    color: ColorTokens.warning,
    width: 1.0,
  );

  /// Transparent border (for consistent sizing)
  static const BorderSide borderTransparent = BorderSide(
    color: Colors.transparent,
    width: 1.0,
  );

  // ============================================================================
  // BORDER RADIUS COMBINATIONS
  // ============================================================================

  /// Small rounded corners
  static const BorderRadius radiusSmall = BorderRadius.all(
    Radius.circular(DimensionTokens.radiusS),
  );

  /// Medium rounded corners
  static const BorderRadius radiusMedium = BorderRadius.all(
    Radius.circular(DimensionTokens.radiusM),
  );

  /// Large rounded corners
  static const BorderRadius radiusLarge = BorderRadius.all(
    Radius.circular(DimensionTokens.radiusL),
  );

  /// Extra large rounded corners
  static const BorderRadius radiusExtraLarge = BorderRadius.all(
    Radius.circular(DimensionTokens.radiusXl),
  );

  /// Pill shape (fully rounded)
  static const BorderRadius radiusPill = BorderRadius.all(
    Radius.circular(DimensionTokens.radiusFull),
  );

  /// Top rounded corners only
  static const BorderRadius radiusTopOnly = BorderRadius.only(
    topLeft: Radius.circular(DimensionTokens.radiusL),
    topRight: Radius.circular(DimensionTokens.radiusL),
  );

  /// Bottom rounded corners only
  static const BorderRadius radiusBottomOnly = BorderRadius.only(
    bottomLeft: Radius.circular(DimensionTokens.radiusL),
    bottomRight: Radius.circular(DimensionTokens.radiusL),
  );

  // ============================================================================
  // OVERLAYS
  // ============================================================================

  /// Light overlay (for modals)
  static Color get overlayLight => Colors.black.withValues(alpha: 0.3);

  /// Medium overlay
  static Color get overlayMedium => Colors.black.withValues(alpha: 0.5);

  /// Dark overlay
  static Color get overlayDark => Colors.black.withValues(alpha: 0.7);

  /// Scrim overlay (for navigation)
  static Color get overlayScrim => Colors.black.withValues(alpha: 0.6);

  /// Success overlay
  static Color get overlaySuccess => ColorTokens.success.withValues(alpha: 0.1);

  /// Warning overlay
  static Color get overlayWarning => ColorTokens.warning.withValues(alpha: 0.1);

  /// Error overlay
  static Color get overlayError => ColorTokens.error.withValues(alpha: 0.1);

  /// Info overlay
  static Color get overlayInfo => ColorTokens.info.withValues(alpha: 0.1);

  // ============================================================================
  // DECORATIONS
  // ============================================================================

  /// Card decoration with shadow
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: ColorTokens.surface,
    borderRadius: radiusLarge,
    boxShadow: [
      BoxShadow(
        color: ColorTokens.shadow,
        offset: const Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  /// Elevated card decoration
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: ColorTokens.surface,
    borderRadius: radiusLarge,
    boxShadow: [
      BoxShadow(
        color: ColorTokens.shadow,
        offset: const Offset(0, 4),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ],
  );

  /// Button decoration
  static BoxDecoration get buttonDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: radiusMedium,
    boxShadow: [
      BoxShadow(
        color: ColorTokens.primary.withValues(alpha: 0.3),
        offset: const Offset(0, 2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ],
  );

  /// Input field decoration
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: ColorTokens.surfaceVariant,
    borderRadius: radiusMedium,
    border: Border.all(color: ColorTokens.outline),
  );

  /// Focus decoration (for input fields)
  static BoxDecoration get focusDecoration => BoxDecoration(
    color: ColorTokens.surfaceVariant,
    borderRadius: radiusMedium,
    border: Border.all(color: ColorTokens.primary, width: 2),
    boxShadow: [
      BoxShadow(
        color: ColorTokens.primary.withValues(alpha: 0.2),
        offset: const Offset(0, 0),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create custom gradient
  static LinearGradient createGradient({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(begin: begin, end: end, colors: colors, stops: stops);
  }

  /// Create custom border
  static BorderSide createBorder({
    required Color color,
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) {
    return BorderSide(color: color, width: width, style: style);
  }

  /// Create custom border radius
  static BorderRadius createRadius(double radius) {
    return BorderRadius.all(Radius.circular(radius));
  }

  /// Create asymmetric border radius
  static BorderRadius createAsymmetricRadius({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  /// Create overlay with custom opacity
  static Color createOverlay(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Create decoration with custom properties
  static BoxDecoration createDecoration({
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      border: border,
    );
  }
}
