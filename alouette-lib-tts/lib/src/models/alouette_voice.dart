import 'package:meta/meta.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../enums/tts_platform.dart';
import '../enums/audio_format.dart';

/// Unified voice model that abstracts platform-specific voice information
@immutable
class AlouetteVoice {
  /// Unique identifier for the voice
  final String id;
  
  /// Display name of the voice
  final String name;
  
  /// BCP 47 language tag (e.g., 'en-US', 'es-ES')
  final String languageCode;
  
  /// ISO country code (optional)
  final String? countryCode;
  
  /// Voice gender
  final VoiceGender gender;
  
  /// Voice quality level
  final VoiceQuality quality;
  
  /// Source platform for this voice
  final TTSPlatform platform;
  
  /// Whether this is the default voice for the language
  final bool isDefault;
  
  /// Additional metadata about the voice
  final Map<String, dynamic> metadata;

  const AlouetteVoice({
    required this.id,
    required this.name,
    required this.languageCode,
    this.countryCode,
    required this.gender,
    required this.quality,
    required this.platform,
    this.isDefault = false,
    this.metadata = const {},
  });

  /// Creates a voice from platform-specific data
  factory AlouetteVoice.fromPlatformData({
    required String id,
    required String name,
    required String languageCode,
    required TTSPlatform platform,
    String? countryCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    bool isDefault = false,
    Map<String, dynamic> metadata = const {},
  }) {
    return AlouetteVoice(
      id: id,
      name: name,
      languageCode: languageCode,
      countryCode: countryCode,
      gender: gender ?? VoiceGender.neutral,
      quality: quality ?? VoiceQuality.standard,
      platform: platform,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Returns the language name from the language code
  String get languageName {
    final parts = languageCode.split('-');
    final language = parts.first.toLowerCase();
    
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese';
      case 'ar':
        return 'Arabic';
      case 'hi':
        return 'Hindi';
      default:
        return language.toUpperCase();
    }
  }

  /// Returns the country name from the country code
  String? get countryName {
    if (countryCode == null) return null;
    
    switch (countryCode!.toUpperCase()) {
      case 'US':
        return 'United States';
      case 'GB':
        return 'United Kingdom';
      case 'CA':
        return 'Canada';
      case 'AU':
        return 'Australia';
      case 'ES':
        return 'Spain';
      case 'MX':
        return 'Mexico';
      case 'FR':
        return 'France';
      case 'DE':
        return 'Germany';
      case 'IT':
        return 'Italy';
      case 'BR':
        return 'Brazil';
      case 'PT':
        return 'Portugal';
      case 'RU':
        return 'Russia';
      case 'JP':
        return 'Japan';
      case 'KR':
        return 'South Korea';
      case 'CN':
        return 'China';
      default:
        return countryCode;
    }
  }

  /// Returns a display name combining language and country
  String get displayName {
    final country = countryName;
    if (country != null) {
      return '$name ($languageName - $country)';
    }
    return '$name ($languageName)';
  }

  /// Checks if this voice supports SSML
  bool supportsSSML() {
    // Desktop platforms with edge-tts generally support SSML
    if (platform.isDesktop) return true;
    
    // Mobile and web support varies
    return metadata['supportsSSML'] as bool? ?? false;
  }

  /// Returns supported audio formats for this voice
  List<AudioFormat> getSupportedFormats() {
    final formats = <AudioFormat>[];
    
    // All voices support MP3 and WAV
    formats.addAll([AudioFormat.mp3, AudioFormat.wav]);
    
    // OGG support varies by platform
    if (platform != TTSPlatform.ios && platform != TTSPlatform.macos) {
      formats.add(AudioFormat.ogg);
    }
    
    return formats;
  }

  /// Converts to Edge TTS voice name format
  String toEdgeTTSVoiceName() {
    // Edge TTS uses format like "Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)"
    return metadata['edgeTTSName'] as String? ?? id;
  }

  /// Converts to Flutter TTS voice name format
  String toFlutterTTSVoiceName() {
    // Flutter TTS uses platform-specific voice names
    return metadata['flutterTTSName'] as String? ?? name;
  }

  /// Creates a copy with modified values
  AlouetteVoice copyWith({
    String? id,
    String? name,
    String? languageCode,
    String? countryCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    TTSPlatform? platform,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) {
    return AlouetteVoice(
      id: id ?? this.id,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      gender: gender ?? this.gender,
      quality: quality ?? this.quality,
      platform: platform ?? this.platform,
      isDefault: isDefault ?? this.isDefault,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'languageCode': languageCode,
      'countryCode': countryCode,
      'gender': gender.name,
      'quality': quality.name,
      'platform': platform.name,
      'isDefault': isDefault,
      'metadata': metadata,
    };
  }

  /// Creates an instance from a Map
  factory AlouetteVoice.fromMap(Map<String, dynamic> map) {
    return AlouetteVoice(
      id: map['id'] as String,
      name: map['name'] as String,
      languageCode: map['languageCode'] as String,
      countryCode: map['countryCode'] as String?,
      gender: VoiceGender.fromString(map['gender'] as String? ?? 'neutral'),
      quality: VoiceQuality.fromString(map['quality'] as String? ?? 'standard'),
      platform: TTSPlatform.values.firstWhere(
        (p) => p.name == map['platform'],
        orElse: () => TTSPlatform.android,
      ),
      isDefault: map['isDefault'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AlouetteVoice &&
        other.id == id &&
        other.name == name &&
        other.languageCode == languageCode &&
        other.countryCode == countryCode &&
        other.gender == gender &&
        other.quality == quality &&
        other.platform == platform &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      languageCode,
      countryCode,
      gender,
      quality,
      platform,
      isDefault,
    );
  }

  @override
  String toString() {
    return 'AlouetteVoice('
        'id: $id, '
        'name: $name, '
        'languageCode: $languageCode, '
        'gender: $gender, '
        'quality: $quality, '
        'platform: $platform)';
  }
}