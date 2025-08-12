/// Translation request model containing all necessary information for a translation operation
class TranslationRequest {
  /// The text to be translated
  final String text;
  
  /// List of target language codes (e.g., ['es', 'fr', 'de'])
  final List<String> targetLanguages;
  
  /// The LLM provider to use for translation
  final String provider;
  
  /// The server URL for the LLM provider
  final String serverUrl;
  
  /// The model name to use for translation
  final String modelName;
  
  /// Optional API key for authentication
  final String? apiKey;
  
  /// Additional request parameters specific to the provider
  final Map<String, dynamic>? additionalParams;

  const TranslationRequest({
    required this.text,
    required this.targetLanguages,
    required this.provider,
    required this.serverUrl,
    required this.modelName,
    this.apiKey,
    this.additionalParams,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'target_languages': targetLanguages,
      'provider': provider,
      'server_url': serverUrl,
      'model_name': modelName,
      'api_key': apiKey,
      'additional_params': additionalParams,
    };
  }

  /// Create from JSON representation
  factory TranslationRequest.fromJson(Map<String, dynamic> json) {
    return TranslationRequest(
      text: json['text'] ?? '',
      targetLanguages: List<String>.from(json['target_languages'] ?? []),
      provider: json['provider'] ?? 'ollama',
      serverUrl: json['server_url'] ?? '',
      modelName: json['model_name'] ?? '',
      apiKey: json['api_key'],
      additionalParams: json['additional_params'] != null
          ? Map<String, dynamic>.from(json['additional_params'])
          : null,
    );
  }

  /// Create a copy with modified fields
  TranslationRequest copyWith({
    String? text,
    List<String>? targetLanguages,
    String? provider,
    String? serverUrl,
    String? modelName,
    String? apiKey,
    Map<String, dynamic>? additionalParams,
  }) {
    return TranslationRequest(
      text: text ?? this.text,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationRequest &&
        other.text == text &&
        other.targetLanguages.length == targetLanguages.length &&
        other.targetLanguages.every((lang) => targetLanguages.contains(lang)) &&
        other.provider == provider &&
        other.serverUrl == serverUrl &&
        other.modelName == modelName &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      targetLanguages,
      provider,
      serverUrl,
      modelName,
      apiKey,
    );
  }

  @override
  String toString() {
    return 'TranslationRequest(text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
           'targetLanguages: $targetLanguages, provider: $provider, modelName: $modelName)';
  }
}