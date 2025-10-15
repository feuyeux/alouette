import 'package:flutter/foundation.dart';
import '../models/llm_config.dart';
import '../models/translation_result.dart';
import '../models/connection_status.dart';
import '../providers/base_translation_provider.dart';
import '../providers/ollama_provider.dart';
import '../providers/lm_studio_provider.dart';
import '../exceptions/translation_exceptions.dart';
import '../utils/text_processor.dart';
import 'llm_config_service.dart';
import 'dart:io';
import 'dart:async';

/// Core unified translation service that handles all translation operations
///
/// This service provides a consistent API for translation functionality across
/// all applications, with comprehensive error handling and provider management.
class TranslationService extends ChangeNotifier {
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;
  List<String> _availableModels = [];
  ConnectionStatus? _connectionStatus;
  bool _isTestingConnection = false;
  bool _isAutoConfiguring = false;
  LLMConfig? _autoDetectedConfig;



  final Map<String, TranslationProvider> _providers;

  /// Constructor with optional provider injection for better testability
  TranslationService({Map<String, TranslationProvider>? providers})
    : _providers =
          providers ??
          {'ollama': OllamaProvider(), 'lmstudio': LMStudioProvider()};

  /// Get the current translation result
  TranslationResult? get currentTranslation => _currentTranslation;

  /// Check if a translation is currently in progress
  bool get isTranslating => _isTranslating;

  /// Get the list of available models from the last successful connection test
  List<String> get availableModels => List.unmodifiable(_availableModels);

  /// Get the last connection status
  ConnectionStatus? get connectionStatus => _connectionStatus;

  /// Check if a connection test is currently in progress
  bool get isTestingConnection => _isTestingConnection;

  /// Check if auto-configuration is in progress
  bool get isAutoConfiguring => _isAutoConfiguring;



  /// Translate text to multiple target languages with enhanced error handling
  Future<TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
    bool enableRetry = true,
  }) async {
    // Enhanced validation
    _validateTranslationRequest(inputText, targetLanguages, config);

    final provider = _getProvider(config.provider);
    if (provider == null) {
      throw UnsupportedProviderException(
        'Provider ${config.provider} is not supported',
        config.provider,
        availableProviders,
      );
    }

    _isTranslating = true;
    notifyListeners();

    try {
      final translations = <String, String>{};
      final cleanedText = inputText.trim();
      final errors = <String, String>{};

      // Translate to each target language with retry logic
      for (int i = 0; i < targetLanguages.length; i++) {
        final language = targetLanguages[i];

        try {
          final translation = enableRetry
              ? await _translateWithRetry(
                  provider,
                  cleanedText,
                  language,
                  config,
                  additionalParams: additionalParams,
                )
              : await provider.translateText(
                  text: cleanedText,
                  targetLanguage: language,
                  config: config,
                  additionalParams: additionalParams,
                );

          // Clean the translation result
          final cleanedTranslation = cleanTranslationResult(
            translation,
            language,
          );

          if (cleanedTranslation.trim().isEmpty) {
            throw InvalidTranslationException(
              'Translation result is empty after cleaning',
              cleanedText,
              language,
            );
          }

          translations[language] = cleanedTranslation;
        } catch (e) {
          // Store error for this language but continue with others
          errors[language] = e.toString();

          // If it's a critical error that affects all translations, rethrow
          if (e is LLMConnectionException ||
              e is LLMAuthenticationException ||
              e is UnsupportedProviderException ||
              e is ConfigurationException) {
            rethrow;
          }
        }
      }

      // Check if we got at least some translations
      if (translations.isEmpty) {
        throw TranslationException(
          'All translations failed. Errors: ${errors.values.join('; ')}',
          code: 'ALL_TRANSLATIONS_FAILED',
          details: {'errors': errors},
        );
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
          'successfulLanguages': translations.keys.toList(),
          'failedLanguages': errors.keys.toList(),
          'errors': errors,
        },
      );

      notifyListeners();
      return _currentTranslation!;
    } catch (error) {
      // Enhanced error handling with proper exception types
      if (error is TranslationException) {
        rethrow;
      }

      // Convert unknown errors to appropriate exception types
      final handledException = handleException(
        error,
        config.provider,
        config.serverUrl,
      );
      throw handledException;
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Test connection to the LLM provider
  Future<ConnectionStatus> testConnection(
    LLMConfig config, {
    Duration? timeout,
  }) async {
    if (_isTestingConnection) {
      return ConnectionStatus.failure(
        message: 'Connection test is already in progress',
      );
    }

    _isTestingConnection = true;
    notifyListeners();

    try {
      final provider = _getProvider(config.provider);
      if (provider == null) {
        throw TranslationException('Unsupported provider: ${config.provider}');
      }

      // Apply timeout if specified
      final connectionFuture = provider.testConnection(config);
      _connectionStatus = timeout != null
          ? await connectionFuture.timeout(
              timeout,
              onTimeout: () => ConnectionStatus.failure(
                message: 'Connection test timed out',
              ),
            )
          : await connectionFuture;

      if (_connectionStatus!.success) {
        // Fetch available models on successful connection
        try {
          final modelsFuture = provider.getAvailableModels(config);
          _availableModels = timeout != null
              ? await modelsFuture.timeout(timeout, onTimeout: () => <String>[])
              : await modelsFuture;
        } catch (e) {
          // Don't fail the connection test if model fetching fails
          _availableModels = [];
        }
      } else {
        _availableModels = [];
      }

      notifyListeners();
      return _connectionStatus!;
    } catch (e) {
      _connectionStatus = ConnectionStatus.failure(
        message: 'Connection test failed: ${e.toString()}',
      );
      _availableModels = [];
      notifyListeners();
      return _connectionStatus!;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
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
      notifyListeners();
      return models;
    } catch (e) {
      throw TranslationException(
        'Failed to get available models: ${e.toString()}',
      );
    }
  }



  /// Get the translation provider for the given provider name
  TranslationProvider? _getProvider(String providerName) {
    return _providers[providerName.toLowerCase()];
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
    notifyListeners();
  }











  /// Validate LLM configuration using the model's validation
  Map<String, dynamic> validateConfig(LLMConfig config) {
    return config.validate();
  }

  /// Auto-detect LLM configuration by testing common endpoints
  /// [quickMode] uses shorter timeout for faster startup (default: false)
  Future<LLMConfig?> autoDetectConfig({bool quickMode = false}) async {
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

    // Use 2 second timeout in quick mode, normal timeout otherwise
    final timeout = quickMode ? const Duration(seconds: 2) : null;

    for (final config in commonConfigs) {
      try {
        final status = await testConnection(config, timeout: timeout);
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

  /// Auto-detect configuration with platform-specific optimizations
  /// [quickMode] uses shorter timeout for faster startup
  Future<LLMConfig?> autoDetectConfigWithPlatformSupport({
    bool isAndroid = false,
    bool quickMode = false,
  }) async {
    // Use different base URL for Android to avoid localhost issues
    final baseUrl = isAndroid ? 'http://10.0.2.2' : 'http://localhost';

    // Use 2 second timeout in quick mode
    final timeout = quickMode ? const Duration(seconds: 2) : null;

    final commonConfigs = [
      // Ollama configurations
      LLMConfig(
        provider: 'ollama',
        serverUrl: '$baseUrl:11434',
        selectedModel: 'qwen2.5:latest',
      ),
      // LM Studio configurations
      LLMConfig(
        provider: 'lmstudio',
        serverUrl: '$baseUrl:1234',
        selectedModel: '',
      ),
    ];

    for (final config in commonConfigs) {
      try {
        final status = await testConnection(config, timeout: timeout);
        if (status.success && _availableModels.isNotEmpty) {
          String selectedModel = _selectBestModel(_availableModels);
          return config.copyWith(selectedModel: selectedModel);
        }
      } catch (e) {
        // Continue to next configuration
        continue;
      }
    }

    return null;
  }

  /// Select the best available model from a list
  String _selectBestModel(List<String> models) {
    if (models.isEmpty) return '';

    // Prefer qwen2.5 models
    final qwenModels = models
        .where((model) => model.toLowerCase().contains('qwen2.5'))
        .toList();

    if (qwenModels.isNotEmpty) {
      // Prefer qwen2.5:latest, then qwen2.5:7b, then any qwen2.5
      if (qwenModels.any((m) => m.contains('latest'))) {
        return qwenModels.firstWhere((m) => m.contains('latest'));
      } else if (qwenModels.any((m) => m.contains('7b'))) {
        return qwenModels.firstWhere((m) => m.contains('7b'));
      } else {
        return qwenModels.first;
      }
    }

    // Fallback to other good models
    final preferredModels = ['llama3.2', 'llama3.1', 'mistral', 'gemma2'];
    for (final preferred in preferredModels) {
      final match = models.firstWhere(
        (model) => model.toLowerCase().contains(preferred),
        orElse: () => '',
      );
      if (match.isNotEmpty) return match;
    }

    return models.first;
  }

  /// Auto-configure LLM connection with comprehensive platform support and retry mechanism
  Future<LLMConfig?> autoConfigureLLM({
    bool enableRetry = true,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool isAndroid = false,
  }) async {
    if (_isAutoConfiguring) {
      return _autoDetectedConfig;
    }

    _isAutoConfiguring = true;
    notifyListeners();

    try {
      // Use quick mode (shorter timeout) when retries are disabled (startup scenario)
      final quickMode = !enableRetry;

      // Use enhanced auto-detection logic with platform support and retry mechanism
      for (
        int attempt = 1;
        attempt <= (enableRetry ? maxRetries : 1);
        attempt++
      ) {
        try {
          // Try platform-specific auto-detection first
          final autoDetected = await autoDetectConfigWithPlatformSupport(
            isAndroid: isAndroid,
            quickMode: quickMode,
          );

          if (autoDetected != null) {
            _autoDetectedConfig = autoDetected;
            notifyListeners();
            return autoDetected;
          }

          // Fallback to basic auto-detection
          final basicAutoDetected = await autoDetectConfig(
            quickMode: quickMode,
          );
          if (basicAutoDetected != null) {
            _autoDetectedConfig = basicAutoDetected;
            notifyListeners();
            return basicAutoDetected;
          }

          if (attempt < (enableRetry ? maxRetries : 1)) {
            await Future.delayed(retryDelay);
          }
        } catch (e) {
          if (attempt < (enableRetry ? maxRetries : 1)) {
            await Future.delayed(retryDelay);
          }
        }
      }

      return null;
    } finally {
      _isAutoConfiguring = false;
      notifyListeners();
    }
  }

  /// Comprehensive auto-configuration that attempts multiple strategies
  /// This replaces the duplicate AutoConfigService implementations in applications
  Future<LLMConfig?> attemptAutoConfiguration({
    bool isAndroid = false,
    bool enableFileSystemCheck = true,
    bool enableNetworkCheck = true,
  }) async {
    try {
      // Strategy 1: Network-based auto-detection (existing logic)
      if (enableNetworkCheck) {
        final networkConfig = await autoConfigureLLM(isAndroid: isAndroid);
        if (networkConfig != null) {
          return networkConfig;
        }
      }

      // Strategy 2: File system-based detection (from removed AutoConfigService)
      if (enableFileSystemCheck) {
        final fileSystemConfig = await _detectConfigFromFileSystem();
        if (fileSystemConfig != null) {
          // Verify the detected config works
          final testResult = await testConnection(fileSystemConfig);
          if (testResult.success) {
            _autoDetectedConfig = fileSystemConfig;
            notifyListeners();
            return fileSystemConfig;
          }
        }
      }

      return null;
    } catch (e) {
      throw ConfigurationException(
        'Auto-configuration failed: ${e.toString()}',
        details: {'originalError': e.toString()},
      );
    }
  }

  /// Detect configuration from file system (consolidated from removed AutoConfigService)
  Future<LLMConfig?> _detectConfigFromFileSystem() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        return await _configureForLinuxOrMac();
      } else if (Platform.isWindows) {
        return await _configureForWindows();
      }
    } catch (e) {
      // Don't throw, just return null for graceful fallback
      return null;
    }
    return null;
  }

  /// Linux/macOS configuration detection
  Future<LLMConfig?> _configureForLinuxOrMac() async {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final ollamaConfig = File('$home/.ollama/config.json');
      if (await ollamaConfig.exists()) {
        return LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: 'qwen2.5:latest', // Use preferred model
        );
      }
    }
    return null;
  }

  /// Windows configuration detection
  Future<LLMConfig?> _configureForWindows() async {
    final home = Platform.environment['USERPROFILE'];
    if (home != null) {
      final ollamaConfig = File('$home\\.ollama\\config.json');
      if (await ollamaConfig.exists()) {
        return LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: 'qwen2.5:latest', // Use preferred model
        );
      }
    }
    return null;
  }

  /// Get recommended settings for a provider
  /// Delegates to LLMConfigService for consistent configuration across the library
  Map<String, dynamic> getRecommendedSettings(
    String provider, {
    bool isAndroid = false,
  }) {
    return LLMConfigService.getRecommendedSettings(
      provider,
      isAndroid: isAndroid,
    );
  }





  /// Unified API method for applications to perform translation with auto-configuration
  /// This provides a single entry point that handles configuration and translation
  Future<TranslationResult> translateWithAutoConfig(
    String inputText,
    List<String> targetLanguages, {
    LLMConfig? config,
    Map<String, dynamic>? additionalParams,
    bool enableRetry = true,
    bool isAndroid = false,
  }) async {
    LLMConfig? workingConfig = config;

    // If no config provided or config is invalid, try auto-configuration
    if (workingConfig == null || !validateConfig(workingConfig)['isValid']) {
      workingConfig = await attemptAutoConfiguration(isAndroid: isAndroid);

      if (workingConfig == null) {
        throw ConfigurationException(
          'No valid configuration available and auto-configuration failed. Please configure LLM settings manually.',
        );
      }
    }

    // Perform translation with the working config
    return await translateText(
      inputText,
      targetLanguages,
      workingConfig,
      additionalParams: additionalParams,
      enableRetry: enableRetry,
    );
  }

  /// Check if the service is ready for translation (has valid config)
  bool get isReady {
    return _autoDetectedConfig != null &&
        validateConfig(_autoDetectedConfig!)['isValid'] as bool;
  }



  /// Initialize the service with auto-configuration
  /// Uses shorter timeout and fewer retries to avoid blocking app startup
  Future<bool> initialize({bool isAndroid = false}) async {
    try {
      // Use faster auto-configuration for startup (no retries, quick timeout)
      final config = await autoConfigureLLM(
        isAndroid: isAndroid,
        enableRetry: false, // No retries during startup
        maxRetries: 1,
      );
      return config != null;
    } catch (e) {
      return false;
    }
  }

  /// Convert generic exceptions to specific translation exceptions with enhanced error handling
  AlouetteTranslationError handleException(
    Object error,
    String providerName,
    String serverUrl,
  ) {
    if (error is TranslationException) {
      return error;
    }

    if (error is SocketException) {
      if (error.message.contains('Connection refused') ||
          error.message.contains('network is unreachable') ||
          error.message.contains('No route to host')) {
        return LLMConnectionException(
          'Cannot connect to $providerName server at $serverUrl. Please check if the server is running and accessible.',
          details: {
            'provider': providerName,
            'serverUrl': serverUrl,
            'originalError': error.message,
          },
        );
      } else if (error.message.contains('timeout') ||
          error.message.contains('timed out')) {
        return TranslationTimeoutException(
          'Translation request timed out. The server may be overloaded.',
          details: {'provider': providerName, 'serverUrl': serverUrl},
        );
      } else if (error.message.contains('Connection reset') ||
          error.message.contains('Broken pipe')) {
        return LLMConnectionException(
          'Connection to $providerName server was reset. The server may have restarted.',
          details: {'provider': providerName, 'serverUrl': serverUrl},
        );
      }
    }

    if (error is FormatException) {
      return TranslationException(
        'Invalid response format from $providerName server. The server may be misconfigured.',
        code: 'INVALID_RESPONSE_FORMAT',
        details: {'provider': providerName, 'originalError': error.message},
      );
    }

    if (error is TimeoutException) {
      return TranslationTimeoutException(
        'Translation request timed out after waiting for server response.',
        timeout: error.duration,
        details: {'provider': providerName, 'serverUrl': serverUrl},
      );
    }

    // Handle HTTP-related errors
    if (error.toString().contains('XMLHttpRequest')) {
      return LLMConnectionException(
        'Network request failed. This may be due to CORS issues or network connectivity problems.',
        details: {
          'provider': providerName,
          'serverUrl': serverUrl,
          'hint': 'Check CORS settings if running in web browser',
        },
      );
    }

    return TranslationException(
      '$providerName translation failed: ${error.toString()}',
      code: 'UNKNOWN_ERROR',
      details: {
        'provider': providerName,
        'serverUrl': serverUrl,
        'errorType': error.runtimeType.toString(),
      },
    );
  }



  /// Validate translation request before processing
  void _validateTranslationRequest(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config,
  ) {
    if (inputText.trim().isEmpty) {
      throw TranslationException(
        'Input text cannot be empty',
        code: 'EMPTY_INPUT',
      );
    }

    if (targetLanguages.isEmpty) {
      throw TranslationException(
        'At least one target language must be specified',
        code: 'NO_TARGET_LANGUAGES',
      );
    }

    if (inputText.length > 10000) {
      throw TranslationException(
        'Input text is too long (maximum 10,000 characters)',
        code: 'TEXT_TOO_LONG',
      );
    }

    final validation = config.validate();
    if (!validation['isValid']) {
      throw ConfigurationException(
        'Invalid configuration: ${validation['errors'].join(', ')}',
      );
    }

    if (!isProviderSupported(config.provider)) {
      throw UnsupportedProviderException(
        'Provider ${config.provider} is not supported',
        config.provider,
        availableProviders,
      );
    }
  }

  /// Enhanced error recovery with retry logic
  Future<String> _translateWithRetry(
    TranslationProvider provider,
    String text,
    String targetLanguage,
    LLMConfig config, {
    Map<String, dynamic>? additionalParams,
    int maxRetries = 2,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await provider.translateText(
          text: text,
          targetLanguage: targetLanguage,
          config: config,
          additionalParams: additionalParams,
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Don't retry on certain errors
        if (e is LLMAuthenticationException ||
            e is UnsupportedProviderException ||
            e is ConfigurationException) {
          rethrow;
        }

        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    // All retries failed
    throw lastException!;
  }

  /// Clean translation result by removing unwanted prefixes, suffixes, and formatting
  /// Delegates to TextProcessor for consistent cleaning logic across the library
  String cleanTranslationResult(String rawText, String targetLanguage) {
    return TextProcessor.cleanTranslationResult(rawText, targetLanguage);
  }
}
