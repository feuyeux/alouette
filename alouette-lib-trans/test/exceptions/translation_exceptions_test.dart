import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_trans/src/exceptions/translation_exceptions.dart';

void main() {
  group('TranslationExceptions', () {
    group('TranslationException', () {
      test('should create basic exception', () {
        const exception = TranslationException('Test error');

        expect(exception.message, equals('Test error'));
        expect(exception.code, isNull);
        expect(exception.details, isNull);
        expect(exception.toString(), equals('TranslationException: Test error'));
      });

      test('should create exception with code and details', () {
        const exception = TranslationException(
          'Test error',
          code: 'TEST_001',
          details: {'key': 'value'},
        );

        expect(exception.message, equals('Test error'));
        expect(exception.code, equals('TEST_001'));
        expect(exception.details, equals({'key': 'value'}));
        expect(exception.toString(), equals('TranslationException [TEST_001]: Test error'));
      });
    });

    group('LLMConnectionException', () {
      test('should create connection exception', () {
        const exception = LLMConnectionException('Connection failed');

        expect(exception.message, equals('Connection failed'));
        expect(exception.toString(), contains('LLMConnectionException'));
      });

      test('should create connection exception with code', () {
        const exception = LLMConnectionException(
          'Connection failed',
          code: 'CONN_001',
        );

        expect(exception.toString(), equals('LLMConnectionException [CONN_001]: Connection failed'));
      });
    });

    group('LLMAuthenticationException', () {
      test('should create authentication exception', () {
        const exception = LLMAuthenticationException('Auth failed');

        expect(exception.message, equals('Auth failed'));
        expect(exception.toString(), contains('LLMAuthenticationException'));
      });
    });

    group('LLMModelNotFoundException', () {
      test('should create model not found exception', () {
        const exception = LLMModelNotFoundException(
          'Model not found',
          'gpt-4',
        );

        expect(exception.message, equals('Model not found'));
        expect(exception.modelName, equals('gpt-4'));
        expect(exception.toString(), contains('Model: gpt-4'));
      });

      test('should create model not found exception with code', () {
        const exception = LLMModelNotFoundException(
          'Model not found',
          'gpt-4',
          code: 'MODEL_001',
        );

        expect(exception.toString(), equals('LLMModelNotFoundException [MODEL_001]: Model not found (Model: gpt-4)'));
      });
    });

    group('TranslationTimeoutException', () {
      test('should create timeout exception', () {
        const exception = TranslationTimeoutException('Request timed out');

        expect(exception.message, equals('Request timed out'));
        expect(exception.timeout, isNull);
        expect(exception.toString(), contains('TranslationTimeoutException'));
      });

      test('should create timeout exception with duration', () {
        const timeout = Duration(seconds: 30);
        const exception = TranslationTimeoutException(
          'Request timed out',
          timeout: timeout,
        );

        expect(exception.timeout, equals(timeout));
        expect(exception.toString(), contains('Timeout: 30s'));
      });
    });

    group('InvalidTranslationException', () {
      test('should create invalid translation exception', () {
        const exception = InvalidTranslationException(
          'Invalid translation',
          'Hello world',
          'es',
        );

        expect(exception.message, equals('Invalid translation'));
        expect(exception.originalText, equals('Hello world'));
        expect(exception.targetLanguage, equals('es'));
        expect(exception.toString(), contains('Language: es'));
      });
    });

    group('ConfigurationException', () {
      test('should create configuration exception', () {
        const exception = ConfigurationException('Invalid config');

        expect(exception.message, equals('Invalid config'));
        expect(exception.field, isNull);
        expect(exception.toString(), contains('ConfigurationException'));
      });

      test('should create configuration exception with field', () {
        const exception = ConfigurationException(
          'Invalid config',
          field: 'serverUrl',
        );

        expect(exception.field, equals('serverUrl'));
        expect(exception.toString(), contains('Field: serverUrl'));
      });
    });

    group('UnsupportedProviderException', () {
      test('should create unsupported provider exception', () {
        const exception = UnsupportedProviderException(
          'Provider not supported',
          'unknown',
          ['ollama', 'lmstudio'],
        );

        expect(exception.message, equals('Provider not supported'));
        expect(exception.providerName, equals('unknown'));
        expect(exception.supportedProviders, equals(['ollama', 'lmstudio']));
        expect(exception.toString(), contains('Provider: unknown'));
        expect(exception.toString(), contains('Supported: ollama, lmstudio'));
      });
    });

    group('RateLimitException', () {
      test('should create rate limit exception', () {
        const exception = RateLimitException('Rate limit exceeded');

        expect(exception.message, equals('Rate limit exceeded'));
        expect(exception.resetTime, isNull);
        expect(exception.remainingRequests, isNull);
        expect(exception.toString(), contains('RateLimitException'));
      });

      test('should create rate limit exception with reset time', () {
        final resetTime = DateTime.now().add(const Duration(minutes: 5));
        final exception = RateLimitException(
          'Rate limit exceeded',
          resetTime: resetTime,
          remainingRequests: 0,
        );

        expect(exception.resetTime, equals(resetTime));
        expect(exception.remainingRequests, equals(0));
        expect(exception.toString(), contains('Reset: $resetTime'));
      });
    });

    group('Exception hierarchy', () {
      test('should maintain proper inheritance', () {
        const baseException = TranslationException('Base error');
        const connectionException = LLMConnectionException('Connection error');
        const authException = LLMAuthenticationException('Auth error');

        expect(baseException, isA<Exception>());
        expect(connectionException, isA<TranslationException>());
        expect(connectionException, isA<Exception>());
        expect(authException, isA<TranslationException>());
        expect(authException, isA<Exception>());
      });
    });
  });
}