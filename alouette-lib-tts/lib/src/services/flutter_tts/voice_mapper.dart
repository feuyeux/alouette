import '../../models/alouette_voice.dart';
import '../../enums/tts_platform.dart';
import '../../enums/voice_gender.dart';
import '../../enums/voice_quality.dart';

/// Maps platform-specific voice data to unified AlouetteVoice objects
class VoiceMapper {
  final TTSPlatform _platform;
  
  const VoiceMapper(this._platform);

  /// Maps a Flutter TTS voice to an AlouetteVoice
  AlouetteVoice? mapFlutterTTSVoice(dynamic platformVoice) {
    try {
      final voiceMap = platformVoice as Map<String, dynamic>;
      final name = voiceMap['name'] as String? ?? 'Unknown';
      final locale = voiceMap['locale'] as String? ?? 'en-US';
      
      // Extract language and country codes
      final localeParts = locale.split('-');
      final languageCode = locale;
      final countryCode = localeParts.length > 1 ? localeParts[1] : null;
      
      // Determine gender from voice name and metadata
      final gender = _determineGenderFromVoiceData(voiceMap);
      
      // Determine quality from voice metadata
      final quality = _determineQualityFromVoiceData(voiceMap);
      
      // Check if this is a default voice
      final isDefault = _isDefaultVoice(voiceMap, locale);
      
      return AlouetteVoice(
        id: _generateVoiceId(name, locale),
        name: name,
        languageCode: languageCode,
        countryCode: countryCode,
        gender: gender,
        quality: quality,
        platform: _platform,
        isDefault: isDefault,
        metadata: _buildVoiceMetadata(voiceMap),
      );
    } catch (e) {
      return null;
    }
  }

  /// Maps multiple Flutter TTS voices to AlouetteVoice objects
  List<AlouetteVoice> mapFlutterTTSVoices(List<dynamic> platformVoices) {
    final mappedVoices = <AlouetteVoice>[];
    
    for (final platformVoice in platformVoices) {
      final mappedVoice = mapFlutterTTSVoice(platformVoice);
      if (mappedVoice != null) {
        mappedVoices.add(mappedVoice);
      }
    }
    
    return mappedVoices;
  }

  /// Finds the best matching voice for given criteria
  AlouetteVoice? findBestMatch({
    required List<AlouetteVoice> voices,
    String? languageCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    bool preferDefault = true,
  }) {
    if (voices.isEmpty) return null;
    
    var candidates = List<AlouetteVoice>.from(voices);
    
    // Filter by language if specified
    if (languageCode != null) {
      final languageMatches = candidates.where((voice) {
        return voice.languageCode.toLowerCase() == languageCode.toLowerCase() ||
               voice.languageCode.toLowerCase().startsWith(languageCode.toLowerCase().split('-').first);
      }).toList();
      
      if (languageMatches.isNotEmpty) {
        candidates = languageMatches;
      }
    }
    
    // Filter by gender if specified
    if (gender != null) {
      final genderMatches = candidates.where((voice) => voice.gender == gender).toList();
      if (genderMatches.isNotEmpty) {
        candidates = genderMatches;
      }
    }
    
    // Filter by quality if specified
    if (quality != null) {
      final qualityMatches = candidates.where((voice) => voice.quality == quality).toList();
      if (qualityMatches.isNotEmpty) {
        candidates = qualityMatches;
      }
    }
    
    // Prefer default voices if requested
    if (preferDefault) {
      final defaultVoices = candidates.where((voice) => voice.isDefault).toList();
      if (defaultVoices.isNotEmpty) {
        return defaultVoices.first;
      }
    }
    
    // Sort by quality (higher quality first) and return the best match
    candidates.sort((a, b) => b.quality.qualityLevel.compareTo(a.quality.qualityLevel));
    
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Filters voices by language code
  List<AlouetteVoice> filterByLanguage(List<AlouetteVoice> voices, String languageCode) {
    return voices.where((voice) {
      final voiceLang = voice.languageCode.toLowerCase();
      final targetLang = languageCode.toLowerCase();
      
      // Exact match
      if (voiceLang == targetLang) return true;
      
      // Language family match (e.g., 'en' matches 'en-US', 'en-GB')
      final voiceLangParts = voiceLang.split('-');
      final targetLangParts = targetLang.split('-');
      
      return voiceLangParts.first == targetLangParts.first;
    }).toList();
  }

  /// Filters voices by gender
  List<AlouetteVoice> filterByGender(List<AlouetteVoice> voices, VoiceGender gender) {
    return voices.where((voice) => voice.gender == gender).toList();
  }

  /// Filters voices by quality
  List<AlouetteVoice> filterByQuality(List<AlouetteVoice> voices, VoiceQuality quality) {
    return voices.where((voice) => voice.quality == quality).toList();
  }

  /// Groups voices by language
  Map<String, List<AlouetteVoice>> groupByLanguage(List<AlouetteVoice> voices) {
    final grouped = <String, List<AlouetteVoice>>{};
    
    for (final voice in voices) {
      final languageKey = voice.languageCode.split('-').first.toLowerCase();
      grouped.putIfAbsent(languageKey, () => <AlouetteVoice>[]).add(voice);
    }
    
    return grouped;
  }

  /// Gets available languages from voice list
  List<String> getAvailableLanguages(List<AlouetteVoice> voices) {
    final languages = <String>{};
    
    for (final voice in voices) {
      languages.add(voice.languageCode);
    }
    
    return languages.toList()..sort();
  }

  /// Normalizes voice metadata for consistency
  AlouetteVoice normalizeVoiceMetadata(AlouetteVoice voice) {
    final normalizedMetadata = Map<String, dynamic>.from(voice.metadata);
    
    // Add platform-specific normalization
    switch (_platform) {
      case TTSPlatform.android:
        normalizedMetadata['androidSpecific'] = _normalizeAndroidVoiceData(voice);
        break;
      case TTSPlatform.ios:
        normalizedMetadata['iosSpecific'] = _normalizeIOSVoiceData(voice);
        break;
      case TTSPlatform.web:
        normalizedMetadata['webSpecific'] = _normalizeWebVoiceData(voice);
        break;
      default:
        break;
    }
    
    return voice.copyWith(metadata: normalizedMetadata);
  }

  // Private helper methods

  /// Generates a unique voice ID
  String _generateVoiceId(String name, String locale) {
    final sanitizedName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${sanitizedName}_${locale}_${_platform.name}';
  }

  /// Determines voice gender from voice data
  VoiceGender _determineGenderFromVoiceData(Map<String, dynamic> voiceData) {
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    
    // Check explicit gender metadata first
    final explicitGender = voiceData['gender'] as String?;
    if (explicitGender != null) {
      return VoiceGender.fromString(explicitGender);
    }
    
    // Platform-specific gender detection
    switch (_platform) {
      case TTSPlatform.android:
        return _determineAndroidVoiceGender(voiceData);
      case TTSPlatform.ios:
        return _determineIOSVoiceGender(voiceData);
      case TTSPlatform.web:
        return _determineWebVoiceGender(voiceData);
      default:
        return _determineGenderFromName(name);
    }
  }

  /// Determines voice quality from voice data
  VoiceQuality _determineQualityFromVoiceData(Map<String, dynamic> voiceData) {
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    
    // Check explicit quality metadata
    final explicitQuality = voiceData['quality'] as String?;
    if (explicitQuality != null) {
      return VoiceQuality.fromString(explicitQuality);
    }
    
    // Detect quality from voice name patterns
    if (name.contains('neural') || name.contains('enhanced') || name.contains('premium')) {
      return VoiceQuality.neural;
    } else if (name.contains('high') || name.contains('plus')) {
      return VoiceQuality.premium;
    } else {
      return VoiceQuality.standard;
    }
  }

  /// Checks if a voice is the default for its language
  bool _isDefaultVoice(Map<String, dynamic> voiceData, String locale) {
    // Check explicit default flag
    final explicitDefault = voiceData['isDefault'] as bool?;
    if (explicitDefault != null) {
      return explicitDefault;
    }
    
    // Platform-specific default detection
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    
    // Common patterns for default voices
    if (name.contains('default') || name.contains('system')) {
      return true;
    }
    
    // Language-specific default voice patterns
    switch (locale.toLowerCase()) {
      case 'en-us':
        return name.contains('samantha') || name.contains('alex') || name.contains('siri');
      case 'en-gb':
        return name.contains('daniel') || name.contains('kate');
      case 'es-es':
        return name.contains('monica') || name.contains('jorge');
      case 'fr-fr':
        return name.contains('amelie') || name.contains('thomas');
      case 'de-de':
        return name.contains('anna') || name.contains('markus');
      default:
        return false;
    }
  }

  /// Builds comprehensive voice metadata
  Map<String, dynamic> _buildVoiceMetadata(Map<String, dynamic> voiceData) {
    final metadata = <String, dynamic>{
      'flutterTTSName': voiceData['name'],
      'originalVoiceData': voiceData,
      'platform': _platform.name,
      'supportsSSML': _determineSSMLSupport(voiceData),
      'supportedFormats': _getSupportedFormats(voiceData),
      'voiceType': _determineVoiceType(voiceData),
      'networkRequired': _requiresNetwork(voiceData),
    };
    
    // Add platform-specific metadata
    switch (_platform) {
      case TTSPlatform.android:
        metadata.addAll(_getAndroidSpecificMetadata(voiceData));
        break;
      case TTSPlatform.ios:
        metadata.addAll(_getIOSSpecificMetadata(voiceData));
        break;
      case TTSPlatform.web:
        metadata.addAll(_getWebSpecificMetadata(voiceData));
        break;
      default:
        break;
    }
    
    return metadata;
  }

  /// Determines gender from voice name using heuristics
  VoiceGender _determineGenderFromName(String name) {
    // Female voice indicators
    final femalePatterns = [
      'female', 'woman', 'girl', 'lady',
      'aria', 'jenny', 'sonia', 'elvira', 'denise', 'katja', 'elsa',
      'francisca', 'nanami', 'sunhi', 'xiaoxiao', 'samantha', 'kate',
      'monica', 'amelie', 'anna', 'zoe', 'emma', 'sophia', 'isabella',
      'olivia', 'ava', 'mia', 'emily', 'abigail', 'madison', 'elizabeth'
    ];
    
    // Male voice indicators
    final malePatterns = [
      'male', 'man', 'boy', 'guy',
      'david', 'mark', 'alex', 'daniel', 'jorge', 'thomas', 'markus',
      'william', 'james', 'benjamin', 'lucas', 'henry', 'alexander',
      'mason', 'michael', 'ethan', 'daniel', 'jacob', 'logan', 'jackson'
    ];
    
    final lowerName = name.toLowerCase();
    
    for (final pattern in femalePatterns) {
      if (lowerName.contains(pattern)) {
        return VoiceGender.female;
      }
    }
    
    for (final pattern in malePatterns) {
      if (lowerName.contains(pattern)) {
        return VoiceGender.male;
      }
    }
    
    return VoiceGender.neutral;
  }

  // Platform-specific helper methods

  VoiceGender _determineAndroidVoiceGender(Map<String, dynamic> voiceData) {
    // Android-specific gender detection logic
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    return _determineGenderFromName(name);
  }

  VoiceGender _determineIOSVoiceGender(Map<String, dynamic> voiceData) {
    // iOS-specific gender detection logic
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    return _determineGenderFromName(name);
  }

  VoiceGender _determineWebVoiceGender(Map<String, dynamic> voiceData) {
    // Web-specific gender detection logic
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    return _determineGenderFromName(name);
  }

  bool _determineSSMLSupport(Map<String, dynamic> voiceData) {
    // Most modern TTS engines support basic SSML
    switch (_platform) {
      case TTSPlatform.web:
        return false; // Web Speech API has limited SSML support
      default:
        return true;
    }
  }

  List<String> _getSupportedFormats(Map<String, dynamic> voiceData) {
    switch (_platform) {
      case TTSPlatform.ios:
      case TTSPlatform.macos:
        return ['wav', 'mp3']; // OGG not well supported on Apple platforms
      case TTSPlatform.web:
        return ['wav']; // Limited format support on web
      default:
        return ['wav', 'mp3', 'ogg'];
    }
  }

  String _determineVoiceType(Map<String, dynamic> voiceData) {
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    
    if (name.contains('neural') || name.contains('ai')) {
      return 'neural';
    } else if (name.contains('enhanced') || name.contains('premium')) {
      return 'enhanced';
    } else {
      return 'standard';
    }
  }

  bool _requiresNetwork(Map<String, dynamic> voiceData) {
    final name = (voiceData['name'] as String? ?? '').toLowerCase();
    
    // Some high-quality voices may require network access
    return name.contains('cloud') || name.contains('online') || name.contains('server');
  }

  Map<String, dynamic> _getAndroidSpecificMetadata(Map<String, dynamic> voiceData) {
    return {
      'androidEngine': voiceData['engine'] ?? 'unknown',
      'androidPackage': voiceData['package'] ?? 'unknown',
    };
  }

  Map<String, dynamic> _getIOSSpecificMetadata(Map<String, dynamic> voiceData) {
    return {
      'iosVoiceIdentifier': voiceData['identifier'] ?? 'unknown',
      'iosVoiceType': voiceData['type'] ?? 'unknown',
    };
  }

  Map<String, dynamic> _getWebSpecificMetadata(Map<String, dynamic> voiceData) {
    return {
      'webVoiceURI': voiceData['voiceURI'] ?? 'unknown',
      'webLocalService': voiceData['localService'] ?? true,
    };
  }

  Map<String, dynamic> _normalizeAndroidVoiceData(AlouetteVoice voice) {
    return {
      'engineName': voice.metadata['androidEngine'] ?? 'default',
      'packageName': voice.metadata['androidPackage'] ?? 'com.android.tts',
    };
  }

  Map<String, dynamic> _normalizeIOSVoiceData(AlouetteVoice voice) {
    return {
      'identifier': voice.metadata['iosVoiceIdentifier'] ?? voice.id,
      'type': voice.metadata['iosVoiceType'] ?? 'system',
    };
  }

  Map<String, dynamic> _normalizeWebVoiceData(AlouetteVoice voice) {
    return {
      'voiceURI': voice.metadata['webVoiceURI'] ?? voice.name,
      'localService': voice.metadata['webLocalService'] ?? true,
    };
  }
}