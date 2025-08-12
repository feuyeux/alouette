import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/src/utils/text_cleaner.dart';

void main() {
  group('TextCleaner', () {
    group('cleanTranslationResult', () {
      test('should remove common prefixes', () {
        expect(
          TextCleaner.cleanTranslationResult('Translation: Hola mundo', 'es'),
          equals('Hola mundo'),
        );

        expect(
          TextCleaner.cleanTranslationResult('Here is the translation: Bonjour', 'fr'),
          equals('Bonjour'),
        );

        expect(
          TextCleaner.cleanTranslationResult('1. Guten Tag', 'de'),
          equals('Guten Tag'),
        );
      });

      test('should remove wrapping quotes', () {
        expect(
          TextCleaner.cleanTranslationResult('"Hola mundo"', 'es'),
          equals('Hola mundo'),
        );

        expect(
          TextCleaner.cleanTranslationResult("'Bonjour le monde'", 'fr'),
          equals('Bonjour le monde'),
        );

        expect(
          TextCleaner.cleanTranslationResult('`Guten Tag`', 'de'),
          equals('Guten Tag'),
        );
      });

      test('should handle multi-line responses', () {
        const multiLine = '''Translation: Hola mundo
        
        This is an explanation of the translation.''';

        expect(
          TextCleaner.cleanTranslationResult(multiLine, 'es'),
          equals('Hola mundo'),
        );
      });

      test('should handle empty or whitespace input', () {
        expect(
          TextCleaner.cleanTranslationResult('', 'es'),
          equals(''),
        );

        expect(
          TextCleaner.cleanTranslationResult('   ', 'es'),
          equals(''),
        );
      });

      test('should preserve valid translations without artifacts', () {
        expect(
          TextCleaner.cleanTranslationResult('Hola mundo', 'es'),
          equals('Hola mundo'),
        );

        expect(
          TextCleaner.cleanTranslationResult('Bonjour le monde!', 'fr'),
          equals('Bonjour le monde!'),
        );
      });

      test('should handle complex cases', () {
        const complex = '''Answer: "¡Hola, mundo!" (Spanish translation)''';

        expect(
          TextCleaner.cleanTranslationResult(complex, 'es'),
          equals('¡Hola, mundo!'),
        );
      });
    });

    group('isValidTranslation', () {
      test('should return false for empty text', () {
        expect(TextCleaner.isValidTranslation('', 'Hello'), isFalse);
        expect(TextCleaner.isValidTranslation('   ', 'Hello'), isFalse);
      });

      test('should return false for identical text', () {
        expect(TextCleaner.isValidTranslation('Hello', 'Hello'), isFalse);
        expect(TextCleaner.isValidTranslation('hello', 'HELLO'), isFalse);
      });

      test('should return false for error patterns', () {
        expect(TextCleaner.isValidTranslation('Error: Cannot translate', 'Hello'), isFalse);
        expect(TextCleaner.isValidTranslation('Sorry, I cannot help', 'Hello'), isFalse);
        expect(TextCleaner.isValidTranslation("I don't understand", 'Hello'), isFalse);
      });

      test('should return true for valid translations', () {
        expect(TextCleaner.isValidTranslation('Hola', 'Hello'), isTrue);
        expect(TextCleaner.isValidTranslation('Bonjour', 'Hello'), isTrue);
        expect(TextCleaner.isValidTranslation('Guten Tag', 'Hello'), isTrue);
      });
    });

    group('cleanAndValidate', () {
      test('should clean and validate successfully', () {
        final result = TextCleaner.cleanAndValidate(
          'Translation: Hola mundo',
          'es',
          'Hello world',
        );

        expect(result, equals('Hola mundo'));
      });

      test('should throw exception for invalid translation', () {
        expect(
          () => TextCleaner.cleanAndValidate('Hello world', 'es', 'Hello world'),
          throwsException,
        );
      });
    });

    group('normalizeText', () {
      test('should normalize whitespace and case', () {
        expect(
          TextCleaner.normalizeText('  Hello   World  '),
          equals('hello world'),
        );

        expect(
          TextCleaner.normalizeText('HELLO\t\nWORLD'),
          equals('hello world'),
        );
      });
    });

    group('cleanLanguageSpecific', () {
      test('should handle Chinese specific cleaning', () {
        expect(
          TextCleaner.cleanLanguageSpecific('翻译: 你好世界', 'zh'),
          equals('你好世界'),
        );

        expect(
          TextCleaner.cleanLanguageSpecific('翻译：你好世界', 'chinese'),
          equals('你好世界'),
        );
      });

      test('should handle Japanese specific cleaning', () {
        expect(
          TextCleaner.cleanLanguageSpecific('翻訳: こんにちは世界', 'ja'),
          equals('こんにちは世界'),
        );
      });

      test('should pass through other languages unchanged', () {
        expect(
          TextCleaner.cleanLanguageSpecific('Hola mundo', 'es'),
          equals('Hola mundo'),
        );
      });
    });

    group('edge cases', () {
      test('should handle very short text', () {
        expect(
          TextCleaner.cleanTranslationResult('A', 'en'),
          equals('A'),
        );
      });

      test('should handle text with only punctuation', () {
        expect(
          TextCleaner.cleanTranslationResult('!!!', 'en'),
          equals('!!!'),
        );
      });

      test('should handle mixed language text', () {
        expect(
          TextCleaner.cleanTranslationResult('Hello 世界', 'mixed'),
          equals('Hello 世界'),
        );
      });

      test('should handle RTL languages', () {
        expect(
          TextCleaner.cleanTranslationResult('مرحبا بالعالم', 'ar'),
          equals('مرحبا بالعالم'),
        );
      });
    });
  });
}