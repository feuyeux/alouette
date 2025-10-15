import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Configuration for the main Alouette application
/// 
/// Contains only application-specific settings. UI constants should use
/// design tokens from alouette_ui library.
class AppConfig {
  /// Default TTS configuration for speech synthesis
  /// Uses UI library defaults for consistent behavior
  static const TTSConfig defaultTTSConfig = TTSConfig(
    speechRate: TTSDefaults.speechRate,
    pitch: TTSDefaults.pitch,
    volume: TTSDefaults.volume,
  );

  /// Application-specific constants
  static const String appTitle = 'Alouette';
  static const String appVersion = '1.0.0';

  /// Feature flags specific to the main application
  static const bool enableTranslationFeature = true;
  static const bool enableTTSFeature = true;
  static const bool enableAutoConfiguration = true;
  static const bool enableErrorReporting = true;

  /// Maximum text length for translation and TTS (application-specific limit)
  static const int maxTextLength = 10000;
}
