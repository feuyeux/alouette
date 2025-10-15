import 'package:flutter/material.dart';

/// Design Tokens - Typography
///
/// Provides consistent typography scale and text styles for the application.
/// Based on Material Design 3 typography guidelines with custom adjustments.
class TypographyTokens {
  const TypographyTokens._();

  // ============================================================================
  // FONT FAMILY
  // ============================================================================

  /// Primary font family (system default)
  static const String fontFamilyPrimary = 'SF Pro Display'; // iOS
  static const String fontFamilySecondary = 'Roboto'; // Android
  static const String fontFamilyMono = 'SF Mono'; // Monospace

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================

  static const FontWeight weightThin = FontWeight.w100;
  static const FontWeight weightExtraLight = FontWeight.w200;
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightExtraBold = FontWeight.w800;
  static const FontWeight weightBlack = FontWeight.w900;

  // ============================================================================
  // FONT SIZES
  // ============================================================================

  /// Display sizes (for large headings)
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;

  /// Headline sizes (for section headings)
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;

  /// Title sizes (for subsection headings)
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;

  /// Label sizes (for buttons and small text)
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  /// Body sizes (for main content)
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;

  // ============================================================================
  // LINE HEIGHTS
  // ============================================================================

  /// Line height ratios (multiply by font size)
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // ============================================================================
  // LETTER SPACING
  // ============================================================================

  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;

  // ============================================================================
  // TEXT STYLES
  // ============================================================================

  /// Display text styles
  static const TextStyle displayLargeStyle = TextStyle(
    fontSize: displayLarge,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingTight,
    height: lineHeightTight,
  );

  static const TextStyle displayMediumStyle = TextStyle(
    fontSize: displayMedium,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
  );

  static const TextStyle displaySmallStyle = TextStyle(
    fontSize: displaySmall,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightTight,
  );

  /// Headline text styles
  static const TextStyle headlineLargeStyle = TextStyle(
    fontSize: headlineLarge,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  static const TextStyle headlineMediumStyle = TextStyle(
    fontSize: headlineMedium,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  static const TextStyle headlineSmallStyle = TextStyle(
    fontSize: headlineSmall,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Title text styles
  static const TextStyle titleLargeStyle = TextStyle(
    fontSize: titleLarge,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  static const TextStyle titleMediumStyle = TextStyle(
    fontSize: titleMedium,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );

  static const TextStyle titleSmallStyle = TextStyle(
    fontSize: titleSmall,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );

  /// Label text styles
  static const TextStyle labelLargeStyle = TextStyle(
    fontSize: labelLarge,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );

  static const TextStyle labelMediumStyle = TextStyle(
    fontSize: labelMedium,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWider,
    height: lineHeightNormal,
  );

  static const TextStyle labelSmallStyle = TextStyle(
    fontSize: labelSmall,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWider,
    height: lineHeightNormal,
  );

  /// Body text styles
  static const TextStyle bodyLargeStyle = TextStyle(
    fontSize: bodyLarge,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );

  static const TextStyle bodyMediumStyle = TextStyle(
    fontSize: bodyMedium,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );

  static const TextStyle bodySmallStyle = TextStyle(
    fontSize: bodySmall,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );

  // ============================================================================
  // SPECIALIZED TEXT STYLES
  // ============================================================================

  /// Code/monospace text styles
  static const TextStyle codeStyle = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: bodySmall,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Caption text style (for image captions, etc.)
  static const TextStyle captionStyle = TextStyle(
    fontSize: labelSmall,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Overline text style (for category labels, etc.)
  static const TextStyle overlineStyle = TextStyle(
    fontSize: labelSmall,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWider,
    height: lineHeightNormal,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create a text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Create a text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Create a text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Create a text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}
