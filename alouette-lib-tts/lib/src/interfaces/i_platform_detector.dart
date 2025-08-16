import '../enums/tts_platform.dart';

/// Interface for platform detection and capability checking
abstract class IPlatformDetector {
  /// Gets the current platform
  TTSPlatform getCurrentPlatform();

  /// Returns true if running on a desktop platform (Linux, macOS, Windows)
  bool isDesktopPlatform();

  /// Returns true if running on a mobile platform (Android, iOS)
  bool isMobilePlatform();

  /// Returns true if running on the web platform
  bool isWebPlatform();

  /// Checks if Edge TTS is available on the current platform
  /// This is primarily for desktop platforms
  Future<bool> isEdgeTTSAvailable();

  /// Gets a list of available TTS engines on the current platform
  Future<List<String>> getAvailableTTSEngines();

  /// Gets platform-specific capabilities and features
  /// Returns a map containing capability information such as:
  /// - 'supportsSSML': bool
  /// - 'supportsPause': bool
  /// - 'supportsVolumeControl': bool
  /// - 'supportsPitchControl': bool
  /// - 'supportsRateControl': bool
  /// - 'maxTextLength': int
  /// - 'supportedFormats': List<String>
  Map<String, dynamic> getPlatformCapabilities();

  /// Gets the platform version information
  Future<String> getPlatformVersion();

  /// Checks if a specific feature is supported on the current platform
  /// 
  /// [feature] - Feature name to check (e.g., 'ssml', 'pause', 'volume')
  bool isFeatureSupported(String feature);

  /// Gets the recommended TTS implementation for the current platform
  /// Returns 'edge-tts' for desktop platforms, 'flutter-tts' for mobile/web
  String getRecommendedTTSImplementation();
}