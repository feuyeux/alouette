/// Alouette Design Tokens
///
/// Central access point for all design tokens used across Alouette applications.
/// This provides a systematic approach to design consistency and maintainability.

import 'dimension_tokens.dart';
import 'typography_tokens.dart';
import 'motion_tokens.dart';

export 'color_tokens.dart';
export 'dimension_tokens.dart';
export 'typography_tokens.dart';
export 'motion_tokens.dart';
export 'elevation_tokens.dart';
export 'effect_tokens.dart';

/// Legacy support - mapping to old constant names
///
/// These are provided for backward compatibility during the migration period.
/// New code should use the new token classes directly.
@deprecated
class UISizes {
  // Icon sizes
  static const double iconSizeSmall = DimensionTokens.iconS;
  static const double iconSizeMedium = DimensionTokens.iconM;
  static const double iconSizeLarge = DimensionTokens.iconL;

  // Spacing
  static const double spacingXs = SpacingTokens.xs;
  static const double spacingS = SpacingTokens.s;
  static const double spacingM = SpacingTokens.l;
  static const double spacingL = SpacingTokens.xl;

  // Button dimensions
  static const double buttonHeightSmall = DimensionTokens.buttonS;
  static const double buttonHeightMedium = DimensionTokens.buttonM;
  static const double buttonHeightLarge = DimensionTokens.buttonL;
  static const double buttonMinWidth = DimensionTokens.buttonMinWidth;

  // Text input height
  static const double textInputHeight = 60.0;
  static const double textInputHeightCompact = DimensionTokens.inputL;

  // Border radius
  static const double inputBorderRadius = DimensionTokens.radiusL;
  static const double buttonBorderRadius = DimensionTokens.radiusL;
  static const double cardBorderRadius = DimensionTokens.radiusXl;
}

@deprecated
class TextStyles {
  static const double smallFontSize = TypographyTokens.bodySmall;
  static const double mediumFontSize = TypographyTokens.bodyMedium;
  static const double largeFontSize = TypographyTokens.bodyLarge;
}

@deprecated
class AppDefaults {
  static const String defaultModel = 'qwen2.5:latest';
  static const String fallbackModel = 'qwen2.5:1.5b';

  // TTS defaults
  static const double defaultSpeechRate = 1.0;
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;

  // UI spacing
  static const double defaultPadding = SpacingTokens.l;
  static const double compactPadding = SpacingTokens.s;
  static const double largePadding = SpacingTokens.xxl;

  // Animation durations
  static const Duration defaultAnimationDuration = MotionTokens.normal;
  static const Duration longAnimationDuration = MotionTokens.slow;
}
