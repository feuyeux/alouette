import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/src/models/llm_config.dart';

void main() {
  group('LLMConfig', () {
    test('should create LLMConfig with required fields', () {
      const config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      expect(config.provider, equals('ollama'));
      expect(config.serverUrl, equals('http://localhost:11434'));
      expect(config.selectedModel, equals('llama3.2'));
      expect(config.apiKey, isNull);
      expect(config.providerSpecific, isNull);
    });

    test('should create LLMConfig with all fields', () {
      final config = LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://localhost:1234',
        selectedModel: 'gpt-3.5-turbo',
        apiKey: 'test-key',
        providerSpecific: {'temperature': 0.5},
      );

      expect(config.provider, equals('lmstudio'));
      expect(config.serverUrl, equals('http://localhost:1234'));
      expect(config.selectedModel, equals('gpt-3.5-turbo'));
      expect(config.apiKey, equals('test-key'));
      expect(config.providerSpecific, equals({'temperature': 0.5}));
    });

    test('should convert to JSON correctly', () {
      final config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
        apiKey: 'test-key',
        providerSpecific: {'custom': 'value'},
      );

      final json = config.toJson();

      expect(json['provider'], equals('ollama'));
      expect(json['server_url'], equals('http://localhost:11434'));
      expect(json['selected_model'], equals('llama3.2'));
      expect(json['api_key'], equals('test-key'));
      expect(json['provider_specific'], equals({'custom': 'value'}));
    });

    test('should create from JSON correctly', () {
      final json = {
        'provider': 'lmstudio',
        'server_url': 'http://localhost:1234',
        'selected_model': 'gpt-4',
        'api_key': 'test-key',
        'provider_specific': {'temperature': 0.7},
      };

      final config = LLMConfig.fromJson(json);

      expect(config.provider, equals('lmstudio'));
      expect(config.serverUrl, equals('http://localhost:1234'));
      expect(config.selectedModel, equals('gpt-4'));
      expect(config.apiKey, equals('test-key'));
      expect(config.providerSpecific, equals({'temperature': 0.7}));
    });

    test('should create from JSON with defaults', () {
      final json = <String, dynamic>{};

      final config = LLMConfig.fromJson(json);

      expect(config.provider, equals('ollama'));
      expect(config.serverUrl, equals('http://localhost:11434'));
      expect(config.selectedModel, equals(''));
      expect(config.apiKey, isNull);
      expect(config.providerSpecific, isNull);
    });

    test('should create copy with modified fields', () {
      const original = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      final modified = original.copyWith(
        provider: 'lmstudio',
        apiKey: 'new-key',
      );

      expect(modified.provider, equals('lmstudio'));
      expect(modified.serverUrl, equals('http://localhost:11434')); // unchanged
      expect(modified.selectedModel, equals('llama3.2')); // unchanged
      expect(modified.apiKey, equals('new-key'));
    });

    test('should implement equality correctly', () {
      const config1 = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      const config2 = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      const config3 = LLMConfig(
        provider: 'lmstudio',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should have meaningful toString', () {
      const config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );

      final string = config.toString();

      expect(string, contains('ollama'));
      expect(string, contains('http://localhost:11434'));
      expect(string, contains('llama3.2'));
    });
  });
}