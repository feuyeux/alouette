import 'package:get_it/get_it.dart';
import '../interfaces/i_tts_service.dart';
import '../interfaces/i_platform_detector.dart';
import '../interfaces/i_tts_factory.dart';
import '../platform/platform_detector.dart';
import '../factory/tts_factory.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Gets the singleton instance of GetIt
  static GetIt get instance => _getIt;

  /// Registers all TTS-related services
  static Future<void> registerServices() async {
    // Register platform detector
    if (!_getIt.isRegistered<IPlatformDetector>()) {
      _getIt.registerLazySingleton<IPlatformDetector>(
        () => _createPlatformDetector(),
      );
    }

    // Register TTS factory
    if (!_getIt.isRegistered<ITTSFactory>()) {
      _getIt.registerLazySingleton<ITTSFactory>(
        () => _createTTSFactory(),
      );
    }

    // Register TTS service (created by factory)
    if (!_getIt.isRegistered<ITTSService>()) {
      _getIt.registerLazySingletonAsync<ITTSService>(
        () async {
          final factory = _getIt<ITTSFactory>();
          return await factory.createTTSService();
        },
      );
    }
  }

  /// Gets the TTS service instance
  static ITTSService get ttsService => _getIt<ITTSService>();

  /// Gets the platform detector instance
  static IPlatformDetector get platformDetector => _getIt<IPlatformDetector>();

  /// Gets the TTS factory instance
  static ITTSFactory get ttsFactory => _getIt<ITTSFactory>();

  /// Checks if services are registered
  static bool get isReady => _getIt.isRegistered<ITTSService>();

  /// Waits for all async services to be ready
  static Future<void> ensureReady() async {
    await _getIt.allReady();
  }

  /// Resets all registered services (useful for testing)
  static Future<void> reset() async {
    await _getIt.reset();
  }

  /// Registers a custom TTS service implementation
  static void registerCustomTTSService(ITTSService service) {
    if (_getIt.isRegistered<ITTSService>()) {
      _getIt.unregister<ITTSService>();
    }
    _getIt.registerSingleton<ITTSService>(service);
  }

  /// Registers a custom platform detector implementation
  static void registerCustomPlatformDetector(IPlatformDetector detector) {
    if (_getIt.isRegistered<IPlatformDetector>()) {
      _getIt.unregister<IPlatformDetector>();
    }
    _getIt.registerSingleton<IPlatformDetector>(detector);
  }

  /// Registers a custom TTS factory implementation
  static void registerCustomTTSFactory(ITTSFactory factory) {
    if (_getIt.isRegistered<ITTSFactory>()) {
      _getIt.unregister<ITTSFactory>();
    }
    _getIt.registerSingleton<ITTSFactory>(factory);
  }

  /// Creates the platform detector implementation
  static IPlatformDetector _createPlatformDetector() {
    // Import the concrete implementation
    return PlatformDetector();
  }

  /// Creates the TTS factory implementation
  static ITTSFactory _createTTSFactory() {
    // Import the concrete implementation
    final platformDetector = _getIt<IPlatformDetector>();
    return TTSFactory(platformDetector);
  }
}

/// Extension methods for easier service access
extension ServiceLocatorExtension on GetIt {
  /// Gets the TTS service with null safety
  ITTSService? get ttsServiceOrNull {
    try {
      return get<ITTSService>();
    } catch (e) {
      return null;
    }
  }

  /// Gets the platform detector with null safety
  IPlatformDetector? get platformDetectorOrNull {
    try {
      return get<IPlatformDetector>();
    } catch (e) {
      return null;
    }
  }

  /// Gets the TTS factory with null safety
  ITTSFactory? get ttsFactoryOrNull {
    try {
      return get<ITTSFactory>();
    } catch (e) {
      return null;
    }
  }
}