import '../models/language_option.dart';

/// TTS Constants containing default values and supported languages
class TTSConstants {
  // Default TTS configuration values
  static const double defaultSpeechRate = 1.0;
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;
  static const String defaultLanguageCode = 'en-US';
  static const bool defaultAwaitCompletion = true;

  // TTS parameter ranges
  static const double minSpeechRate = 0.0;
  static const double maxSpeechRate = 2.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
  static const double minPitch = 0.0;
  static const double maxPitch = 2.0;

  // Supported languages list
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'zh-CN', name: '简体中文', flag: '🇨🇳'),
    LanguageOption(code: 'en-US', name: 'English (US)', flag: '🇺🇸'),
    LanguageOption(code: 'ja-JP', name: '日本語', flag: '🇯🇵'),
    LanguageOption(code: 'ko-KR', name: '한국어', flag: '🇰🇷'),
    LanguageOption(code: 'fr-FR', name: 'Français', flag: '🇫🇷'),
    LanguageOption(code: 'de-DE', name: 'Deutsch', flag: '🇩🇪'),
    LanguageOption(code: 'es-ES', name: 'Español', flag: '🇪🇸'),
    LanguageOption(code: 'it-IT', name: 'Italiano', flag: '🇮🇹'),
    LanguageOption(code: 'ru-RU', name: 'Русский', flag: '🇷🇺'),
    LanguageOption(code: 'ar-SA', name: 'العربية', flag: '🇸🇦'),
    LanguageOption(code: 'hi-IN', name: 'हिंदी', flag: '🇮🇳'),
    LanguageOption(code: 'el-GR', name: 'Ελληνικά', flag: '🇬🇷'),
  ];

  // Default language
  static const LanguageOption defaultLanguage = 
    LanguageOption(code: 'en-US', name: 'English (US)', flag: '🇺🇸');

  // Platform-specific constants
  static const String androidAudioStreamType = 'setAudioStreamType';
  static const String androidGetMaxVolume = 'getMaxVolume';
  static const String androidGetCurrentVolume = 'getCurrentVolume';

  /// Get language option by code
  static LanguageOption? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get all supported language codes
  static List<String> get supportedLanguageCodes {
    return supportedLanguages.map((lang) => lang.code).toList();
  }

  /// Check if a language code is supported
  static bool isLanguageSupported(String code) {
    return supportedLanguageCodes.contains(code);
  }

  /// Validate speech rate value
  static bool isValidSpeechRate(double rate) {
    return rate >= minSpeechRate && rate <= maxSpeechRate;
  }

  /// Validate volume value
  static bool isValidVolume(double volume) {
    return volume >= minVolume && volume <= maxVolume;
  }

  /// Validate pitch value
  static bool isValidPitch(double pitch) {
    return pitch >= minPitch && pitch <= maxPitch;
  }
}