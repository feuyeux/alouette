import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/alouette_lib_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TTS Library Integration Tests', () {
    test('should handle TTS service creation without initialization', () {
      final ttsService = TTSService();
      expect(ttsService.isInitialized, isFalse);
      expect(ttsService.currentState, equals(TTSState.stopped));
      ttsService.dispose();
    });

    test('should handle initialization errors gracefully', () async {
      final ttsService = TTSService();

      // This will fail in test environment due to missing platform implementation
      expect(() async => await ttsService.initialize(
        onStart: () {},
        onComplete: () {},
        onError: (message) {},
      ), throwsA(isA<TTSInitializationException>()));

      ttsService.dispose();
    });

    test('should throw exceptions when not initialized', () async {
      final ttsService = TTSService();

      expect(() async => await ttsService.getLanguages(), 
             throwsA(isA<TTSNotInitializedException>()));
      
      expect(() async => await ttsService.speak(
        text: 'Test',
        languageCode: 'en-US',
        speechRate: 0.5,
        volume: 0.8,
        pitch: 1.0,
      ), throwsA(isA<TTSNotInitializedException>()));

      expect(() async => await ttsService.setSpeechRate(0.5), 
             throwsA(isA<TTSNotInitializedException>()));

      ttsService.dispose();
    });

    test('should validate TTS configuration models', () {
      final config = TTSConfig(
        speechRate: 0.5,
        volume: 0.8,
        pitch: 1.2,
        languageCode: 'en-US',
        awaitCompletion: true,
      );

      expect(config.speechRate, equals(0.5));
      expect(config.volume, equals(0.8));
      expect(config.pitch, equals(1.2));
      expect(config.languageCode, equals('en-US'));
      expect(config.awaitCompletion, isTrue);

      // Test serialization
      final json = config.toJson();
      final configFromJson = TTSConfig.fromJson(json);
      expect(configFromJson.speechRate, equals(config.speechRate));
      expect(configFromJson.volume, equals(config.volume));
      expect(configFromJson.pitch, equals(config.pitch));
      expect(configFromJson.languageCode, equals(config.languageCode));
    });

    test('should validate language option models', () {
      final languageOption = LanguageOption(
        code: 'en-US',
        name: 'English (US)',
        flag: '🇺🇸',
      );

      expect(languageOption.code, equals('en-US'));
      expect(languageOption.name, equals('English (US)'));
      expect(languageOption.flag, equals('🇺🇸'));

      // Test serialization
      final json = languageOption.toJson();
      final optionFromJson = LanguageOption.fromJson(json);
      expect(optionFromJson.code, equals(languageOption.code));
      expect(optionFromJson.name, equals(languageOption.name));
      expect(optionFromJson.flag, equals(languageOption.flag));
    });
  });
}