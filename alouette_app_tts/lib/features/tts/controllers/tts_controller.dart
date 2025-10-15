import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart' as tts_lib;
import 'package:alouette_ui/alouette_ui.dart';
import '../../../config/tts_app_config.dart';

/// Controller for TTS functionality using UnifiedTTSService from ServiceLocator
class TTSController extends ChangeNotifier {
  // Current TTS service (direct library type)
  tts_lib.TTSService? _ttsService;

  // State variables
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentVoice;
  List<tts_lib.VoiceModel> _availableVoices = [];
  tts_lib.TTSEngineType? _currentEngine;

  // TTS parameters
  double _rate = TTSAppConfig.defaultTTSConfig.speechRate;
  double _pitch = TTSAppConfig.defaultTTSConfig.pitch;
  double _volume = TTSAppConfig.defaultTTSConfig.volume;

  // Error handling
  String? _lastError;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  String? get currentVoice => _currentVoice;
  List<tts_lib.VoiceModel> get availableVoices => _availableVoices;
  tts_lib.TTSEngineType? get currentEngine => _currentEngine;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String? get lastError => _lastError;

  /// Initialize TTS service using UI ServiceManager
  Future<void> initialize() async {
    try {
      _clearError();
      // Get TTS service
      _ttsService = ServiceManager.getTTSService();
      // Initialize if not already initialized
      if (!_ttsService!.isInitialized) {
        await _ttsService!.initialize(
          autoFallback: TTSAppConfig.enableAutoFallback,
        );
      }

      // Load available voices
      await _loadVoices();

      // Update current engine
      _currentEngine = _ttsService!.currentEngine;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize TTS: $e');
      _isInitialized = true; // Set to true to show error state
      notifyListeners();
    }
  }

  /// Load available voices
  Future<void> _loadVoices() async {
    try {
      _availableVoices = await _ttsService!.getVoices();

      // Set default voice if none selected
      if (_currentVoice == null && _availableVoices.isNotEmpty) {
        // Prefer en-US if exists
        final en = _availableVoices.firstWhere(
          (v) => v.languageCode == 'en-US',
          orElse: () => _availableVoices.first,
        );
        _currentVoice = en.id;
      }
    } catch (e) {
      _setError('Failed to load voices: $e');
    }
  }

  /// Speak the provided text
  Future<void> speakText(String text) async {
    if (!_isInitialized || _ttsService == null || text.trim().isEmpty) {
      return;
    }

    try {
      _clearError();
      _isPlaying = true;
      notifyListeners();

      // Speak the text
      await _ttsService!.speakText(
        text,
        voiceName: _currentVoice,
        rate: _rate,
        volume: _volume,
        pitch: _pitch,
      );

      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      _isPlaying = false;
      _setError('Failed to speak text: $e');
      notifyListeners();
    }
  }

  /// Stop current TTS operation
  Future<void> stopSpeaking() async {
    if (!_isInitialized || _ttsService == null) {
      return;
    }

    try {
      await _ttsService!.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop TTS: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Change the current voice
  Future<void> changeVoice(String voiceId) async {
    if (_currentVoice == voiceId) return;

    _currentVoice = voiceId;
    notifyListeners();
  }

  /// Update speech rate
  Future<void> updateRate(double newRate) async {
    if (_rate == newRate) return;

    _rate = newRate.clamp(TTSAppConfig.minRate, TTSAppConfig.maxRate);

    // rate applied in speak()

    notifyListeners();
  }

  /// Update pitch
  Future<void> updatePitch(double newPitch) async {
    if (_pitch == newPitch) return;

    _pitch = newPitch.clamp(TTSAppConfig.minPitch, TTSAppConfig.maxPitch);

    // pitch applied in speak()

    notifyListeners();
  }

  /// Update volume
  Future<void> updateVolume(double newVolume) async {
    if (_volume == newVolume) return;

    _volume = newVolume.clamp(TTSAppConfig.minVolume, TTSAppConfig.maxVolume);

    // volume applied in speak()

    notifyListeners();
  }

  /// Switch TTS engine
  Future<void> switchEngine(tts_lib.TTSEngineType engineType) async {
    if (!_isInitialized ||
        _ttsService == null ||
        _currentEngine == engineType) {
      return;
    }

    try {
      _clearError();

      await _ttsService!.switchEngine(engineType);

      _currentEngine = engineType;

      // Reload voices for new engine
      await _loadVoices();

      notifyListeners();
    } catch (e) {
      _setError('Failed to switch engine: $e');
      notifyListeners();
    }
  }

  /// Get platform information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    // TTSServiceContract does not expose platform info in this refactor;
    // return minimal info to populate the dialog consistently
    return {
      'platform': 'desktop',
      'currentBackend': _currentEngine?.name,
      'supportedEngines': <String>[],
      'availableEngines': <String>[],
      'recommendedEngine': _currentEngine?.name,
      'isDesktop': true,
      'isMobile': false,
      'isWeb': false,
      'supportsProcessExecution': false,
      'supportsFileSystem': true,
    };
  }

  // Parameters are passed directly to speak(); no separate update step needed

  /// Set error message
  void _setError(String error) {
    _lastError = error;
  }

  /// Clear error message
  void _clearError() {
    _lastError = null;
  }

  @override
  void dispose() {
    // Don't dispose the TTS service as it's managed by ServiceLocator
    // and might be used by other parts of the application
    super.dispose();
  }
}
