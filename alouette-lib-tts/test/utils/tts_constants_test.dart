import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/src/utils/tts_constants.dart';

void main() {
  group('TTSConstants', () {
    test('should have correct default values', () {
      expect(TTSConstants.defaultSpeechRate, equals(1.0));
      expect(TTSConstants.defaultVolume, equals(1.0));
      expect(TTSConstants.defaultPitch, equals(1.0));
      expect(TTSConstants.defaultLanguageCode, equals('en-US'));
      expect(TTSConstants.defaultAwaitCompletion, equals(true));
    });

    test('should have correct parameter ranges', () {
      expect(TTSConstants.minSpeechRate, equals(0.0));
      expect(TTSConstants.maxSpeechRate, equals(2.0));
      expect(TTSConstants.minVolume, equals(0.0));
      expect(TTSConstants.maxVolume, equals(1.0));
      expect(TTSConstants.minPitch, equals(0.0));
      expect(TTSConstants.maxPitch, equals(2.0));
    });

    test('should have supported languages', () {
      expect(TTSConstants.supportedLanguages, isNotEmpty);
      expect(TTSConstants.supportedLanguages.length, greaterThan(5));
      
      // Check for some common languages
      final languageCodes = TTSConstants.supportedLanguages.map((l) => l.code).toList();
      expect(languageCodes, contains('en-US'));
      expect(languageCodes, contains('zh-CN'));
      expect(languageCodes, contains('ja-JP'));
      expect(languageCodes, contains('fr-FR'));
    });

    test('should have default language', () {
      expect(TTSConstants.defaultLanguage.code, equals('en-US'));
      expect(TTSConstants.defaultLanguage.name, isNotEmpty);
      expect(TTSConstants.defaultLanguage.flag, isNotEmpty);
    });

    test('should get language by code', () {
      final english = TTSConstants.getLanguageByCode('en-US');
      expect(english, isNotNull);
      expect(english!.code, equals('en-US'));
      
      final chinese = TTSConstants.getLanguageByCode('zh-CN');
      expect(chinese, isNotNull);
      expect(chinese!.code, equals('zh-CN'));
      
      final nonExistent = TTSConstants.getLanguageByCode('xx-XX');
      expect(nonExistent, isNull);
    });

    test('should get supported language codes', () {
      final codes = TTSConstants.supportedLanguageCodes;
      expect(codes, isNotEmpty);
      expect(codes, contains('en-US'));
      expect(codes, contains('zh-CN'));
      expect(codes.length, equals(TTSConstants.supportedLanguages.length));
    });

    test('should check if language is supported', () {
      expect(TTSConstants.isLanguageSupported('en-US'), isTrue);
      expect(TTSConstants.isLanguageSupported('zh-CN'), isTrue);
      expect(TTSConstants.isLanguageSupported('xx-XX'), isFalse);
      expect(TTSConstants.isLanguageSupported(''), isFalse);
    });

    test('should validate speech rate', () {
      expect(TTSConstants.isValidSpeechRate(0.0), isTrue);
      expect(TTSConstants.isValidSpeechRate(1.0), isTrue);
      expect(TTSConstants.isValidSpeechRate(2.0), isTrue);
      expect(TTSConstants.isValidSpeechRate(-0.1), isFalse);
      expect(TTSConstants.isValidSpeechRate(2.1), isFalse);
    });

    test('should validate volume', () {
      expect(TTSConstants.isValidVolume(0.0), isTrue);
      expect(TTSConstants.isValidVolume(0.5), isTrue);
      expect(TTSConstants.isValidVolume(1.0), isTrue);
      expect(TTSConstants.isValidVolume(-0.1), isFalse);
      expect(TTSConstants.isValidVolume(1.1), isFalse);
    });

    test('should validate pitch', () {
      expect(TTSConstants.isValidPitch(0.0), isTrue);
      expect(TTSConstants.isValidPitch(1.0), isTrue);
      expect(TTSConstants.isValidPitch(2.0), isTrue);
      expect(TTSConstants.isValidPitch(-0.1), isFalse);
      expect(TTSConstants.isValidPitch(2.1), isFalse);
    });

    test('should have platform-specific constants', () {
      expect(TTSConstants.androidAudioStreamType, equals('setAudioStreamType'));
      expect(TTSConstants.androidGetMaxVolume, equals('getMaxVolume'));
      expect(TTSConstants.androidGetCurrentVolume, equals('getCurrentVolume'));
    });
  });
}