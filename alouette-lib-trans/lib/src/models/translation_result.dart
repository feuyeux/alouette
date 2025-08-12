import 'llm_config.dart';

/// Translation result model containing the original text and all translations
class TranslationResult {
  /// The original text that was translated
  final String original;
  
  /// Map of language codes to translated text
  final Map<String, String> translations;
  
  /// List of target languages that were requested
  final List<String> languages;
  
  /// Timestamp when the translation was completed
  final DateTime timestamp;
  
  /// The LLM configuration used for this translation
  final LLMConfig config;
  
  /// Optional metadata about the translation process
  final Map<String, dynamic>? metadata;

  const TranslationResult({
    required this.original,
    required this.translations,
    required this.languages,
    required this.timestamp,
    required this.config,
    this.metadata,
  });

  /// Create from JSON representation
  factory TranslationResult.fromJson(Map<String, dynamic> json, LLMConfig config) {
    return TranslationResult(
      original: json['original'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      languages: List<String>.from(json['languages'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      config: config,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'translations': translations,
      'languages': languages,
      'timestamp': timestamp.toIso8601String(),
      'config': config.toJson(),
      'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  TranslationResult copyWith({
    String? original,
    Map<String, String>? translations,
    List<String>? languages,
    DateTime? timestamp,
    LLMConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    return TranslationResult(
      original: original ?? this.original,
      translations: translations ?? this.translations,
      languages: languages ?? this.languages,
      timestamp: timestamp ?? this.timestamp,
      config: config ?? this.config,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get translation for a specific language
  String? getTranslation(String languageCode) {
    return translations[languageCode];
  }

  /// Check if translation exists for a language
  bool hasTranslation(String languageCode) {
    return translations.containsKey(languageCode) && 
           translations[languageCode]?.isNotEmpty == true;
  }

  /// Get all available language codes with translations
  List<String> get availableLanguages {
    return translations.keys.where((lang) => translations[lang]?.isNotEmpty == true).toList();
  }

  /// Check if all requested languages have translations
  bool get isComplete {
    return languages.every((lang) => hasTranslation(lang));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationResult &&
        other.original == original &&
        other.translations.length == translations.length &&
        other.translations.keys.every((key) => translations[key] == other.translations[key]) &&
        other.languages.length == languages.length &&
        other.languages.every((lang) => languages.contains(lang)) &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      original,
      Object.hashAll(translations.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAll(languages),
      timestamp,
    );
  }

  @override
  String toString() {
    return 'TranslationResult(original: ${original.length > 30 ? '${original.substring(0, 30)}...' : original}, '
           'languages: $languages, translations: ${translations.length})';
  }
}