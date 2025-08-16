import 'dart:async';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../models/alouette_tts_config.dart';
import 'audio_cache.dart';

/// Manages audio caching with automatic cleanup and monitoring
class AudioCacheManager {
  static AudioCacheManager? _instance;
  static final Completer<AudioCacheManager> _initCompleter =
      Completer<AudioCacheManager>();

  final AudioCache _cache;
  Timer? _cleanupTimer;

  /// Whether automatic cleanup is enabled
  bool _autoCleanupEnabled = true;

  /// Cleanup interval for removing expired entries
  Duration _cleanupInterval = const Duration(minutes: 30);

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

    _instance!._autoCleanupEnabled = autoCleanupEnabled;
    if (cleanupInterval != null) {
      _instance!._cleanupInterval = cleanupInterval;
    }

    // Start auto-cleanup if enabled
    if (autoCleanupEnabled) {
      _instance!._startAutoCleanup();
    }

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
    _autoCleanupEnabled = enabled;

    if (enabled) {
      _startAutoCleanup();
    } else {
      _stopAutoCleanup();
    }
  }

  /// Sets the automatic cleanup interval
  void setCleanupInterval(Duration interval) {
    _cleanupInterval = interval;

    if (_autoCleanupEnabled) {
      _stopAutoCleanup();
      _startAutoCleanup();
    }
  }

  /// Gets cache performance metrics
  AudioCachePerformanceMetrics getPerformanceMetrics() {
    final stats = _cache.getStats();
    final entries = _cache.getEntries();

    // Calculate average entry size
    final totalSize =
        entries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
    final avgEntrySize = entries.isNotEmpty ? totalSize / entries.length : 0.0;

    // Calculate age distribution
    final now = DateTime.now();
    final ages = entries
        .map((entry) => now.difference(entry.timestamp).inMinutes)
        .toList();
    ages.sort();

    final avgAge =
        ages.isNotEmpty ? ages.reduce((a, b) => a + b) / ages.length : 0.0;
    final medianAge = ages.isNotEmpty ? ages[ages.length ~/ 2].toDouble() : 0.0;

    // Calculate expired entries
    final expiredCount = entries.where((entry) => entry.isExpired).length;

    return AudioCachePerformanceMetrics(
      hitRate: stats.hitRate,
      sizeUtilization: stats.sizeUtilization,
      entryUtilization: stats.entryUtilization,
      averageEntrySize: avgEntrySize,
      averageAgeMinutes: avgAge,
      medianAgeMinutes: medianAge,
      expiredEntryCount: expiredCount,
      evictionRate:
          stats.evictions / (stats.hits + stats.misses + stats.evictions),
    );
  }

  /// Optimizes cache by removing expired entries and least valuable entries
  AudioCacheOptimizationResult optimizeCache({
    double? targetUtilization,
    bool removeExpired = true,
  }) {
    final initialStats = _cache.getStats();
    int removedExpired = 0;
    int removedLRU = 0;

    // Remove expired entries
    if (removeExpired) {
      removedExpired = _cache.cleanupExpired();
    }

    // Remove LRU entries if target utilization is specified
    if (targetUtilization != null &&
        targetUtilization > 0 &&
        targetUtilization < 1) {
      final currentStats = _cache.getStats();
      final targetSize =
          (currentStats.maxSizeBytes * targetUtilization).round();
      final entries = _cache.getEntries();

      // Sort by access time (oldest first) and remove until we reach target
      final sortedEntries = entries.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final entry in sortedEntries) {
        final stats = _cache.getStats();
        if (stats.sizeBytes <= targetSize) break;

        _cache.invalidateAudio(entry.text, entry.config);
        removedLRU++;
      }
    }

    final finalStats = _cache.getStats();

    return AudioCacheOptimizationResult(
      initialStats: initialStats,
      finalStats: finalStats,
      removedExpiredEntries: removedExpired,
      removedLRUEntries: removedLRU,
      spaceSavedBytes: initialStats.sizeBytes - finalStats.sizeBytes,
    );
  }

  /// Starts automatic cleanup timer
  void _startAutoCleanup() {
    _stopAutoCleanup();

    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      // Cleanup expired entries in background
      unawaited(_backgroundCleanup());
    });
  }

  /// Stops automatic cleanup timer
  void _stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Performs background cleanup
  Future<void> _backgroundCleanup() async {
    try {
      _cache.cleanupExpired();
    } catch (e) {
      // Ignore errors in background cleanup
    }
  }

  /// Disposes the cache manager
  void dispose() {
    _stopAutoCleanup();
  }
}

/// Audio cache performance metrics
@immutable
class AudioCachePerformanceMetrics {
  final double hitRate;
  final double sizeUtilization;
  final double entryUtilization;
  final double averageEntrySize;
  final double averageAgeMinutes;
  final double medianAgeMinutes;
  final int expiredEntryCount;
  final double evictionRate;

  const AudioCachePerformanceMetrics({
    required this.hitRate,
    required this.sizeUtilization,
    required this.entryUtilization,
    required this.averageEntrySize,
    required this.averageAgeMinutes,
    required this.medianAgeMinutes,
    required this.expiredEntryCount,
    required this.evictionRate,
  });

  @override
  String toString() {
    return 'AudioCachePerformanceMetrics('
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'sizeUtil: ${(sizeUtilization * 100).toStringAsFixed(1)}%, '
        'entryUtil: ${(entryUtilization * 100).toStringAsFixed(1)}%, '
        'avgSize: ${(averageEntrySize / 1024).toStringAsFixed(1)}KB, '
        'avgAge: ${averageAgeMinutes.toStringAsFixed(1)}min, '
        'expired: $expiredEntryCount, '
        'evictionRate: ${(evictionRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// Result of cache optimization operation
@immutable
class AudioCacheOptimizationResult {
  final AudioCacheStats initialStats;
  final AudioCacheStats finalStats;
  final int removedExpiredEntries;
  final int removedLRUEntries;
  final int spaceSavedBytes;

  const AudioCacheOptimizationResult({
    required this.initialStats,
    required this.finalStats,
    required this.removedExpiredEntries,
    required this.removedLRUEntries,
    required this.spaceSavedBytes,
  });

  /// Total entries removed
  int get totalRemovedEntries => removedExpiredEntries + removedLRUEntries;

  /// Space saved in MB
  double get spaceSavedMB => spaceSavedBytes / 1024 / 1024;

  @override
  String toString() {
    return 'AudioCacheOptimizationResult('
        'removed: $totalRemovedEntries entries '
        '($removedExpiredEntries expired, $removedLRUEntries LRU), '
        'spaceSaved: ${spaceSavedMB.toStringAsFixed(1)}MB, '
        'utilization: ${(initialStats.sizeUtilization * 100).toStringAsFixed(1)}% → '
        '${(finalStats.sizeUtilization * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// Extension to avoid awaiting futures in fire-and-forget scenarios
extension _Unawaited on Future<void> {
  void get unawaited {}
}

/// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally not awaiting
}
