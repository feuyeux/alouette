import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/src/models/tts_config.dart';

void main() {
  group('TTSConfig', () {
    test('should create default config', () {
      final config = TTSConfig.defaultConfig();
      
      expect(config.speechRate, equals(1.0));
      expect(config.volume, equals(1.0));
      expect(config.pitch, equals(1.0));
      expect(config.languageCode, equals('en-US'));
      expect(config.awaitCompletion, equals(true));
      expect(config.platformSpecific, isNull);
    });

    test('should create config with custom values', () {
      final config = TTSConfig(
        speechRate: 1.5,
        volume: 0.8,
        pitch: 1.2,
        languageCode: 'zh-CN',
        awaitCompletion: false,
        platformSpecific: {'test': 'value'},
      );
      
      expect(config.speechRate, equals(1.5));
      expect(config.volume, equals(0.8));
      expect(config.pitch, equals(1.2));
      expect(config.languageCode, equals('zh-CN'));
      expect(config.awaitCompletion, equals(false));
      expect(config.platformSpecific, equals({'test': 'value'}));
    });

    test('should create copy with updated values', () {
      final original = TTSConfig.defaultConfig();
      final copy = original.copyWith(
        speechRate: 1.5,
        languageCode: 'zh-CN',
      );
      
      expect(copy.speechRate, equals(1.5));
      expect(copy.volume, equals(1.0)); // unchanged
      expect(copy.pitch, equals(1.0)); // unchanged
      expect(copy.languageCode, equals('zh-CN'));
      expect(copy.awaitCompletion, equals(true)); // unchanged
    });

    test('should serialize to JSON', () {
      final config = TTSConfig(
        speechRate: 1.5,
        volume: 0.8,
        pitch: 1.2,
        languageCode: 'zh-CN',
        awaitCompletion: false,
      );
      
      final json = config.toJson();
      
      expect(json['speechRate'], equals(1.5));
      expect(json['volume'], equals(0.8));
      expect(json['pitch'], equals(1.2));
      expect(json['languageCode'], equals('zh-CN'));
      expect(json['awaitCompletion'], equals(false));
    });

    test('should deserialize from JSON', () {
      final json = {
        'speechRate': 1.5,
        'volume': 0.8,
        'pitch': 1.2,
        'languageCode': 'zh-CN',
        'awaitCompletion': false,
      };
      
      final config = TTSConfig.fromJson(json);
      
      expect(config.speechRate, equals(1.5));
      expect(config.volume, equals(0.8));
      expect(config.pitch, equals(1.2));
      expect(config.languageCode, equals('zh-CN'));
      expect(config.awaitCompletion, equals(false));
    });

    test('should handle missing JSON fields with defaults', () {
      final json = <String, dynamic>{};
      
      final config = TTSConfig.fromJson(json);
      
      expect(config.speechRate, equals(1.0));
      expect(config.volume, equals(1.0));
      expect(config.pitch, equals(1.0));
      expect(config.languageCode, equals('en-US'));
      expect(config.awaitCompletion, equals(true));
    });

    test('should validate configuration', () {
      // Valid config
      final validConfig = TTSConfig(
        speechRate: 1.0,
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );
      expect(validConfig.isValid(), isTrue);

      // Invalid speech rate
      final invalidSpeechRate = TTSConfig(
        speechRate: 3.0, // > 2.0
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );
      expect(invalidSpeechRate.isValid(), isFalse);

      // Invalid volume
      final invalidVolume = TTSConfig(
        speechRate: 1.0,
        volume: 1.5, // > 1.0
        pitch: 1.0,
        languageCode: 'en-US',
      );
      expect(invalidVolume.isValid(), isFalse);

      // Invalid pitch
      final invalidPitch = TTSConfig(
        speechRate: 1.0,
        volume: 0.5,
        pitch: -0.5, // < 0.0
        languageCode: 'en-US',
      );
      expect(invalidPitch.isValid(), isFalse);

      // Empty language code
      final emptyLanguage = TTSConfig(
        speechRate: 1.0,
        volume: 0.5,
        pitch: 1.0,
        languageCode: '',
      );
      expect(emptyLanguage.isValid(), isFalse);
    });

    test('should implement equality correctly', () {
      final config1 = TTSConfig(
        speechRate: 1.0,
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );
      
      final config2 = TTSConfig(
        speechRate: 1.0,
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );
      
      final config3 = TTSConfig(
        speechRate: 1.5,
        volume: 0.5,
        pitch: 1.0,
        languageCode: 'en-US',
      );
      
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('should have meaningful toString', () {
      final config = TTSConfig(
        speechRate: 1.5,
        volume: 0.8,
        pitch: 1.2,
        languageCode: 'zh-CN',
      );
      
      final string = config.toString();
      
      expect(string, contains('TTSConfig'));
      expect(string, contains('speechRate: 1.5'));
      expect(string, contains('volume: 0.8'));
      expect(string, contains('pitch: 1.2'));
      expect(string, contains('languageCode: zh-CN'));
    });
  });
}