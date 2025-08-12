import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_tts/src/services/tts_service.dart';
import 'package:alouette_lib_tts/src/models/tts_config.dart';
import 'package:alouette_lib_tts/src/models/tts_state.dart';
import 'package:alouette_lib_tts/src/exceptions/tts_exceptions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TTSService', () {
    late TTSService ttsService;

    setUp(() {
      // Mock the method channel to avoid platform-specific issues in tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'speak':
              return null;
            case 'stop':
              return null;
            case 'setSpeechRate':
              return null;
            case 'setVolume':
              return null;
            case 'setPitch':
              return null;
            case 'setLanguage':
              return null;
            case 'getLanguages':
              return ['en-US', 'zh-CN', 'ja-JP'];
            case 'awaitSpeakCompletion':
              return null;
            case 'setSharedInstance':
              return null;
            default:
              return null;
          }
        },
      );
      
      // Mock Android audio channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.alouette.lib.tts/audio'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'setAudioStreamType':
              return true;
            case 'getMaxVolume':
              return 15;
            case 'getCurrentVolume':
              return 10;
            default:
              return null;
          }
        },
      );
      
      ttsService = TTSService();
    });

    tearDown(() {
      ttsService.dispose();
      // Clear mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.alouette.lib.tts/audio'), null);
    });

    test('should have correct initial state', () {
      expect(ttsService.isInitialized, isFalse);
      expect(ttsService.currentState, equals(TTSState.stopped));
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.isStopped, isTrue);
    });

    test('should throw exception when not initialized', () async {
      expect(
        () async => await ttsService.speak(
          text: 'Hello',
          languageCode: 'en-US',
          speechRate: 1.0,
          volume: 1.0,
          pitch: 1.0,
        ),
        throwsA(isA<TTSNotInitializedException>()),
      );

      expect(
        () async => await ttsService.stop(),
        throwsA(isA<TTSNotInitializedException>()),
      );

      expect(
        () async => await ttsService.setSpeechRate(1.0),
        throwsA(isA<TTSNotInitializedException>()),
      );
    });

    test('should validate speech parameters', () async {
      await ttsService.initialize(
        onStart: () {},
        onComplete: () {},
        onError: (error) {},
      );

      // Test invalid speech rate
      expect(
        () async => await ttsService.setSpeechRate(3.0),
        throwsA(isA<TTSConfigurationException>()),
      );

      // Test invalid volume
      expect(
        () async => await ttsService.setVolume(1.5),
        throwsA(isA<TTSConfigurationException>()),
      );

      // Test invalid pitch
      expect(
        () async => await ttsService.setPitch(-0.5),
        throwsA(isA<TTSConfigurationException>()),
      );

      // Test empty text
      expect(
        () async => await ttsService.speak(
          text: '',
          languageCode: 'en-US',
          speechRate: 1.0,
          volume: 1.0,
          pitch: 1.0,
        ),
        throwsA(isA<TTSSpeechException>()),
      );
    });

    test('should handle configuration updates', () {
      final config = TTSConfig(
        speechRate: 1.5,
        volume: 0.8,
        pitch: 1.2,
        languageCode: 'zh-CN',
      );

      expect(config.isValid(), isTrue);
      
      // Test getter methods (these work without initialization)
      expect(ttsService.currentConfig.speechRate, equals(1.0)); // default
      expect(ttsService.currentConfig.volume, equals(1.0)); // default
      expect(ttsService.currentConfig.pitch, equals(1.0)); // default
      expect(ttsService.currentConfig.languageCode, equals('en-US')); // default
    });

    test('should provide supported languages', () {
      final languages = ttsService.getSupportedLanguages();
      expect(languages, isNotEmpty);
      expect(languages.any((lang) => lang.code == 'en-US'), isTrue);
      expect(languages.any((lang) => lang.code == 'zh-CN'), isTrue);
    });

    test('should get language by code', () {
      final english = ttsService.getLanguageByCode('en-US');
      expect(english, isNotNull);
      expect(english!.code, equals('en-US'));

      final nonExistent = ttsService.getLanguageByCode('xx-XX');
      expect(nonExistent, isNull);
    });

    test('should handle invalid configuration', () async {
      final invalidConfig = TTSConfig(
        speechRate: 3.0, // Invalid: > 2.0
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );

      expect(invalidConfig.isValid(), isFalse);

      expect(
        () async => await ttsService.initialize(
          onStart: () {},
          onComplete: () {},
          onError: (error) {},
          config: invalidConfig,
        ),
        throwsA(isA<TTSInitializationException>()),
      );
    });

    test('should dispose properly', () {
      ttsService.dispose();
      expect(ttsService.currentState, equals(TTSState.stopped));
      expect(ttsService.isInitialized, isFalse);
    });

    test('should handle unsupported language', () async {
      await ttsService.initialize(
        onStart: () {},
        onComplete: () {},
        onError: (error) {},
      );

      expect(
        () async => await ttsService.setLanguage('xx-XX'),
        throwsA(isA<TTSLanguageNotSupportedException>()),
      );
    });

    test('should maintain state correctly', () {
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.isStopped, isTrue);
      
      // State should remain stopped until actually speaking
      expect(ttsService.currentState, equals(TTSState.stopped));
    });
  });
}