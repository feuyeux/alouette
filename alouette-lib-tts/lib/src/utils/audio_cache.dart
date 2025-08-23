import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import '../models/alouette_tts_config.dart';
// audio_format not needed in this file

/// Audio cache for storing synthesized audio data with content-based keys
class AudioCache {
  static const Duration _defaultExpiration = Duration(hours: 6);
  static const int _defaultMaxSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int _defaultMaxEntries = 1000;

  final Duration _expiration;
  final int _maxSizeBytes;
  final int _maxEntries;
  final Map<String, _AudioCacheEntry> _cache = {};
  final List<String> _accessOrder = [];

  /// Current cache size in bytes
  int _currentSizeBytes = 0;

  /// Cache hit/miss metrics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  AudioCache({
    Duration expiration = _defaultExpiration,
    int maxSizeBytes = _defaultMaxSizeBytes,
    int maxEntries = _defaultMaxEntries,
  })  : _expiration = expiration,
        _maxSizeBytes = maxSizeBytes,
        _maxEntries = maxEntries;

  /// Gets cached audio data for the given text and config
  Uint8List? getAudio(String text, AlouetteTTSConfig config) {
    final key = _generateCacheKey(text, config);
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (_isExpired(entry)) {
      _removeEntry(key);
      _misses++;
      return null;
    }

    // Update access order for LRU
    _updateAccessOrder(key);
    _hits++;

    return Uint8List.fromList(entry.audioData);
  }

  /// Caches audio data for the given text and config
  void putAudio(String text, AlouetteTTSConfig config, Uint8List audioData) {
    final key = _generateCacheKey(text, config);
    final audioSize = audioData.length;

    // Check if the single entry would exceed cache size
    if (audioSize > _maxSizeBytes) {
      return; // Don't cache entries that are too large
    }

    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      _removeEntry(key);
    }

    // Ensure we have space for the new entry
    _ensureSpace(audioSize);

    // Add new entry
    final entry = _AudioCacheEntry(
      audioData: Uint8List.fromList(audioData),
      timestamp: DateTime.now(),
      sizeBytes: audioSize,
      text: text,
      config: config,
    );

    _cache[key] = entry;
    _currentSizeBytes += audioSize;

    // Update access order
    _updateAccessOrder(key);

    // Enforce entry count limit
    _enforceEntryLimit();
  }

  /// Checks if audio is cached for the given text and config
  bool hasAudio(String text, AlouetteTTSConfig config) {
    final key = _generateCacheKey(text, config);
    final entry = _cache[key];

    if (entry == null) return false;
    return !_isExpired(entry);
  }

  /// Invalidates cache for specific text and config
  void invalidateAudio(String text, AlouetteTTSConfig config) {
    final key = _generateCacheKey(text, config);
    _removeEntry(key);
  }

  /// Invalidates all cached audio
  void invalidateAll() {
    _cache.clear();
    _accessOrder.clear();
    _currentSizeBytes = 0;
  }

  /// Gets cache statistics
  AudioCacheStats getStats() {
    final total = _hits + _misses;
    final hitRate = total > 0 ? _hits / total : 0.0;

    return AudioCacheStats(
      hits: _hits,
      misses: _misses,
      hitRate: hitRate,
      evictions: _evictions,
      entryCount: _cache.length,
      maxEntries: _maxEntries,
      sizeBytes: _currentSizeBytes,
      maxSizeBytes: _maxSizeBytes,
    );
  }

  /// Resets cache statistics
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }

  /// Gets cache entries sorted by access time (most recent first)
  List<AudioCacheEntryInfo> getEntries() {
    final entries = <AudioCacheEntryInfo>[];

    for (final key in _accessOrder.reversed) {
      final entry = _cache[key];
      if (entry != null) {
        entries.add(AudioCacheEntryInfo(
          key: key,
          text: entry.text,
          config: entry.config,
          sizeBytes: entry.sizeBytes,
          timestamp: entry.timestamp,
          isExpired: _isExpired(entry),
        ));
      }
    }

    return entries;
  }

  /// Removes expired entries from cache
  int cleanupExpired() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (_isExpired(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _removeEntry(key);
    }

    return expiredKeys.length;
  }

  /// Generates a content-based cache key
  String _generateCacheKey(String text, AlouetteTTSConfig config) {
    // Create a deterministic key based on text and relevant config parameters
    // Normalize whitespace by replacing multiple spaces with single space
    final normalizedText =
        text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final keyData = {
      'text': normalizedText,
      'languageCode': config.languageCode,
      'voiceName': config.voiceName,
      'speechRate': config.speechRate.toStringAsFixed(2),
      'pitch': config.pitch.toStringAsFixed(2),
      'volume': config.volume.toStringAsFixed(2),
      'audioFormat': config.audioFormat.name,
      'enableSSML': config.enableSSML,
    };

    final keyString = jsonEncode(keyData);
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Checks if a cache entry is expired
  bool _isExpired(_AudioCacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) > _expiration;
  }

  /// Updates access order for LRU eviction
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Removes an entry from the cache
  void _removeEntry(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      _accessOrder.remove(key);
    }
  }

  /// Ensures there's enough space for a new entry
  void _ensureSpace(int requiredBytes) {
    // Remove expired entries first
    cleanupExpired();

    // Remove LRU entries until we have enough space
    while (_currentSizeBytes + requiredBytes > _maxSizeBytes &&
        _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.first;
      _removeEntry(oldestKey);
      _evictions++;
    }
  }

  /// Enforces the maximum number of entries
  void _enforceEntryLimit() {
    while (_cache.length > _maxEntries && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.first;
      _removeEntry(oldestKey);
      _evictions++;
    }
  }
}

/// Audio cache entry containing audio data and metadata
@immutable
class _AudioCacheEntry {
  final Uint8List audioData;
  final DateTime timestamp;
  final int sizeBytes;
  final String text;
  final AlouetteTTSConfig config;

  const _AudioCacheEntry({
    required this.audioData,
    required this.timestamp,
    required this.sizeBytes,
    required this.text,
    required this.config,
  });
}

/// Audio cache statistics
@immutable
class AudioCacheStats {
  final int hits;
  final int misses;
  final double hitRate;
  final int evictions;
  final int entryCount;
  final int maxEntries;
  final int sizeBytes;
  final int maxSizeBytes;

  const AudioCacheStats({
    required this.hits,
    required this.misses,
    required this.hitRate,
    required this.evictions,
    required this.entryCount,
    required this.maxEntries,
    required this.sizeBytes,
    required this.maxSizeBytes,
  });

  /// Cache utilization as a percentage (0.0 to 1.0)
  double get sizeUtilization =>
      maxSizeBytes > 0 ? sizeBytes / maxSizeBytes : 0.0;

  /// Entry utilization as a percentage (0.0 to 1.0)
  double get entryUtilization => maxEntries > 0 ? entryCount / maxEntries : 0.0;

  @override
  String toString() {
    return 'AudioCacheStats('
        'hits: $hits, '
        'misses: $misses, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'evictions: $evictions, '
        'entries: $entryCount/$maxEntries, '
        'size: ${(sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB/${(maxSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB'
        ')';
  }
}

/// Information about a cache entry
@immutable
class AudioCacheEntryInfo {
  final String key;
  final String text;
  final AlouetteTTSConfig config;
  final int sizeBytes;
  final DateTime timestamp;
  final bool isExpired;

  const AudioCacheEntryInfo({
    required this.key,
    required this.text,
    required this.config,
    required this.sizeBytes,
    required this.timestamp,
    required this.isExpired,
  });

  /// Human-readable size
  String get sizeString {
    if (sizeBytes < 1024) {
      return '${sizeBytes}B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }
  }

  /// Age of the entry
  Duration get age => DateTime.now().difference(timestamp);

  @override
  String toString() {
    return 'AudioCacheEntryInfo('
        'text: "${text.length > 50 ? text.substring(0, 50) + "..." : text}", '
        'size: $sizeString, '
        'age: ${age.inMinutes}min, '
        'expired: $isExpired'
        ')';
  }
}
