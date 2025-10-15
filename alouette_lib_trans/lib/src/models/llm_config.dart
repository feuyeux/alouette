/// LLM Provider configuration model
class LLMConfig {
  /// The LLM provider type ('ollama', 'lmstudio', etc.)
  final String provider;

  /// The server URL for the LLM provider
  final String serverUrl;

  /// The selected model name
  final String selectedModel;

  /// Provider-specific configuration options
  final Map<String, dynamic>? providerSpecific;

  const LLMConfig({
    required this.provider,
    required this.serverUrl,
    required this.selectedModel,
    this.providerSpecific,
  });

  /// Basic validation of the configuration
  bool get isValid {
    return provider.isNotEmpty &&
        serverUrl.isNotEmpty &&
        selectedModel.isNotEmpty;
  }

  /// Comprehensive validation with detailed error reporting
  Map<String, dynamic> validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Required field validation
    if (provider.isEmpty) {
      errors.add('Provider is required');
    }

    if (serverUrl.isEmpty) {
      errors.add('Server URL is required');
    }

    if (selectedModel.isEmpty) {
      errors.add('Model selection is required');
    }

    // URL format validation
    if (serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(serverUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          errors.add('Invalid server URL format');
        }
      } catch (e) {
        errors.add('Invalid server URL format');
      }
    }

    // URL-related warnings
    if (serverUrl.isNotEmpty) {
      if (serverUrl.contains('localhost') || serverUrl.contains('127.0.0.1')) {
        warnings.add(
          'Using localhost - ensure the server is running on this machine',
        );
      }

      if (serverUrl.startsWith('http:') &&
          !serverUrl.contains('localhost') &&
          !serverUrl.contains('127.0.0.1')) {
        warnings.add(
          'Using HTTP (not HTTPS) for remote server - consider using HTTPS for security',
        );
      }
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Get normalized server URL (without trailing slash)
  String get normalizedServerUrl {
    return serverUrl.trimRight().replaceAll(RegExp(r'\/$'), '');
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'server_url': serverUrl,
      'selected_model': selectedModel,
      'provider_specific': providerSpecific,
    };
  }

  /// Create from JSON representation
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      provider: json['provider'] ?? 'ollama',
      serverUrl: json['server_url'] ?? 'http://localhost:11434',
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
    String? selectedModel,
    Map<String, dynamic>? providerSpecific,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
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
        other.selectedModel == selectedModel;
  }

  @override
  int get hashCode {
    return Object.hash(provider, serverUrl, selectedModel);
  }

  @override
  String toString() {
    return 'LLMConfig(provider: $provider, serverUrl: $serverUrl, selectedModel: $selectedModel)';
  }
}
