import 'dart:typed_data';
import 'dart:async';

import '../interfaces/i_tts_service.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';
import 'error_recovery_service.dart';

/// A retry TTS service wrapper that adds automatic error recovery and retry logic
class RetryTTSService implements ITTSService {
  final ITTSService _primaryService;
  final ErrorRecoveryService _errorRecoveryService;

  /// Current configuration with voice fallback applied
  AlouetteTTSConfig? _effectiveConfig;

  /// Whether voice fallback has been applied
  bool _voiceFallbackApplied = false;

  RetryTTSService(
    this._primaryService,
    this._errorRecoveryService,
  );

  @override
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  }) async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.initialize(
        onStart: onStart,
        onComplete: onComplete,
        onError: onError,
        config: config,
      ),
      primaryService: _primaryService,
      operationName: 'initialize',
    );
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    final effectiveConfig = await _getEffectiveConfig(config);

    return await _errorRecoveryService.executeWithFallback(
      (service, cfg) => service.speak(text, config: cfg),
      _primaryService,
      effectiveConfig,
      operationName: 'speak',
    );
  }

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async {
    final effectiveConfig = await _getEffectiveConfig(config);

    return await _errorRecoveryService.executeWithFallback(
      (service, cfg) => service.speakSSML(ssml, config: cfg),
      _primaryService,
      effectiveConfig,
      operationName: 'speakSSML',
    );
  }

  @override
  Future<Uint8List> synthesizeToAudio(String text,
      {AlouetteTTSConfig? config}) async {
    final effectiveConfig = await _getEffectiveConfig(config);

    return await _errorRecoveryService.executeWithFallback(
      (service, cfg) => service.synthesizeToAudio(text, config: cfg),
      _primaryService,
      effectiveConfig,
      operationName: 'synthesizeToAudio',
    );
  }

  @override
  Future<void> stop() async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.stop(),
      primaryService: _primaryService,
      operationName: 'stop',
    );
  }

  @override
  Future<void> pause() async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.pause(),
      primaryService: _primaryService,
      operationName: 'pause',
    );
  }

  @override
  Future<void> resume() async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.resume(),
      primaryService: _primaryService,
      operationName: 'resume',
    );
  }

  @override
  Future<void> updateConfig(AlouetteTTSConfig config) async {
    // Reset voice fallback when config is explicitly updated
    _voiceFallbackApplied = false;
    _effectiveConfig = null;

    final effectiveConfig = await _getEffectiveConfig(config);

    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.updateConfig(effectiveConfig),
      primaryService: _primaryService,
      operationName: 'updateConfig',
    );
  }

  @override
  AlouetteTTSConfig get currentConfig {
    return _effectiveConfig ?? _primaryService.currentConfig;
  }

  @override
  TTSState get currentState {
    return _primaryService.currentState;
  }

  @override
  Future<List<AlouetteVoice>> getAvailableVoices() async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.getAvailableVoices(),
      primaryService: _primaryService,
      operationName: 'getAvailableVoices',
    );
  }

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.getVoicesByLanguage(languageCode),
      primaryService: _primaryService,
      operationName: 'getVoicesByLanguage',
      context: {'languageCode': languageCode},
    );
  }

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.saveAudioToFile(audioData, filePath),
      primaryService: _primaryService,
      operationName: 'saveAudioToFile',
      context: {
        'filePath': filePath,
        'audioDataSize': audioData.length,
      },
    );
  }

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async {
    return await _errorRecoveryService.executeWithRecovery(
      () => _primaryService.processBatch(requests),
      primaryService: _primaryService,
      operationName: 'processBatch',
      context: {
        'requestCount': requests.length,
      },
    );
  }

  @override
  void dispose() {
    _primaryService.dispose();
    _errorRecoveryService.dispose();
  }

  /// Gets the effective configuration with voice fallback applied if necessary
  Future<AlouetteTTSConfig> _getEffectiveConfig(
      AlouetteTTSConfig? config) async {
    final baseConfig = config ?? _primaryService.currentConfig;

    // If we already have an effective config and no new config is provided, use it
    if (config == null && _effectiveConfig != null) {
      return _effectiveConfig!;
    }

    // If voice fallback has already been applied and we're using the same base config, return it
    if (_voiceFallbackApplied && config == null && _effectiveConfig != null) {
      return _effectiveConfig!;
    }

    // Check if the requested voice is available
    if (baseConfig.voiceName != null) {
      try {
        final availableVoices = await _primaryService.getAvailableVoices();
        
        final requestedVoiceExists = availableVoices.any(
          (voice) => voice.name == baseConfig.voiceName ||
                    voice.id == baseConfig.voiceName ||
                    voice.toEdgeTTSVoiceName() == baseConfig.voiceName,
        );

        if (!requestedVoiceExists) {
          // Try to find a fallback voice
          final fallbackVoice = await _errorRecoveryService.findFallbackVoice(
            _primaryService,
            baseConfig.voiceName!,
            baseConfig.languageCode,
          );

          if (fallbackVoice != null) {
            // Apply voice fallback - use the proper Edge TTS voice name format
            _effectiveConfig = baseConfig.copyWith(
              voiceName: fallbackVoice.toEdgeTTSVoiceName(),
              languageCode: fallbackVoice.languageCode,
            );
            _voiceFallbackApplied = true;

            return _effectiveConfig!;
          }
        }
      } catch (e) {
        // If voice checking fails, continue with original config
      }
    }

    // No fallback needed or fallback failed, use original config
    _effectiveConfig = baseConfig;
    return _effectiveConfig!;
  }
}

/// Factory for creating retry TTS services
class RetryTTSServiceFactory {
  /// Creates a retry TTS service with the specified error recovery configuration
  static RetryTTSService create(
    ITTSService primaryService, {
    ErrorRecoveryConfig? errorRecoveryConfig,
    required dynamic platformDetector,
  }) {
    final errorRecoveryService = ErrorRecoveryService(
      config: errorRecoveryConfig,
      platformDetector: platformDetector,
    );

    return RetryTTSService(primaryService, errorRecoveryService);
  }

  /// Creates a retry TTS service with default error recovery settings
  static RetryTTSService createDefault(
    ITTSService primaryService, {
    required dynamic platformDetector,
  }) {
    return create(
      primaryService,
      platformDetector: platformDetector,
    );
  }

  /// Creates a retry TTS service with fast retry settings
  static RetryTTSService createFast(
    ITTSService primaryService, {
  required dynamic platformDetector,
  }) {
    final aggressiveConfig = const ErrorRecoveryConfig(
      maxRetries: 5,
      baseDelayMs: 500,
      maxDelayMs: 60000,
      backoffMultiplier: 2.5,
      enablePlatformFallback: true,
      enableVoiceFallback: true,
      retryTimeout: Duration(seconds: 45),
      enableJitter: true,
    );

    return create(
      primaryService,
  errorRecoveryConfig: aggressiveConfig,
  platformDetector: platformDetector,
    );
  }

  /// Creates a retry TTS service with safe retry settings
  static RetryTTSService createSafe(
    ITTSService primaryService, {
  required dynamic platformDetector,
  }) {
    final conservativeConfig = const ErrorRecoveryConfig(
      maxRetries: 1,
      baseDelayMs: 2000,
      maxDelayMs: 10000,
      backoffMultiplier: 1.5,
      enablePlatformFallback: false,
      enableVoiceFallback: true,
      retryTimeout: Duration(seconds: 15),
      enableJitter: false,
    );

    return create(
      primaryService,
      errorRecoveryConfig: conservativeConfig,
  platformDetector: platformDetector,
    );
  }
}
