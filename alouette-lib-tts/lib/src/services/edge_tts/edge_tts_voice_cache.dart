import '../../models/alouette_voice.dart';

/// Cache for Edge TTS voices with expiration support
class EdgeTTSVoiceCache {
  static const Duration _defaultCacheExpiry = Duration(hours: 24);

  final Map<String, _CacheEntry> _cache = {};
  final Duration _cacheExpiry;

  EdgeTTSVoiceCache({Duration? cacheExpiry})
      : _cacheExpiry = cacheExpiry ?? _defaultCacheExpiry;

  /// Gets cached voices for a specific cache key
  List<AlouetteVoice>? getVoices(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null) return null;

    if (_isExpired(entry)) {
      _cache.remove(cacheKey);
      return null;
    }

    return entry.voices;
  }

  /// Caches voices with the specified key
  void cacheVoices(String cacheKey, List<AlouetteVoice> voices) {
    _cache[cacheKey] = _CacheEntry(
      voices: List.unmodifiable(voices),
      timestamp: DateTime.now(),
    );
  }

  /// Invalidates cache for a specific key
  void invalidateCache(String cacheKey) {
    _cache.remove(cacheKey);
  }

  /// Invalidates all cached voices
  void invalidateAll() {
    _cache.clear();
  }

  /// Checks if a cache entry is expired
  bool _isExpired(_CacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) > _cacheExpiry;
  }

  /// Gets cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    int totalVoices = 0;

    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) > _cacheExpiry) {
        expiredEntries++;
      } else {
        validEntries++;
        totalVoices += entry.voices.length;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'totalVoices': totalVoices,
      'cacheExpiryHours': _cacheExpiry.inHours,
    };
  }

  /// Cleans up expired entries
  void cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Gets all cached voice IDs
  Set<String> getCachedVoiceIds() {
    final voiceIds = <String>{};

    for (final entry in _cache.values) {
      if (!_isExpired(entry)) {
        voiceIds.addAll(entry.voices.map((v) => v.id));
      }
    }

    return voiceIds;
  }

  /// Checks if a specific voice is cached
  bool isVoiceCached(String voiceId) {
    return getCachedVoiceIds().contains(voiceId);
  }

  /// Finds a cached voice by ID
  AlouetteVoice? findCachedVoice(String voiceId) {
    for (final entry in _cache.values) {
      if (!_isExpired(entry)) {
        for (final voice in entry.voices) {
          if (voice.id == voiceId) {
            return voice;
          }
        }
      }
    }
    return null;
  }
}

/// Internal cache entry structure
class _CacheEntry {
  final List<AlouetteVoice> voices;
  final DateTime timestamp;

  const _CacheEntry({
    required this.voices,
    required this.timestamp,
  });
}
