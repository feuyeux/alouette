/// Language constants for Alouette applications
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String _emojiFlag;
  final int order;
  final String sampleText;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required String flag,
    required this.order,
    required this.sampleText,
  }) : _emojiFlag = flag;

  /// Get platform-appropriate flag representation
  String get flag => _emojiFlag;

  /// Get short 2-character language code (e.g., 'ZH', 'EN', 'JA')
  String get shortCode {
    // Extract language code (first part before '-') and convert to uppercase
    final parts = code.split('-');
    if (parts.isNotEmpty) {
      return parts[0].toUpperCase();
    }
    return code.substring(0, 2).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageOption &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class LanguageConstants {
  /// Supported languages with comprehensive information
  /// Order matches the main README.md documentation
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'zh-CN',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
      order: 1,
      sampleText: '中文。这是中文语音合成技术的演示。',
    ),
    LanguageOption(
      code: 'en-US',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      order: 2,
      sampleText: 'English. This is a demonstration of TTS in English.',
    ),
    LanguageOption(
      code: 'de-DE',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      order: 3,
      sampleText: 'Deutsch. Dies ist eine Demonstration der deutschen Sprachsynthese-Technologie.',
    ),
    LanguageOption(
      code: 'fr-FR',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      order: 4,
      sampleText: 'Français. Ceci est une démonstration de la technologie de synthèse vocale française.',
    ),
    LanguageOption(
      code: 'es-ES',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      order: 5,
      sampleText: 'Español. Esta es una demostración de la tecnología de síntesis de voz en español.',
    ),
    LanguageOption(
      code: 'it-IT',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      order: 6,
      sampleText: 'Italiano. Questa è una dimostrazione della tecnologia di sintesi vocale italiana.',
    ),
    LanguageOption(
      code: 'ru-RU',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
      order: 7,
      sampleText: 'Русский. Это демонстрация технологии синтеза речи на русском языке.',
    ),
    LanguageOption(
      code: 'el-GR',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      flag: '🇬🇷',
      order: 8,
      sampleText: 'Ελληνικά. Αυτή είναι μια επίδειξη της τεχνολογίας σύνθεσης ομιλίας στα ελληνικά.',
    ),
    LanguageOption(
      code: 'ar-SA',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      order: 9,
      sampleText: 'العربية. هذا عرض توضيحي لتقنية تحويل النص إلى كلام باللغة العربية.',
    ),
    LanguageOption(
      code: 'hi-IN',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      order: 10,
      sampleText: 'हिन्दी. यह हिंदी भाषा में टेक्स्ट-टू-स्पीच तकनीक का प्रदर्शन है।',
    ),
    LanguageOption(
      code: 'ja-JP',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
      order: 11,
      sampleText: '日本語。これは日本語音声合成技術のデモンストレーションです。',
    ),
    LanguageOption(
      code: 'ko-KR',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
      order: 12,
      sampleText: '한국어. 이것은 한국어 음성 합성 기술의 시연입니다。',
    ),
  ];

  static const LanguageOption defaultLanguage = LanguageOption(
    code: 'en-US',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    order: 2,
    sampleText: 'English. This is a demonstration of TTS in English.',
  );

  /// Default selected languages for translation
  static const List<String> defaultSelectedLanguages = ['English'];

  /// Get language option by code
  static LanguageOption? getLanguageByCode(String code) {
    try {
      final key = code.toLowerCase();
      return supportedLanguages.firstWhere(
        (lang) => lang.code.toLowerCase() == key,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get language option by name
  static LanguageOption? getLanguageByName(String name) {
    try {
      return supportedLanguages.firstWhere(
        (lang) => lang.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get translation language names mapping
  static Map<String, String> get translationLanguageNames {
    return Map.fromEntries(
      supportedLanguages.map((lang) => MapEntry(lang.code, lang.name)),
    );
  }

  /// Get list of language names only
  static List<String> get languageNames {
    return supportedLanguages.map((lang) => lang.name).toList();
  }

  /// Get list of language codes only
  static List<String> get languageCodes {
    return supportedLanguages.map((lang) => lang.code).toList();
  }
}
