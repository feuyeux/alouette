import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:alouette_lib_trans/src/services/translation_service.dart';
import 'package:alouette_lib_trans/src/models/llm_config.dart';
import 'package:alouette_lib_trans/src/providers/translation_provider.dart';
import 'package:alouette_lib_trans/src/exceptions/translation_exceptions.dart';

import 'translation_service_test.mocks.dart';

@GenerateMocks([TranslationProvider])
void main() {
  group('TranslationService', () {
    late TranslationService service;
    late MockTranslationProvider mockProvider;
    late LLMConfig testConfig;

    setUp(() {
      service = TranslationService();
      mockProvider = MockTranslationProvider();
      testConfig = const LLMConfig(
        provider: 'test',
        serverUrl: 'http://localhost:8080',
        selectedModel: 'test-model',
      );

      // Register mock provider
      service.registerProvider('test', mockProvider);
    });

    group('translateText', () {
      test('should translate text successfully', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async => 'Hola');

        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'fr',
          config: testConfig,
        )).thenAnswer((_) async => 'Bonjour');

        // Act
        final result = await service.translateText(
          'Hello',
          ['es', 'fr'],
          testConfig,
        );

        // Assert
        expect(result.original, equals('Hello'));
        expect(result.translations['es'], equals('Hola'));
        expect(result.translations['fr'], equals('Bonjour'));
        expect(result.languages, equals(['es', 'fr']));
        expect(result.config, equals(testConfig));
        expect(service.currentTranslation, equals(result));
      });

      test('should throw exception for empty text', () async {
        expect(
          () => service.translateText('', ['es'], testConfig),
          throwsA(isA<TranslationException>()),
        );

        expect(
          () => service.translateText('   ', ['es'], testConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should throw exception for empty languages', () async {
        expect(
          () => service.translateText('Hello', [], testConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should throw exception for empty server URL', () async {
        final invalidConfig = testConfig.copyWith(serverUrl: '');

        expect(
          () => service.translateText('Hello', ['es'], invalidConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should throw exception for empty model', () async {
        final invalidConfig = testConfig.copyWith(selectedModel: '');

        expect(
          () => service.translateText('Hello', ['es'], invalidConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should throw exception for unsupported provider', () async {
        final unsupportedConfig = testConfig.copyWith(provider: 'unsupported');

        expect(
          () => service.translateText('Hello', ['es'], unsupportedConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should handle provider errors', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenThrow(Exception('Provider error'));

        // Act & Assert
        expect(
          () => service.translateText('Hello', ['es'], testConfig),
          throwsA(isA<TranslationException>()),
        );
      });

      test('should set isTranslating flag correctly', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async {
          expect(service.isTranslating, isTrue);
          return 'Hola';
        });

        // Act
        expect(service.isTranslating, isFalse);
        final future = service.translateText('Hello', ['es'], testConfig);
        await future;

        // Assert
        expect(service.isTranslating, isFalse);
      });
    });

    group('createRequest', () {
      test('should create translation request correctly', () {
        final request = service.createRequest(
          'Hello',
          ['es', 'fr'],
          testConfig,
          additionalParams: {'temperature': 0.5},
        );

        expect(request.text, equals('Hello'));
        expect(request.targetLanguages, equals(['es', 'fr']));
        expect(request.provider, equals('test'));
        expect(request.serverUrl, equals('http://localhost:8080'));
        expect(request.modelName, equals('test-model'));
        expect(request.additionalParams, equals({'temperature': 0.5}));
      });
    });

    group('provider management', () {
      test('should register and check providers', () {
        expect(service.isProviderSupported('test'), isTrue);
        expect(service.isProviderSupported('nonexistent'), isFalse);
        expect(service.availableProviders, contains('test'));
      });
    });

    group('state management', () {
      test('should clear translation', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async => 'Hola');

        await service.translateText('Hello', ['es'], testConfig);
        expect(service.currentTranslation, isNotNull);

        // Act
        service.clearTranslation();

        // Assert
        expect(service.currentTranslation, isNull);
      });

      test('should get translation state', () async {
        // Initial state
        var state = service.getTranslationState();
        expect(state['isTranslating'], isFalse);
        expect(state['hasTranslation'], isFalse);
        expect(state['currentTranslation'], isNull);

        // After translation
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async => 'Hola');

        await service.translateText('Hello', ['es'], testConfig);
        state = service.getTranslationState();
        expect(state['isTranslating'], isFalse);
        expect(state['hasTranslation'], isTrue);
        expect(state['currentTranslation'], isNotNull);
      });
    });

    group('formatForDisplay', () {
      test('should format translation for display', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async => 'Hola');

        final result = await service.translateText('Hello', ['es'], testConfig);

        // Act
        final formatted = service.formatForDisplay(result);

        // Assert
        expect(formatted, isNotNull);
        expect(formatted!['original'], equals('Hello'));
        expect(formatted['translations'], equals({'es': 'Hola'}));
        expect(formatted['languages'], equals(['es']));
        expect(formatted['provider'], equals('test'));
        expect(formatted['model'], equals('test-model'));
        expect(formatted['isComplete'], isTrue);
        expect(formatted['availableLanguages'], equals(['es']));
      });

      test('should return null for no translation', () {
        final formatted = service.formatForDisplay();
        expect(formatted, isNull);
      });
    });

    group('getTranslationStats', () {
      test('should return stats for translation', () async {
        // Arrange
        when(mockProvider.translateText(
          text: 'Hello world',
          targetLanguage: 'es',
          config: testConfig,
        )).thenAnswer((_) async => 'Hola mundo');

        when(mockProvider.translateText(
          text: 'Hello world',
          targetLanguage: 'fr',
          config: testConfig,
        )).thenAnswer((_) async => 'Bonjour le monde');

        final result = await service.translateText('Hello world', ['es', 'fr'], testConfig);

        // Act
        final stats = service.getTranslationStats(result);

        // Assert
        expect(stats['totalTranslations'], equals(2));
        expect(stats['completedTranslations'], equals(2));
        expect(stats['completionRate'], equals(1.0));
        expect(stats['originalLength'], equals(11)); // "Hello world".length
        expect(stats['averageTranslationLength'], greaterThan(0));
      });

      test('should return empty stats for no translation', () {
        final stats = service.getTranslationStats();

        expect(stats['totalTranslations'], equals(0));
        expect(stats['completedTranslations'], equals(0));
        expect(stats['completionRate'], equals(0.0));
      });
    });
  });
}