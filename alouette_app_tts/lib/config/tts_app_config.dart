import 'package:alouette_lib_tts/alouette_tts.dart';

/// Configuration for the TTS Application
class TTSAppConfig {
  /// Default TTS configuration
  static const TTSConfig defaultTTSConfig = TTSConfig(
    speechRate: 1.0,
    pitch: 1.0,
    volume: 1.0,
  );

  /// TTS app-specific settings
  static const TTSEngineType? preferredEngine = null; // Auto-detect
  static const bool enableAutoFallback = true;

  /// Application-specific constants
  static const String appTitle = 'Alouette TTS';

  /// UI slider ranges
  static const double minRate = 0.5;
  static const double maxRate = 2.0;
  static const double minPitch = 0.5;
  static const double maxPitch = 2.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
}
