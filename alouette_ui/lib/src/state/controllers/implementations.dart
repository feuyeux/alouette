/// Concrete implementations of common UI controllers
library alouette_ui.state.controllers.implementations;

import 'dart:async';
import 'package:alouette_lib_tts/alouette_tts.dart' as lib_tts;
import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;

import '../../../alouette_ui.dart';

/// Translation controller implementation
class TranslationController extends BaseStateController
    implements ITranslationController {
  final trans_lib.TranslationService _translationService;
  final StreamController<Map<String, String>> _translationController =
      StreamController<Map<String, String>>.broadcast();

  String _inputText = '';
  String? _sourceLanguage;
  final List<String> _targetLanguages = [];
  final Map<String, String> _translations = {};

  TranslationController(this._translationService);

  @override
  String get inputText => _inputText;

  @override
  set inputText(String value) {
    ensureNotDisposed();
    if (_inputText != value) {
      _inputText = value;
      clearTranslations();
    }
  }

  @override
  String? get sourceLanguage => _sourceLanguage;

  @override
  List<String> get targetLanguages => List.unmodifiable(_targetLanguages);

  @override
  Map<String, String> get translations => Map.unmodifiable(_translations);

  @override
  Stream<Map<String, String>> get translationStream =>
      _translationController.stream;

  @override
  void setSourceLanguage(String? languageCode) {
    ensureNotDisposed();
    if (_sourceLanguage != languageCode) {
      _sourceLanguage = languageCode;
      clearTranslations();
    }
  }

  @override
  void setTargetLanguages(List<String> languageCodes) {
    ensureNotDisposed();
    _targetLanguages.clear();
    _targetLanguages.addAll(languageCodes);
    clearTranslations();
  }

  @override
  Future<void> translate() async {
    ensureNotDisposed();

    if (_inputText.isEmpty) {
      setError('Input text cannot be empty');
      return;
    }

    if (_targetLanguages.isEmpty) {
      setError('Please select at least one target language');
      return;
    }

    await executeAsync(() async {
      try {
        // Use the new translateWithAutoConfig method
        final result = await _translationService.translateWithAutoConfig(
          _inputText,
          _targetLanguages,
        );

        _translations.clear();
        _translations.addAll(result.translations);
        _translationController.add(translations);
      } catch (e) {
        // Handle translation error
        final errorResults = <String, String>{};
        for (final targetLang in _targetLanguages) {
          errorResults[targetLang] = 'Translation failed: $e';
        }
        _translations.clear();
        _translations.addAll(errorResults);
        _translationController.add(translations);
      }
    });
  }

  @override
  void clearTranslations() {
    ensureNotDisposed();
    if (_translations.isNotEmpty) {
      _translations.clear();
      _translationController.add(translations);
    }
  }

  @override
  void onDispose() {
    _translationController.close();
    super.onDispose();
  }
}

/// TTS controller implementation - simplified to use lib layer directly
class TTSController extends BaseStateController implements ITTSController {
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _pausedController =
      StreamController<bool>.broadcast();

  String _text = '';
  String? _selectedVoice;
  String? _languageCode;
  List<String> _availableVoices = [];
  bool _isSpeaking = false;
  bool _isPaused = false;
  // Controller uses 0.0-1.0 range where 0.5 = normal (0% adjustment)
  // For Edge TTS: rate/pitch are mapped to -50% to +50% around 0.5 midpoint
  double _speechRate = 1.0; // 1.0 = normal speed (1.0x)
  double _speechPitch = 1.0; // 1.0 = normal pitch (1.0x)
  double _speechVolume = 1.0; // 1.0 = 100% volume

  // Use lib layer directly
  late final dynamic _libTTSService;

  TTSController() {
    _initializeLibService();
  }

  Future<void> _initializeLibService() async {
    try {
      _libTTSService = lib_tts.TTSService();
      await _libTTSService.initialize();
      await _initializeVoices();
      // Reset error state after successful initialization (handles hot reload residual errors)
      try {
        clearError();
      } catch (_) {}
    } catch (e) {
      setError('Failed to initialize TTS service: $e');
    }
  }

  @override
  String get text => _text;

  @override
  set text(String value) {
    ensureNotDisposed();
    _text = value;
  }

  @override
  String? get selectedVoice => _selectedVoice;

  @override
  String? get languageCode => _languageCode;

  @override
  List<String> get availableVoices => List.unmodifiable(_availableVoices);

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  @override
  double get speechRate => _speechRate;

  @override
  double get speechPitch => _speechPitch;

  @override
  double get speechVolume => _speechVolume;

  @override
  Stream<bool> get speakingStream => _speakingController.stream;

  @override
  Stream<bool> get pausedStream => _pausedController.stream;

  @override
  void setVoice(String voiceId) {
    ensureNotDisposed();
    _selectedVoice = voiceId;
  }

  @override
  void setLanguageCode(String? languageCode) {
    ensureNotDisposed();
    _languageCode = languageCode;
  }

  @override
  void setSpeechRate(double rate) {
    ensureNotDisposed();
    _speechRate = rate.clamp(0.0, 1.0);
    // Parameter will be passed directly in speak() via TTSRequest
  }

  @override
  void setSpeechPitch(double pitch) {
    ensureNotDisposed();
    _speechPitch = pitch.clamp(0.0, 1.0);
    // Parameter will be passed directly in speak() via TTSRequest
  }

  @override
  void setSpeechVolume(double volume) {
    ensureNotDisposed();
    _speechVolume = volume.clamp(0.0, 1.0);
    // Parameter will be passed directly in speak() via TTSRequest
  }

  @override
  Future<void> speak() async {
    ensureNotDisposed();
    // Reset residual TTS error state before starting a new speak action
    clearError();

    if (_text.isEmpty) {
      setError('Text cannot be empty');
      return;
    }

    await executeAsync(() async {
      _setSpeaking(true);
      _setPaused(false);

      // Use lib layer directly - parameters passed via TTSRequest
      await _libTTSService.speakText(
        _text,
        voiceName: _selectedVoice,
        languageName: _languageCode,
        format: 'audio-24khz-48kbitrate-mono-mp3',
        rate: _speechRate,
        pitch: _speechPitch,
        volume: _speechVolume,
      );

      _setSpeaking(false);
    });
  }

  @override
  Future<void> speakWithLanguage(String languageCode) async {
    ensureNotDisposed();
    // Reset residual TTS error state before starting a new speak action
    clearError();

    if (_text.isEmpty) {
      setError('Text cannot be empty');
      return;
    }

    await executeAsync(() async {
      _setSpeaking(true);
      _setPaused(false);

      // Use lib layer directly
      await _libTTSService.speakText(
        _text,
        languageCode: languageCode,
        rate: _speechRate,
        pitch: _speechPitch,
        volume: _speechVolume,
      );

      _setSpeaking(false);
    });
  }

  @override
  Future<void> pause() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _libTTSService.pause();
      _setPaused(true);
    });
  }

  @override
  Future<void> resume() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _libTTSService.resume();
      _setPaused(false);
    });
  }

  @override
  Future<void> stop() async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _libTTSService.stop();
      _setSpeaking(false);
      _setPaused(false);
    });
  }

  // Switch TTS engine and reset error state after successful switch
  Future<void> switchEngine(lib_tts.TTSEngineType engine) async {
    ensureNotDisposed();
    await executeAsync(() async {
      await _libTTSService.switchEngine(engine);
      try {
        clearError();
      } catch (_) {}
    });
  }

  Future<void> _initializeVoices() async {
    try {
      final voices = await _libTTSService.getVoices();

      // Handle VoiceModel objects from lib layer
      if (voices is List) {
        _availableVoices = voices.map((voice) {
          // Extract id from VoiceModel objects
          if (voice != null && voice.toString().contains('id: ')) {
            // Parse VoiceModel string to extract id
            final voiceStr = voice.toString();
            final idMatch = RegExp(r'id: ([^,)]+)').firstMatch(voiceStr);
            if (idMatch != null) {
              return idMatch.group(1)!;
            }
          }
          return voice.toString();
        }).toList();
      } else {
        throw Exception('Unexpected voices format: ${voices.runtimeType}');
      }

      if (_availableVoices.isNotEmpty && _selectedVoice == null) {
        // Prefer an English voice by default
        final enVoice = _availableVoices.firstWhere(
          (v) => v.toString().startsWith('en-US'),
          orElse: () => _availableVoices.first,
        );
        _selectedVoice = enVoice;
        // Also set language to en-US if not already chosen
        _languageCode ??= 'en-US';
      }
    } catch (e) {
      setError('Failed to load voices: $e');
    }
  }

  void _setSpeaking(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      _speakingController.add(speaking);
    }
  }

  void _setPaused(bool paused) {
    if (_isPaused != paused) {
      _isPaused = paused;
      _pausedController.add(paused);
    }
  }

  @override
  void onDispose() {
    _speakingController.close();
    _pausedController.close();
    super.onDispose();
  }
}

/// Language selection controller implementation
class LanguageSelectionController extends BaseSelectionController<String> {
  final List<String> _availableLanguages;

  LanguageSelectionController(this._availableLanguages);

  List<String> get availableLanguages => List.unmodifiable(_availableLanguages);

  /// Select languages by their codes
  void selectLanguageCodes(List<String> codes) {
    ensureNotDisposed();
    clearSelection();
    for (final code in codes) {
      if (_availableLanguages.contains(code)) {
        select(code);
      }
    }
  }

  /// Check if a language is available
  bool isLanguageAvailable(String languageCode) {
    return _availableLanguages.contains(languageCode);
  }
}

/// Form controller implementation
class FormController extends BaseStateController implements IFormController {
  final StreamController<Map<String, dynamic>> _valuesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _formValidationController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, String>> _fieldErrorsController =
      StreamController<Map<String, String>>.broadcast();

  final Map<String, dynamic> _values = {};
  final Map<String, String> _fieldErrors = {};
  final Map<String, bool Function(dynamic)> _validators = {};

  @override
  Map<String, dynamic> get values => Map.unmodifiable(_values);

  @override
  Stream<Map<String, dynamic>> get valuesStream => _valuesController.stream;

  @override
  bool get isFormValid => _fieldErrors.isEmpty && _values.isNotEmpty;

  @override
  Stream<bool> get formValidationStream => _formValidationController.stream;

  @override
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  @override
  Stream<Map<String, String>> get fieldErrorsStream =>
      _fieldErrorsController.stream;

  /// Add a validator for a field
  void addValidator(String fieldName, bool Function(dynamic) validator) {
    ensureNotDisposed();
    _validators[fieldName] = validator;
  }

  /// Remove a validator for a field
  void removeValidator(String fieldName) {
    ensureNotDisposed();
    _validators.remove(fieldName);
  }

  @override
  T? getValue<T>(String fieldName) {
    final value = _values[fieldName];
    return value is T ? value : null;
  }

  @override
  void setValue(String fieldName, dynamic value) {
    ensureNotDisposed();
    _values[fieldName] = value;
    _valuesController.add(values);
    validateField(fieldName);
  }

  @override
  bool validateField(String fieldName) {
    ensureNotDisposed();

    final validator = _validators[fieldName];
    if (validator == null) {
      _fieldErrors.remove(fieldName);
      _notifyFieldErrors();
      return true;
    }

    final value = _values[fieldName];
    try {
      if (validator(value)) {
        _fieldErrors.remove(fieldName);
        _notifyFieldErrors();
        _notifyFormValidation();
        return true;
      } else {
        _fieldErrors[fieldName] = 'Invalid value';
        _notifyFieldErrors();
        _notifyFormValidation();
        return false;
      }
    } catch (e) {
      _fieldErrors[fieldName] = e.toString();
      _notifyFieldErrors();
      _notifyFormValidation();
      return false;
    }
  }

  @override
  bool validateForm() {
    ensureNotDisposed();

    bool isValid = true;
    for (final fieldName in _validators.keys) {
      if (!validateField(fieldName)) {
        isValid = false;
      }
    }
    return isValid;
  }

  @override
  void reset() {
    ensureNotDisposed();
    _values.clear();
    _fieldErrors.clear();
    _valuesController.add(values);
    _fieldErrorsController.add(fieldErrors);
    _formValidationController.add(isFormValid);
  }

  @override
  Future<void> submit() async {
    ensureNotDisposed();

    if (!validateForm()) {
      setError('Please fix form errors before submitting');
      return;
    }

    await executeAsync(() async {
      // Override this method to implement form submission
      await onSubmit(values);
    });
  }

  /// Override this method to implement custom form submission logic
  Future<void> onSubmit(Map<String, dynamic> formData) async {
    // Default implementation does nothing
  }

  void _notifyFieldErrors() {
    _fieldErrorsController.add(fieldErrors);
  }

  void _notifyFormValidation() {
    _formValidationController.add(isFormValid);
  }

  @override
  void onDispose() {
    _valuesController.close();
    _formValidationController.close();
    _fieldErrorsController.close();
    super.onDispose();
  }
}

/// Search controller implementation
class SearchController extends BaseStateController
    implements ISearchController {
  final StreamController<List<dynamic>> _resultsController =
      StreamController<List<dynamic>>.broadcast();

  String _query = '';
  final List<dynamic> _results = [];
  bool _hasMoreResults = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  String get query => _query;

  @override
  set query(String value) {
    ensureNotDisposed();
    if (_query != value) {
      _query = value;
      _results.clear();
      _currentPage = 0;
      _hasMoreResults = false;
      _resultsController.add(results);
    }
  }

  @override
  List<dynamic> get results => List.unmodifiable(_results);

  @override
  Stream<List<dynamic>> get resultsStream => _resultsController.stream;

  @override
  bool get hasMoreResults => _hasMoreResults;

  @override
  Future<void> search() async {
    ensureNotDisposed();

    if (_query.isEmpty) {
      _results.clear();
      _resultsController.add(results);
      return;
    }

    await executeAsync(() async {
      _currentPage = 0;
      final searchResults = await performSearch(
        _query,
        _currentPage,
        _pageSize,
      );
      _results.clear();
      _results.addAll(searchResults);
      _hasMoreResults = searchResults.length == _pageSize;
      _resultsController.add(results);
    });
  }

  @override
  Future<void> loadMore() async {
    ensureNotDisposed();

    if (!_hasMoreResults || isLoading) return;

    await executeAsync(() async {
      _currentPage++;
      final searchResults = await performSearch(
        _query,
        _currentPage,
        _pageSize,
      );
      _results.addAll(searchResults);
      _hasMoreResults = searchResults.length == _pageSize;
      _resultsController.add(results);
    });
  }

  @override
  void clearSearch() {
    ensureNotDisposed();
    _query = '';
    _results.clear();
    _currentPage = 0;
    _hasMoreResults = false;
    _resultsController.add(results);
  }

  /// Override this method to implement custom search logic
  Future<List<dynamic>> performSearch(
    String query,
    int page,
    int pageSize,
  ) async {
    // Default implementation returns empty list
    return [];
  }

  @override
  void onDispose() {
    _resultsController.close();
    super.onDispose();
  }
}
