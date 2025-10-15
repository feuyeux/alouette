import 'dart:async';
import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import '../core/service_locator.dart';
import '../core/service_configuration.dart';
import '../core/configuration_manager.dart';

/// Service Manager for Alouette Applications
///
/// Provides centralized service management using dependency injection.
/// Manages the lifecycle of all services including initialization, registration, and disposal.
///
/// Now uses direct library types instead of wrapper interfaces for better simplicity and maintainability.
class ServiceManager {
  static bool _isInitialized = false;
  static final List<String> _initializationLog = [];
  static final Map<Type, bool> _serviceStatus = {};

  /// Initialize all services with default implementations
  ///
  /// This should be called once at app startup.
  /// [config] - Service configuration (defaults to combined configuration)
  static Future<ServiceInitializationResult> initialize([
    ServiceConfiguration config = ServiceConfiguration.combined,
  ]) async {
    if (_isInitialized) {
      return ServiceInitializationResult(
        isSuccessful: true,
        serviceResults: Map.from(
          _serviceStatus.map((k, v) => MapEntry(k.toString(), v)),
        ),
        errors: [],
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    _initializationLog.clear();
    _serviceStatus.clear();
    final errors = <String>[];

    try {
      if (config.verboseLogging) {
        _log('Starting service initialization with config: $config');
      } else {
        _log('Starting service initialization...');
      }

      // Register services as singletons using direct library types
      if (config.initializeTTS) {
        _log('Registering TTS service');
        ServiceLocator.registerSingleton<tts_lib.TTSService>(
          () => tts_lib.TTSService(),
        );
        _log('TTS service registered');
      }

      if (config.initializeTranslation) {
        _log('Registering Translation service');
        ServiceLocator.registerSingleton<trans_lib.TranslationService>(
          () => trans_lib.TranslationService(),
        );
        _log('Translation service registered');
      }

      // Register ConfigurationManager as a singleton
      _log('Registering ConfigurationManager');
      ServiceLocator.registerSingleton<ConfigurationManager>(
        () => ConfigurationManager.instance,
      );
      _log('ConfigurationManager registered');

      // Initialize services with timeout
      final initFuture = _initializeServicesWithConfig(config);
      await initFuture.timeout(
        Duration(milliseconds: config.initializationTimeoutMs),
        onTimeout: () {
          throw TimeoutException(
            'Service initialization timed out after ${config.initializationTimeoutMs}ms',
          );
        },
      );

      _isInitialized = true;
      stopwatch.stop();

      final result = ServiceInitializationResult(
        isSuccessful: true,
        serviceResults: Map.from(
          _serviceStatus.map((k, v) => MapEntry(k.toString(), v)),
        ),
        errors: errors,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      _log('All services initialized successfully in ${result.durationMs}ms');

      return result;
    } catch (e) {
      stopwatch.stop();
      errors.add(e.toString());
      _log('Service initialization failed: $e');

      final result = ServiceInitializationResult(
        isSuccessful: false,
        serviceResults: Map.from(
          _serviceStatus.map((k, v) => MapEntry(k.toString(), v)),
        ),
        errors: errors,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      await dispose(); // Cleanup on failure
      return result;
    }
  }

  /// Initialize services based on configuration
  static Future<void> _initializeServicesWithConfig(
    ServiceConfiguration config,
  ) async {
    // Initialize services in parallel for better performance
    final futures = <Future<void>>[];

    if (config.initializeTTS) {
      futures.add(_initializeService<tts_lib.TTSService>('TTS', config));
    }

    if (config.initializeTranslation) {
      futures.add(
        _initializeService<trans_lib.TranslationService>('Translation', config),
      );
    }

    // Initialize ConfigurationManager
    futures.add(_initializeConfigurationManager());

    // Wait for all services to initialize
    await Future.wait(futures);
  }

  /// Initialize ConfigurationManager
  static Future<void> _initializeConfigurationManager() async {
    try {
      _log('Getting ConfigurationManager instance');
      final configManager = ServiceLocator.get<ConfigurationManager>();
      _log('Got ConfigurationManager instance: $configManager');

      _log('Initializing ConfigurationManager');
      await configManager.initialize();
      _log('ConfigurationManager initialized');

      _serviceStatus[ConfigurationManager] = true;
      _log('ConfigurationManager initialized');
    } catch (e) {
      _serviceStatus[ConfigurationManager] = false;
      _log('ConfigurationManager initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize a specific service
  static Future<void> _initializeService<T>(
    String serviceName,
    ServiceConfiguration config,
  ) async {
    try {
      _log('Getting service instance for $serviceName');
      final service = ServiceLocator.get<T>();
      _log('Got service instance for $serviceName: $service');

      bool success = false;
      if (service is tts_lib.TTSService) {
        _log('Initializing TTS service');
        await service.initialize(autoFallback: config.ttsAutoFallback);
        success = true;
        _log('TTS service initialized successfully');
      } else if (service is trans_lib.TranslationService) {
        _log('Initializing Translation service');
        success = await service.initialize();
        _log('Translation service initialized with success=$success');
      }

      if (!success) {
        // For TranslationService, allow app to continue even if auto-config fails
        if (service is trans_lib.TranslationService) {
          _serviceStatus[T] = false;
          _log(
            '$serviceName service initialized but auto-configuration failed - service can still be configured manually',
          );
          return; // Don't throw, allow app to start
        }
        throw Exception('Failed to initialize $serviceName service');
      }

      _serviceStatus[T] = true;
      _log('$serviceName service initialized');
    } catch (e) {
      _serviceStatus[T] = false;
      _log('$serviceName service failed: $e');

      // For TranslationService, don't rethrow - allow app to start
      if (serviceName == 'Translation') {
        _log('Continuing without Translation service auto-configuration');
        return;
      }
      rethrow;
    }
  }

  /// Get TTS service instance
  ///
  /// Returns the singleton TTS service instance.
  /// Throws ServiceNotRegisteredException if not initialized.
  static tts_lib.TTSService getTTSService() {
    _ensureInitialized();
    _ensureServiceAvailable<tts_lib.TTSService>('TTS');
    return ServiceLocator.get<tts_lib.TTSService>();
  }

  /// Get Translation service instance
  ///
  /// Returns the singleton Translation service instance.
  /// Throws ServiceNotRegisteredException if not initialized.
  static trans_lib.TranslationService getTranslationService() {
    _ensureInitialized();
    _ensureServiceAvailable<trans_lib.TranslationService>('Translation');
    return ServiceLocator.get<trans_lib.TranslationService>();
  }

  /// Register a custom TTS service implementation
  ///
  /// Useful for testing or using alternative implementations.
  static void registerTTSService(tts_lib.TTSService service) {
    ServiceLocator.register<tts_lib.TTSService>(service);
    _serviceStatus[tts_lib.TTSService] = true;
  }

  /// Register a custom Translation service implementation
  ///
  /// Useful for testing or using alternative implementations.
  static void registerTranslationService(trans_lib.TranslationService service) {
    ServiceLocator.register<trans_lib.TranslationService>(service);
    _serviceStatus[trans_lib.TranslationService] = true;
  }

  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;

  /// Check if a specific service is available and initialized
  static bool isServiceAvailable<T>() {
    return _isInitialized &&
        ServiceLocator.isRegistered<T>() &&
        (_serviceStatus[T] ?? false);
  }

  /// Get service initialization status
  static Map<String, bool> getServiceStatus() {
    return {
      'TTS': isServiceAvailable<tts_lib.TTSService>(),
      'Translation': isServiceAvailable<trans_lib.TranslationService>(),
    };
  }

  /// Get initialization log for debugging
  static List<String> getInitializationLog() {
    return List.unmodifiable(_initializationLog);
  }

  /// Dispose all services and cleanup
  ///
  /// Should be called when the app is shutting down.
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _log('Starting service disposal...');

      // Dispose TTS service if it exists
      if (ServiceLocator.isRegistered<tts_lib.TTSService>()) {
        final ttsService = ServiceLocator.get<tts_lib.TTSService>();
        ttsService.dispose();
        _log('TTS service disposed');
      }

      // Dispose Translation service if it exists
      if (ServiceLocator.isRegistered<trans_lib.TranslationService>()) {
        final translationService =
            ServiceLocator.get<trans_lib.TranslationService>();
        translationService.dispose();
        _log('Translation service disposed');
      }

      // Clear all services
      ServiceLocator.clear();
      _serviceStatus.clear();
      _isInitialized = false;

      _log('All services disposed successfully');
    } catch (e) {
      _log('Service disposal error: $e');
    }
  }

  /// Reset services (useful for testing)
  ///
  /// Disposes current services and allows re-initialization.
  static Future<void> reset() async {
    await dispose();
    _initializationLog.clear();
    _serviceStatus.clear();
    _isInitialized = false;
  }

  /// Reinitialize a specific service
  ///
  /// Useful for recovering from service failures.
  static Future<void> reinitializeService<T>(String serviceName) async {
    if (!_isInitialized) {
      throw StateError(
        'Service Manager not initialized. Call initialize() first.',
      );
    }

    try {
      _log('Reinitializing $serviceName service...');
      await _initializeService<T>(serviceName, ServiceConfiguration.combined);
      _log('$serviceName service reinitialized successfully');
    } catch (e) {
      _log('Failed to reinitialize $serviceName service: $e');
      rethrow;
    }
  }

  /// Private helper methods
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Service Manager not initialized. Call initialize() first.',
      );
    }
  }

  static void _ensureServiceAvailable<T>(String serviceName) {
    if (!isServiceAvailable<T>()) {
      throw StateError(
        '$serviceName service is not available or failed to initialize.',
      );
    }
  }

  static void _log(String message) {
    _initializationLog.add(message);
  }
}

/// Helper extension for easier service access
extension ServiceManagerHelpers on ServiceManager {
  /// Quick access to TTS speak functionality
  static Future<void> speak(String text, {String? voiceName}) async {
    final ttsService = ServiceManager.getTTSService();
    await ttsService.speakText(text, voiceName: voiceName);
  }

  /// Quick access to TTS stop functionality
  static Future<void> stopSpeaking() async {
    final ttsService = ServiceManager.getTTSService();
    await ttsService.stop();
  }

  /// Quick access to get available voices
  static Future<List<tts_lib.VoiceModel>> getVoices() async {
    final ttsService = ServiceManager.getTTSService();
    return await ttsService.getVoices();
  }

  /// Quick access to translation functionality with auto-config
  static Future<trans_lib.TranslationResult> translate({
    required String text,
    required List<String> targetLanguages,
  }) async {
    final translationService = ServiceManager.getTranslationService();
    return await translationService.translateWithAutoConfig(
      text,
      targetLanguages,
    );
  }
}
