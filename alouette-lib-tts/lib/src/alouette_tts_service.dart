import 'dart:typed_data';
import 'interfaces/i_tts_service.dart';
import 'interfaces/i_tts_factory.dart';
import 'interfaces/i_platform_detector.dart';
import 'models/alouette_tts_config.dart';
import 'models/alouette_voice.dart';
import 'models/tts_request.dart';
import 'models/tts_result.dart';
import 'models/tts_state.dart';
import 'exceptions/tts_exception.dart';
// text_preprocessor not currently used; keep removed to avoid analyzer warning
import 'utils/ssml_validator.dart';
import 'utils/audio_file_manager.dart';
import 'utils/audio_saver.dart';
import 'utils/request_logger.dart';
import 'services/edge_tts_service.dart';
import 'services/flutter_tts_service.dart';
import 'platform/platform_detector.dart';
import 'factory/tts_factory.dart';
import 'enums/tts_platform.dart';
import 'enums/audio_format.dart';

/// Main Alouette TTS service that provides unified TTS functionality
/// across all platforms by delegating to the appropriate implementation
class AlouetteTTSService implements ITTSService {
  /// The underlying platform-specific TTS service
  ITTSService? _underlyingService;

  /// Current configuration
  AlouetteTTSConfig _config = AlouetteTTSConfig.defaultConfig();

  /// Current state
  TTSState _state = TTSState.stopped;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Optional factory for dependency injection (mainly for testing)
  final ITTSFactory? _factory;

  /// Platform detector for dependency injection
  late final IPlatformDetector _platformDetector;

  /// Request/response logger
  final RequestLogger _requestLogger = RequestLogger();

  /// Creates a new Alouette TTS service instance
  AlouetteTTSService({
    ITTSFactory? factory,
    IPlatformDetector? platformDetector,
  }) : _factory = factory,
       _platformDetector = platformDetector ?? PlatformDetector();

  @override
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  }) async {
    if (_isInitialized) {
      throw const TTSInitializationException(
        'Service is already initialized',
        'AlouetteTTS',
      );
    }

    try {
      // Get the platform-specific TTS service from the factory
      final factory = _factory;
      if (factory != null) {
        // Use injected factory (mainly for testing)
        _underlyingService = await factory.createTTSService();
      } else {
        // Create services directly with improved error handling
        final ttsFactory = TTSFactory(
          _platformDetector,
          enableErrorRecovery: true, // Enable error recovery by default
        );
        _underlyingService = await ttsFactory.createTTSService();
      }

      // Initialize the underlying service with enhanced error handling
      await _underlyingService!.initialize(
        onStart: () {
          _state = TTSState.playing;
          onStart();
        },
        onComplete: () {
          _state = TTSState.stopped;
          onComplete();
        },
        onError: (error) {
          _state = TTSState.error;
          onError(error);
        },
        config: config,
      );

      // Update configuration if provided
      if (config != null) {
        _config = config;
      }

      _isInitialized = true;
    } catch (e) {
      _state = TTSState.error;
      throw TTSInitializationException(
        'Failed to initialize Alouette TTS service: $e',
        'AlouetteTTS',
        originalError: e,
      );
    }
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    final effectiveConfig = config ?? currentConfig;
    try {
      final underlying = await _underlyingService;

      // On web, some voice names (e.g. cloud neural voices like
      // 'ar-SA-ZariyahNeural' or 'el-GR-AthinaNeural') are not available as
      // browser voices. For Arabic/Greek requests, consult the runtime
      // available voices and replace or clear the configured voiceName so
      // the browser TTS can select a suitable local voice when possible.
      try {
        final platform = _platformDetector.getCurrentPlatform();
        if (platform == TTSPlatform.web && underlying != null) {
          final langLower = (effectiveConfig.languageCode ?? '').toLowerCase();
          if (langLower.startsWith('ar') || langLower.startsWith('el')) {
            try {
              final available = await underlying.getVoicesByLanguage(effectiveConfig.languageCode);
              if (available.isNotEmpty) {
                // Prefer the runtime voice name if provided
                final runtimeName = available.first.name.isNotEmpty ? available.first.name : available.first.id;
                // Use a copied config with the runtime voice name
                config = effectiveConfig.copyWith(voiceName: runtimeName);
              } else {
                // No browser/local voices for this language — clear the voiceName
                // so the web implementation can attempt language-only matching.
                config = effectiveConfig.copyWith(voiceName: null);
              }
            } catch (_) {
              // If querying voices fails, leave the config as-is and let
              // the underlying service handle the fallback.
            }
          }
        }
      } catch (_) {
        // ignore platform-detection failures
      }

      final finalConfig = config ?? effectiveConfig;
      await underlying?.updateConfig(finalConfig);
      await underlying?.speak(text, config: finalConfig);
    } catch (e, stackTrace) {
      print('Error in AlouetteTTSService.speak: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async {
    _ensureInitialized();

    try {
      _state = TTSState.synthesizing;

      // Get current platform for SSML validation
      final platform = _platformDetector.getCurrentPlatform();

      // Validate and process SSML
      final processedSSML = _validateAndProcessSSML(ssml, platform, config);

      // Update config if provided
      if (config != null) {
        await _underlyingService!.updateConfig(config);
      }

      // Check if platform supports SSML
      if (!_platformSupportsSSML(platform)) {
        // Extract text and use regular speak method
        final plainText = SSMLValidator.extractTextFromSSML(processedSSML);
        await speak(plainText, config: config);
        return;
      }

      await _underlyingService!.speakSSML(processedSSML, config: config);
    } catch (e) {
      _state = TTSState.error;
      throw TTSSynthesisException(
        'Failed to speak SSML: $e',
        text: ssml,
        originalError: e,
      );
    }
  }

  @override
  Future<Uint8List> synthesizeToAudio(
    String text, {
    AlouetteTTSConfig? config,
  }) async {
    _ensureInitialized();

    try {
      // Log request
      await _requestLogger.logRequest({
        'operation': 'synthesizeToAudio',
        'text': text,
        'config': config?.toEdgeTTSConfig() ?? _config.toEdgeTTSConfig(),
      });
      _state = TTSState.synthesizing;

      // Update config if provided
      if (config != null) {
        await _underlyingService!.updateConfig(config);
      }

      final audioData = await _underlyingService!.synthesizeToAudio(
        text,
        config: config,
      );
      _state = TTSState.stopped;

      // Log response
      await _requestLogger.logResponse({
        'operation': 'synthesizeToAudio',
        'status': 'ok',
        'requestedLanguage': config?.languageCode ?? _config.languageCode,
        'audioSizeBytes': audioData.lengthInBytes,
      });

      return audioData;
    } catch (e) {
      // Log error
      await _requestLogger.logResponse({
        'operation': 'synthesizeToAudio',
        'status': 'error',
        'error': e.toString(),
        'requestedLanguage': config?.languageCode ?? _config.languageCode,
      });
      _state = TTSState.error;
      throw TTSSynthesisException(
        'Failed to synthesize audio: $e',
        text: text,
        originalError: e,
      );
    }
  }

  @override
  Future<void> stop() async {
    _ensureInitialized();

    try {
      // Check if stop operation is valid for current state
      if (!_state.canStop) {
        throw TTSException(
          'Cannot stop TTS in current state: ${_state.stateName}',
        );
      }

      await _underlyingService!.stop();
      _state = TTSState.stopped;
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to stop TTS: $e', originalError: e);
    }
  }

  @override
  Future<void> pause() async {
    _ensureInitialized();

    try {
      // Check if pause operation is valid for current state
      if (!_state.canPause) {
        throw TTSException(
          'Cannot pause TTS in current state: ${_state.stateName}',
        );
      }

      // Check platform support for pause functionality
      final platform = _platformDetector.getCurrentPlatform();

      if (!_platformSupportsPause(platform)) {
        throw TTSPlatformException(
          'Pause functionality is not supported on ${platform.platformName}',
          platform,
        );
      }

      await _underlyingService!.pause();
      _state = TTSState.paused;
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to pause TTS: $e', originalError: e);
    }
  }

  @override
  Future<void> resume() async {
    _ensureInitialized();

    try {
      // Check if resume operation is valid for current state
      if (!_state.canResume) {
        throw TTSException(
          'Cannot resume TTS in current state: ${_state.stateName}',
        );
      }

      // Check platform support for resume functionality
      final platform = _platformDetector.getCurrentPlatform();

      if (!_platformSupportsResume(platform)) {
        throw TTSPlatformException(
          'Resume functionality is not supported on ${platform.platformName}',
          platform,
        );
      }

      await _underlyingService!.resume();
      _state = TTSState.playing;
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to resume TTS: $e', originalError: e);
    }
  }

  @override
  Future<void> updateConfig(AlouetteTTSConfig config) async {
    _ensureInitialized();

    try {
      await _underlyingService!.updateConfig(config);
      _config = config;
    } catch (e) {
      throw TTSConfigurationException(
        'Failed to update configuration: $e',
        originalError: e,
      );
    }
  }

  @override
  AlouetteTTSConfig get currentConfig => _config;

  @override
  TTSState get currentState => _state;

  @override
  Future<List<AlouetteVoice>> getAvailableVoices() async {
    _ensureInitialized();

    try {
      return await _underlyingService!.getAvailableVoices();
    } catch (e) {
      throw TTSVoiceException(
        'Failed to get available voices: $e',
        requestedVoice: 'all',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async {
    _ensureInitialized();

    try {
      return await _underlyingService!.getVoicesByLanguage(languageCode);
    } catch (e) {
      throw TTSVoiceException(
        'Failed to get voices for language $languageCode: $e',
        requestedVoice: languageCode,
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async {
    _ensureInitialized();

    try {
      await _underlyingService!.saveAudioToFile(audioData, filePath);
    } catch (e) {
      throw TTSFileException(
        'Failed to save audio to file: $e',
        filePath: filePath,
        operation: 'save',
        originalError: e,
      );
    }
  }

  /// Synthesizes text to audio and saves it directly to a file
  ///
  /// [text] - Text to synthesize
  /// [filePath] - Destination file path
  /// [config] - Optional configuration override
  /// [overwriteMode] - How to handle existing files
  ///
  /// Returns the actual file path used (may differ if renamed)
  Future<String> synthesizeToFile(
    String text,
    String filePath, {
    AlouetteTTSConfig? config,
    FileOverwriteMode overwriteMode = FileOverwriteMode.error,
  }) async {
    _ensureInitialized();

    try {
      // Synthesize audio
      final audioData = await synthesizeToAudio(text, config: config);

      // Get the format from config
      final effectiveConfig = config ?? _config;
      final format = effectiveConfig.audioFormat;

      // Save to file with specified overwrite mode
      final actualPath = await AudioFileManager.saveAudioToFile(
        audioData,
        filePath,
        format,
        overwriteMode: overwriteMode,
      );

      return actualPath;
    } catch (e) {
      throw TTSFileException(
        'Failed to synthesize to file: $e',
        filePath: filePath,
        operation: 'synthesize_to_file',
        originalError: e,
      );
    }
  }

  /// Validates a file path for audio output
  ///
  /// [filePath] - The file path to validate
  /// [format] - Optional audio format (uses current config if not provided)
  ///
  /// Throws [TTSException] if the path is invalid
  Future<void> validateAudioFilePath(
    String filePath, {
    AudioFormat? format,
  }) async {
    try {
      final audioFormat = format ?? _config.audioFormat;
      AudioFileManager.validateFilePath(filePath, audioFormat);

      // Check permissions
      if (!await AudioFileManager.hasWritePermission(filePath)) {
        throw TTSFileException(
          'No write permission for path: $filePath',
          filePath: filePath,
          operation: 'validate',
        );
      }
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSFileException(
        'File path validation failed: $e',
        filePath: filePath,
        operation: 'validate',
        originalError: e,
      );
    }
  }

  /// Estimates the file size for synthesizing given text
  ///
  /// [text] - Text to be synthesized
  /// [format] - Optional audio format (uses current config if not provided)
  ///
  /// Returns estimated file size in bytes
  int estimateAudioFileSize(String text, {AudioFormat? format}) {
    try {
      final audioFormat = format ?? _config.audioFormat;
      return AudioFileManager.estimateFileSize(
        text,
        audioFormat,
        speechRate: _config.speechRate,
      );
    } catch (e) {
      // Return a default estimate if calculation fails
      return text.length * 1000; // Rough estimate: 1KB per character
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
    _ensureInitialized();

    try {
      // Check if underlying service supports advanced options
      if (_underlyingService is EdgeTTSService) {
        return await (_underlyingService as EdgeTTSService)
            .saveAudioToFileWithOptions(audioData, filePath, options);
      } else if (_underlyingService is FlutterTTSService) {
        return await (_underlyingService as FlutterTTSService)
            .saveAudioToFileWithOptions(audioData, filePath, options);
      } else {
        // Fallback to enhanced saver directly
        return await AudioSaver.save(audioData, filePath, options);
      }
    } catch (e) {
      throw TTSFileException(
        'Failed to save audio with options: $e',
        filePath: filePath,
        operation: 'save_with_options',
        originalError: e,
      );
    }
  }

  /// Saves audio with automatic format conversion
  ///
  /// [audioData] - Audio data to save
  /// [filePath] - Destination file path
  /// [quality] - Quality level (0.0 to 1.0)
  /// [overwriteMode] - How to handle existing files
  ///
  /// Returns [AudioSaveResult] with operation details
  Future<AudioSaveResult> saveAudioWithAutoConversion(
    Uint8List audioData,
    String filePath, {
    double quality = 0.8,
    FileOverwriteMode overwriteMode = FileOverwriteMode.error,
  }) async {
    _ensureInitialized();

    try {
      return await AudioSaver.saveAuto(
        audioData,
        filePath,
        quality: quality,
        overwriteMode: overwriteMode,
      );
    } catch (e) {
      throw TTSFileException(
        'Failed to save audio with auto conversion: $e',
        filePath: filePath,
        operation: 'save_with_auto_conversion',
        originalError: e,
      );
    }
  }

  /// Batch saves multiple audio files
  ///
  /// [audioFiles] - List of audio data and file path pairs
  /// [options] - Common save options for all files
  /// [maxConcurrent] - Maximum number of concurrent save operations
  ///
  /// Returns list of [AudioSaveResult] for each file
  Future<List<AudioSaveResult>> saveBatchAudioFiles(
    List<AudioFileData> audioFiles,
    AudioSaveOptions options, {
    int maxConcurrent = 3,
  }) async {
    _ensureInitialized();

    try {
      // Validate storage space before starting
      if (!await AudioSaver.checkBatchSpace(audioFiles)) {
        throw TTSException(
          'Insufficient storage space for batch save operation',
        );
      }

      return await AudioSaver.saveBatch(
        audioFiles,
        options,
        maxConcurrent: maxConcurrent,
      );
    } catch (e) {
      throw TTSFileException(
        'Failed to save audio files in batch: $e',
        filePath: 'batch_operation',
        operation: 'batch_save',
        originalError: e,
      );
    }
  }

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async {
    _ensureInitialized();

    try {
      return await _underlyingService!.processBatch(requests);
    } catch (e) {
      throw TTSException(
        'Failed to process batch requests: $e',
        originalError: e,
      );
    }
  }

  @override
  void dispose() {
    _underlyingService?.dispose();
    _underlyingService = null;
    _isInitialized = false;
    _state = TTSState.stopped;
  }

  /// Ensures the service is initialized before operations
  void _ensureInitialized() {
    if (!_isInitialized || _underlyingService == null) {
      throw const TTSInitializationException(
        'Service must be initialized before use',
        'AlouetteTTS',
      );
    }
  }

  /// Preprocesses a text chunk (without length validation)
  // Intentionally left in place for future use. Marked unused to silence analyzer.
  // ignore: unused_element
  String _preprocessTextChunk(
    String text,
    AlouetteTTSConfig? config,
    TTSPlatform platform,
  ) {
    if (text.trim().isEmpty) {
      return text;
    }

    try {
      // Use preprocessing without length validation since chunks are already sized appropriately
      String processedText = text;

      // 1. Normalize whitespace
      processedText = processedText.replaceAll(RegExp(r'\s+'), ' ').trim();

      // 2. Handle special characters and symbols
      final replacements = {
        '&': ' and ',
        '@': ' at ',
        '#': ' hash ',
        '%': ' percent ',
        '+': ' plus ',
        '=': ' equals ',
        '<': ' less than ',
        '>': ' greater than ',
        '|': ' pipe ',
        '~': ' tilde ',
        '^': ' caret ',
        '`': ' backtick ',
      };

      replacements.forEach((symbol, replacement) {
        processedText = processedText.replaceAll(symbol, replacement);
      });

      // 3. Apply platform-specific preprocessing
      if (platform == TTSPlatform.web) {
        // Web Speech API has limited capabilities
        processedText = processedText.replaceAll(
          RegExp(r'[^\w\s.,!?;:\-()"]'),
          ' ',
        );
      }

      // 4. Apply language-specific preprocessing
      final languageCode = config?.languageCode ?? _config.languageCode;
      if (languageCode.toLowerCase().startsWith('zh')) {
        // Chinese text processing - add spaces between Chinese and Latin characters
        processedText = processedText
            .replaceAllMapped(
              RegExp(r'([\u4e00-\u9fff])([a-zA-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}',
            )
            .replaceAllMapped(
              RegExp(r'([a-zA-Z])([\u4e00-\u9fff])'),
              (match) => '${match.group(1)} ${match.group(2)}',
            );
      }

      return processedText;
    } catch (e) {
      throw TTSSynthesisException(
        'Failed to preprocess text chunk: $e',
        text: text,
        originalError: e,
      );
    }
  }

  /// Validates and processes SSML markup
  String _validateAndProcessSSML(
    String ssml,
    TTSPlatform platform,
    AlouetteTTSConfig? config,
  ) {
    if (ssml.trim().isEmpty) {
      throw const TTSSynthesisException('SSML cannot be empty', text: '');
    }

    try {
      String processedSSML = ssml;

      // Check if this is plain text (no SSML tags)
      if (!ssml.contains('<speak')) {
        final languageCode = config?.languageCode ?? _config.languageCode;
        processedSSML = SSMLValidator.wrapInSSML(
          ssml,
          languageCode: languageCode,
        );
      }

      // Validate SSML
      final validationResult = SSMLValidator.validateSSML(
        processedSSML,
        platform,
      );

      // Log warnings but don't fail for them
      for (final warning in validationResult.warnings) {
        // In a real implementation, you might want to use a proper logging framework
        print('SSML Warning: ${warning.message}');
      }

      // Throw error if there are validation errors
      if (!validationResult.isValid) {
        final errorMessages = validationResult.errors
            .map((e) => e.message)
            .join('; ');
        throw TTSSynthesisException(
          'SSML validation failed: $errorMessages',
          text: ssml,
        );
      }

      // Sanitize SSML for the platform
      processedSSML = SSMLValidator.sanitizeSSML(processedSSML, platform);

      return processedSSML;
    } catch (e) {
      if (e is TTSSynthesisException) {
        rethrow;
      }
      throw TTSSynthesisException(
        'Failed to process SSML: $e',
        text: ssml,
        originalError: e,
      );
    }
  }

  /// Speaks multiple text chunks sequentially
  // Intentionally kept for future reference.
  // ignore: unused_element
  Future<void> _speakTextChunks(
    List<String> chunks,
    AlouetteTTSConfig? config,
  ) async {
    for (int i = 0; i < chunks.length; i++) {
      if (_state == TTSState.stopped) {
        // Stop processing if the service was stopped
        break;
      }

      await _underlyingService!.speak(chunks[i], config: config);

      // Add a small pause between chunks if not the last chunk
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Checks if the platform supports SSML
  bool _platformSupportsSSML(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.web:
        // Web Speech API has very limited SSML support
        return false;
      case TTSPlatform.android:
      case TTSPlatform.ios:
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        return true;
    }
  }

  /// Checks if the platform supports pause functionality
  bool _platformSupportsPause(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
      case TTSPlatform.ios:
        // Mobile platforms generally support pause
        return true;
      case TTSPlatform.web:
        // Web Speech API has limited pause support
        return false;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        // Desktop platforms with Edge TTS support pause
        return true;
    }
  }

  /// Checks if the platform supports resume functionality
  bool _platformSupportsResume(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
      case TTSPlatform.ios:
        // Mobile platforms generally support resume
        return true;
      case TTSPlatform.web:
        // Web Speech API has limited resume support
        return false;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        // Desktop platforms with Edge TTS support resume
        return true;
    }
  }

  /// Gets the current playback capabilities for the platform
  Map<String, bool> getPlaybackCapabilities() {
    final platform = _platformDetector.getCurrentPlatform();

    return {
      'canPlay': true, // All platforms support basic playback
      'canStop': true, // All platforms support stop
      'canPause': _platformSupportsPause(platform),
      'canResume': _platformSupportsResume(platform),
      'canSeek': false, // TTS generally doesn't support seeking
      'canSetVolume': true, // All platforms support volume control
      'canSetRate': true, // All platforms support rate control
      'canSetPitch': platform != TTSPlatform.web, // Web may have limitations
    };
  }

  /// Gets information about the current TTS engine being used
  Map<String, dynamic> getTTSEngineInfo() {
    final platform = _platformDetector.getCurrentPlatform();

    // 优先根据实际 underlyingService 类型判断
    String engineType = 'unknown';
    String engineName = 'Unknown';
    String description = '';

    if (_underlyingService is EdgeTTSService) {
      engineType = 'edge-tts';
      engineName = 'Microsoft Edge TTS';
      description = 'High-quality neural voices powered by Microsoft Edge TTS';
    } else if (_underlyingService is FlutterTTSService) {
      engineType = 'flutter-tts';
      engineName = 'Flutter TTS';
      description = 'Cross-platform TTS using native platform voices';
    } else {
      // fallback: 按平台类型推断
      if (platform.isDesktop) {
        engineType = 'edge-tts';
        engineName = 'Microsoft Edge TTS';
        description = 'High-quality neural voices powered by Microsoft Edge TTS';
      } else {
        engineType = 'flutter-tts';
        engineName = 'Flutter TTS';
        description = 'Cross-platform TTS using native platform voices';
      }
    }

    return {
      'engineType': engineType,
      'engineName': engineName,
      'description': description,
      'platform': platform.platformName,
      'isInitialized': _isInitialized,
      'currentState': _state.toString(),
    };
  }

  /// Static method to create and initialize a new service instance
  static Future<AlouetteTTSService> create({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
    ITTSFactory? factory,
    IPlatformDetector? platformDetector,
  }) async {
    final service = AlouetteTTSService(
      factory: factory,
      platformDetector: platformDetector,
    );
    await service.initialize(
      onStart: onStart,
      onComplete: onComplete,
      onError: onError,
      config: config,
    );
    return service;
  }
}
