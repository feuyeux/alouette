import 'i_tts_service.dart';
import '../enums/tts_platform.dart';

/// Factory interface for creating appropriate TTS implementations
abstract class ITTSFactory {
  /// Creates the appropriate TTS service for the current platform
  /// Automatically detects the platform and returns the optimal implementation
  Future<ITTSService> createTTSService();

  /// Creates an Edge TTS service implementation
  /// Primarily used for desktop platforms (Linux, macOS, Windows)
  Future<ITTSService> createEdgeTTSService();

  /// Creates a Flutter TTS service implementation
  /// Used for mobile platforms (Android, iOS) and web
  Future<ITTSService> createFlutterTTSService();

  /// Creates a TTS service for a specific platform
  /// 
  /// [platform] - Target platform for the TTS service
  Future<ITTSService> createTTSServiceForPlatform(TTSPlatform platform);

  /// Checks if a specific TTS implementation is available
  /// 
  /// [implementation] - Implementation name ('edge-tts' or 'flutter-tts')
  Future<bool> isImplementationAvailable(String implementation);

  /// Gets the default TTS implementation for the current platform
  String getDefaultImplementation();

  /// Gets all available TTS implementations for the current platform
  Future<List<String>> getAvailableImplementations();
}