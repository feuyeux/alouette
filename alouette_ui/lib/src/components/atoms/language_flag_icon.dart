import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

import '../../constants/language_constants.dart';
import '../../core/logger.dart';
import '../../utils/emoji_flag_style.dart';

/// Cross-platform atom for rendering country flags based on language codes.
///
/// This component automatically selects the best rendering strategy:
/// - **Platforms with emoji support** (web, macOS, iOS, Android):
///   Uses native emoji flags (🇺🇸, 🇨🇳, etc.) with proper font fallbacks
/// - **Platforms without emoji support** (Windows desktop):
///   Falls back to PNG assets from the `country_icons` package (250px standard, 1000px fallback)
/// - **Fallback strategy**: If assets are missing, displays country code monogram
///
/// ## Usage Examples
///
/// ```dart
/// // Basic usage with default rectangular aspect ratio (1.5:1)
/// LanguageFlagIcon(
///   language: LanguageOption(code: 'en-US', ...),
///   size: 16,
/// )
///
/// // Square flag for compact layouts
/// LanguageFlagIcon(
///   language: language,
///   size: 20,
///   aspectRatio: LanguageFlagIcon.aspectRatioSquare,
/// )
///
/// // Wide flag for headers
/// LanguageFlagIcon(
///   language: language,
///   size: 24,
///   aspectRatio: LanguageFlagIcon.aspectRatioWide,
///   borderRadius: 6,
/// )
/// ```
///
/// ## Technical Details
///
/// - Extracts country code from language codes (e.g., "CN" from "zh-CN")
/// - Uses ClipRRect for rounded corners on PNG assets
/// - Provides debug logging when assets are missing
/// - Gracefully degrades to styled monogram fallback (e.g., "US")
class LanguageFlagIcon extends StatelessWidget {
  /// Standard aspect ratios for different layout contexts
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioRectangle = 1.5;
  static const double aspectRatioWide = 2.0;

  /// Scaling factors for different rendering modes
  static const double _emojiFontScale = 0.9;
  static const double _monogramFontScale = 0.5;

  final LanguageOption language;

  /// Height of the rendered flag in logical pixels.
  /// Width is automatically calculated as `size * aspectRatio`.
  final double size;

  /// Corner radius for rounded flag borders (PNG assets only).
  final double borderRadius;

  /// Width-to-height ratio for the flag.
  /// Common values:
  /// - 1.0 for square flags
  /// - 1.5 for standard rectangular flags (default)
  /// - 2.0 for wide flags
  final double aspectRatio;

  const LanguageFlagIcon({
    super.key,
    required this.language,
    this.size = 16,
    this.borderRadius = 2,
    this.aspectRatio = aspectRatioRectangle,
  });

  double get _width => size * aspectRatio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: _width, height: size, child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (PlatformUtils.supportsEmojiFlags) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(
          language.flag,
          style: EmojiFlagStyle.forSize(size * _emojiFontScale),
        ),
      );
    }

    final countryCode = _resolveCountryCode(language.code);
    if (countryCode == null) {
      return _buildMonogramFallback(context);
    }

    // country_icons 3.0.0+ uses size-specific directories: png100px, png250px, png1000px
    final assetPath = 'icons/flags/png250px/${countryCode.toLowerCase()}.png';
    return _buildImageWithFallback(
      context,
      assetPath,
      () => _attemptHighResolutionFallback(context, countryCode.toLowerCase()),
    );
  }

  Widget _attemptHighResolutionFallback(
    BuildContext context,
    String countryCode,
  ) {
    // Try high resolution 1000px version as fallback
    final hiResPath = 'icons/flags/png1000px/$countryCode.png';
    return _buildImageWithFallback(
      context,
      hiResPath,
      () => _buildMonogramFallback(context),
    );
  }

  Widget _buildImageWithFallback(
    BuildContext context,
    String assetPath,
    Widget Function() onMissing,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        package: 'country_icons',
        width: _width,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) {
          logger.d(
            '[UI] LanguageFlagIcon: missing asset "$assetPath" for code ${language.code}',
          );
          return onMissing();
        },
      ),
    );
  }

  /// Builds a styled country code monogram as the final fallback.
  /// Displays the country portion of the language code (e.g., "US" from "en-US").
  Widget _buildMonogramFallback(BuildContext context) {
    final monogram = language.code.split('-').last.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _width,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceDim,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        monogram,
        style: TextStyle(
          fontSize: size * _monogramFontScale,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Extracts the country code from a language code.
  /// Returns null if the code format is invalid.
  ///
  /// Examples:
  /// - "en-US" → "US"
  /// - "zh-CN" → "CN"
  /// - "fr-FR" → "FR"
  String? _resolveCountryCode(String code) {
    if (code.isEmpty) {
      return null;
    }

    final parts = code.split('-');
    if (parts.length < 2) {
      return null;
    }

    return parts.last;
  }
}
