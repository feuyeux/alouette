import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_lib_tts/src/models/language_option.dart';

void main() {
  group('LanguageOption', () {
    test('should create language option with required fields', () {
      const option = LanguageOption(
        code: 'en-US',
        name: 'English (US)',
        flag: '🇺🇸',
      );
      
      expect(option.code, equals('en-US'));
      expect(option.name, equals('English (US)'));
      expect(option.flag, equals('🇺🇸'));
    });

    test('should create copy with updated values', () {
      const original = LanguageOption(
        code: 'en-US',
        name: 'English (US)',
        flag: '🇺🇸',
      );
      
      final copy = original.copyWith(
        name: 'American English',
      );
      
      expect(copy.code, equals('en-US')); // unchanged
      expect(copy.name, equals('American English'));
      expect(copy.flag, equals('🇺🇸')); // unchanged
    });

    test('should serialize to JSON', () {
      const option = LanguageOption(
        code: 'zh-CN',
        name: '简体中文',
        flag: '🇨🇳',
      );
      
      final json = option.toJson();
      
      expect(json['code'], equals('zh-CN'));
      expect(json['name'], equals('简体中文'));
      expect(json['flag'], equals('🇨🇳'));
    });

    test('should deserialize from JSON', () {
      final json = {
        'code': 'ja-JP',
        'name': '日本語',
        'flag': '🇯🇵',
      };
      
      final option = LanguageOption.fromJson(json);
      
      expect(option.code, equals('ja-JP'));
      expect(option.name, equals('日本語'));
      expect(option.flag, equals('🇯🇵'));
    });

    test('should implement equality correctly', () {
      const option1 = LanguageOption(
        code: 'fr-FR',
        name: 'Français',
        flag: '🇫🇷',
      );
      
      const option2 = LanguageOption(
        code: 'fr-FR',
        name: 'Français',
        flag: '🇫🇷',
      );
      
      const option3 = LanguageOption(
        code: 'fr-FR',
        name: 'French',
        flag: '🇫🇷',
      );
      
      expect(option1, equals(option2));
      expect(option1, isNot(equals(option3)));
      expect(option1.hashCode, equals(option2.hashCode));
      expect(option1.hashCode, isNot(equals(option3.hashCode)));
    });

    test('should have meaningful toString', () {
      const option = LanguageOption(
        code: 'de-DE',
        name: 'Deutsch',
        flag: '🇩🇪',
      );
      
      final string = option.toString();
      
      expect(string, contains('LanguageOption'));
      expect(string, contains('code: de-DE'));
      expect(string, contains('name: Deutsch'));
      expect(string, contains('flag: 🇩🇪'));
    });
  });
}