import 'dart:async';
import '../models/alouette_voice.dart';
import '../enums/tts_platform.dart';
import '../interfaces/i_platform_detector.dart';
import 'voice_cache.dart';

/// Manages voice caching with automatic refresh and invalidation
class VoiceCacheManager {
  static VoiceCacheManager? _instance;
  static final Completer<VoiceCacheManager> _initCompleter =
      Completer<VoiceCacheManager>();

  final VoiceCache _cache;
  final IPlatformDetector _platformDetector;
  Timer? _refreshTimer;

  /// Callback to fetch fresh voices when cache miss occurs
  Future<List<AlouetteVoice>> Function(TTSPlatform platform)? _voiceFetcher;

  /// Whether automatic refresh is enabled
  bool _autoRefreshEnabled = true;

  /// Refresh interval for automatic cache updates
  Duration _refreshInterval = const Duration(hours: 12);

  VoiceCacheManager._({
    required VoiceCache cache,
    required IPlatformDetector platformDetector,
  })  : _cache = cache,
        _platformDetector = platformDetector;

  /// Gets the singleton instance
  static VoiceCacheManager get instance {
    if (_instance == null) {
      throw StateError(
          'VoiceCacheManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Gets the future that completes when initialization is done
  static Future<VoiceCacheManager> get initialized => _initCompleter.future;

  /// Initializes the voice cache manager
  static Future<VoiceCacheManager> initialize({
    VoiceCache? cache,
    required IPlatformDetector platformDetector,
    Duration? refreshInterval,
    bool autoRefreshEnabled = true,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final cacheInstance = cache ?? VoiceCache();

    _instance = VoiceCacheManager._(
      cache: cacheInstance,
      platformDetector: platformDetector,
    );

    _instance!._autoRefreshEnabled = autoRefreshEnabled;
    if (refreshInterval != null) {
      _instance!._refreshInterval = refreshInterval;
    }

    // Load cache from storage
    await _instance!._cache.loadFromStorage();

    // Start auto-refresh if enabled
    if (autoRefreshEnabled) {
      _instance!._startAutoRefresh();
    }

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete(_instance!);
    }

    return _instance!;
  }

  /// Sets the voice fetcher callback
  void setVoiceFetcher(
      Future<List<AlouetteVoice>> Function(TTSPlatform platform) fetcher) {
    _voiceFetcher = fetcher;
  }

  /// Gets voices for a platform with caching
  Future<List<AlouetteVoice>> getVoices(TTSPlatform platform,
      {bool forceRefresh = false}) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cachedVoices = _cache.getVoices(platform);
      if (cachedVoices != null) {
        return cachedVoices;
      }
    }

    // Cache miss or force refresh - fetch fresh voices
    if (_voiceFetcher != null) {
      try {
        final freshVoices = await _voiceFetcher!(platform);

        // Cache the fresh voices
        _cache.putVoices(platform, freshVoices);

        // Save to storage asynchronously
        unawaited(_cache.saveToStorage());

        return freshVoices;
      } catch (e) {
        // If fetching fails and we have cached data, return it even if expired
        final cachedVoices = _cache.getVoices(platform);
        if (cachedVoices != null) {
          return cachedVoices;
        }
        rethrow;
      }
    }

    // No fetcher available and no cached data
    return [];
  }

  /// Gets voices for the current platform
  Future<List<AlouetteVoice>> getVoicesForCurrentPlatform(
      {bool forceRefresh = false}) async {
    final platform = _platformDetector.getCurrentPlatform();
    return getVoices(platform, forceRefresh: forceRefresh);
  }

  /// Checks if voices are cached for a platform
  bool hasValidVoices(TTSPlatform platform) {
    return _cache.hasValidVoices(platform);
  }

  /// Preloads voices for a platform
  Future<void> preloadVoices(TTSPlatform platform) async {
    if (!hasValidVoices(platform)) {
      await getVoices(platform);
    }
  }

  /// Preloads voices for all platforms
  Future<void> preloadAllVoices() async {
    final platforms = TTSPlatform.values;
    final futures = platforms.map((platform) => preloadVoices(platform));
    await Future.wait(futures, eagerError: false);
  }

  /// Refreshes voices for a platform
  Future<List<AlouetteVoice>> refreshVoices(TTSPlatform platform) async {
    return getVoices(platform, forceRefresh: true);
  }

  /// Refreshes voices for the current platform
  Future<List<AlouetteVoice>> refreshCurrentPlatformVoices() async {
    final platform = _platformDetector.getCurrentPlatform();
    return refreshVoices(platform);
  }

  /// Refreshes voices for all platforms
  Future<void> refreshAllVoices() async {
    final platforms = TTSPlatform.values;
    final futures = platforms.map((platform) => refreshVoices(platform));
    await Future.wait(futures, eagerError: false);
  }

  /// Invalidates cache for a platform
  void invalidatePlatform(TTSPlatform platform) {
    _cache.invalidatePlatform(platform);
    unawaited(_cache.saveToStorage());
  }

  /// Invalidates cache for the current platform
  void invalidateCurrentPlatform() {
    final platform = _platformDetector.getCurrentPlatform();
    invalidatePlatform(platform);
  }

  /// Invalidates all cached voices
  void invalidateAll() {
    _cache.invalidateAll();
    unawaited(_cache.saveToStorage());
  }

  /// Gets cache statistics
  CacheStats getStats() {
    return _cache.getStats();
  }

  /// Resets cache statistics
  void resetStats() {
    _cache.resetStats();
  }

  /// Enables or disables automatic refresh
  void setAutoRefreshEnabled(bool enabled) {
    _autoRefreshEnabled = enabled;

    if (enabled) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  /// Sets the automatic refresh interval
  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;

    if (_autoRefreshEnabled) {
      _stopAutoRefresh();
      _startAutoRefresh();
    }
  }

  /// Starts automatic refresh timer
  void _startAutoRefresh() {
    _stopAutoRefresh();

    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      // Refresh voices for current platform in background
      unawaited(_backgroundRefresh());
    });
  }

  /// Stops automatic refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Performs background refresh for current platform
  Future<void> _backgroundRefresh() async {
    try {
      final platform = _platformDetector.getCurrentPlatform();

      // Only refresh if we have cached voices that might be getting stale
      if (_cache.hasValidVoices(platform)) {
        await refreshVoices(platform);
      }
    } catch (e) {
      // Ignore errors in background refresh
    }
  }

  /// Disposes the cache manager
  void dispose() {
    _stopAutoRefresh();
    unawaited(_cache.saveToStorage());
  }

  /// Saves cache to storage manually
  Future<void> saveToStorage() async {
    await _cache.saveToStorage();
  }

  /// Loads cache from storage manually
  Future<void> loadFromStorage() async {
    await _cache.loadFromStorage();
  }
}

/// Extension to avoid awaiting futures in fire-and-forget scenarios

/// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally not awaiting
}
