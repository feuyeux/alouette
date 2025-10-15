import 'dart:typed_data';
import '../models/voice_model.dart';
import '../models/tts_request.dart';
import '../models/tts_error.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/cache_manager.dart';
import '../utils/error_handler.dart';
import '../utils/logger_config.dart';

/// Base TTS processor interface following Flutter naming conventions
/// Provides unified interface for all TTS engines
/// 
/// Key Principle: Processors only handle synthesis/playback and parameter mapping.
/// They do NOT store parameters - all parameters come from TTSRequest.
abstract class TTSProcessor {
  /// Get the engine name
  String get engineName;

  /// Get cache manager
  CacheManager get cacheManager;

  /// Get all available voices
  Future<List<VoiceModel>> getAvailableVoices();

  /// Synthesize text to audio bytes with all parameters from request
  ///
  /// [request] Complete TTS request with all parameters
  ///
  /// Returns audio data as bytes
  Future<Uint8List> synthesizeToAudio(TTSRequest request);

  /// Stop current TTS playback
  Future<void> stop();

  /// Dispose resources
  void dispose();
}

/// Base implementation of TTS processor with common functionality
/// Provides caching, error handling, and validation
abstract class BaseTTSProcessor implements TTSProcessor {
  bool _disposed = false;
  late final CacheManager _cacheManager;

  BaseTTSProcessor() {
    _cacheManager = CacheManager.instance;
  }

  /// Cache manager instance
  CacheManager get cacheManager => _cacheManager;

  /// Check if processor is disposed
  bool get isDisposed => _disposed;

  /// Ensure processor is not disposed
  void ensureNotDisposed() {
    if (_disposed) {
      throw StateError('TTS processor has been disposed');
    }
  }

  /// Get voices with caching support
  Future<List<VoiceModel>> getVoicesWithCache(
    Future<List<VoiceModel>> Function() fetcher,
  ) async {
    ensureNotDisposed();

    // Check cache first
    final cachedVoices = _cacheManager.getCachedVoices(engineName);
    if (cachedVoices != null) {
      return cachedVoices;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        ttsLogger.i('[TTS] Loading voices for $engineName');
        final voices = await fetcher();

        // Cache results
        _cacheManager.cacheVoices(engineName, voices);

        ttsLogger.i('[TTS] Loaded ${voices.length} voices for $engineName');
        return voices;
      },
      '$engineName voice list retrieval',
      TTSErrorCodes.voiceListError,
    );
  }

  /// Synthesize text with caching support
  Future<Uint8List> synthesizeTextWithCache(
    String text,
    String voiceName,
    String format,
    Future<Uint8List> Function() synthesizer, {
    String? cacheKeySuffix,
  }) async {
    ensureNotDisposed();

    // Validate parameters
    _validateSynthesisParams(text, voiceName);

    // Check cache
    final String voiceKey = (cacheKeySuffix != null && cacheKeySuffix.isNotEmpty)
        ? '$voiceName$cacheKeySuffix'
        : voiceName;
    
    ttsLogger.d('[TTS] Attempting synthesis - Text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...", Voice: $voiceKey');
    
    final cachedAudio = _cacheManager.getCachedAudio(text, voiceKey, format);
    if (cachedAudio != null) {
      return cachedAudio;
    }

    return await ErrorHandler.wrapAsync(
      () async {
        ttsLogger.d('[TTS] Synthesizing new audio with $engineName - ${text.length} chars, voice: $voiceKey, format: $format');

        final audioData = await synthesizer();

        // Only cache actual audio data (> 10 bytes)
        // Don't cache minimal placeholder data from direct playback mode
        if (audioData.length > 10) {
          _cacheManager.cacheAudio(text, voiceKey, format, audioData);
        } else {
          ttsLogger.d('[TTS] Synthesis completed (direct playback mode) - ${audioData.length} bytes, not cached');
        }

        return audioData;
      },
      '$engineName text synthesis',
      TTSErrorCodes.synthesisError,
    );
  }

  /// Validate synthesis parameters
  void _validateSynthesisParams(String text, String voiceName) {
    if (text.trim().isEmpty) {
      throw TTSError(
        'Text cannot be empty. Please provide valid text content for synthesis.',
        code: TTSErrorCodes.emptyText,
      );
    }

    if (voiceName.trim().isEmpty) {
      throw TTSError(
        'Voice name cannot be empty. Please specify a valid voice name. '
        'Use getAvailableVoices() to see available voices.',
        code: TTSErrorCodes.emptyVoiceName,
      );
    }
  }

  @override
  void dispose() {
    ttsLogger.d('[TTS] Disposing $engineName processor');
    _disposed = true;
  }
}
