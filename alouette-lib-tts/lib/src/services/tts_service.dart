import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import '../models/tts_config.dart';
import '../models/tts_state.dart';
import '../models/language_option.dart';
import '../utils/tts_constants.dart';
import '../exceptions/tts_exceptions.dart';

/// Core TTS service providing text-to-speech functionality across platforms
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  static const MethodChannel _androidChannel = MethodChannel('com.alouette.lib.tts/audio');
  
  // Current configuration
  TTSConfig _currentConfig = TTSConfig.defaultConfig();
  TTSState _currentState = TTSState.stopped;
  bool _isInitialized = false;

  // Callback handlers
  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  void Function(dynamic message)? _onError;

  /// Get current TTS configuration
  TTSConfig get currentConfig => _currentConfig;

  /// Get current TTS state
  TTSState get currentState => _currentState;

  /// Check if TTS service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize TTS service with callback handlers
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(dynamic message) onError,
    TTSConfig? config,
  }) async {
    try {
      _onStart = onStart;
      _onComplete = onComplete;
      _onError = onError;

      // Set up TTS handlers
      _flutterTts.setStartHandler(() {
        _currentState = TTSState.playing;
        _onStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        _currentState = TTSState.stopped;
        _onComplete?.call();
      });

      _flutterTts.setErrorHandler((message) {
        _currentState = TTSState.stopped;
        _onError?.call(message);
      });

      _flutterTts.setPauseHandler(() {
        _currentState = TTSState.paused;
      });

      _flutterTts.setContinueHandler(() {
        _currentState = TTSState.continued;
      });

      // Apply configuration
      if (config != null) {
        await _applyConfig(config);
      } else {
        await _applyConfig(_currentConfig);
      }

      // Platform-specific initialization
      if (!kIsWeb && Platform.isAndroid) {
        await _configureAndroidAudio();
      }

      _isInitialized = true;
    } catch (e) {
      throw TTSInitializationException(
        'Failed to initialize TTS service: ${e.toString()}',
        e,
      );
    }
  }

  /// Configure Android-specific audio settings
  Future<void> _configureAndroidAudio() async {
    try {
      // Set audio stream type for media playback
      await _androidChannel.invokeMethod(TTSConstants.androidAudioStreamType);

      // Configure TTS engine parameters
      await _flutterTts.awaitSpeakCompletion(_currentConfig.awaitCompletion);
      await _flutterTts.setSharedInstance(true);

      // Log volume information for debugging
      if (kDebugMode) {
        try {
          final maxVolume = await _androidChannel.invokeMethod(TTSConstants.androidGetMaxVolume);
          final currentVolume = await _androidChannel.invokeMethod(TTSConstants.androidGetCurrentVolume);
          debugPrint('TTS Audio - Max Volume: $maxVolume, Current Volume: $currentVolume');
        } catch (e) {
          debugPrint('Failed to get Android volume info: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to configure Android audio: $e');
      }
      throw TTSPlatformException(
        'Failed to configure Android audio settings: ${e.toString()}',
        'android',
        e,
      );
    }
  }

  /// Apply TTS configuration
  Future<void> _applyConfig(TTSConfig config) async {
    if (!config.isValid()) {
      throw TTSConfigurationException(
        'Invalid TTS configuration provided',
        'config',
      );
    }

    await _flutterTts.setSpeechRate(config.speechRate);
    await _flutterTts.setVolume(config.volume);
    await _flutterTts.setPitch(config.pitch);
    await _flutterTts.setLanguage(config.languageCode);

    if (!kIsWeb) {
      await _flutterTts.awaitSpeakCompletion(config.awaitCompletion);
    }

    _currentConfig = config;
  }

  /// Speak text with specified parameters
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double volume,
    required double pitch,
  }) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (text.isEmpty) {
      throw const TTSSpeechException('Text cannot be empty');
    }

    try {
      // Create temporary config for this speech
      final speechConfig = TTSConfig(
        speechRate: speechRate,
        volume: volume,
        pitch: pitch,
        languageCode: languageCode,
        awaitCompletion: _currentConfig.awaitCompletion,
      );

      // Apply speech configuration
      await _applyConfig(speechConfig);

      // Start speaking
      await _flutterTts.speak(text);
    } catch (e) {
      throw TTSSpeechException(
        'Failed to speak text: ${e.toString()}',
        e,
      );
    }
  }

  /// Speak text using current configuration
  Future<void> speakWithConfig(String text, {TTSConfig? config}) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (text.isEmpty) {
      throw const TTSSpeechException('Text cannot be empty');
    }

    try {
      if (config != null) {
        await _applyConfig(config);
      }

      await _flutterTts.speak(text);
    } catch (e) {
      throw TTSSpeechException(
        'Failed to speak text: ${e.toString()}',
        e,
      );
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    try {
      await _flutterTts.stop();
      _currentState = TTSState.stopped;
    } catch (e) {
      throw TTSSpeechException(
        'Failed to stop speech: ${e.toString()}',
        e,
      );
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    try {
      // flutter_tts doesn't have a pause method, only stop
      // For now, we'll use stop and update state accordingly
      await _flutterTts.stop();
      _currentState = TTSState.paused;
    } catch (e) {
      throw TTSSpeechException(
        'Failed to pause speech: ${e.toString()}',
        e,
      );
    }
  }

  /// Resume paused speech
  Future<void> resume() async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    try {
      // flutter_tts doesn't have a resume method, so we'll use continue
      // or re-implement by storing the last text and continuing from where we left off
      _currentState = TTSState.continued;
      // Note: flutter_tts doesn't support resume, this is a placeholder
      // In a real implementation, you might need to store the current position
      // and restart from there, or use platform-specific implementations
    } catch (e) {
      throw TTSSpeechException(
        'Failed to resume speech: ${e.toString()}',
        e,
      );
    }
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (!TTSConstants.isValidSpeechRate(rate)) {
      throw TTSConfigurationException(
        'Speech rate must be between ${TTSConstants.minSpeechRate} and ${TTSConstants.maxSpeechRate}',
        'speechRate',
      );
    }

    try {
      await _flutterTts.setSpeechRate(rate);
      _currentConfig = _currentConfig.copyWith(speechRate: rate);
    } catch (e) {
      throw TTSConfigurationException(
        'Failed to set speech rate: ${e.toString()}',
        'speechRate',
        e,
      );
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (!TTSConstants.isValidVolume(volume)) {
      throw TTSConfigurationException(
        'Volume must be between ${TTSConstants.minVolume} and ${TTSConstants.maxVolume}',
        'volume',
      );
    }

    try {
      await _flutterTts.setVolume(volume);
      _currentConfig = _currentConfig.copyWith(volume: volume);
    } catch (e) {
      throw TTSConfigurationException(
        'Failed to set volume: ${e.toString()}',
        'volume',
        e,
      );
    }
  }

  /// Set pitch
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (!TTSConstants.isValidPitch(pitch)) {
      throw TTSConfigurationException(
        'Pitch must be between ${TTSConstants.minPitch} and ${TTSConstants.maxPitch}',
        'pitch',
      );
    }

    try {
      await _flutterTts.setPitch(pitch);
      _currentConfig = _currentConfig.copyWith(pitch: pitch);
    } catch (e) {
      throw TTSConfigurationException(
        'Failed to set pitch: ${e.toString()}',
        'pitch',
        e,
      );
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    if (!TTSConstants.isLanguageSupported(languageCode)) {
      throw TTSLanguageNotSupportedException(
        'Language $languageCode is not supported',
        languageCode,
      );
    }

    try {
      await _flutterTts.setLanguage(languageCode);
      _currentConfig = _currentConfig.copyWith(languageCode: languageCode);
    } catch (e) {
      throw TTSLanguageNotSupportedException(
        'Failed to set language $languageCode: ${e.toString()}',
        languageCode,
        e,
      );
    }
  }

  /// Get available languages from TTS engine
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        return languages.cast<String>();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get languages from TTS engine: $e');
      }
    }

    // Return default supported languages if engine query fails
    return TTSConstants.supportedLanguageCodes;
  }

  /// Get supported language options
  List<LanguageOption> getSupportedLanguages() {
    return TTSConstants.supportedLanguages;
  }

  /// Get language option by code
  LanguageOption? getLanguageByCode(String code) {
    return TTSConstants.getLanguageByCode(code);
  }

  /// Update TTS configuration
  Future<void> updateConfig(TTSConfig config) async {
    if (!_isInitialized) {
      throw const TTSNotInitializedException();
    }

    await _applyConfig(config);
  }

  /// Get current speech rate
  double getSpeechRate() => _currentConfig.speechRate;

  /// Get current volume
  double getVolume() => _currentConfig.volume;

  /// Get current pitch
  double getPitch() => _currentConfig.pitch;

  /// Get current language code
  String getLanguageCode() => _currentConfig.languageCode;

  /// Check if TTS is currently speaking
  bool get isSpeaking => _currentState == TTSState.playing;

  /// Check if TTS is paused
  bool get isPaused => _currentState == TTSState.paused;

  /// Check if TTS is stopped
  bool get isStopped => _currentState == TTSState.stopped;

  /// Dispose of TTS resources
  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
      _currentState = TTSState.stopped;
      _isInitialized = false;
    }
  }
}