import 'package:meta/meta.dart';
import 'alouette_voice.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../enums/tts_platform.dart';

/// Voice management utilities for filtering and searching voices
@immutable
class VoiceManager {
  const VoiceManager();

  /// Filters voices by language code
  List<AlouetteVoice> filterByLanguage(
    List<AlouetteVoice> voices,
    String languageCode,
  ) {
    final normalizedLanguage = languageCode.toLowerCase();
    
    return voices.where((voice) {
      final voiceLanguage = voice.languageCode.toLowerCase();
      
      // Exact match
      if (voiceLanguage == normalizedLanguage) return true;
      
      // Language-only match (e.g., 'en' matches 'en-US')
      if (normalizedLanguage.length == 2) {
        return voiceLanguage.startsWith('$normalizedLanguage-');
      }
      
      // Base language match (e.g., 'en-US' matches 'en')
      if (voiceLanguage.length == 2) {
        return normalizedLanguage.startsWith('$voiceLanguage-');
      }
      
      return false;
    }).toList();
  }

  /// Filters voices by gender
  List<AlouetteVoice> filterByGender(
    List<AlouetteVoice> voices,
    VoiceGender gender,
  ) {
    return voices.where((voice) => voice.gender == gender).toList();
  }

  /// Filters voices by quality
  List<AlouetteVoice> filterByQuality(
    List<AlouetteVoice> voices,
    VoiceQuality quality,
  ) {
    return voices.where((voice) => voice.quality == quality).toList();
  }

  /// Filters voices by platform
  List<AlouetteVoice> filterByPlatform(
    List<AlouetteVoice> voices,
    TTSPlatform platform,
  ) {
    return voices.where((voice) => voice.platform == platform).toList();
  }

  /// Filters voices by country code
  List<AlouetteVoice> filterByCountry(
    List<AlouetteVoice> voices,
    String countryCode,
  ) {
    final normalizedCountry = countryCode.toUpperCase();
    return voices.where((voice) => voice.countryCode == normalizedCountry).toList();
  }

  /// Filters voices that support SSML
  List<AlouetteVoice> filterBySSMLSupport(
    List<AlouetteVoice> voices,
    bool supportsSSML,
  ) {
    return voices.where((voice) => voice.supportsSSML() == supportsSSML).toList();
  }

  /// Gets only default voices for each language
  List<AlouetteVoice> getDefaultVoices(List<AlouetteVoice> voices) {
    return voices.where((voice) => voice.isDefault).toList();
  }

  /// Searches voices by name (case-insensitive)
  List<AlouetteVoice> searchByName(
    List<AlouetteVoice> voices,
    String query,
  ) {
    if (query.isEmpty) return voices;
    
    final normalizedQuery = query.toLowerCase();
    
    return voices.where((voice) {
      return voice.name.toLowerCase().contains(normalizedQuery) ||
             voice.displayName.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Finds the best matching voice for given criteria
  AlouetteVoice? findBestMatch(
    List<AlouetteVoice> voices, {
    String? languageCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    TTSPlatform? platform,
    bool preferDefault = true,
  }) {
    var candidates = List<AlouetteVoice>.from(voices);
    
    // Filter by language if specified
    if (languageCode != null) {
      candidates = filterByLanguage(candidates, languageCode);
      if (candidates.isEmpty) return null;
    }
    
    // Filter by platform if specified
    if (platform != null) {
      candidates = filterByPlatform(candidates, platform);
      if (candidates.isEmpty) return null;
    }
    
    // Filter by gender if specified
    if (gender != null) {
      final genderFiltered = filterByGender(candidates, gender);
      if (genderFiltered.isNotEmpty) {
        candidates = genderFiltered;
      }
    }
    
    // Filter by quality if specified
    if (quality != null) {
      final qualityFiltered = filterByQuality(candidates, quality);
      if (qualityFiltered.isNotEmpty) {
        candidates = qualityFiltered;
      }
    }
    
    // Prefer default voices if requested
    if (preferDefault) {
      final defaultVoices = getDefaultVoices(candidates);
      if (defaultVoices.isNotEmpty) {
        candidates = defaultVoices;
      }
    }
    
    // Sort by quality (higher is better) and return the best
    candidates.sort((a, b) => b.quality.qualityLevel.compareTo(a.quality.qualityLevel));
    
    return candidates.isNotEmpty ? candidates.first : null;
  }

  /// Groups voices by language
  Map<String, List<AlouetteVoice>> groupByLanguage(List<AlouetteVoice> voices) {
    final groups = <String, List<AlouetteVoice>>{};
    
    for (final voice in voices) {
      final language = voice.languageCode;
      groups.putIfAbsent(language, () => <AlouetteVoice>[]);
      groups[language]!.add(voice);
    }
    
    return groups;
  }

  /// Groups voices by platform
  Map<TTSPlatform, List<AlouetteVoice>> groupByPlatform(List<AlouetteVoice> voices) {
    final groups = <TTSPlatform, List<AlouetteVoice>>{};
    
    for (final voice in voices) {
      groups.putIfAbsent(voice.platform, () => <AlouetteVoice>[]);
      groups[voice.platform]!.add(voice);
    }
    
    return groups;
  }

  /// Gets available languages from a list of voices
  List<String> getAvailableLanguages(List<AlouetteVoice> voices) {
    final languages = voices.map((voice) => voice.languageCode).toSet().toList();
    languages.sort();
    return languages;
  }

  /// Gets available countries from a list of voices
  List<String> getAvailableCountries(List<AlouetteVoice> voices) {
    final countries = voices
        .where((voice) => voice.countryCode != null)
        .map((voice) => voice.countryCode!)
        .toSet()
        .toList();
    countries.sort();
    return countries;
  }

  /// Sorts voices by various criteria
  List<AlouetteVoice> sortVoices(
    List<AlouetteVoice> voices, {
    VoiceSortCriteria criteria = VoiceSortCriteria.name,
    bool ascending = true,
  }) {
    final sorted = List<AlouetteVoice>.from(voices);
    
    switch (criteria) {
      case VoiceSortCriteria.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case VoiceSortCriteria.language:
        sorted.sort((a, b) => a.languageCode.compareTo(b.languageCode));
        break;
      case VoiceSortCriteria.quality:
        sorted.sort((a, b) => a.quality.qualityLevel.compareTo(b.quality.qualityLevel));
        break;
      case VoiceSortCriteria.gender:
        sorted.sort((a, b) => a.gender.name.compareTo(b.gender.name));
        break;
      case VoiceSortCriteria.platform:
        sorted.sort((a, b) => a.platform.name.compareTo(b.platform.name));
        break;
    }
    
    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Applies multiple filters in sequence
  List<AlouetteVoice> applyFilters(
    List<AlouetteVoice> voices,
    List<VoiceFilter> filters,
  ) {
    var result = List<AlouetteVoice>.from(voices);
    
    for (final filter in filters) {
      result = filter.apply(result, this);
    }
    
    return result;
  }
}

/// Enumeration of voice sorting criteria
enum VoiceSortCriteria {
  name,
  language,
  quality,
  gender,
  platform,
}

/// Abstract base class for voice filters
abstract class VoiceFilter {
  const VoiceFilter();
  
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager);
}

/// Filter by language code
class LanguageFilter extends VoiceFilter {
  final String languageCode;
  
  const LanguageFilter(this.languageCode);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.filterByLanguage(voices, languageCode);
  }
}

/// Filter by gender
class GenderFilter extends VoiceFilter {
  final VoiceGender gender;
  
  const GenderFilter(this.gender);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.filterByGender(voices, gender);
  }
}

/// Filter by quality
class QualityFilter extends VoiceFilter {
  final VoiceQuality quality;
  
  const QualityFilter(this.quality);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.filterByQuality(voices, quality);
  }
}

/// Filter by platform
class PlatformFilter extends VoiceFilter {
  final TTSPlatform platform;
  
  const PlatformFilter(this.platform);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.filterByPlatform(voices, platform);
  }
}

/// Filter by name search
class NameSearchFilter extends VoiceFilter {
  final String query;
  
  const NameSearchFilter(this.query);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.searchByName(voices, query);
  }
}

/// Filter by SSML support
class SSMLSupportFilter extends VoiceFilter {
  final bool supportsSSML;
  
  const SSMLSupportFilter(this.supportsSSML);
  
  @override
  List<AlouetteVoice> apply(List<AlouetteVoice> voices, VoiceManager manager) {
    return manager.filterBySSMLSupport(voices, supportsSSML);
  }
}