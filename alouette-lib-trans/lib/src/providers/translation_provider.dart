import '../models/llm_config.dart';
import '../models/connection_status.dart';

/// Abstract interface for translation providers
abstract class TranslationProvider {
  /// The provider name (e.g., 'ollama', 'lmstudio')
  String get providerName;

  /// Translate text to a specific target language
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    required LLMConfig config,
    Map<String, dynamic>? additionalParams,
  });

  /// Test connection to the provider
  Future<ConnectionStatus> testConnection(LLMConfig config);

  /// Get available models from the provider
  Future<List<String>> getAvailableModels(LLMConfig config);

  /// Check if the provider supports the given configuration
  bool supportsConfig(LLMConfig config) {
    return config.provider == providerName;
  }

  /// Get the system prompt for translation
  String getSystemPrompt(String targetLanguage) {
    final explicitLang = getExplicitLanguageSpec(targetLanguage);
    return '''You are a professional translator. Translate the given text directly to $explicitLang. 
Requirements:
- Provide ONLY the translation, no explanations
- Maintain the original meaning and tone
- Use natural, fluent language
- Do not include phrases like "Translation:" or any prefixes''';
  }

  /// Get explicit language specification to avoid confusion
  String getExplicitLanguageSpec(String targetLang) {
    switch (targetLang.toLowerCase()) {
      case 'chinese':
      case 'zh':
      case 'cn':
        return 'Simplified Chinese (中文)';
      case 'traditional chinese':
      case 'zh-tw':
        return 'Traditional Chinese (繁体中文)';
      case 'english':
      case 'en':
        return 'English';
      case 'japanese':
      case 'ja':
      case 'jp':
        return 'Japanese (日本語)';
      case 'korean':
      case 'ko':
      case 'kr':
        return 'Korean (한국어)';
      case 'french':
      case 'fr':
        return 'French (Français)';
      case 'german':
      case 'de':
        return 'German (Deutsch)';
      case 'spanish':
      case 'es':
        return 'Spanish (Español)';
      case 'italian':
      case 'it':
        return 'Italian (Italiano)';
      case 'russian':
      case 'ru':
        return 'Russian (Русский)';
      case 'arabic':
      case 'ar':
        return 'Arabic (العربية)';
      case 'hindi':
      case 'hi':
        return 'Hindi (हिन्दी)';
      case 'greek':
      case 'el':
        return 'Greek (Ελληνικά)';
      default:
        return targetLang;
    }
  }
}