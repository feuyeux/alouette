import 'dart:async';
import 'dart:typed_data';
import '../models/alouette_tts_config.dart';
import 'audio_cache.dart';

/// Manages audio caching with automatic cleanup and monitoring
class AudioCacheManager {
  static AudioCacheManager? _instance;
  static final Completer<AudioCacheManager> _initCompleter =
      Completer<AudioCacheManager>();

  final AudioCache _cache;

  /// Whether automatic cleanup is enabled

  /// Cleanup interval for removing expired entries

  AudioCacheManager._({
    required AudioCache cache,
  }) : _cache = cache;

  /// Gets the singleton instance
  static AudioCacheManager get instance {
    if (_instance == null) {
      throw StateError(
          'AudioCacheManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Gets the future that completes when initialization is done
  static Future<AudioCacheManager> get initialized => _initCompleter.future;

  /// Initializes the audio cache manager
  static Future<AudioCacheManager> initialize({
    AudioCache? cache,
    Duration? cleanupInterval,
    bool autoCleanupEnabled = true,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final cacheInstance = cache ?? AudioCache();

    _instance = AudioCacheManager._(
      cache: cacheInstance,
    );


  // Auto-cleanup logic removed

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete(_instance!);
    }

    return _instance!;
  }

  /// Gets cached audio data for the given text and config
  Uint8List? getAudio(String text, AlouetteTTSConfig config) {
    return _cache.getAudio(text, config);
  }

  /// Caches audio data for the given text and config
  void putAudio(String text, AlouetteTTSConfig config, Uint8List audioData) {
    _cache.putAudio(text, config, audioData);
  }

  /// Checks if audio is cached for the given text and config
  bool hasAudio(String text, AlouetteTTSConfig config) {
    return _cache.hasAudio(text, config);
  }

  /// Invalidates cache for specific text and config
  void invalidateAudio(String text, AlouetteTTSConfig config) {
    _cache.invalidateAudio(text, config);
  }

  /// Invalidates all cached audio
  void invalidateAll() {
    _cache.invalidateAll();
  }

  /// Gets cache statistics
  AudioCacheStats getStats() {
    return _cache.getStats();
  }

  /// Resets cache statistics
  void resetStats() {
    _cache.resetStats();
  }

  /// Gets cache entries information
  List<AudioCacheEntryInfo> getEntries() {
    return _cache.getEntries();
  }

  /// Manually triggers cleanup of expired entries
  int cleanupExpired() {
    return _cache.cleanupExpired();
  }

  /// Enables or disables automatic cleanup
  void setAutoCleanupEnabled(bool enabled) {
  // Auto-cleanup logic removed
  }

  /// Sets the automatic cleanup interval
  void setCleanupInterval(Duration interval) {
    // Implementation for setting the cleanup interval
    // Add your logic here
  }
}

