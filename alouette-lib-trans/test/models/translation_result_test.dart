import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/src/models/llm_config.dart';
import 'package:alouette_lib_trans/src/models/translation_result.dart';

void main() {
  group('TranslationResult', () {
    late LLMConfig testConfig;
    late DateTime testTimestamp;

    setUp(() {
      testConfig = const LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: 'llama3.2',
      );
      testTimestamp = DateTime.now();
    });

    test('should create TranslationResult with required fields', () {
      final result = TranslationResult(
        original: 'Hello, world!',
        translations: {'es': 'Hola, mundo!', 'fr': 'Bonjour, le monde!'},
        languages: ['es', 'fr'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      expect(result.original, equals('Hello, world!'));
      expect(result.translations, equals({'es': 'Hola, mundo!', 'fr': 'Bonjour, le monde!'}));
      expect(result.languages, equals(['es', 'fr']));
      expect(result.timestamp, equals(testTimestamp));
      expect(result.config, equals(testConfig));
      expect(result.metadata, isNull);
    });

    test('should get translation for specific language', () {
      final result = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola', 'fr': 'Bonjour'},
        languages: ['es', 'fr'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      expect(result.getTranslation('es'), equals('Hola'));
      expect(result.getTranslation('fr'), equals('Bonjour'));
      expect(result.getTranslation('de'), isNull);
    });

    test('should check if translation exists', () {
      final result = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola', 'fr': '', 'de': 'Hallo'},
        languages: ['es', 'fr', 'de'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      expect(result.hasTranslation('es'), isTrue);
      expect(result.hasTranslation('fr'), isFalse); // empty translation
      expect(result.hasTranslation('de'), isTrue);
      expect(result.hasTranslation('it'), isFalse); // not in translations
    });

    test('should get available languages', () {
      final result = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola', 'fr': '', 'de': 'Hallo'},
        languages: ['es', 'fr', 'de'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final available = result.availableLanguages;
      expect(available, contains('es'));
      expect(available, contains('de'));
      expect(available, isNot(contains('fr'))); // empty translation
    });

    test('should check if translation is complete', () {
      final completeResult = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola', 'fr': 'Bonjour'},
        languages: ['es', 'fr'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final incompleteResult = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola'},
        languages: ['es', 'fr'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      expect(completeResult.isComplete, isTrue);
      expect(incompleteResult.isComplete, isFalse);
    });

    test('should convert to JSON correctly', () {
      final result = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola'},
        languages: ['es'],
        timestamp: testTimestamp,
        config: testConfig,
        metadata: {'test': 'value'},
      );

      final json = result.toJson();

      expect(json['original'], equals('Hello'));
      expect(json['translations'], equals({'es': 'Hola'}));
      expect(json['languages'], equals(['es']));
      expect(json['timestamp'], equals(testTimestamp.toIso8601String()));
      expect(json['config'], equals(testConfig.toJson()));
      expect(json['metadata'], equals({'test': 'value'}));
    });

    test('should create from JSON correctly', () {
      final json = {
        'original': 'Hello',
        'translations': {'es': 'Hola'},
        'languages': ['es'],
        'timestamp': testTimestamp.toIso8601String(),
        'metadata': {'test': 'value'},
      };

      final result = TranslationResult.fromJson(json, testConfig);

      expect(result.original, equals('Hello'));
      expect(result.translations, equals({'es': 'Hola'}));
      expect(result.languages, equals(['es']));
      expect(result.timestamp, equals(testTimestamp));
      expect(result.config, equals(testConfig));
      expect(result.metadata, equals({'test': 'value'}));
    });

    test('should create copy with modified fields', () {
      final original = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola'},
        languages: ['es'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final newTimestamp = DateTime.now().add(const Duration(hours: 1));
      final modified = original.copyWith(
        translations: {'es': 'Hola', 'fr': 'Bonjour'},
        timestamp: newTimestamp,
      );

      expect(modified.original, equals('Hello')); // unchanged
      expect(modified.translations, equals({'es': 'Hola', 'fr': 'Bonjour'}));
      expect(modified.timestamp, equals(newTimestamp));
    });

    test('should implement equality correctly', () {
      final result1 = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola'},
        languages: ['es'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final result2 = TranslationResult(
        original: 'Hello',
        translations: {'es': 'Hola'},
        languages: ['es'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final result3 = TranslationResult(
        original: 'Hi',
        translations: {'es': 'Hola'},
        languages: ['es'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('should have meaningful toString', () {
      final result = TranslationResult(
        original: 'Hello, world! This is a long text for testing',
        translations: {'es': 'Hola', 'fr': 'Bonjour'},
        languages: ['es', 'fr'],
        timestamp: testTimestamp,
        config: testConfig,
      );

      final string = result.toString();

      expect(string, contains('Hello, world! This is a long')); // truncated
      expect(string, contains('es'));
      expect(string, contains('fr'));
      expect(string, contains('2')); // translation count
    });
  });
}