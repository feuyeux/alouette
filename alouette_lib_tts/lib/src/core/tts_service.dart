import 'dart:typed_data';
import '../engines/base_tts_processor.dart';
import '../models/voice_model.dart';
import '../models/tts_request.dart';
import '../models/tts_error.dart';
import '../enums/tts_engine_type.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/logger_config.dart';
import '../utils/error_handler.dart';
import 'package:flutter/foundation.dart';

import 'tts_engine_factory.dart';
import '../utils/platform_utils.dart';
import 'tts_service_interface.dart';
import 'audio_player.dart';
import 'voice_service.dart';

/// Unified TTS Service - Main service interface for text-to-speech functionality
/// Provides consistent API across all TTS engines with automatic platform detection
class TTSService implements TTSServiceInterface {
  TTSProcessor? _processor;
  TTSEngineType? _currentEngine;
  AudioPlayer? _audioPlayer;
  bool _initialized = false;

  final TTSEngineFactory _engineFactory = TTSEngineFactory.instance;

  /// Get audio player instance
  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  /// Get current engine type
  TTSEngineType? get currentEngine => _currentEngine;

  /// Get current engine name
  String? get currentEngineName => _processor?.engineName;

  /// Get current backend name (alias for currentEngineName)
  String? get currentBackend => currentEngineName;

  /// Check if service is initialized
  bool get isInitialized => _initialized && _processor != null;

  /// Initialize TTS service with optional preferred engine
  Future<void> initialize({
    TTSEngineType? preferredEngine,
    bool autoFallback = true,
  }) async {
    if (_initialized) {
      return; // Already initialized
    }

    try {
      if (preferredEngine != null) {
        // Check if preferred engine is supported on current platform
        final strategy = PlatformUtils.getTTSStrategy();

        if (!strategy.isEngineSupported(preferredEngine)) {
          ttsLogger.w('[TTS] Preferred engine ${preferredEngine.name} is not supported on ${PlatformUtils.platformName}');

          if (!autoFallback) {
            throw TTSError(
              'Engine ${preferredEngine.name} is not supported on ${PlatformUtils.platformName}',
              code: TTSErrorCodes.platformNotSupported,
            );
          }

          // Use platform-specific fallback
          _processor = await _engineFactory.createForPlatform();
          _currentEngine = _getActualEngineFromProcessor();
        } else {
          // Try to use specified engine
          try {
            _processor = await _engineFactory.createForEngine(preferredEngine);
            _currentEngine = preferredEngine;
            ttsLogger.i('[TTS] Engine initialized: ${preferredEngine.name} - Using preferred engine');
          } catch (e) {
            ttsLogger.w('[TTS] Preferred engine ${preferredEngine.name} failed', error: e);

            if (!autoFallback) {
              rethrow; // Don't fallback if not allowed
            }

            // Fallback using platform strategy
            ttsLogger.w('[TTS] Preferred engine ${preferredEngine.name} failed, using platform fallback strategy');
            _processor = await _engineFactory.createForPlatform();
            _currentEngine = _getActualEngineFromProcessor();
          }
        }
      } else {
        // Auto-select best engine for platform using strategy
        _processor = await _engineFactory.createForPlatform();
        _currentEngine = _getActualEngineFromProcessor();
      }

      _initialized = true;
      ttsLogger.i('[TTS] Service initialization completed - Using ${_currentEngine?.name} engine on ${PlatformUtils.platformName}');
    } catch (e) {
      throw ErrorHandler.handleInitializationError(e, 'TTS service');
    }
  }

  /// Switch to different TTS engine
  Future<void> switchEngine(
    TTSEngineType engineType, {
    bool disposeOld = true,
    bool autoFallback = true,
  }) async {
    if (_currentEngine == engineType && _processor != null) {
      return; // Already using target engine
    }

    // Check if target engine is supported on current platform
    final strategy = PlatformUtils.getTTSStrategy();
    if (!strategy.isEngineSupported(engineType)) {
      if (!autoFallback) {
        throw TTSError(
          'Engine ${engineType.name} is not supported on ${PlatformUtils.platformName}',
          code: TTSErrorCodes.platformNotSupported,
        );
      }

      // Use platform fallback strategy
      ttsLogger.w('[TTS] Engine ${engineType.name} not supported on ${PlatformUtils.platformName}, using platform fallback');
      final fallbackEngines = strategy.getFallbackEngines();

      for (final fallbackEngine in fallbackEngines) {
        if (fallbackEngine != engineType &&
            await isEngineAvailable(fallbackEngine)) {
          return await switchEngine(
            fallbackEngine,
            disposeOld: disposeOld,
            autoFallback: false,
          );
        }
      }

      throw TTSError(
        'No suitable fallback engine available for ${engineType.name} on ${PlatformUtils.platformName}',
        code: TTSErrorCodes.noFallbackAvailable,
      );
    }

    TTSProcessor? oldProcessor = _processor;

    try {
      // Create new processor
      _processor = await _engineFactory.createForEngine(engineType);
      _currentEngine = engineType;
      ttsLogger.i('[TTS] Engine switched: ${engineType.name} - Engine switch completed successfully on ${PlatformUtils.platformName}');

      // Dispose old processor
      if (disposeOld && oldProcessor != null) {
        try {
          oldProcessor.dispose();
          ttsLogger.d('[TTS] Old processor disposed successfully');
        } catch (e) {
          ttsLogger.w('[TTS] Failed to dispose old processor', error: e);
        }
      }
    } catch (e) {
      // Restore old processor on failure
      _processor = oldProcessor;
      throw ErrorHandler.handleInitializationError(
        e,
        '${engineType.name} engine',
      );
    }
  }

  /// Get available voices
  Future<List<VoiceModel>> getVoices() async {
    _ensureInitialized();

    try {
      return await _processor!.getAvailableVoices();
    } catch (e) {
      throw ErrorHandler.handleVoiceError(
        e,
        'retrieval from ${_currentEngine?.name} engine',
      );
    }
  }

  /// Synthesize text to audio bytes
  /// This is a simplified version that uses default parameters
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  }) async {
    _ensureInitialized();

    try {
      final request = TTSRequest(
        text: text,
        voiceName: voiceName,
        format: format,
      );
      return await _processor!.synthesizeToAudio(request);
    } catch (e) {
      throw TTSError(
        'Failed to synthesize text using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.synthesisError,
        originalError: e,
      );
    }
  }

  /// Stop current TTS operation
  Future<void> stop() async {
    _ensureInitialized();

    try {
      final stopTasks = <Future<void>>[];

      if (_processor != null) {
        stopTasks.add(_processor!.stop());
      }

      if (_audioPlayer != null &&
          (_audioPlayer!.state == PlaybackState.playing ||
              _audioPlayer!.state == PlaybackState.paused)) {
        stopTasks.add(_audioPlayer!.stop());
      }

      if (stopTasks.isEmpty) {
        return;
      }

      await Future.wait(stopTasks);
    } catch (e) {
      throw TTSError(
        'Failed to stop TTS using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.stopFailed,
        originalError: e,
      );
    }
  }



  /// Check if specific engine is available
  Future<bool> isEngineAvailable(TTSEngineType engineType) async {
    return await _engineFactory.isEngineAvailable(engineType);
  }

  /// Get platform and engine information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    final platformInfo = await _engineFactory.getPlatformInfo();
    final strategy = PlatformUtils.getTTSStrategy();

    return {
      ...platformInfo,
      'currentEngine': _currentEngine?.name,
      'currentEngineName': currentEngineName,
      'isInitialized': isInitialized,
      'strategy': strategy.runtimeType.toString(),
      'fallbackEngines': strategy
          .getFallbackEngines()
          .map((e) => e.name)
          .toList(),
      'supportedEngines': TTSEngineType.values
          .where((e) => strategy.isEngineSupported(e))
          .map((e) => e.name)
          .toList(),
    };
  }

  /// Clear audio cache for all items
  void clearAudioCache() {
    _processor?.cacheManager.clearAudioCache();
    ttsLogger.d('[CACHE] Cleared all audio caches');
  }

  /// Clear audio cache for a specific text and voice
  void clearAudioCacheItem(String text, String voiceName, {String format = 'mp3'}) {
    _processor?.cacheManager.clearAudioCacheItem(text, voiceName, format);
    ttsLogger.d('[CACHE] Cleared audio cache for specific item');
  }





  /// Speak text directly with audio playback
  /// All parameters are now encapsulated in TTSRequest for consistency
  Future<void> speakText(
    String text, {
    String? voiceName,
    String? languageName,
    String? languageCode,
    String format = 'mp3',
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    _ensureInitialized();

    try {
      // Use provided voice or find best voice for language
      String selectedVoice = voiceName ?? '';
      if (selectedVoice.isEmpty) {
        VoiceModel? bestVoice;

        // Try to find voice by language name first
        if (languageName != null && languageName.isNotEmpty) {
          final voiceService = VoiceService(this);
          bestVoice = await voiceService.getBestVoiceForLanguageName(
            languageName,
          );
        }

        // Fallback to first available voice
        if (bestVoice == null) {
          final voices = await getVoices();
          if (voices.isNotEmpty) {
            bestVoice = voices.first;
          } else {
            throw TTSError(
              'No voices available for TTS',
              code: TTSErrorCodes.noVoicesAvailable,
            );
          }
        }

        selectedVoice = bestVoice.id;
      }

      ttsLogger.d('[TTS] Speaking text with voice: $selectedVoice');

      // Create TTS request with all parameters
      final request = TTSRequest(
        text: text,
        voiceName: selectedVoice,
        languageCode: languageCode,
        languageName: languageName,
        format: format,
        rate: rate ?? 1.0, // Default to normal speed (1.0x)
        pitch: pitch ?? 1.0, // Default to normal pitch (1.0x)
        volume: volume ?? 1.0, // Default to full volume (100%)
      );

      // Synthesize audio using the request
      final audioData = await _processor!.synthesizeToAudio(request);

      // Check if this is minimal audio data (direct playback mode)
      if (audioData.length <= 10) {
        ttsLogger.d('[TTS] Using direct playback mode - audio should have played already');
        return; // Direct playback has already occurred
      }

      await audioPlayer.playBytes(audioData);
      ttsLogger.d('[TTS] Audio playback completed');
    } catch (e) {
      throw TTSError(
        'Failed to speak text using ${_currentEngine?.name} engine: $e',
        code: TTSErrorCodes.speakError,
        originalError: e,
      );
    }
  }













  /// Dispose service and release resources
  void dispose() {
    ttsLogger.d('[TTS] Disposing TTS service');
    try {
      _processor?.dispose();
      _audioPlayer?.dispose();
    } catch (e) {
      ttsLogger.w('[TTS] Error during disposal', error: e);
    } finally {
      _processor = null;
      _audioPlayer = null;
      _currentEngine = null;
      _initialized = false;
      ttsLogger.d('[TTS] TTS service disposed successfully');
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!isInitialized) {
      throw TTSError(
        'TTS service is not initialized. Please call initialize() first.',
        code: TTSErrorCodes.notInitialized,
      );
    }
  }

  /// Get the actual engine type from the processor
  TTSEngineType? _getActualEngineFromProcessor() {
    if (_processor == null) return null;

    switch (_processor!.engineName) {
      case 'edge':
        return TTSEngineType.edge;
      case 'flutter':
        return TTSEngineType.flutter;
      default:
        return null;
    }
  }
}
