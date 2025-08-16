import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;

import '../interfaces/i_tts_service.dart';
import '../utils/audio_file_manager.dart';
import '../utils/audio_format_converter.dart';
import '../utils/audio_saver.dart';
import '../enums/audio_format.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';
import '../exceptions/tts_exception.dart';
import '../enums/tts_platform.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import 'edge_tts/edge_tts_websocket_client.dart';
import 'edge_tts/edge_tts_command_line_client.dart';
import 'edge_tts/edge_tts_ssml_generator.dart';
import 'batch_processor.dart';
import 'edge_tts/edge_tts_voice_selector.dart';
import 'edge_tts/edge_tts_voice_discovery.dart';
import 'edge_tts/edge_tts_voice_cache.dart';
import 'edge_tts/edge_tts_connection_pool.dart';
import 'edge_tts/edge_tts_performance_monitor.dart';

/// Edge TTS service implementation for desktop platforms
class EdgeTTSService implements ITTSService {
  AlouetteTTSConfig _config = AlouetteTTSConfig.defaultConfig();
  TTSState _state = TTSState.stopped;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  void Function(String error)? _onError;

  EdgeTTSWebSocketClient? _wsClient;
  EdgeTTSCommandLineClient? _cmdClient;
  EdgeTTSVoiceDiscovery? _voiceDiscovery;
  EdgeTTSVoiceCache? _voiceCache;
  EdgeTTSConnectionPool? _connectionPool;
  EdgeTTSPerformanceMonitor? _performanceMonitor;
  Timer? _playbackTimer;
  bool _useCommandLineFallback = false;
  bool _isInitialized = false;

  @override
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  }) async {
    try {
      _onStart = onStart;
      _onComplete = onComplete;
      _onError = onError;

      if (config != null) {
        _config = config;
      }

      // Initialize WebSocket client
      _wsClient = EdgeTTSWebSocketClient();

      // Initialize command-line client as fallback
      _cmdClient = EdgeTTSCommandLineClient();

      // Initialize voice discovery and caching
      _voiceDiscovery = EdgeTTSVoiceDiscovery();
      _voiceCache = EdgeTTSVoiceCache();

      // Initialize connection pool and performance monitoring
      _connectionPool = EdgeTTSConnectionPool();
      _performanceMonitor = EdgeTTSPerformanceMonitor();

      // Check if command-line fallback is available
      _useCommandLineFallback = await EdgeTTSCommandLineClient.isAvailable();

      _state = TTSState.ready;
      _isInitialized = true;
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('Failed to initialize Edge TTS service: $e');
      rethrow;
    }
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    try {
      _state = TTSState.synthesizing;
      _onStart?.call();

      final effectiveConfig = config ?? _config;
      final audioData = await synthesizeToAudio(text, config: effectiveConfig);

      // For now, we'll just complete immediately since we don't have audio playback
      // Audio playback will be implemented in a future task
      _state = TTSState.playing;

      // Simulate playback duration
      final estimatedDuration = _estimatePlaybackDuration(text);
      _playbackTimer = Timer(estimatedDuration, () {
        _state = TTSState.stopped;
        _onComplete?.call();
      });
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('Speech synthesis failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async {
    try {
      _state = TTSState.synthesizing;
      _onStart?.call();

      final effectiveConfig = config ?? _config;

      // Process SSML and synthesize
      final processedSSML = EdgeTTSSSMLGenerator.processSSML(
        ssml,
        effectiveConfig,
      );
      final audioData = await _synthesizeSSML(processedSSML, effectiveConfig);

      // Simulate playback
      _state = TTSState.playing;
      final text = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml);
      final estimatedDuration = _estimatePlaybackDuration(text);

      _playbackTimer = Timer(estimatedDuration, () {
        _state = TTSState.stopped;
        _onComplete?.call();
      });
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('SSML synthesis failed: $e');
      rethrow;
    }
  }

  @override
  Future<Uint8List> synthesizeToAudio(
    String text, {
    AlouetteTTSConfig? config,
  }) async {
    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      final effectiveConfig = config ?? _config;

      // Validate text length
      if (text.isEmpty) {
        throw TTSSynthesisException('Text cannot be empty', text: text);
      }

      if (text.length > 10000) {
        throw TTSSynthesisException(
          'Text length exceeds maximum limit of 10000 characters',
          text: text.substring(0, 50) + '...',
        );
      }

      _state = TTSState.synthesizing;

      // Generate SSML from text
      final ssml = EdgeTTSSSMLGenerator.generateSSML(text, effectiveConfig);

      // Synthesize audio
      final audioData = await _synthesizeSSML(ssml, effectiveConfig);

      // Validate audio format
      final expectedFormat = effectiveConfig.audioFormat;
      if (!_validateAudioFormat(audioData, expectedFormat)) {
        throw TTSSynthesisException(
          'Generated audio does not match expected format: ${expectedFormat.formatName}',
          text: text.substring(0, 50) + '...',
        );
      }

      _state = TTSState.ready;
      return audioData;
    } catch (e) {
      _state = TTSState.error;
      if (e is TTSException) {
        rethrow;
      }
      throw TTSSynthesisException('Audio synthesis failed: $e', text: text);
    }
  }

  @override
  Future<void> stop() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _state = TTSState.stopped;
  }

  @override
  Future<void> pause() async {
    if (_state == TTSState.playing) {
      _playbackTimer?.cancel();
      _state = TTSState.paused;
    }
  }

  @override
  Future<void> resume() async {
    if (_state == TTSState.paused) {
      _state = TTSState.playing;
      // Note: Real implementation would resume from pause position
      // For now, we'll just continue with remaining time
    }
  }

  @override
  Future<void> updateConfig(AlouetteTTSConfig config) async {
    _config = config;
  }

  @override
  AlouetteTTSConfig get currentConfig => _config;

  @override
  TTSState get currentState => _state;

  @override
  Future<List<AlouetteVoice>> getAvailableVoices() async {
    if (_voiceCache == null || _voiceDiscovery == null) {
      return _getDefaultVoices();
    }

    // Check cache first
    const cacheKey = 'all_voices';
    final cachedVoices = _voiceCache!.getVoices(cacheKey);
    if (cachedVoices != null) {
      return cachedVoices;
    }

    // Discover voices if not cached
    try {
      final voices = await _voiceDiscovery!.discoverVoices();
      _voiceCache!.cacheVoices(cacheKey, voices);
      return voices;
    } catch (e) {
      // Fallback to default voices if discovery fails
      final defaultVoices = _getDefaultVoices();
      _voiceCache!.cacheVoices(cacheKey, defaultVoices);
      return defaultVoices;
    }
  }

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async {
    if (_voiceCache == null || _voiceDiscovery == null) {
      final allVoices = await getAvailableVoices();
      return allVoices
          .where(
            (voice) => EdgeTTSVoiceSelector.isVoiceCompatible(
              voice,
              AlouetteTTSConfig(languageCode: languageCode),
            ),
          )
          .toList();
    }

    // Check cache for language-specific voices
    final cacheKey = 'voices_$languageCode';
    final cachedVoices = _voiceCache!.getVoices(cacheKey);
    if (cachedVoices != null) {
      return cachedVoices;
    }

    // Get all voices and filter by language
    final allVoices = await getAvailableVoices();
    final languageVoices = _voiceDiscovery!.filterByLanguage(
      allVoices,
      languageCode,
    );
    final sortedVoices = _voiceDiscovery!.sortByPreference(languageVoices);

    // Cache the filtered results
    _voiceCache!.cacheVoices(cacheKey, sortedVoices);

    return sortedVoices;
  }

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async {
    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      // Use enhanced audio file saver with current config
      final options = AudioSaveOptions(
        format: _config.audioFormat,
        quality: 0.8, // High quality by default
        overwriteMode: FileOverwriteMode.error,
        enableValidation: true,
        validateFormat: true,
      );

      final result = await AudioSaver.save(audioData, filePath, options);

      if (!result.success) {
        throw TTSException('Failed to save audio file: ${result.error}');
      }

      // Log successful save for performance monitoring
      _performanceMonitor?.recordFileOperation(
        operation: 'save_audio',
        filePath: result.filePath,
        fileSize: result.finalSize,
        success: true,
        metadata: {
          'originalSize': result.originalSize,
          'compressionRatio': result.compressionRatio,
          'wasConverted': result.wasConverted,
          'wasRenamed': result.wasRenamed,
          'processingTime': result.processingTime.inMilliseconds,
        },
      );
    } catch (e) {
      // Log failed save for performance monitoring
      _performanceMonitor?.recordFileOperation(
        operation: 'save_audio',
        filePath: filePath,
        fileSize: audioData.length,
        success: false,
        error: e.toString(),
      );

      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to save audio file: $e');
    }
  }

  /// Saves audio to file with advanced options
  ///
  /// [audioData] - Audio data to save
  /// [filePath] - Destination file path
  /// [options] - Save options including format, quality, and overwrite behavior
  ///
  /// Returns [AudioSaveResult] with operation details
  Future<AudioSaveResult> saveAudioToFileWithOptions(
    Uint8List audioData,
    String filePath,
    AudioSaveOptions options,
  ) async {
    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      final result = await AudioSaver.save(audioData, filePath, options);

      // Log operation for performance monitoring
      _performanceMonitor?.recordFileOperation(
        operation: 'save_audio_advanced',
        filePath: result.filePath,
        fileSize: result.finalSize,
        success: result.success,
        error: result.error,
        metadata: {
          'originalSize': result.originalSize,
          'compressionRatio': result.compressionRatio,
          'wasConverted': result.wasConverted,
          'wasRenamed': result.wasRenamed,
          'processingTime': result.processingTime.inMilliseconds,
        },
      );

      return result;
    } catch (e) {
      // Log failed operation
      _performanceMonitor?.recordFileOperation(
        operation: 'save_audio_advanced',
        filePath: filePath,
        fileSize: audioData.length,
        success: false,
        error: e.toString(),
      );

      rethrow;
    }
  }

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async {
    if (!_isInitialized) {
      throw const TTSInitializationException(
        'EdgeTTS service must be initialized before batch processing',
        'EdgeTTS',
      );
    }

    if (requests.isEmpty) {
      return [];
    }

    // Create batch processing engine
    final batchEngine = BatchEngine(
      this,
      config: const BatchProcessingConfig(
        maxConcurrency: 5, // EdgeTTS can handle more concurrent connections
        maxMemoryUsage: 200 * 1024 * 1024, // 200MB for desktop
        requestTimeout: Duration(seconds: 45), // Longer timeout for desktop
        continueOnFailure: true,
        retryFailedRequests: true,
        maxRetries: 3,
        retryDelay: Duration(milliseconds: 1000),
        sortByPriority: true,
        groupByConfiguration: true,
      ),
    );

    try {
      return await batchEngine.processBatch(requests);
    } catch (e) {
      throw TTSException(
        'EdgeTTS batch processing failed: $e',
        originalError: e,
      );
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _wsClient?.disconnect();
    _wsClient = null;
    _cmdClient = null;
    _voiceDiscovery?.dispose();
    _voiceDiscovery = null;
    _voiceCache?.invalidateAll();
    _voiceCache = null;
    _connectionPool?.dispose();
    _connectionPool = null;
    _performanceMonitor = null;
    _state = TTSState.disposed;
  }

  /// Gets performance statistics for the EdgeTTS service
  Map<String, dynamic> getPerformanceStats() {
    if (_performanceMonitor == null) {
      return {'error': 'Performance monitoring not initialized'};
    }

    final stats = _performanceMonitor!.getOverallStats();

    // Add connection pool stats if available
    if (_connectionPool != null) {
      stats['connectionPool'] = _connectionPool!.getPoolStats();
    }

    // Add voice cache stats if available
    if (_voiceCache != null) {
      stats['voiceCache'] = _voiceCache!.getCacheStats();
    }

    return stats;
  }

  /// Synthesizes SSML using WebSocket client with command-line fallback
  Future<Uint8List> _synthesizeSSML(
    String ssml,
    AlouetteTTSConfig config,
  ) async {
    final stopwatch = Stopwatch()..start();
    final textLength = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml).length;

    print('DEBUG: Starting synthesis for language: ${config.languageCode}');
    print('DEBUG: Text length: $textLength');
    print(
      'DEBUG: SSML preview: ${ssml.substring(0, math.min(200, ssml.length))}...',
    );

    try {
      // Try WebSocket first
      if (_wsClient != null) {
        try {
          print('DEBUG: Attempting WebSocket synthesis...');
          final result = await _wsClient!.synthesize(ssml, config);

          // Record successful synthesis
          _performanceMonitor?.recordSynthesis(
            duration: stopwatch.elapsed,
            textLength: textLength,
            success: true,
            metadata: {'method': 'websocket'},
          );

          print('DEBUG: WebSocket synthesis successful');
          return result;
        } catch (e) {
          print('DEBUG: WebSocket synthesis failed: $e');

          // If WebSocket fails and command-line is available, try fallback
          if (_useCommandLineFallback && _cmdClient != null) {
            try {
              print('DEBUG: Attempting command-line fallback...');
              // Extract text from SSML for command-line client
              final text = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml);
              final result = await _cmdClient!.synthesize(text, config);

              // Record successful fallback synthesis
              _performanceMonitor?.recordSynthesis(
                duration: stopwatch.elapsed,
                textLength: textLength,
                success: true,
                metadata: {'method': 'command_line_fallback'},
              );

              print('DEBUG: Command-line fallback successful');
              return result;
            } catch (fallbackError) {
              print('DEBUG: Command-line fallback also failed: $fallbackError');

              // Record failure
              _performanceMonitor?.recordSynthesis(
                duration: stopwatch.elapsed,
                textLength: textLength,
                success: false,
                errorType: 'both_methods_failed',
              );

              // If both fail, throw the original WebSocket error
              if (e is TTSException) rethrow;
              throw TTSSynthesisException(
                'Failed to synthesize SSML: $e',
                text: ssml,
              );
            }
          }

          // Record WebSocket failure
          _performanceMonitor?.recordSynthesis(
            duration: stopwatch.elapsed,
            textLength: textLength,
            success: false,
            errorType: 'websocket_failed',
          );

          // No fallback available, rethrow original error
          if (e is TTSException) rethrow;
          throw TTSSynthesisException(
            'Failed to synthesize SSML: $e',
            text: ssml,
          );
        }
      }

      // WebSocket not available, try command-line
      if (_useCommandLineFallback && _cmdClient != null) {
        try {
          final text = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml);
          final result = await _cmdClient!.synthesize(text, config);

          // Record successful command-line synthesis
          _performanceMonitor?.recordSynthesis(
            duration: stopwatch.elapsed,
            textLength: textLength,
            success: true,
            metadata: {'method': 'command_line'},
          );

          return result;
        } catch (e) {
          // Record command-line failure
          _performanceMonitor?.recordSynthesis(
            duration: stopwatch.elapsed,
            textLength: textLength,
            success: false,
            errorType: 'command_line_failed',
          );

          if (e is TTSException) rethrow;
          throw TTSSynthesisException(
            'Failed to synthesize using command-line: $e',
            text: ssml,
          );
        }
      }

      // Record initialization failure
      _performanceMonitor?.recordSynthesis(
        duration: stopwatch.elapsed,
        textLength: textLength,
        success: false,
        errorType: 'no_client_available',
      );

      throw TTSInitializationException(
        'No EdgeTTS client available (neither WebSocket nor command-line)',
        'desktop',
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Estimates playback duration based on text length
  Duration _estimatePlaybackDuration(String text) {
    // Rough estimate: average speaking rate is about 150 words per minute
    final wordCount = text.split(RegExp(r'\s+')).length;
    final wordsPerMinute = 150 * _config.speechRate;
    final minutes = wordCount / wordsPerMinute;
    return Duration(milliseconds: (minutes * 60 * 1000).round());
  }

  /// Validates audio format
  bool _validateAudioFormat(Uint8List audioData, AudioFormat expectedFormat) {
    return AudioFormatConverter.validateAudioFormat(audioData, expectedFormat);
  }

  /// Returns a default set of voices for testing
  List<AlouetteVoice> _getDefaultVoices() {
    return [
      AlouetteVoice.fromPlatformData(
        id: 'en-US-AriaNeural',
        name: 'Aria (Neural)',
        languageCode: 'en-US',
        platform: TTSPlatform.windows,
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        isDefault: true,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)',
        },
      ),
      AlouetteVoice.fromPlatformData(
        id: 'en-US-GuyNeural',
        name: 'Guy (Neural)',
        languageCode: 'en-US',
        platform: TTSPlatform.windows,
        gender: VoiceGender.male,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (en-US, GuyNeural)',
        },
      ),
      AlouetteVoice.fromPlatformData(
        id: 'es-ES-ElviraNeural',
        name: 'Elvira (Neural)',
        languageCode: 'es-ES',
        platform: TTSPlatform.windows,
        gender: VoiceGender.female,
        quality: VoiceQuality.neural,
        metadata: {
          'edgeTTSName':
              'Microsoft Server Speech Text to Speech Voice (es-ES, ElviraNeural)',
        },
      ),
    ];
  }
}
