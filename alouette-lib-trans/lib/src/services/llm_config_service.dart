import 'dart:convert';
import 'dart:io';
import '../models/llm_config.dart';
import '../models/connection_status.dart';
import '../providers/translation_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/lmstudio_provider.dart';
import '../exceptions/translation_exceptions.dart';

/// Service for managing LLM configurations and testing connections
class LLMConfigService {
  List<String> _availableModels = [];
  ConnectionStatus? _connectionStatus;
  bool _isTestingConnection = false;

  final Map<String, TranslationProvider> _providers = {
    'ollama': OllamaProvider(),
    'lmstudio': LMStudioProvider(),
  };

  /// Get the list of available models from the last successful connection test
  List<String> get availableModels => List.unmodifiable(_availableModels);

  /// Get the last connection status
  ConnectionStatus? get connectionStatus => _connectionStatus;

  /// Check if a connection test is currently in progress
  bool get isTestingConnection => _isTestingConnection;

  /// Test connection to the LLM provider
  Future<ConnectionStatus> testConnection(LLMConfig config) async {
    if (_isTestingConnection) {
      return ConnectionStatus.failure(
        message: 'Connection test is already in progress',
      );
    }

    _isTestingConnection = true;

    try {
      final provider = _getProvider(config.provider);
      if (provider == null) {
        throw TranslationException('Unsupported provider: ${config.provider}');
      }

      _connectionStatus = await provider.testConnection(config);

      if (_connectionStatus!.success) {
        // Fetch available models on successful connection
        try {
          _availableModels = await provider.getAvailableModels(config);
        } catch (e) {
          // Don't fail the connection test if model fetching fails
          _availableModels = [];
        }
      } else {
        _availableModels = [];
      }

      return _connectionStatus!;
    } catch (e) {
      _connectionStatus = ConnectionStatus.failure(
        message: 'Connection test failed: ${e.toString()}',
      );
      _availableModels = [];
      return _connectionStatus!;
    } finally {
      _isTestingConnection = false;
    }
  }

  /// Get available models from the provider
  Future<List<String>> getAvailableModels(LLMConfig config) async {
    final provider = _getProvider(config.provider);
    if (provider == null) {
      throw TranslationException('Unsupported provider: ${config.provider}');
    }

    try {
      final models = await provider.getAvailableModels(config);
      _availableModels = models;
      return models;
    } catch (e) {
      throw TranslationException(
        'Failed to get available models: ${e.toString()}',
      );
    }
  }

  /// Save LLM configuration to local storage
  Future<void> saveConfig(LLMConfig config) async {
    try {
      // This is a basic implementation - in a real app, you might use
      // shared_preferences or another storage mechanism
      final configJson = jsonEncode(config.toJson());
      // For now, we'll just store it in memory or use platform-specific storage
      // Implementation would depend on the specific storage mechanism chosen
    } catch (e) {
      throw TranslationException(
        'Failed to save configuration: ${e.toString()}',
      );
    }
  }

  /// Load LLM configuration from local storage
  Future<LLMConfig?> loadConfig() async {
    try {
      // This is a basic implementation - in a real app, you might use
      // shared_preferences or another storage mechanism
      // For now, return null indicating no saved config
      return null;
    } catch (e) {
      throw TranslationException(
        'Failed to load configuration: ${e.toString()}',
      );
    }
  }

  /// Auto-detect LLM configuration by testing common endpoints
  Future<LLMConfig?> autoDetectConfig() async {
    final commonConfigs = [
      // Ollama configurations with qwen2.5 as preferred model
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://127.0.0.1:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      // LM Studio configurations
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://localhost:1234',
        selectedModel: '',
      ),
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://127.0.0.1:1234',
        selectedModel: '',
      ),
    ];

    for (final config in commonConfigs) {
      try {
        final status = await testConnection(config);
        if (status.success && _availableModels.isNotEmpty) {
          // Prefer qwen2.5 models if available
          String selectedModel = _availableModels.first;

          // Look for qwen2.5 models (various versions)
          final qwenModels = _availableModels
              .where((model) => model.toLowerCase().contains('qwen2.5'))
              .toList();

          if (qwenModels.isNotEmpty) {
            // Prefer qwen2.5:latest, then qwen2.5:7b, then any qwen2.5
            if (qwenModels.any((m) => m.contains('latest'))) {
              selectedModel = qwenModels.firstWhere(
                (m) => m.contains('latest'),
              );
            } else if (qwenModels.any((m) => m.contains('7b'))) {
              selectedModel = qwenModels.firstWhere((m) => m.contains('7b'));
            } else {
              selectedModel = qwenModels.first;
            }
          }

          return config.copyWith(selectedModel: selectedModel);
        }
      } catch (e) {
        // Continue to next configuration
        continue;
      }
    }

    return null; // No working configuration found
  }

  /// Validate LLM configuration
  Map<String, dynamic> validateConfig(LLMConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required field validation
    if (config.provider.isEmpty) {
      errors.add('Provider is required');
    }

    if (config.serverUrl.isEmpty) {
      errors.add('Server URL is required');
    }

    if (config.selectedModel.isEmpty) {
      errors.add('Model selection is required');
    }

    // URL format validation
    if (config.serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(config.serverUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          errors.add('Invalid server URL format');
        }
      } catch (e) {
        errors.add('Invalid server URL format');
      }
    }

    // Provider-specific validation
    if (!_providers.containsKey(config.provider.toLowerCase())) {
      errors.add('Unsupported provider: ${config.provider}');
    }

    // Provider-specific warnings
    if (config.provider == 'lmstudio' &&
        (config.apiKey == null || config.apiKey!.isEmpty)) {
      warnings.add('API key is recommended for LM Studio');
    }

    // URL-related warnings
    if (config.serverUrl.isNotEmpty) {
      if (config.serverUrl.contains('localhost') ||
          config.serverUrl.contains('127.0.0.1')) {
        warnings.add(
          'Using localhost - ensure the server is running on this machine',
        );
      }

      if (config.serverUrl.startsWith('http:') &&
          !config.serverUrl.contains('localhost') &&
          !config.serverUrl.contains('127.0.0.1')) {
        warnings.add(
          'Using HTTP (not HTTPS) for remote server - consider using HTTPS for security',
        );
      }
    }

    return {'isValid': errors.isEmpty, 'errors': errors, 'warnings': warnings};
  }

  /// Get recommended settings for a provider
  Map<String, dynamic> getRecommendedSettings(
    String provider, {
    bool isAndroid = false,
  }) {
    // Use different base URL for Android to avoid localhost issues
    final baseUrl = isAndroid ? 'http://10.0.2.2' : 'http://localhost';

    switch (provider.toLowerCase()) {
      case 'ollama':
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Ollama typically runs on port 11434',
          'setupInstructions': [
            'Install Ollama from https://ollama.ai',
            'Run "ollama serve" to start the server',
            'Pull a model with "ollama pull llama3.2" or similar',
          ],
          'commonModels': ['llama3.2', 'llama3.1', 'mistral', 'codellama'],
        };

      case 'lmstudio':
        return {
          'serverUrl': '$baseUrl:1234',
          'apiKey': '',
          'description': 'LM Studio typically runs on port 1234',
          'setupInstructions': [
            'Install LM Studio from https://lmstudio.ai',
            'Download and load a model in LM Studio',
            'Start the local server from the server tab',
            'Enable CORS if accessing from web applications',
          ],
          'commonModels': [
            'microsoft/DialoGPT-medium',
            'microsoft/DialoGPT-large',
            'huggingface models',
          ],
        };

      default:
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Default configuration',
          'setupInstructions': [],
          'commonModels': [],
        };
    }
  }

  /// Get platform-specific configuration adjustments
  Map<String, dynamic> getPlatformAdjustments() {
    final platform = Platform.operatingSystem;

    return {
      'platform': platform,
      'isAndroid': platform == 'android',
      'isIOS': platform == 'ios',
      'isWeb': false, // This would need to be detected differently for web
      'recommendedTimeout': platform == 'android' || platform == 'ios'
          ? 30
          : 10,
      'networkNotes': _getNetworkNotes(platform),
    };
  }

  List<String> _getNetworkNotes(String platform) {
    switch (platform) {
      case 'android':
        return [
          'Use 10.0.2.2 instead of localhost for Android emulator',
          'Use your computer\'s IP address for physical devices',
          'Ensure the server allows connections from your device\'s IP',
        ];
      case 'ios':
        return [
          'Use your computer\'s IP address instead of localhost',
          'Ensure the server allows connections from your device\'s IP',
          'Check iOS network permissions if connection fails',
        ];
      default:
        return [
          'localhost should work for desktop applications',
          'Ensure firewall allows connections to the server port',
        ];
    }
  }

  /// Get the provider instance for the given name
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

  /// Clear connection status and cached models
  void clearConnection() {
    _availableModels.clear();
    _connectionStatus = null;
  }

  /// Get connection summary for display
  Map<String, dynamic> getConnectionSummary() {
    return {
      'isConnected': _connectionStatus?.success ?? false,
      'lastConnectionTime': _connectionStatus?.timestamp.toIso8601String(),
      'modelCount': _availableModels.length,
      'availableModels': _availableModels,
      'lastMessage': _connectionStatus?.message,
      'responseTime': _connectionStatus?.responseTimeMs,
    };
  }
}
