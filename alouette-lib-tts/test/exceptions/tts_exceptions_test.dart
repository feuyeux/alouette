import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/src/exceptions/tts_exceptions.dart';

void main() {
  group('TTS Exceptions', () {
    test('TTSException should have message and optional original error', () {
      const exception = TTSInitializationException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.originalError, isNull);
      expect(exception.toString(), contains('TTSInitializationException: Test message'));
      
      const exceptionWithError = TTSInitializationException('Test message', 'original error');
      expect(exceptionWithError.originalError, equals('original error'));
    });

    test('TTSInitializationException should format correctly', () {
      const exception = TTSInitializationException('Failed to initialize');
      expect(exception.toString(), equals('TTSInitializationException: Failed to initialize'));
    });

    test('TTSPlatformException should include platform info', () {
      const exception = TTSPlatformException('Platform error', 'android');
      expect(exception.platform, equals('android'));
      expect(exception.toString(), equals('TTSPlatformException [android]: Platform error'));
    });

    test('TTSLanguageNotSupportedException should include language code', () {
      const exception = TTSLanguageNotSupportedException('Language not supported', 'xx-XX');
      expect(exception.languageCode, equals('xx-XX'));
      expect(exception.toString(), equals('TTSLanguageNotSupportedException [xx-XX]: Language not supported'));
    });

    test('TTSConfigurationException should include config field', () {
      const exception = TTSConfigurationException('Invalid config', 'speechRate');
      expect(exception.configField, equals('speechRate'));
      expect(exception.toString(), equals('TTSConfigurationException [speechRate]: Invalid config'));
    });

    test('TTSSpeechException should format correctly', () {
      const exception = TTSSpeechException('Speech failed');
      expect(exception.toString(), equals('TTSSpeechException: Speech failed'));
    });

    test('TTSNotInitializedException should have default message', () {
      const exception = TTSNotInitializedException();
      expect(exception.message, contains('not been initialized'));
      expect(exception.toString(), contains('TTSNotInitializedException'));
      
      const customException = TTSNotInitializedException('Custom message');
      expect(customException.message, equals('Custom message'));
    });

    test('All exceptions should be instances of TTSException', () {
      const initException = TTSInitializationException('test');
      const platformException = TTSPlatformException('test', 'android');
      const languageException = TTSLanguageNotSupportedException('test', 'xx-XX');
      const configException = TTSConfigurationException('test', 'field');
      const speechException = TTSSpeechException('test');
      const notInitException = TTSNotInitializedException('test');
      
      expect(initException, isA<TTSException>());
      expect(platformException, isA<TTSException>());
      expect(languageException, isA<TTSException>());
      expect(configException, isA<TTSException>());
      expect(speechException, isA<TTSException>());
      expect(notInitException, isA<TTSException>());
    });

    test('All exceptions should implement Exception', () {
      const initException = TTSInitializationException('test');
      const platformException = TTSPlatformException('test', 'android');
      const languageException = TTSLanguageNotSupportedException('test', 'xx-XX');
      const configException = TTSConfigurationException('test', 'field');
      const speechException = TTSSpeechException('test');
      const notInitException = TTSNotInitializedException('test');
      
      expect(initException, isA<Exception>());
      expect(platformException, isA<Exception>());
      expect(languageException, isA<Exception>());
      expect(configException, isA<Exception>());
      expect(speechException, isA<Exception>());
      expect(notInitException, isA<Exception>());
    });
  });
}