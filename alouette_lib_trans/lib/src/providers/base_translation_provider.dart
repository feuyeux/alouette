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

  /// Get default configuration for this provider
  LLMConfig getDefaultConfig() {
    return LLMConfig(
      provider: providerName,
      serverUrl: 'http://localhost:11434',
      selectedModel: '',
    );
  }

  /// Get the system prompt for translation
  String getSystemPrompt(String targetLanguage) {
    final explicitLang = getExplicitLanguageSpec(targetLanguage);
    return '''You are a professional translator. Translate the following text to $explicitLang.

CRITICAL REQUIREMENTS:
- Output ONLY the translated text - nothing else
- NO explanations, NO thinking process, NO meta-commentary
- NO emojis, NO symbols
- Use natural, idiomatic expressions that native speakers would use
- Maintain the original meaning and tone
- Do NOT add any prefixes like "Translation:", "Output:", or similar
- Do NOT wrap the translation in quotes or any markers
- NEVER use <thinking> tags or any XML-style tags
- NEVER output any thinking process or reasoning
- NEVER show your internal thoughts or analysis

Examples:
- "hello" → "你好" (Chinese) / "こんにちは" (Japanese) / "안녕하세요" (Korean) / "Привет" (Russian)
- "thank you" → "谢谢" (Chinese) / "ありがとう" (Japanese) / "감사합니다" (Korean) / "Спасибо" (Russian)

Now translate to $explicitLang:''';
  }

  /// Get explicit language specification to avoid confusion
  String getExplicitLanguageSpec(String targetLang) {
    // Normalize: lowercase and extract primary language code
    // Handles formats: 'ko-KR' -> 'ko', 'Korean' -> 'korean', 'KO' -> 'ko'
    final normalized = targetLang.toLowerCase().trim();
    final lang = normalized.split('-').first.split('_').first;

    switch (lang) {
      // Chinese variants
      case 'chinese':
      case 'zh':
      case 'cn':
      case 'chs':
      case 'simplified chinese':
        return 'Simplified Chinese (中文)';
      case 'traditional chinese':
      case 'zh-tw':
      case 'tw':
      case 'cht':
        return 'Traditional Chinese (繁体中文)';

      // English
      case 'english':
      case 'en':
        return 'English';

      // Japanese
      case 'japanese':
      case 'ja':
      case 'jp':
      case 'jpn':
        return 'Japanese (日本語)';

      // Korean - 关键修复！
      case 'korean':
      case 'ko':
      case 'kr':
      case 'kor':
        return 'Korean (한국어)';

      // French
      case 'french':
      case 'français':
      case 'francais':
      case 'fr':
      case 'fra':
        return 'French (Français)';

      // German
      case 'german':
      case 'deutsch':
      case 'de':
      case 'deu':
      case 'ger':
        return 'German (Deutsch)';

      // Spanish
      case 'spanish':
      case 'español':
      case 'espanol':
      case 'es':
      case 'spa':
        return 'Spanish (Español)';

      // Italian
      case 'italian':
      case 'italiano':
      case 'it':
      case 'ita':
        return 'Italian (Italiano)';

      // Russian
      case 'russian':
      case 'русский':
      case 'ru':
      case 'rus':
        return 'Russian (Русский)';

      // Arabic
      case 'arabic':
      case 'ar':
      case 'ara':
      case 'sa':
        return 'Arabic (العربية)';

      // Hindi
      case 'hindi':
      case 'हिन्दी':
      case 'hi':
      case 'hin':
      case 'in':
        return 'Hindi (हिन्दी)';

      // Greek
      case 'greek':
      case 'ελληνικά':
      case 'el':
      case 'gr':
      case 'gre':
      case 'ell':
        return 'Greek (Ελληνικά)';

      // Portuguese
      case 'portuguese':
      case 'português':
      case 'portugues':
      case 'pt':
      case 'por':
        return 'Portuguese (Português)';

      // Dutch
      case 'dutch':
      case 'nederlands':
      case 'nl':
      case 'nld':
      case 'dut':
        return 'Dutch (Nederlands)';

      // Polish
      case 'polish':
      case 'polski':
      case 'pl':
      case 'pol':
        return 'Polish (Polski)';

      // Turkish
      case 'turkish':
      case 'türkçe':
      case 'turkce':
      case 'tr':
      case 'tur':
        return 'Turkish (Türkçe)';

      // Swedish
      case 'swedish':
      case 'svenska':
      case 'sv':
      case 'swe':
        return 'Swedish (Svenska)';

      // Default fallback
      default:
        // Try to extract meaningful language name from input
        if (normalized.length > 2) {
          // Likely a full name like "Korean" or "Japanese"
          return '${targetLang[0].toUpperCase()}${targetLang.substring(1)}';
        }
        return 'Translate to $targetLang language';
    }
  }
}
