import 'llm_config.dart';

/// Translation result model containing the original text and all translations
///
/// This is the standardized data model used across all Alouette applications
/// for translation results. It includes comprehensive validation and serialization.
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

  /// Whether the translation was successful
  final bool isSuccessful;

  /// Error message if translation failed
  final String? errorMessage;

  const TranslationResult({
    required this.original,
    required this.translations,
    required this.languages,
    required this.timestamp,
    required this.config,
    this.metadata,
    this.isSuccessful = true,
    this.errorMessage,
  });

  /// Create a successful translation result
  factory TranslationResult.success({
    required String original,
    required Map<String, String> translations,
    required List<String> languages,
    required LLMConfig config,
    Map<String, dynamic>? metadata,
  }) {
    return TranslationResult(
      original: original,
      translations: translations,
      languages: languages,
      timestamp: DateTime.now(),
      config: config,
      metadata: metadata,
      isSuccessful: true,
    );
  }

  /// Create a failed translation result
  factory TranslationResult.failure({
    required String original,
    required List<String> languages,
    required LLMConfig config,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return TranslationResult(
      original: original,
      translations: {},
      languages: languages,
      timestamp: DateTime.now(),
      config: config,
      metadata: metadata,
      isSuccessful: false,
      errorMessage: errorMessage,
    );
  }

  /// Create from JSON representation
  factory TranslationResult.fromJson(
    Map<String, dynamic> json,
    LLMConfig config,
  ) {
    return TranslationResult(
      original: json['original'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      languages: List<String>.from(json['languages'] ?? []),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      config: config,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isSuccessful: json['is_successful'] ?? true,
      errorMessage: json['error_message'],
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
      'is_successful': isSuccessful,
      'error_message': errorMessage,
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
    bool? isSuccessful,
    String? errorMessage,
  }) {
    return TranslationResult(
      original: original ?? this.original,
      translations: translations ?? this.translations,
      languages: languages ?? this.languages,
      timestamp: timestamp ?? this.timestamp,
      config: config ?? this.config,
      metadata: metadata ?? this.metadata,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
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
    return translations.keys
        .where((lang) => translations[lang]?.isNotEmpty == true)
        .toList();
  }



  /// Validate the translation result
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (original.trim().isEmpty) {
      errors.add('Original text cannot be empty');
    }

    if (languages.isEmpty) {
      errors.add('Target languages list cannot be empty');
    }

    if (isSuccessful) {
      if (translations.isEmpty) {
        errors.add('Successful translation must have at least one translation');
      }

      // Check for missing translations
      final missingLanguages = languages
          .where((lang) => !hasTranslation(lang))
          .toList();
      if (missingLanguages.isNotEmpty) {
        warnings.add(
          'Missing translations for languages: ${missingLanguages.join(", ")}',
        );
      }
    } else {
      if (errorMessage == null || errorMessage!.trim().isEmpty) {
        errors.add('Failed translation must have an error message');
      }
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationResult &&
        other.original == original &&
        other.translations.length == translations.length &&
        other.translations.keys.every(
          (key) => translations[key] == other.translations[key],
        ) &&
        other.languages.length == languages.length &&
        other.languages.every((lang) => languages.contains(lang)) &&
        other.timestamp == timestamp &&
        other.isSuccessful == isSuccessful &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      original,
      Object.hashAll(
        translations.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      Object.hashAll(languages),
      timestamp,
      isSuccessful,
      errorMessage,
    );
  }

  @override
  String toString() {
    return 'TranslationResult(original: ${original.length > 30 ? '${original.substring(0, 30)}...' : original}, '
        'languages: $languages, translations: ${translations.length}, successful: $isSuccessful)';
  }
}
