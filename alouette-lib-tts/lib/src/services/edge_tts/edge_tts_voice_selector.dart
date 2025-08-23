import '../../models/alouette_voice.dart';
import '../../models/alouette_tts_config.dart';
import '../../enums/voice_gender.dart';
import '../../enums/voice_quality.dart';

/// Handles voice selection logic for Edge TTS
class EdgeTTSVoiceSelector {
  /// Selects the best voice based on configuration and available voices
  static AlouetteVoice? selectBestVoice(
    List<AlouetteVoice> availableVoices,
    AlouetteTTSConfig config, {
    VoiceGender? preferredGender,
    VoiceQuality? preferredQuality,
  }) {
    if (availableVoices.isEmpty) return null;
    
    // If a specific voice is requested, try to find it
    if (config.voiceName != null) {
      final requestedVoice = availableVoices.where((voice) =>
          voice.name == config.voiceName ||
          voice.id == config.voiceName ||
          voice.toEdgeTTSVoiceName() == config.voiceName).firstOrNull;
      
      if (requestedVoice != null) return requestedVoice;
    }
    
    // Filter by language
    final languageVoices = availableVoices
        .where((voice) => voice.languageCode.toLowerCase() == config.languageCode.toLowerCase())
        .toList();
    
    if (languageVoices.isEmpty) {
      // Try language without region (e.g., 'en' from 'en-US')
      final baseLanguage = config.languageCode.split('-').first.toLowerCase();
      final baseLanguageVoices = availableVoices
          .where((voice) => voice.languageCode.toLowerCase().startsWith(baseLanguage))
          .toList();
      
      if (baseLanguageVoices.isNotEmpty) {
        return _selectFromCandidates(baseLanguageVoices, preferredGender, preferredQuality);
      }
      
      // Fallback to any English voice
      final englishVoices = availableVoices
          .where((voice) => voice.languageCode.toLowerCase().startsWith('en'))
          .toList();
      
      if (englishVoices.isNotEmpty) {
        return _selectFromCandidates(englishVoices, preferredGender, preferredQuality);
      }
      
      // Last resort: return first available voice
      return availableVoices.first;
    }
    
    return _selectFromCandidates(languageVoices, preferredGender, preferredQuality);
  }
  
  /// Selects the best voice from a list of candidates
  static AlouetteVoice _selectFromCandidates(
    List<AlouetteVoice> candidates,
    VoiceGender? preferredGender,
    VoiceQuality? preferredQuality,
  ) {
    if (candidates.isEmpty) throw ArgumentError('Candidates list cannot be empty');
    if (candidates.length == 1) return candidates.first;
    
    // Score each voice based on preferences
    final scoredVoices = candidates.map((voice) {
      int score = 0;
      
      // Prefer default voices
      if (voice.isDefault) score += 10;
      
      // Prefer neural/premium quality
      switch (voice.quality) {
        case VoiceQuality.neural:
          score += 8;
          break;
        case VoiceQuality.premium:
          score += 6;
          break;
        case VoiceQuality.standard:
          score += 4;
          break;
      }
      
      // Match preferred gender
      if (preferredGender != null && voice.gender == preferredGender) {
        score += 5;
      }
      
      // Match preferred quality
      if (preferredQuality != null && voice.quality == preferredQuality) {
        score += 3;
      }
      
      return MapEntry(voice, score);
    }).toList();
    
    // Sort by score (highest first)
    scoredVoices.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredVoices.first.key;
  }
  
  /// Finds alternative voices when the preferred voice is not available
  static List<AlouetteVoice> findAlternativeVoices(
    List<AlouetteVoice> availableVoices,
    String requestedVoiceName,
    String languageCode,
  ) {
    // Try to find voices with similar characteristics
    final alternatives = <AlouetteVoice>[];
    
    // First, try same language
    final sameLanguageVoices = availableVoices
        .where((voice) => voice.languageCode.toLowerCase() == languageCode.toLowerCase())
        .toList();
    
    alternatives.addAll(sameLanguageVoices);
    
    // If no same language voices, try base language
    if (alternatives.isEmpty) {
      final baseLanguage = languageCode.split('-').first.toLowerCase();
      final baseLanguageVoices = availableVoices
          .where((voice) => voice.languageCode.toLowerCase().startsWith(baseLanguage))
          .toList();
      
      alternatives.addAll(baseLanguageVoices);
    }
    
    // Sort alternatives by quality and default status
    alternatives.sort((a, b) {
      // Prefer default voices
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      
      // Prefer higher quality
      final qualityOrder = [VoiceQuality.neural, VoiceQuality.premium, VoiceQuality.standard];
      final aQualityIndex = qualityOrder.indexOf(a.quality);
      final bQualityIndex = qualityOrder.indexOf(b.quality);
      
      return aQualityIndex.compareTo(bQualityIndex);
    });
    
    return alternatives;
  }
  
  /// Validates if a voice is compatible with the given configuration
  static bool isVoiceCompatible(AlouetteVoice voice, AlouetteTTSConfig config) {
    // Check language compatibility
    final voiceLang = voice.languageCode.toLowerCase();
    final configLang = config.languageCode.toLowerCase();
    
    // Exact match
    if (voiceLang == configLang) return true;
    
    // Base language match (e.g., 'en-US' voice with 'en-GB' config)
    final voiceBaseLang = voiceLang.split('-').first;
    final configBaseLang = configLang.split('-').first;
    
    return voiceBaseLang == configBaseLang;
  }
  
  /// Gets voice recommendations based on use case
  static List<AlouetteVoice> getRecommendedVoices(
    List<AlouetteVoice> availableVoices,
    String languageCode, {
    VoiceUseCase useCase = VoiceUseCase.general,
  }) {
    final languageVoices = availableVoices
        .where((voice) => isVoiceCompatible(voice, AlouetteTTSConfig(languageCode: languageCode)))
        .toList();
    
    switch (useCase) {
      case VoiceUseCase.narration:
        // Prefer neural voices with neutral gender for narration
        return languageVoices
            .where((voice) => 
                voice.quality == VoiceQuality.neural &&
                voice.gender == VoiceGender.neutral)
            .toList();
            
      case VoiceUseCase.conversation:
        // Prefer natural-sounding voices
        return languageVoices
            .where((voice) => voice.quality == VoiceQuality.neural)
            .toList();
            
      case VoiceUseCase.announcement:
        // Prefer clear, authoritative voices
        return languageVoices
            .where((voice) => 
                voice.quality == VoiceQuality.neural &&
                (voice.gender == VoiceGender.male || voice.gender == VoiceGender.female))
            .toList();
            
      case VoiceUseCase.general:
        // Return all compatible voices, sorted by quality
        languageVoices.sort((a, b) {
          final qualityOrder = [VoiceQuality.neural, VoiceQuality.premium, VoiceQuality.standard];
          return qualityOrder.indexOf(a.quality).compareTo(qualityOrder.indexOf(b.quality));
        });
        return languageVoices;
    }
  }
}

/// Voice use case enumeration for recommendations
enum VoiceUseCase {
  general,
  narration,
  conversation,
  announcement,
}

/// Extension to add firstOrNull method
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}