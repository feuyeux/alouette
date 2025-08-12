import '../models/llm_config.dart';
import '../models/translation_request.dart';
import '../models/translation_result.dart';
import '../providers/translation_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/lmstudio_provider.dart';
import '../exceptions/translation_exceptions.dart';

/// Core translation service that handles text translation operations
class TranslationService {
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;
  
  final Map<String, TranslationProvider> _providers = {
    'ollama': OllamaProvider(),
    'lmstudio': LMStudioProvider(),
  };

  /// Get the current translation result
  TranslationResult? get currentTranslation => _currentTranslation;
  
  /// Check if a translation is currently in progress
  bool get isTranslating => _isTranslating;

  /// Translate text to multiple target languages
  Future<TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
  }) async {
    // Validation
    if (inputText.trim().isEmpty) {
      throw TranslationException('Please enter text to translate');
    }

    if (targetLanguages.isEmpty) {
      throw TranslationException('Please select at least one target language');
    }

    if (config.serverUrl.isEmpty || config.selectedModel.isEmpty) {
      throw TranslationException('Please configure LLM settings first');
    }

    final provider = _getProvider(config.provider);
    if (provider == null) {
      throw TranslationException('Unsupported provider: ${config.provider}');
    }

    _isTranslating = true;
    
    try {
      final translations = <String, String>{};
      final cleanedText = inputText.trim();

      // Translate to each target language
      for (int i = 0; i < targetLanguages.length; i++) {
        final language = targetLanguages[i];
        
        final translation = await provider.translateText(
          text: cleanedText,
          targetLanguage: language,
          config: config,
          additionalParams: additionalParams,
        );

        translations[language] = translation;
      }

      _currentTranslation = TranslationResult(
        original: cleanedText,
        translations: translations,
        languages: targetLanguages,
        timestamp: DateTime.now(),
        config: config,
        metadata: {
          'provider': config.provider,
          'model': config.selectedModel,
          'translationCount': translations.length,
        },
      );

      return _currentTranslation!;
    } catch (error) {
      // Re-throw known exceptions
      if (error is TranslationException) {
        rethrow;
      }
      
      // Wrap unknown errors
      throw TranslationException('Translation failed: ${error.toString()}');
    } finally {
      _isTranslating = false;
    }
  }

  /// Create a translation request from the given parameters
  TranslationRequest createRequest(
    String text,
    List<String> targetLanguages,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
  }) {
    return TranslationRequest(
      text: text,
      targetLanguages: targetLanguages,
      provider: config.provider,
      serverUrl: config.serverUrl,
      modelName: config.selectedModel,
      apiKey: config.apiKey,
      additionalParams: additionalParams,
    );
  }

  /// Get the translation provider for the given provider name
  TranslationProvider? _getProvider(String providerName) {
    return _providers[providerName.toLowerCase()];
  }

  /// Register a custom translation provider
  void registerProvider(String name, TranslationProvider provider) {
    _providers[name.toLowerCase()] = provider;
  }

  /// Get all available provider names
  List<String> get availableProviders => _providers.keys.toList();

  /// Check if a provider is supported
  bool isProviderSupported(String providerName) {
    return _providers.containsKey(providerName.toLowerCase());
  }

  /// Clear the current translation
  void clearTranslation() {
    _currentTranslation = null;
  }

  /// Get the current translation state
  Map<String, dynamic> getTranslationState() {
    return {
      'isTranslating': _isTranslating,
      'hasTranslation': _currentTranslation != null,
      'currentTranslation': _currentTranslation?.toJson(),
    };
  }

  /// Format translation result for display
  Map<String, dynamic>? formatForDisplay([TranslationResult? translation]) {
    final trans = translation ?? _currentTranslation;
    if (trans == null) return null;

    return {
      'original': trans.original,
      'translations': trans.translations,
      'languages': trans.languages,
      'timestamp': trans.timestamp.toLocal().toString(),
      'model': trans.config.selectedModel,
      'provider': trans.config.provider,
      'isComplete': trans.isComplete,
      'availableLanguages': trans.availableLanguages,
    };
  }

  /// Get translation statistics
  Map<String, dynamic> getTranslationStats([TranslationResult? translation]) {
    final trans = translation ?? _currentTranslation;
    if (trans == null) {
      return {
        'totalTranslations': 0,
        'completedTranslations': 0,
        'completionRate': 0.0,
      };
    }

    final completed = trans.availableLanguages.length;
    final total = trans.languages.length;
    
    return {
      'totalTranslations': total,
      'completedTranslations': completed,
      'completionRate': total > 0 ? completed / total : 0.0,
      'originalLength': trans.original.length,
      'averageTranslationLength': completed > 0 
          ? trans.translations.values
              .where((t) => t.isNotEmpty)
              .map((t) => t.length)
              .reduce((a, b) => a + b) / completed
          : 0.0,
    };
  }
}