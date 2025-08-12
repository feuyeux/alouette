/// LLM Provider configuration model
class LLMConfig {
  /// The LLM provider type ('ollama', 'lmstudio', etc.)
  final String provider;
  
  /// The server URL for the LLM provider
  final String serverUrl;
  
  /// Optional API key for authentication
  final String? apiKey;
  
  /// The selected model name
  final String selectedModel;
  
  /// Provider-specific configuration options
  final Map<String, dynamic>? providerSpecific;

  const LLMConfig({
    required this.provider,
    required this.serverUrl,
    this.apiKey,
    required this.selectedModel,
    this.providerSpecific,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'server_url': serverUrl,
      'api_key': apiKey,
      'selected_model': selectedModel,
      'provider_specific': providerSpecific,
    };
  }

  /// Create from JSON representation
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      provider: json['provider'] ?? 'ollama',
      serverUrl: json['server_url'] ?? 'http://localhost:11434',
      apiKey: json['api_key'],
      selectedModel: json['selected_model'] ?? '',
      providerSpecific: json['provider_specific'] != null 
          ? Map<String, dynamic>.from(json['provider_specific'])
          : null,
    );
  }

  /// Create a copy with modified fields
  LLMConfig copyWith({
    String? provider,
    String? serverUrl,
    String? apiKey,
    String? selectedModel,
    Map<String, dynamic>? providerSpecific,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      providerSpecific: providerSpecific ?? this.providerSpecific,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LLMConfig &&
        other.provider == provider &&
        other.serverUrl == serverUrl &&
        other.apiKey == apiKey &&
        other.selectedModel == selectedModel;
  }

  @override
  int get hashCode {
    return Object.hash(provider, serverUrl, apiKey, selectedModel);
  }

  @override
  String toString() {
    return 'LLMConfig(provider: $provider, serverUrl: $serverUrl, selectedModel: $selectedModel)';
  }
}