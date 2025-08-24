import 'dart:typed_data';
import 'dart:async';
import 'dart:io';
// math import not needed currently

import '../interfaces/i_tts_service.dart';
import '../utils/audio_file_manager.dart';
import '../utils/audio_format_converter.dart';
import '../utils/audio_saver.dart';
import '../enums/audio_format.dart';
import '../enums/tts_error_code.dart';
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

class _Player {
  final String executable;
  final List<String> Function(String path) args;
  _Player(this.executable, this.args);
}

/// Edge TTS service implementation for desktop platforms
class EdgeTTSService implements ITTSService {
  AlouetteTTSConfig _config = AlouetteTTSConfig.defaultConfig();
  TTSState _state = TTSState.stopped;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  void Function(String error)? _onError;

  EdgeTTSWebSocketClient? _wsClient;
  EdgeTTSCommandLineClient? _cmdClient;
  // Per-language WebSocket clients for connection reuse
  final Map<String, EdgeTTSWebSocketClient> _wsClientsByLanguage = {};
  EdgeTTSVoiceDiscovery? _voiceDiscovery;
  EdgeTTSVoiceCache? _voiceCache;
  EdgeTTSConnectionPool? _connectionPool;
  EdgeTTSPerformanceMonitor? _performanceMonitor;
  Timer? _playbackTimer;
  Process? _currentAudioProcess;
  bool _useCommandLineFallback = false;
  bool _isInitialized = false;
  // Simple in-memory cache (key -> audio bytes)
  final Map<String, Uint8List> _audioCache = {};
  late final Directory _cacheDir;

  @override
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  }) async {
    try {
      print('Initializing Edge TTS service...');
      _onStart = onStart;
      _onComplete = onComplete;
      _onError = onError;

      if (config != null) {
        _config = config;
      }

      // Initialize components safely with error handling
      await _initializeComponents();

      _state = TTSState.ready;
      _isInitialized = true;
      print('Edge TTS service initialized successfully');
    } catch (e) {
      print('Edge TTS service initialization failed: $e');
      _state = TTSState.error;
      _onError?.call('Failed to initialize Edge TTS service: $e');
      rethrow;
    }
  }

  /// Initialize components with proper error handling
  Future<void> _initializeComponents() async {
    try {
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

      // Prepare disk cache directory
      _cacheDir = Directory('${Directory.systemTemp.path}/alouette_tts_cache');
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      // Check if command-line fallback is available
      try {
        _useCommandLineFallback = await EdgeTTSCommandLineClient.isAvailable();
      } catch (e) {
        // Command line fallback not available, continue with WebSocket only
        _useCommandLineFallback = false;
      }

      // Pre-warm WebSocket connection for better responsiveness
      await _preWarmConnection();
    } catch (e) {
      throw TTSInitializationException(
        'Failed to initialize Edge TTS components: $e',
        'Edge TTS',
        errorCode: TTSErrorCode.initializationFailed,
      );
    }
  }

  /// Pre-warms the WebSocket connection for better responsiveness
  Future<void> _preWarmConnection() async {
    // Pre-warm a default client for the configured language
    final lang = _config.languageCode;
    try {
      final client = EdgeTTSWebSocketClient();
      _wsClientsByLanguage[lang] = client;
      await client.connect();
    } catch (e) {
      // WebSocket pre-warming failed, will fallback to command-line
    }
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    try {
      _state = TTSState.synthesizing;
      _onStart?.call();

      final effectiveConfig = config ?? _config;
      final audioData = await synthesizeToAudio(text, config: effectiveConfig);

      // Try to play the audio data using a system player if available.
      _state = TTSState.playing;
      await _playAudioData(audioData, text);
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

      // Play audio data
      _state = TTSState.playing;
      final text = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml);
      await _playAudioData(audioData, text);
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

      // Use cache key based on text + language + voice
      final cacheKey =
          '${effectiveConfig.languageCode}::${effectiveConfig.voiceName ?? ''}::${text.hashCode}';

      // Check in-memory cache first
      if (_audioCache.containsKey(cacheKey)) {
        return _audioCache[cacheKey]!;
      }

      // Check disk cache
      final cachedFile = File('${_cacheDir.path}/$cacheKey.mp3');
      if (await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        _audioCache[cacheKey] = Uint8List.fromList(bytes);
        return _audioCache[cacheKey]!;
      }

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

      // Save to caches
      try {
        _audioCache[cacheKey] = audioData;
        await File('${_cacheDir.path}/$cacheKey.mp3').writeAsBytes(audioData);
      } catch (_) {}

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
    // Kill any external player process
    try {
      if (_currentAudioProcess != null) {
        _currentAudioProcess!.kill(ProcessSignal.sigterm);
        _currentAudioProcess = null;
      }
    } catch (e) {
      // ignore
    }

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

  /// Plays raw audio data using a system player. Saves to a temp file and executes
  /// a suitable player (mpv/ffplay/aplay/paplay/xdg-open). Emits onComplete when done.
  Future<void> _playAudioData(Uint8List audioData, String textHint) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/alouette_play_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    try {
      await tempFile.writeAsBytes(audioData);

      // Attempt to find a system player
      final player = await _findSystemPlayer();
      if (player == null) {
        // If none, just simulate playback duration
        final estimatedDuration = _estimatePlaybackDuration(textHint);
        _playbackTimer = Timer(estimatedDuration, () {
          _state = TTSState.stopped;
          _onComplete?.call();
        });
        return;
      }

      // Spawn player process
      final proc = await Process.start(
        player.executable,
        player.args(tempFile.path),
      );
      _currentAudioProcess = proc;

      // When process exits, mark complete
      proc.exitCode.then((_) {
        _currentAudioProcess = null;
        _state = TTSState.stopped;
        _onComplete?.call();
      });
    } catch (e) {
      // On error, fallback to simulated playback
      final estimatedDuration = _estimatePlaybackDuration(textHint);
      _playbackTimer = Timer(estimatedDuration, () {
        _state = TTSState.stopped;
        _onComplete?.call();
      });
    } finally {
      // copy last file for debugging
      try {
        final saved = File('/tmp/alouette_last_tts.mp3');
        if (await tempFile.exists()) {
          await tempFile.copy(saved.path);
        }
      } catch (_) {}
      // schedule temp cleanup after a short delay to allow player to open
      Future.delayed(Duration(seconds: 5), () async {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      });
    }
  }

  /// Finds an available system audio player and returns an executable + arg builder.
  Future<_Player?> _findSystemPlayer() async {
    // Prefer mpv, ffplay, paplay, aplay, xdg-open
    final candidates = [
      _Player('mpv', (path) => ['--no-terminal', path]),
      _Player('ffplay', (path) => ['-nodisp', '-autoexit', path]),
      _Player('paplay', (path) => [path]),
      _Player('aplay', (path) => [path]),
      _Player('xdg-open', (path) => [path]),
    ];

    for (final p in candidates) {
      try {
        final result = await Process.run('which', [p.executable]);
        if (result.exitCode == 0) return p;
      } catch (_) {}
    }

    return null;
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

  /// Ensures WebSocket connection is ready, reconnecting if necessary
  Future<void> _ensureConnectionReady() async {
    // No-op: individual per-language clients are managed in _synthesizeSSML
    return;
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

    try {
      // Ensure any global readiness (noop for per-language clients)
      await _ensureConnectionReady();

      final lang = config.languageCode;
      var perLangClient = _wsClientsByLanguage[lang];
      if (perLangClient == null) {
        perLangClient = EdgeTTSWebSocketClient();
        _wsClientsByLanguage[lang] = perLangClient;
      }

      // Try WebSocket synthesis using the per-language client
      try {
        final result = await perLangClient.synthesize(ssml, config);

        _performanceMonitor?.recordSynthesis(
          duration: stopwatch.elapsed,
          textLength: textLength,
          success: true,
          metadata: {'method': 'websocket'},
        );

        return result;
      } catch (e) {
        // Try command-line fallback if available
        if (_useCommandLineFallback && _cmdClient != null) {
          try {
            final text = EdgeTTSSSMLGenerator.extractTextFromSSML(ssml);
            final result = await _cmdClient!.synthesize(text, config);

            _performanceMonitor?.recordSynthesis(
              duration: stopwatch.elapsed,
              textLength: textLength,
              success: true,
              metadata: {'method': 'command_line_fallback'},
            );

            return result;
          } catch (fallbackError) {
            _performanceMonitor?.recordSynthesis(
              duration: stopwatch.elapsed,
              textLength: textLength,
              success: false,
              errorType: 'both_methods_failed',
            );

            if (e is TTSException) rethrow;
            throw TTSSynthesisException(
              'Failed to synthesize SSML: $e',
              text: ssml,
            );
          }
        }

        _performanceMonitor?.recordSynthesis(
          duration: stopwatch.elapsed,
          textLength: textLength,
          success: false,
          errorType: 'websocket_failed',
        );

        if (e is TTSException) rethrow;
        throw TTSSynthesisException(
          'Failed to synthesize SSML: $e',
          text: ssml,
        );
      }
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
