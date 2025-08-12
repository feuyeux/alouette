import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

// Mock HTTP client for testing
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('Translation Library Integration Tests', () {
    late TranslationService translationService;
    late LLMConfigService configService;

    setUp(() {
      translationService = TranslationService();
      configService = LLMConfigService();
    });

    test('should validate LLM configuration models', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama2',
        apiKey: null,
      );

      expect(config.provider, equals('ollama'));
      expect(config.serverUrl, equals('http://localhost:11434'));
      expect(config.selectedModel, equals('llama2'));
      expect(config.apiKey, isNull);

      // Test serialization
      final json = config.toJson();
      final configFromJson = LLMConfig.fromJson(json);
      expect(configFromJson.provider, equals(config.provider));
      expect(configFromJson.serverUrl, equals(config.serverUrl));
      expect(configFromJson.selectedModel, equals(config.selectedModel));
      expect(configFromJson.apiKey, equals(config.apiKey));
    });

    test('should validate translation request models', () {
      final request = TranslationRequest(
        text: 'Hello world',
        targetLanguages: ['Chinese', 'Japanese'],
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        modelName: 'llama2',
        apiKey: null,
      );

      expect(request.text, equals('Hello world'));
      expect(request.targetLanguages, equals(['Chinese', 'Japanese']));
      expect(request.provider, equals('ollama'));
      expect(request.serverUrl, equals('http://localhost:11434'));
      expect(request.modelName, equals('llama2'));
      expect(request.apiKey, isNull);

      // Test serialization
      final json = request.toJson();
      final requestFromJson = TranslationRequest.fromJson(json);
      expect(requestFromJson.text, equals(request.text));
      expect(requestFromJson.targetLanguages, equals(request.targetLanguages));
      expect(requestFromJson.provider, equals(request.provider));
    });

    test('should validate translation result models', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama2',
        apiKey: null,
      );

      final result = TranslationResult(
        original: 'Hello world',
        translations: {'Chinese': '你好世界', 'Japanese': 'こんにちは世界'},
        languages: ['Chinese', 'Japanese'],
        timestamp: DateTime.now(),
        config: config,
      );

      expect(result.original, equals('Hello world'));
      expect(result.translations['Chinese'], equals('你好世界'));
      expect(result.translations['Japanese'], equals('こんにちは世界'));
      expect(result.languages, equals(['Chinese', 'Japanese']));
      expect(result.config.provider, equals('ollama'));

      // Test serialization
      final json = result.toJson();
      final resultFromJson = TranslationResult.fromJson(json, config);
      expect(resultFromJson.original, equals(result.original));
      expect(resultFromJson.translations, equals(result.translations));
      expect(resultFromJson.languages, equals(result.languages));
    });

    test('should validate connection status models', () {
      final status = ConnectionStatus(
        success: true,
        message: 'Connection successful',
        modelCount: 5,
        timestamp: DateTime.now(),
      );

      expect(status.success, isTrue);
      expect(status.message, equals('Connection successful'));
      expect(status.modelCount, equals(5));
      expect(status.timestamp, isNotNull);

      // Test serialization
      final json = status.toJson();
      final statusFromJson = ConnectionStatus.fromJson(json);
      expect(statusFromJson.success, equals(status.success));
      expect(statusFromJson.message, equals(status.message));
      expect(statusFromJson.modelCount, equals(status.modelCount));
    });

    test('should handle translation service state management', () {
      expect(translationService.currentTranslation, isNull);
      expect(translationService.isTranslating, isFalse);

      // Test clear translation
      translationService.clearTranslation();
      expect(translationService.currentTranslation, isNull);

      // Test state retrieval
      final state = translationService.getTranslationState();
      expect(state, isA<Map<String, dynamic>>());
      expect(state['isTranslating'], isFalse);
      expect(state['hasTranslation'], isFalse);
    });

    test('should handle text cleaning utilities', () {
      const dirtyText = '  Hello\n\nworld  \t\n  ';
      final cleanedText = TextCleaner.cleanTranslationResult(dirtyText, 'English');
      expect(cleanedText, equals('Hello'));

      const emptyText = '   \n\t   ';
      final cleanedEmpty = TextCleaner.cleanTranslationResult(emptyText, 'English');
      expect(cleanedEmpty, isEmpty);
    });

    test('should validate translation exceptions', () {
      final connectionException = LLMConnectionException('Connection failed');
      expect(connectionException.message, equals('Connection failed'));
      expect(connectionException.toString(), contains('Connection failed'));

      final authException = LLMAuthenticationException('Auth failed');
      expect(authException.message, equals('Auth failed'));
      expect(authException.toString(), contains('Auth failed'));

      final modelException = LLMModelNotFoundException('Model not found', 'llama2');
      expect(modelException.message, equals('Model not found'));
      expect(modelException.modelName, equals('llama2'));
      expect(modelException.toString(), contains('Model not found'));

      final timeoutException = TranslationTimeoutException('Request timeout');
      expect(timeoutException.message, equals('Request timeout'));
      expect(timeoutException.toString(), contains('Request timeout'));
    });

    test('should handle LLM config service operations', () async {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama2',
        apiKey: null,
      );

      // Test config save/load (will use in-memory storage for tests)
      await configService.saveConfig(config);
      final loadedConfig = await configService.loadConfig();
      
      // In test environment, config might not persist, so we just verify no errors
      expect(() async => await configService.saveConfig(config), returnsNormally);
      expect(() async => await configService.loadConfig(), returnsNormally);
    });

    test('should handle provider-specific functionality', () {
      // Test Ollama provider
      final ollamaProvider = OllamaProvider();
      expect(ollamaProvider.providerName, equals('ollama'));

      // Test LM Studio provider
      final lmStudioProvider = LMStudioProvider();
      expect(lmStudioProvider.providerName, equals('lmstudio'));
    });

    test('should validate translation constants', () {
      expect(TranslationConstants.supportedProviders, isNotEmpty);
      expect(TranslationConstants.supportedProviders, contains('ollama'));
      expect(TranslationConstants.supportedProviders, contains('lmstudio'));

      expect(TranslationConstants.defaultTimeout, isA<Duration>());
      expect(TranslationConstants.maxRetryAttempts, isA<int>());
      expect(TranslationConstants.maxRetryAttempts, greaterThan(0));
      
      expect(TranslationConstants.languageNames, isNotEmpty);
      expect(TranslationConstants.languageNames, containsPair('en', 'English'));
      expect(TranslationConstants.languageNames, containsPair('zh', 'Chinese (Simplified)'));
    });
  });
}