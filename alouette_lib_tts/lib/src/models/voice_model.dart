import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';

/// Voice model representing a TTS voice
/// Following Flutter naming conventions with VoiceModel class name
class VoiceModel {
  /// Voice identifier/name
  final String id;

  /// Display name for the voice
  final String displayName;

  /// Language code (e.g., 'en-US', 'zh-CN')
  final String languageCode;

  /// Voice gender
  final VoiceGender gender;

  /// Voice quality
  final VoiceQuality quality;

  /// Whether this is a neural voice
  final bool isNeural;

  const VoiceModel({
    required this.id,
    required this.displayName,
    required this.languageCode,
    required this.gender,
    required this.quality,
    this.isNeural = false,
  });

  /// Whether this is a standard voice (opposite of neural)
  bool get isStandard => !isNeural;

  /// Alias for id (for backward compatibility)
  String get name => id;

  /// Alias for languageCode (for backward compatibility)
  String get locale => languageCode;

  /// Create VoiceModel from JSON
  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      id: json['Name'] ?? json['id'] ?? json['name'] ?? '',
      displayName:
          json['DisplayName'] ??
          json['displayName'] ??
          json['display_name'] ??
          '',
      languageCode:
          json['Locale'] ??
          json['languageCode'] ??
          json['locale'] ??
          json['language_code'] ??
          '',
      gender: _parseGender(json['Gender'] ?? json['gender'] ?? ''),
      quality: _parseQuality(
        json['VoiceType'] ??
            json['voiceType'] ??
            json['voice_type'] ??
            json['quality'] ??
            '',
      ),
      isNeural:
          (json['VoiceType'] ??
                  json['voiceType'] ??
                  json['voice_type'] ??
                  json['is_neural'] ??
                  '')
              .toString()
              .toLowerCase()
              .contains('neural') ||
          json['is_neural'] == true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': id, // Backward compatibility
    'display_name': displayName,
    'language_code': languageCode,
    'locale': languageCode, // Backward compatibility
    'gender': gender.name,
    'voice_type': isNeural ? 'Neural' : 'Standard',
    'quality': quality.name,
    'is_neural': isNeural,
    // Legacy format for backward compatibility
    'Name': id,
    'DisplayName': displayName,
    'Locale': languageCode,
    'Gender': gender.name,
    'VoiceType': isNeural ? 'Neural' : 'Standard',
  };

  /// Parse gender from string
  static VoiceGender _parseGender(String genderStr) {
    switch (genderStr.toLowerCase()) {
      case 'male':
        return VoiceGender.male;
      case 'female':
        return VoiceGender.female;
      default:
        return VoiceGender.unknown;
    }
  }

  /// Parse quality from string
  static VoiceQuality _parseQuality(String qualityStr) {
    if (qualityStr.toLowerCase().contains('neural')) {
      return VoiceQuality.neural;
    } else if (qualityStr.toLowerCase().contains('standard')) {
      return VoiceQuality.standard;
    }
    return VoiceQuality.standard;
  }

  /// Create a copy with modified fields
  VoiceModel copyWith({
    String? id,
    String? displayName,
    String? languageCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    bool? isNeural,
  }) {
    return VoiceModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      languageCode: languageCode ?? this.languageCode,
      gender: gender ?? this.gender,
      quality: quality ?? this.quality,
      isNeural: isNeural ?? this.isNeural,
    );
  }



  @override
  String toString() {
    return 'VoiceModel(id: $id, displayName: $displayName, languageCode: $languageCode, gender: $gender, quality: $quality, isNeural: $isNeural)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
