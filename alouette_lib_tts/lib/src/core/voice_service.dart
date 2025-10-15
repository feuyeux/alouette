import 'package:flutter/foundation.dart';
import '../models/voice_model.dart';
import '../models/tts_error.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../exceptions/tts_exceptions.dart';
import '../utils/cache_manager.dart';
import 'tts_service_interface.dart';

/// Service for managing TTS voices and voice selection
///
/// Provides advanced voice discovery, filtering, and selection capabilities
/// with caching and preference management.
class VoiceService extends ChangeNotifier {
  final TTSServiceInterface _ttsService;
  final CacheManager _cacheManager = CacheManager.instance;
  List<VoiceModel> _cachedVoices = [];
  Map<String, List<VoiceModel>> _languageVoiceCache = {};
  bool _isLoading = false;
  String? _preferredVoice;

  /// Notifier for voice loading state
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  VoiceService(this._ttsService);

  /// Get all cached voices
  List<VoiceModel> get cachedVoices => List.unmodifiable(_cachedVoices);

  /// Check if voices are currently being loaded
  bool get isLoading => _isLoading;

  /// Get the preferred voice name
  String? get preferredVoice => _preferredVoice;

  /// Get all available voices with caching
  Future<List<VoiceModel>> getAllVoices({bool forceRefresh = false}) async {
    // 检查统一缓存管理器中的缓存
    if (!forceRefresh &&
        _cachedVoices.isEmpty &&
        _ttsService.currentBackend != null) {
      final cachedVoices = _cacheManager.getCachedVoices(
        _ttsService.currentBackend!,
      );
      if (cachedVoices != null) {
        _cachedVoices = cachedVoices;
        _updateLanguageCache();
        return _cachedVoices;
      }
    }

    if (_cachedVoices.isNotEmpty && !forceRefresh) {
      return _cachedVoices;
    }

    _isLoading = true;
    isLoadingNotifier.value = true;
    notifyListeners();

    try {
      _cachedVoices = await _ttsService.getVoices();

      // 缓存到统一缓存管理器
      if (_ttsService.currentBackend != null) {
        _cacheManager.cacheVoices(_ttsService.currentBackend!, _cachedVoices);
      }

      _updateLanguageCache();
      notifyListeners();
      return _cachedVoices;
    } catch (e) {
      throw TTSError(
        'Failed to load voices: $e',
        code: TTSErrorCodes.voiceListError,
        originalError: e,
      );
    } finally {
      _isLoading = false;
      isLoadingNotifier.value = false;
      notifyListeners();
    }
  }

  /// Get voices for a specific language
  Future<List<VoiceModel>> getVoicesByLanguage(
    String languageCode, {
    bool exactMatch = false,
  }) async {
    final cacheKey = '$languageCode:$exactMatch';

    if (_languageVoiceCache.containsKey(cacheKey)) {
      return _languageVoiceCache[cacheKey]!;
    }

    final allVoices = await getAllVoices();
    List<VoiceModel> filteredVoices;

    if (exactMatch) {
      filteredVoices = allVoices
          .where(
            (voice) =>
                voice.languageCode.toLowerCase() == languageCode.toLowerCase(),
          )
          .toList();
    } else {
      // Match language prefix (e.g., 'en' matches 'en-US', 'en-GB')
      final langPrefix = languageCode.toLowerCase().split('-')[0];
      filteredVoices = allVoices
          .where(
            (voice) => voice.languageCode.toLowerCase().startsWith(langPrefix),
          )
          .toList();
    }

    _languageVoiceCache[cacheKey] = filteredVoices;
    return filteredVoices;
  }

  /// Find the best voice for a language based on quality preferences
  Future<VoiceModel?> findBestVoice(
    String languageCode,
    VoiceQuality preferredQuality, {
    VoiceGender? preferredGender,
    bool exactLanguageMatch = false,
  }) async {
    final voices = await getVoicesByLanguage(
      languageCode,
      exactMatch: exactLanguageMatch,
    );

    if (voices.isEmpty) return null;

    // Sort voices by preference
    final sortedVoices = List<VoiceModel>.from(voices);
    sortedVoices.sort((a, b) {
      // Quality preference (neural > standard)
      if (preferredQuality == VoiceQuality.neural) {
        if (a.isNeural && !b.isNeural) return -1;
        if (!a.isNeural && b.isNeural) return 1;
      } else {
        if (a.isStandard && !b.isStandard) return -1;
        if (!a.isStandard && b.isStandard) return 1;
      }

      // Gender preference
      if (preferredGender != null) {
        final aGenderMatch = a.gender == preferredGender;
        final bGenderMatch = b.gender == preferredGender;
        if (aGenderMatch && !bGenderMatch) return -1;
        if (!aGenderMatch && bGenderMatch) return 1;
      }

      // Exact locale match preference
      final exactLocale = languageCode.toLowerCase();
      final aExactMatch = a.languageCode.toLowerCase() == exactLocale;
      final bExactMatch = b.languageCode.toLowerCase() == exactLocale;
      if (aExactMatch && !bExactMatch) return -1;
      if (!aExactMatch && bExactMatch) return 1;

      // Alphabetical order as final criteria
      return a.displayName.compareTo(b.displayName);
    });

    return sortedVoices.first;
  }

  /// Get default voice for a language
  Future<VoiceModel?> getDefaultVoice(String languageCode) async {
    // Try to find a neural voice first
    final bestNeural = await findBestVoice(languageCode, VoiceQuality.neural);

    if (bestNeural != null) return bestNeural;

    // Fallback to any available voice
    return await findBestVoice(languageCode, VoiceQuality.standard);
  }

  /// Get best voice for a language name (e.g., "Chinese", "English")
  Future<VoiceModel?> getBestVoiceForLanguageName(String languageName) async {
    // Language name to language codes mapping
    final languageVoiceMap = {
      'Chinese': ['zh-CN', 'zh'],
      'English': ['en-US', 'en-GB', 'en'],
      'Japanese': ['ja-JP', 'ja'],
      'Korean': ['ko-KR', 'ko'],
      'French': ['fr-FR', 'fr'],
      'German': ['de-DE', 'de'],
      'Spanish': ['es-ES', 'es-MX', 'es'],
      'Italian': ['it-IT', 'it'],
      'Russian': ['ru-RU', 'ru'],
      'Greek': ['el-GR', 'el'],
      'Arabic': ['ar-SA', 'ar'],
      'Hindi': ['hi-IN', 'hi'],
    };

    final allVoices = await getAllVoices();
    
    // Try to find the best voice for the language
    if (languageVoiceMap.containsKey(languageName)) {
      final preferredCodes = languageVoiceMap[languageName]!;
      
      for (final code in preferredCodes) {
        final matchingVoices = allVoices.where((voice) {
          final voiceLanguage = voice.languageCode.toLowerCase();
          return voiceLanguage.startsWith(code.toLowerCase());
        }).toList();
        
        if (matchingVoices.isNotEmpty) {
          // Prefer neural voices if available
          final neuralVoices = matchingVoices.where((v) => v.isNeural).toList();
          if (neuralVoices.isNotEmpty) {
            return neuralVoices.first;
          }
          return matchingVoices.first;
        }
      }
    }
    
    // Smart fallback: try to find a reasonable alternative
    // For languages without available voices, use English as fallback
    final englishVoices = allVoices.where((voice) {
      final voiceLanguage = voice.languageCode.toLowerCase();
      return voiceLanguage.startsWith('en');
    }).toList();
    
    if (englishVoices.isNotEmpty) {
      return englishVoices.first;
    }
    
    // Final fallback to first available voice
    if (allVoices.isNotEmpty) {
      return allVoices.first;
    }
    
    return null;
  }

  /// Filter voices by criteria
  List<VoiceModel> filterVoices({
    List<VoiceModel>? voices,
    String? languageCode,
    VoiceGender? gender,
    VoiceQuality? quality,
    String? searchTerm,
  }) {
    final voicesToFilter = voices ?? _cachedVoices;

    return voicesToFilter.where((voice) {
      // Language filter
      if (languageCode != null) {
        final langPrefix = languageCode.toLowerCase().split('-')[0];
        if (!voice.languageCode.toLowerCase().startsWith(langPrefix)) {
          return false;
        }
      }

      // Gender filter
      if (gender != null) {
        if (voice.gender != gender) {
          return false;
        }
      }

      // Quality filter
      if (quality != null) {
        if (voice.quality != quality) {
          return false;
        }
      }

      // Search term filter
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        return voice.displayName.toLowerCase().contains(term) ||
            voice.id.toLowerCase().contains(term) ||
            voice.languageCode.toLowerCase().contains(term);
      }

      return true;
    }).toList();
  }

  /// Group voices by language
  Map<String, List<VoiceModel>> groupVoicesByLanguage([
    List<VoiceModel>? voices,
  ]) {
    final voicesToGroup = voices ?? _cachedVoices;
    final grouped = <String, List<VoiceModel>>{};

    for (final voice in voicesToGroup) {
      final langCode = voice.languageCode;
      grouped.putIfAbsent(langCode, () => []).add(voice);
    }

    // Sort voices within each language group
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        // Neural voices first
        if (a.isNeural && !b.isNeural) return -1;
        if (!a.isNeural && b.isNeural) return 1;

        // Then by display name
        return a.displayName.compareTo(b.displayName);
      });
    }

    return grouped;
  }

  /// Set preferred voice
  void setPreferredVoice(String voiceName) {
    _preferredVoice = voiceName;
    notifyListeners();
  }

  /// Clear preferred voice
  void clearPreferredVoice() {
    _preferredVoice = null;
    notifyListeners();
  }

  /// Get voice statistics
  Map<String, dynamic> getVoiceStatistics([List<VoiceModel>? voices]) {
    final voicesToAnalyze = voices ?? _cachedVoices;

    final totalVoices = voicesToAnalyze.length;
    final neuralVoices = voicesToAnalyze.where((v) => v.isNeural).length;
    final standardVoices = voicesToAnalyze.where((v) => v.isStandard).length;

    final languageGroups = groupVoicesByLanguage(voicesToAnalyze);
    final languageCount = languageGroups.length;

    final genderCounts = <String, int>{};
    for (final voice in voicesToAnalyze) {
      genderCounts[voice.gender.name] =
          (genderCounts[voice.gender.name] ?? 0) + 1;
    }

    return {
      'totalVoices': totalVoices,
      'neuralVoices': neuralVoices,
      'standardVoices': standardVoices,
      'languageCount': languageCount,
      'languages': languageGroups.keys.toList(),
      'genderDistribution': genderCounts,
      'neuralPercentage': totalVoices > 0
          ? (neuralVoices / totalVoices * 100).round()
          : 0,
    };
  }

  /// Update language voice cache
  void _updateLanguageCache() {
    _languageVoiceCache.clear();
    // Cache will be rebuilt on demand
  }

  /// Clear all caches
  void clearCache() {
    _cachedVoices.clear();
    _languageVoiceCache.clear();

    // 也清理统一缓存管理器中的语音缓存
    if (_ttsService.currentBackend != null) {
      _cacheManager.clearVoiceCache(_ttsService.currentBackend!);
    }

    notifyListeners();
  }

  /// Refresh voices from the TTS service
  Future<void> refreshVoices() async {
    clearCache();
    await getAllVoices(forceRefresh: true);
  }

  /// Check if a voice exists
  bool hasVoice(String voiceName) {
    return _cachedVoices.any((voice) => voice.id == voiceName);
  }

  /// Find voice by name
  VoiceModel? findVoice(String voiceName) {
    try {
      return _cachedVoices.firstWhere((voice) => voice.id == voiceName);
    } catch (e) {
      return null;
    }
  }

  /// Get recommended voices for a language
  Future<List<VoiceModel>> getRecommendedVoices(
    String languageCode, {
    int maxCount = 3,
  }) async {
    final voices = await getVoicesByLanguage(languageCode);

    if (voices.isEmpty) return [];

    // Sort by recommendation criteria
    final sortedVoices = List<VoiceModel>.from(voices);
    sortedVoices.sort((a, b) {
      // Neural voices first
      if (a.isNeural && !b.isNeural) return -1;
      if (!a.isNeural && b.isNeural) return 1;

      // Exact locale match
      final exactLocale = languageCode.toLowerCase();
      final aExact = a.languageCode.toLowerCase() == exactLocale;
      final bExact = b.languageCode.toLowerCase() == exactLocale;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      // Gender diversity (prefer alternating male/female)
      return a.displayName.compareTo(b.displayName);
    });

    return sortedVoices.take(maxCount).toList();
  }

  @override
  void dispose() {
    isLoadingNotifier.dispose();
    super.dispose();
  }
}
