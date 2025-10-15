import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility for rendering emoji flags with cross-platform font fallback support.
///
/// ## Problem Statement
///
/// Regional indicator emoji flags (e.g., 🇺🇸, 🇨🇳) require specialized color emoji fonts
/// that are not available in all system default fonts:
///
/// - **Windows**: `Segoe UI` (default) lacks regional indicator glyphs
/// - **macOS/iOS**: `San Francisco` (default) lacks regional indicator glyphs
/// - **Android**: System fonts often lack complete emoji coverage
/// - **Web**: Browsers handle emoji fallback automatically, but not always reliably
///
/// ## Solution Approach
///
/// This utility provides platform-optimized font fallback stacks that ensure
/// emoji flags render correctly without bundling custom font files (~10-30MB).
/// Each platform gets a tailored list based on available system emoji fonts.
///
/// ## Font Selection Rationale
///
/// - **Segoe UI Emoji** (Windows): Microsoft's color emoji font, ships with Windows 10+
/// - **Apple Color Emoji** (macOS/iOS): Apple's emoji font, complete flag support
/// - **Noto Color Emoji** (Android/Linux): Google's open-source emoji font
/// - **Twemoji Mozilla** (Web): Twitter's emoji font, widely supported in browsers
///
/// ## Usage
///
/// ```dart
/// Text('🇺🇸', style: EmojiFlagStyle.forSize(16))
/// Text('🇨🇳', style: EmojiFlagStyle.forSize(24, fontWeight: FontWeight.bold))
/// ```
class EmojiFlagStyle {
  const EmojiFlagStyle._();

  /// Returns a [TextStyle] optimized for emoji flag rendering on the current platform.
  ///
  /// The style includes:
  /// - Platform-specific font fallback stack
  /// - Tight line height (1.1) to prevent excessive spacing
  /// - Even leading distribution for vertical centering
  ///
  /// Parameters:
  /// - [fontSize]: Size of the emoji in logical pixels
  /// - [fontWeight]: Optional weight (most emoji fonts ignore this)
  static TextStyle forSize(double fontSize, {FontWeight? fontWeight}) {
    final fonts = _preferredFonts;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fonts.isNotEmpty ? fonts.first : null,
      fontFamilyFallback: fonts.length > 1 ? fonts.sublist(1) : null,
      height: 1.1,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Returns the optimal font fallback stack for the current platform.
  ///
  /// Each platform prioritizes fonts in order of:
  /// 1. Native color emoji font (best quality, always installed)
  /// 2. Cross-platform fallbacks (for edge cases)
  /// 3. Monochrome emoji fonts (last resort)
  static List<String> get _preferredFonts {
    if (kIsWeb) {
      // Web: Cast wide net since browser emoji support varies
      // Twemoji is common in Firefox, Segoe UI Emoji in Edge, Apple in Safari
      return const [
        'Twemoji Mozilla', // Firefox default
        'Segoe UI Emoji', // Edge/Chrome on Windows
        'Apple Color Emoji', // Safari on macOS
        'Noto Color Emoji', // Chrome on Linux/Android
        'EmojiOne Color', // Open-source fallback
        'Segoe UI Symbol', // Monochrome fallback
      ];
    }

    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.windows) {
      // Windows 10+: Segoe UI Emoji is the primary color emoji font
      // Segoe UI Symbol provides monochrome fallback for older systems
      return const ['Segoe UI Emoji', 'Segoe UI Symbol', 'Segoe UI'];
    }
    if (platform == TargetPlatform.macOS || platform == TargetPlatform.iOS) {
      // Apple platforms: Apple Color Emoji is comprehensive and high-quality
      return const ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'];
    }
    if (platform == TargetPlatform.android) {
      // Android: Noto Color Emoji is the system default since Android 7
      // "Android Emoji" covers older versions
      return const ['Noto Color Emoji', 'Android Emoji', 'Segoe UI Emoji'];
    }
    if (platform == TargetPlatform.linux ||
        platform == TargetPlatform.fuchsia) {
      // Linux: Font availability varies by distro, Noto is most common
      // EmojiOne Color is popular in open-source communities
      return const ['Noto Color Emoji', 'EmojiOne Color', 'Segoe UI Emoji'];
    }

    // Unknown platform: Use universal fallback stack
    return const ['Segoe UI Emoji', 'Apple Color Emoji', 'Noto Color Emoji'];
  }
}
