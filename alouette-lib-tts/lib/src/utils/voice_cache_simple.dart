import 'dart:convert';
import 'package:meta/meta.dart';
import '../models/alouette_voice.dart';
import '../enums/tts_platform.dart';

/// Simple LRU cache for voice lists with expiration (without persistence)
class VoiceCacheSimple {
  static const Duration _defaultExpiration = Duration(hours: 24);
  static const int _defaultMaxSize = 100;

  final Duration _expiration;
  final int _maxSize;
  final Map<String, _CacheEntry> _cache = {};
  final List<String> _accessOrder = [];

  /// Cache hit/miss metrics
  int _hits = 0;
  int _misses = 0;

  VoiceCacheSimple({
    Duration expiration = _defaultExpiration,
    int maxSize = _defaultMaxSize,
  })  : _expiration = expiration,
        _maxSize = maxSize;

  /// Gets cached voices for a platform
  List<AlouetteVoice>? getVoices(TTSPlatform platform) {
    final key = _getPlatformKey(platform);
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (_isExpired(entry)) {
      _cache.remove(key);
      _accessOrder.remove(key);
      _misses++;
      return null;
    }

    // Update access order for LRU
    _updateAccessOrder(key);
    _hits++;

    return List<AlouetteVoice>.from(entry.voices);
  }

  /// Caches voices for a platform
  void putVoices(TTSPlatform platform, List<AlouetteVoice> voices) {
    final key = _getPlatformKey(platform);

    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Add new entry
    _cache[key] = _CacheEntry(
      voices: List<AlouetteVoice>.from(voices),
      timestamp: DateTime.now(),
    );

    // Update access order
    _updateAccessOrder(key);

    // Enforce size limit
    _enforceSizeLimit();
  }

  /// Checks if voices are cached and not expired for a platform
  bool hasValidVoices(TTSPlatform platform) {
    final key = _getPlatformKey(platform);
    final entry = _cache[key];

    if (entry == null) return false;
    return !_isExpired(entry);
  }

  /// Invalidates cache for a specific platform
  void invalidatePlatform(TTSPlatform platform) {
    final key = _getPlatformKey(platform);
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Invalidates all cached voices
  void invalidateAll() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Gets cache statistics
  CacheStats getStats() {
    final total = _hits + _misses;
    final hitRate = total > 0 ? _hits / total : 0.0;

    return CacheStats(
      hits: _hits,
      misses: _misses,
      hitRate: hitRate,
      size: _cache.length,
      maxSize: _maxSize,
    );
  }

  /// Resets cache statistics
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Exports cache data as JSON string
  String exportToJson() {
    // Remove expired entries before export
    _removeExpiredEntries();

    final data = {
      'entries': _cache.map((key, entry) => MapEntry(
            key,
            {
              'timestamp': entry.timestamp.toIso8601String(),
              'voices': entry.voices.map((v) => v.toMap()).toList(),
            },
          )),
      'accessOrder': _accessOrder,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  /// Imports cache data from JSON string
  void importFromJson(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      _cache.clear();
      _accessOrder.clear();

      final entries = data['entries'] as Map<String, dynamic>? ?? {};
      final accessOrder = List<String>.from(data['accessOrder'] as List? ?? []);

      // Load entries
      for (final entry in entries.entries) {
        final entryData = entry.value as Map<String, dynamic>;
        final timestamp = DateTime.parse(entryData['timestamp'] as String);
        final voicesData = entryData['voices'] as List;

        final voices = voicesData
            .map((v) => AlouetteVoice.fromMap(v as Map<String, dynamic>))
            .toList();

        _cache[entry.key] = _CacheEntry(
          voices: voices,
          timestamp: timestamp,
        );
      }

      // Restore access order
      _accessOrder.addAll(accessOrder.where((key) => _cache.containsKey(key)));

      // Remove expired entries
      _removeExpiredEntries();
    } catch (e) {
      // If import fails, start with empty cache
      _cache.clear();
      _accessOrder.clear();
    }
  }

  /// Generates a cache key for a platform
  String _getPlatformKey(TTSPlatform platform) {
    return 'voices_${platform.name}';
  }

  /// Checks if a cache entry is expired
  bool _isExpired(_CacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) > _expiration;
  }

  /// Updates access order for LRU eviction
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Enforces cache size limit using LRU eviction
  void _enforceSizeLimit() {
    while (_cache.length > _maxSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
  }

  /// Removes expired entries from cache
  void _removeExpiredEntries() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (_isExpired(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }
}

/// Cache entry containing voices and timestamp
@immutable
class _CacheEntry {
  final List<AlouetteVoice> voices;
  final DateTime timestamp;

  const _CacheEntry({
    required this.voices,
    required this.timestamp,
  });
}

/// Cache statistics
@immutable
class CacheStats {
  final int hits;
  final int misses;
  final double hitRate;
  final int size;
  final int maxSize;

  const CacheStats({
    required this.hits,
    required this.misses,
    required this.hitRate,
    required this.size,
    required this.maxSize,
  });

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, size: $size/$maxSize)';
  }
}
