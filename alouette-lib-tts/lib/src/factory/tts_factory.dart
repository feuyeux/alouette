import '../interfaces/i_tts_factory.dart';
import '../interfaces/i_tts_service.dart';
import '../interfaces/i_platform_detector.dart';
import '../enums/tts_platform.dart';
import '../models/tts_state.dart';
import '../services/edge_tts_service.dart';
import '../services/flutter_tts_service.dart';
import '../services/retry_tts_service.dart';
import '../services/error_recovery_service.dart';
import '../exceptions/tts_exceptions.dart';

/// Concrete implementation of TTS factory with platform routing
class TTSFactory implements ITTSFactory {
  final IPlatformDetector _platformDetector;

  /// Cache for created services to avoid recreating them unnecessarily
  ITTSService? _cachedEdgeTTSService;
  ITTSService? _cachedFlutterTTSService;
  ITTSService? _cachedResilientService;

  /// Error recovery configuration
  final ErrorRecoveryConfig? _errorRecoveryConfig;

  /// Whether to enable error recovery by default
  final bool _enableErrorRecovery;

  TTSFactory(
    this._platformDetector, {
    ErrorRecoveryConfig? errorRecoveryConfig,
    bool enableErrorRecovery = true,
  })  : _errorRecoveryConfig = errorRecoveryConfig,
        _enableErrorRecovery = enableErrorRecovery;

  @override
  Future<ITTSService> createTTSService() async {
    // Return cached resilient service if available and not disposed
    if (_cachedResilientService != null &&
        _cachedResilientService!.currentState != TTSState.disposed) {
      return _cachedResilientService!;
    }

    final platform = _platformDetector.getCurrentPlatform();

    try {
      ITTSService primaryService;

      // For desktop platforms, Edge TTS is required and should be used. Do not
      // fall back to Flutter TTS on desktop.
      if (platform.isDesktop) {
        final isEdgeAvailable = await _platformDetector.isEdgeTTSAvailable();
        if (!isEdgeAvailable) {
          throw TTSInitializationException(
            'Edge TTS is required on desktop platforms but is not available. Please install and configure edge-tts.',
            platform.platformName,
          );
        }
        primaryService = await _createRawEdgeTTSService();
      } else {
        // For mobile and web platforms, use Flutter TTS only
        primaryService = await _createRawFlutterTTSService();
      }

      // Wrap with error recovery if enabled
      if (_enableErrorRecovery) {
          final resilientService = RetryTTSServiceFactory.create(
            primaryService,
            errorRecoveryConfig: _errorRecoveryConfig,
            platformDetector: _platformDetector,
          );
        _cachedResilientService = resilientService;
        return resilientService;
      } else {
        _cachedResilientService = primaryService;
        return primaryService;
      }
    } catch (e) {
      throw TTSInitializationException(
        'Failed to create TTS service for platform ${platform.platformName}: $e',
        platform.platformName,
      );
    }
  }

  @override
  Future<ITTSService> createEdgeTTSService() async {
    final rawService = await _createRawEdgeTTSService();

    // Wrap with error recovery if enabled
    if (_enableErrorRecovery) {
        return RetryTTSServiceFactory.create(
          rawService,
          errorRecoveryConfig: _errorRecoveryConfig,
          platformDetector: _platformDetector,
        );
    }

    return rawService;
  }

  /// Creates a raw Edge TTS service without error recovery wrapper
  Future<ITTSService> _createRawEdgeTTSService() async {
    // Return cached service if available and not disposed
    if (_cachedEdgeTTSService != null &&
        _cachedEdgeTTSService!.currentState != TTSState.disposed) {
      return _cachedEdgeTTSService!;
    }

    // Check if Edge TTS is available on this platform
    if (!_platformDetector.isDesktopPlatform()) {
      throw TTSPlatformException(
        'Edge TTS is not supported on ${_platformDetector.getCurrentPlatform().platformName}',
        _platformDetector.getCurrentPlatform(),
      );
    }

    final isAvailable = await _platformDetector.isEdgeTTSAvailable();
    if (!isAvailable) {
      throw TTSInitializationException(
        'Edge TTS is not available on this system. Please ensure edge-tts is installed and accessible.',
        _platformDetector.getCurrentPlatform().platformName,
      );
    }

    try {
      final service = EdgeTTSService();
      _cachedEdgeTTSService = service;
      return service;
    } catch (e) {
      throw TTSInitializationException(
        'Failed to initialize Edge TTS service: $e',
        _platformDetector.getCurrentPlatform().platformName,
      );
    }
  }

  @override
  Future<ITTSService> createFlutterTTSService() async {
    final rawService = await _createRawFlutterTTSService();

    // Wrap with error recovery if enabled
    if (_enableErrorRecovery) {
        return RetryTTSServiceFactory.create(
          rawService,
          errorRecoveryConfig: _errorRecoveryConfig,
          platformDetector: _platformDetector,
        );
    }

    return rawService;
  }

  /// Creates a raw Flutter TTS service without error recovery wrapper
  Future<ITTSService> _createRawFlutterTTSService() async {
    // Return cached service if available and not disposed
    if (_cachedFlutterTTSService != null &&
        _cachedFlutterTTSService!.currentState != TTSState.disposed) {
      return _cachedFlutterTTSService!;
    }

    try {
      final service = FlutterTTSService();
      _cachedFlutterTTSService = service;
      return service;
    } catch (e) {
      throw TTSInitializationException(
        'Failed to initialize Flutter TTS service: $e',
        _platformDetector.getCurrentPlatform().platformName,
      );
    }
  }

  @override
  Future<ITTSService> createTTSServiceForPlatform(TTSPlatform platform) async {
    try {
      if (platform.isDesktop) {
        // For desktop platforms, require Edge TTS (no fallback to Flutter TTS)
        if (await _platformDetector.isEdgeTTSAvailable()) {
          return await createEdgeTTSService();
        }

        throw TTSInitializationException(
          'Edge TTS is required on desktop platforms but is not available.',
          platform.platformName,
        );
      }

      // For mobile and web platforms, use Flutter TTS
      return await createFlutterTTSService();
    } catch (e) {
      throw TTSInitializationException(
        'Failed to create TTS service for platform ${platform.platformName}: $e',
        platform.platformName,
      );
    }
  }

  @override
  Future<bool> isImplementationAvailable(String implementation) async {
    switch (implementation.toLowerCase()) {
      case 'edge-tts':
        return _platformDetector.isDesktopPlatform() &&
            await _platformDetector.isEdgeTTSAvailable();
      case 'flutter-tts':
  // Flutter TTS is available on non-desktop platforms only.
  final platform = _platformDetector.getCurrentPlatform();
  return !platform.isDesktop;
      default:
        return false;
    }
  }

  @override
  String getDefaultImplementation() {
    return _platformDetector.getRecommendedTTSImplementation();
  }

  @override
  Future<List<String>> getAvailableImplementations() async {
    final implementations = <String>[];

    final platform = _platformDetector.getCurrentPlatform();

    // Flutter TTS is only listed for non-desktop platforms.
    if (!platform.isDesktop) {
      implementations.add('flutter-tts');
    }

    // Edge TTS is available on desktop platforms if installed
    if (_platformDetector.isDesktopPlatform() &&
        await _platformDetector.isEdgeTTSAvailable()) {
      implementations.add('edge-tts');
    }

    return implementations;
  }

  /// Clears the cached services
  /// Useful for testing or when services need to be recreated
  void clearCache() {
    _cachedEdgeTTSService?.dispose();
    _cachedFlutterTTSService?.dispose();
    _cachedResilientService?.dispose();
    _cachedEdgeTTSService = null;
    _cachedFlutterTTSService = null;
    _cachedResilientService = null;
  }

  /// Disposes of all cached services and releases resources
  void dispose() {
    clearCache();
  }
}
