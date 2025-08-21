import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';

import '../interfaces/i_tts_service.dart';
import '../utils/audio_file_manager.dart';
import '../utils/audio_format_converter.dart';
import '../utils/audio_saver.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';
import '../enums/tts_platform.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../exceptions/tts_exceptions.dart';
import '../platform/platform_detector.dart';
import 'flutter_tts/voice_mapper.dart';
import 'flutter_tts/platform_audio_manager.dart';
import 'batch_processor.dart';

/// Flutter TTS service implementation for mobile and web platforms
class FlutterTTSService implements ITTSService {
  final FlutterTts _flutterTts = FlutterTts();
  final PlatformDetector _platformDetector = PlatformDetector();
  late final VoiceMapper _voiceMapper;
  late final PlatformAudioManager _audioManager;

  AlouetteTTSConfig _config = AlouetteTTSConfig.defaultConfig();
  TTSState _state = TTSState.stopped;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  void Function(String error)? _onError;

  // Voice caching
  List<AlouetteVoice>? _cachedVoices;
  DateTime? _voiceCacheTime;
  static const Duration _voiceCacheExpiry = Duration(hours: 1);

  // Audio capture for synthesis-to-file
  Uint8List? _capturedAudio;
  bool _isCapturingAudio = false;
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

      // Initialize voice mapper
      _voiceMapper = VoiceMapper(_platformDetector.getCurrentPlatform());

      // Initialize platform audio manager
      _audioManager = PlatformAudioManager.create(
        _platformDetector.getCurrentPlatform(),
      );
      await _audioManager.initialize(_config);

      // Initialize platform-specific settings
      await _initializePlatformSpecific();

      // Set up Flutter TTS callbacks
      await _setupCallbacks();

      // Apply initial configuration
      await _applyConfiguration(_config);

      _state = TTSState.ready;
      _isInitialized = true;
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('Failed to initialize FlutterTTS: $e');
      throw TTSInitializationException(
        'Failed to initialize FlutterTTS service: $e',
        _platformDetector.getCurrentPlatform().name,
      );
    }
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      // Apply configuration if provided
      if (config != null) {
        await _applyConfiguration(config);
      }

      _state = TTSState.synthesizing;

      // Prepare audio for synthesis
      await _audioManager.prepareForSynthesis();

      // Validate text length
      final maxLength =
          _platformDetector.getPlatformCapabilities()['maxTextLength']
              as int? ??
          4000;
      if (text.length > maxLength) {
        throw TTSSynthesisException(
          'Text length exceeds platform limit of $maxLength characters',
          text: text.substring(0, 50) + '...',
        );
      }

      // Start synthesis
      final result = await _flutterTts.speak(text);

      if (result == 1) {
        _state = TTSState.playing;
      } else {
        _state = TTSState.error;
        throw TTSSynthesisException(
          'Failed to start speech synthesis',
          text: text,
        );
      }
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('Speech synthesis failed: $e');
      if (e is TTSException) {
        rethrow;
      } else {
        throw TTSSynthesisException('Speech synthesis failed: $e', text: text);
      }
    }
  }

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async {
    // Check if SSML is supported on current platform
    if (!_platformDetector.isFeatureSupported('ssml')) {
      // Extract text from SSML and use regular speak
      final plainText = _extractTextFromSSML(ssml);
      return speak(plainText, config: config);
    }

    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      // Apply configuration if provided
      if (config != null) {
        await _applyConfiguration(config);
      }

      _state = TTSState.synthesizing;

      // Prepare audio for synthesis
      await _audioManager.prepareForSynthesis();

      // Validate SSML
      if (!_isValidSSML(ssml)) {
        throw TTSSynthesisException(
          'Invalid SSML markup',
          text: ssml.substring(0, 50) + '...',
        );
      }

      // Use SSML speak method if available
      final result = await _flutterTts.speak(ssml);

      if (result == 1) {
        _state = TTSState.playing;
      } else {
        _state = TTSState.error;
        throw TTSSynthesisException(
          'Failed to start SSML synthesis',
          text: ssml,
        );
      }
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('SSML synthesis failed: $e');
      if (e is TTSException) {
        rethrow;
      } else {
        throw TTSSynthesisException('SSML synthesis failed: $e', text: ssml);
      }
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
      // Validate text
      if (text.isEmpty) {
        throw TTSSynthesisException('Text cannot be empty', text: text);
      }

      // Apply configuration if provided
      final effectiveConfig = config ?? _config;
      if (config != null) {
        await _applyConfiguration(config);
      }

      _state = TTSState.synthesizing;
      _isCapturingAudio = true;
      _capturedAudio = null;

      // Prepare audio for synthesis
      await _audioManager.prepareForSynthesis();

      // Check if platform supports direct audio synthesis
      if (_platformDetector.isFeatureSupported('synthesizeToFile')) {
        // Use platform's native synthesis-to-file capability
        final audioData = await _synthesizeToFileNative(text, effectiveConfig);
        _state = TTSState.ready;
        return audioData;
      } else {
        // Fallback: capture audio during playback
        await _setupAudioCapture();

        // Start synthesis
        final result = await _flutterTts.speak(text);

        if (result != 1) {
          throw TTSSynthesisException(
            'Failed to start audio synthesis',
            text: text,
          );
        }

        // Wait for audio capture to complete
        await _waitForAudioCapture();

        if (_capturedAudio == null) {
          throw TTSSynthesisException(
            'Failed to capture synthesized audio',
            text: text,
          );
        }

        // Validate and convert audio format if needed
        final audioData = await _processAudioData(
          _capturedAudio!,
          effectiveConfig,
        );

        _state = TTSState.ready;
        return audioData;
      }
    } catch (e) {
      _state = TTSState.error;
      _isCapturingAudio = false;
      _onError?.call('Audio synthesis failed: $e');
      if (e is TTSException) {
        rethrow;
      } else {
        throw TTSSynthesisException('Audio synthesis failed: $e', text: text);
      }
    } finally {
      _isCapturingAudio = false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TTSState.stopped;
      _isCapturingAudio = false;
    } catch (e) {
      _onError?.call('Failed to stop TTS: $e');
      throw TTSException('Failed to stop TTS: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (!_platformDetector.isFeatureSupported('pause')) {
      throw TTSPlatformException(
        'Pause is not supported on this platform',
        _platformDetector.getCurrentPlatform(),
      );
    }

    try {
      await _flutterTts.pause();
      _state = TTSState.paused;
    } catch (e) {
      _onError?.call('Failed to pause TTS: $e');
      throw TTSException('Failed to pause TTS: $e');
    }
  }

  @override
  Future<void> resume() async {
    if (!_platformDetector.isFeatureSupported('pause')) {
      throw TTSPlatformException(
        'Resume is not supported on this platform',
        _platformDetector.getCurrentPlatform(),
      );
    }

    try {
      // Flutter TTS doesn't have a direct resume method, use speak to continue
      _state = TTSState.playing;
    } catch (e) {
      _onError?.call('Failed to resume TTS: $e');
      throw TTSException('Failed to resume TTS: $e');
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
    // Check cache first
    if (_cachedVoices != null && _voiceCacheTime != null) {
      final cacheAge = DateTime.now().difference(_voiceCacheTime!);
      if (cacheAge < _voiceCacheExpiry) {
        return List<AlouetteVoice>.from(_cachedVoices!);
      }
    }

    try {
      final voices = await _flutterTts.getVoices;
      List<AlouetteVoice> alouetteVoices = [];

      if (voices != null) {
        alouetteVoices = _voiceMapper.mapFlutterTTSVoices(voices);

        // Normalize voice metadata for consistency
        alouetteVoices = alouetteVoices
            .map((voice) => _voiceMapper.normalizeVoiceMetadata(voice))
            .toList();
      }

      // Cache the results
      _cachedVoices = alouetteVoices;
      _voiceCacheTime = DateTime.now();

      return alouetteVoices;
    } catch (e) {
      _onError?.call('Failed to get available voices: $e');
      throw TTSVoiceException(
        'Failed to get available voices: $e',
        requestedVoice: 'all',
        availableVoices: [],
      );
    }
  }

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.filterByLanguage(allVoices, languageCode);
  }

  /// Gets voices filtered by gender
  Future<List<AlouetteVoice>> getVoicesByGender(VoiceGender gender) async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.filterByGender(allVoices, gender);
  }

  /// Gets voices filtered by quality
  Future<List<AlouetteVoice>> getVoicesByQuality(VoiceQuality quality) async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.filterByQuality(allVoices, quality);
  }

  /// Finds the best matching voice for given criteria
  Future<AlouetteVoice?> findBestVoice({
    String? languageCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    bool preferDefault = true,
  }) async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.findBestMatch(
      voices: allVoices,
      languageCode: languageCode,
      gender: gender,
      quality: quality,
      preferDefault: preferDefault,
    );
  }

  /// Gets available languages from all voices
  Future<List<String>> getAvailableLanguages() async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.getAvailableLanguages(allVoices);
  }

  /// Groups voices by language
  Future<Map<String, List<AlouetteVoice>>> getVoicesGroupedByLanguage() async {
    final allVoices = await getAvailableVoices();
    return _voiceMapper.groupByLanguage(allVoices);
  }

  /// Gets platform-specific audio capabilities
  Map<String, dynamic> getAudioCapabilities() {
    return _audioManager.getAudioCapabilities();
  }

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async {
    if (_state == TTSState.disposed) {
      throw TTSException('TTS service has been disposed');
    }

    try {
      // Use the current config's audio format
      final format = _config.audioFormat;

      // Validate that the format is supported on this platform
      if (!format.isSupportedOnPlatform(
        _platformDetector.getCurrentPlatform().name,
      )) {
        throw TTSPlatformException(
          'Audio format ${format.formatName} is not supported on ${_platformDetector.getCurrentPlatform().name}',
          _platformDetector.getCurrentPlatform(),
        );
      }

      // Use enhanced audio file saver
      final options = AudioSaveOptions(
        format: format,
        quality: 0.8, // High quality by default
        overwriteMode: FileOverwriteMode.error,
        enableValidation: true,
        validateFormat: false, // Skip format validation for mobile platforms
      );

      final result = await AudioSaver.save(audioData, filePath, options);

      if (!result.success) {
        throw TTSException('Failed to save audio file: ${result.error}');
      }
    } catch (e) {
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
      // Validate format support on current platform
      final format = options.format ?? _config.audioFormat;
      if (!format.isSupportedOnPlatform(
        _platformDetector.getCurrentPlatform().name,
      )) {
        throw TTSPlatformException(
          'Audio format ${format.formatName} is not supported on ${_platformDetector.getCurrentPlatform().name}',
          _platformDetector.getCurrentPlatform(),
        );
      }

      return await AudioSaver.save(audioData, filePath, options);
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to save audio file with options: $e');
    }
  }

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async {
    if (!_isInitialized) {
      throw const TTSInitializationException(
        'FlutterTTS service must be initialized before batch processing',
        'FlutterTTS',
      );
    }

    if (requests.isEmpty) {
      return [];
    }

    // Create batch processing engine with mobile-optimized settings
    final batchEngine = BatchEngine(
      this,
      config: const BatchProcessingConfig(
        maxConcurrency: 2, // Lower concurrency for mobile devices
        maxMemoryUsage: 50 * 1024 * 1024, // 50MB for mobile
        requestTimeout: Duration(seconds: 30),
        continueOnFailure: true,
        retryFailedRequests: true,
        maxRetries: 2,
        retryDelay: Duration(milliseconds: 750),
        sortByPriority: true,
        groupByConfiguration: true,
      ),
    );

    try {
      return await batchEngine.processBatch(requests);
    } catch (e) {
      throw TTSException(
        'FlutterTTS batch processing failed: $e',
        originalError: e,
      );
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
      _audioManager.cleanup();
      _state = TTSState.disposed;
      _cachedVoices = null;
      _voiceCacheTime = null;
      _capturedAudio = null;
      _isCapturingAudio = false;
    } catch (e) {
      // Ignore errors during disposal
    }
  }

  // Private helper methods

  /// Initialize platform-specific settings
  Future<void> _initializePlatformSpecific() async {
    final platform = _platformDetector.getCurrentPlatform();

    switch (platform) {
      case TTSPlatform.android:
        await _initializeForAndroid();
        break;
      case TTSPlatform.ios:
        await _initializeForIOS();
        break;
      case TTSPlatform.web:
        await _initializeForWeb();
        break;
      default:
        // Other platforms use default settings
        break;
    }
  }

  /// Initialize Android-specific settings
  Future<void> _initializeForAndroid() async {
    try {
      // Set Android audio attributes
      await _flutterTts.setSharedInstance(true);

      // Configure audio session for Android
      final androidConfig =
          _config.platformSpecific['androidAudioAttributes']
              as Map<String, dynamic>?;
      if (androidConfig != null) {
        await _audioManager.configureAudioSession(androidConfig);
      }
    } catch (e) {
      // Continue with default settings if platform-specific setup fails
    }
  }

  /// Initialize iOS-specific settings
  Future<void> _initializeForIOS() async {
    try {
      // Set iOS shared instance
      await _flutterTts.setSharedInstance(true);

      // Configure iOS audio session
      final iosConfig =
          _config.platformSpecific['iosAudioSession'] as Map<String, dynamic>?;
      if (iosConfig != null) {
        await _audioManager.configureAudioSession(iosConfig);
      }
    } catch (e) {
      // Continue with default settings if platform-specific setup fails
    }
  }

  /// Initialize Web-specific settings
  Future<void> _initializeForWeb() async {
    try {
      // Web-specific initialization
      final webConfig =
          _config.platformSpecific['webSpeechAPI'] as Map<String, dynamic>?;
      if (webConfig != null) {
        await _audioManager.configureAudioSession(webConfig);
      }
    } catch (e) {
      // Continue with default settings if platform-specific setup fails
    }
  }

  /// Set up Flutter TTS callbacks
  Future<void> _setupCallbacks() async {
    _flutterTts.setStartHandler(() {
      // Ensure callback runs on main thread
      Future.microtask(() {
        _state = TTSState.playing;
        _onStart?.call();
      });
    });

    _flutterTts.setCompletionHandler(() {
      // Ensure callback runs on main thread
      Future.microtask(() {
        _state = TTSState.ready;
        _onComplete?.call();

        // Handle audio capture completion
        if (_isCapturingAudio) {
          _isCapturingAudio = false;
        }
      });
    });

    _flutterTts.setErrorHandler((msg) {
      // Ensure callback runs on main thread
      Future.microtask(() {
        _state = TTSState.error;
        _onError?.call(msg);

        if (_isCapturingAudio) {
          _isCapturingAudio = false;
        }
      });
    });

    _flutterTts.setPauseHandler(() {
      // Ensure callback runs on main thread
      Future.microtask(() {
        _state = TTSState.paused;
      });
    });

    _flutterTts.setContinueHandler(() {
      _state = TTSState.playing;
    });
  }

  /// Apply configuration to Flutter TTS
  Future<void> _applyConfiguration(AlouetteTTSConfig config) async {
    try {
      final flutterConfig = config.toFlutterTTSConfig();
      final platform = _platformDetector.getCurrentPlatform();

      // Apply settings one by one with individual error handling
      await _safelyApplySetting(() async {
        await _flutterTts.setSpeechRate(flutterConfig['speechRate'] as double);
      }, 'setSpeechRate');

      await _safelyApplySetting(() async {
        await _flutterTts.setVolume(flutterConfig['volume'] as double);
      }, 'setVolume');

      // Check if platform supports pitch control before trying to set it
      if (_platformSupportsPitch(platform)) {
        await _safelyApplySetting(() async {
          await _flutterTts.setPitch(flutterConfig['pitch'] as double);
        }, 'setPitch');
      }

      await _safelyApplySetting(() async {
        await _flutterTts.setLanguage(flutterConfig['language'] as String);
      }, 'setLanguage');

      // Set voice if specified
      final voiceName = flutterConfig['voice'] as String?;
      if (voiceName != null) {
        await _setVoiceByName(voiceName, config.languageCode);
      } else {
        // Try to find the best voice for the language
        await _setBestVoiceForLanguage(config.languageCode);
      }

      _config = config;

      // Update audio manager configuration if needed
      await _updateAudioManagerConfig(config);
    } catch (e) {
      throw TTSException('Failed to apply configuration: $e');
    }
  }

  /// Check if the current platform supports pitch control with FlutterTTS
  bool _platformSupportsPitch(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
      case TTSPlatform.ios:
        // Mobile platforms generally support pitch control
        return true;
      case TTSPlatform.web:
        // Web Speech API may have limited pitch support
        return true;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        // Desktop platforms using FlutterTTS have limited pitch support
        // This is based on the actual implementation capabilities
        return false;
    }
  }

  /// Safely apply a TTS setting with error handling
  Future<void> _safelyApplySetting(Future<void> Function() setter, String settingName) async {
    try {
      await setter();
    } catch (e) {
      // Log the error but don't fail initialization for missing methods
      _onError?.call('Warning: $settingName not supported on this platform: $e');
    }
  }

  /// Set voice by name and locale
  Future<void> _setVoiceByName(String voiceName, String languageCode) async {
    try {
      await _flutterTts.setVoice({'name': voiceName, 'locale': languageCode});
    } catch (e) {
      // If setting specific voice fails, try to find an alternative
      await _setBestVoiceForLanguage(languageCode);
    }
  }

  /// Set the best available voice for a language
  Future<void> _setBestVoiceForLanguage(String languageCode) async {
    try {
      final bestVoice = await findBestVoice(
        languageCode: languageCode,
        preferDefault: true,
      );

      if (bestVoice != null) {
        final flutterVoiceName =
            bestVoice.metadata['flutterTTSName'] as String?;
        if (flutterVoiceName != null) {
          await _flutterTts.setVoice({
            'name': flutterVoiceName,
            'locale': bestVoice.languageCode,
          });
        }
      }
    } catch (e) {
      // Continue with default voice if voice selection fails
    }
  }

  /// Extract plain text from SSML markup
  String _extractTextFromSSML(String ssml) {
    // Simple SSML text extraction (remove XML tags)
    return ssml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Validate SSML markup (basic validation)
  bool _isValidSSML(String ssml) {
    // Basic SSML validation - check for balanced tags
    try {
      final tagPattern = RegExp(r'<(/?)(\w+)[^>]*>');
      final matches = tagPattern.allMatches(ssml);
      final tagStack = <String>[];

      for (final match in matches) {
        final isClosing = match.group(1) == '/';
        final tagName = match.group(2)!;

        if (isClosing) {
          if (tagStack.isEmpty || tagStack.last != tagName) {
            return false;
          }
          tagStack.removeLast();
        } else {
          // Self-closing tags or tags that don't need closing
          if (!['break', 'phoneme', 'sub', 'say-as'].contains(tagName)) {
            tagStack.add(tagName);
          }
        }
      }

      return tagStack.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Set up audio capture for synthesis-to-file
  Future<void> _setupAudioCapture() async {
    // Note: Flutter TTS doesn't directly support audio capture
    // This is a placeholder for platform-specific audio capture implementation
    // In a real implementation, this would set up platform channels or
    // use platform-specific audio recording mechanisms
  }

  /// Wait for audio capture to complete
  Future<void> _waitForAudioCapture() async {
    // Wait for synthesis to complete and audio to be captured
    var attempts = 0;
    const maxAttempts = 100; // 10 seconds timeout

    while (_isCapturingAudio && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (attempts >= maxAttempts) {
      throw TTSSynthesisException(
        'Audio capture timeout',
        text: 'audio_capture',
      );
    }
  }

  /// Synthesizes audio using native platform capabilities
  Future<Uint8List> _synthesizeToFileNative(
    String text,
    AlouetteTTSConfig config,
  ) async {
    // This would use platform-specific synthesis-to-file methods
    // For now, we'll use the fallback method
    throw TTSPlatformException(
      'Native synthesis-to-file not implemented for this platform',
      _platformDetector.getCurrentPlatform(),
    );
  }

  /// Processes captured audio data and converts format if needed
  Future<Uint8List> _processAudioData(
    Uint8List audioData,
    AlouetteTTSConfig config,
  ) async {
    // Detect current format
    final detectedFormat = AudioFormatConverter.detectAudioFormat(audioData);
    final targetFormat = config.audioFormat;

    if (detectedFormat == null) {
      // Assume raw PCM and add appropriate headers
      return AudioFormatConverter.addFormatHeaders(
        audioData,
        targetFormat,
        sampleRate: 22050,
        channels: 1,
        bitsPerSample: 16,
      );
    }

    if (detectedFormat != targetFormat) {
      // Convert to target format
      return await AudioFormatConverter.convertToFormat(
        audioData,
        targetFormat,
        sourceFormat: detectedFormat,
      );
    }

    return audioData;
  }

  /// Update audio manager configuration
  Future<void> _updateAudioManagerConfig(AlouetteTTSConfig config) async {
    try {
      final platform = _platformDetector.getCurrentPlatform();

      switch (platform) {
        case TTSPlatform.android:
          final androidConfig =
              config.platformSpecific['androidAudioAttributes']
                  as Map<String, dynamic>?;
          if (androidConfig != null) {
            await _audioManager.configureAudioSession(androidConfig);
          }
          break;
        case TTSPlatform.ios:
          final iosConfig =
              config.platformSpecific['iosAudioSession']
                  as Map<String, dynamic>?;
          if (iosConfig != null) {
            await _audioManager.configureAudioSession(iosConfig);
          }
          break;
        case TTSPlatform.web:
          final webConfig =
              config.platformSpecific['webSpeechAPI'] as Map<String, dynamic>?;
          if (webConfig != null) {
            await _audioManager.configureAudioSession(webConfig);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      // Continue if audio manager config update fails
    }
  }
}
