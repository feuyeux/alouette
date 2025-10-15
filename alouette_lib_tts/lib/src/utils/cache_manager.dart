import 'dart:convert';
import 'dart:typed_data';
import '../models/voice_model.dart';
import '../utils/logger_config.dart';

/// 缓存条目基类
abstract class CacheEntry {
  final DateTime createdAt;
  final DateTime? expiresAt;

  CacheEntry({DateTime? createdAt, this.expiresAt})
    : createdAt = createdAt ?? DateTime.now();

  /// 检查缓存是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 获取缓存的大小（字节）
  int get sizeInBytes;
}

/// Voice list cache entry
class VoiceCacheEntry extends CacheEntry {
  final List<VoiceModel> voices;
  final String engineType;

  VoiceCacheEntry({
    required this.voices,
    required this.engineType,
    super.createdAt,
    super.expiresAt,
  });

  @override
  int get sizeInBytes {
    // Estimate memory size of voice list
    int totalSize = 0;
    for (final voice in voices) {
      totalSize += voice.id.length * 2; // UTF-16
      totalSize += voice.displayName.length * 2;
      totalSize += voice.languageCode.length * 2;
      totalSize += 16; // Enums and other fields
    }
    totalSize += engineType.length * 2;
    return totalSize;
  }
}

/// 音频数据缓存条目
class AudioCacheEntry extends CacheEntry {
  final Uint8List audioData;
  final String textHash;
  final String voiceName;
  final String format;

  AudioCacheEntry({
    required this.audioData,
    required this.textHash,
    required this.voiceName,
    required this.format,
    super.createdAt,
    super.expiresAt,
  });

  @override
  int get sizeInBytes =>
      audioData.length +
      textHash.length * 2 +
      voiceName.length * 2 +
      format.length * 2;
}

/// 配置缓存条目
class ConfigCacheEntry extends CacheEntry {
  final Map<String, dynamic> config;
  final String configPath;

  ConfigCacheEntry({
    required this.config,
    required this.configPath,
    super.createdAt,
    super.expiresAt,
  });

  @override
  int get sizeInBytes {
    final jsonString = jsonEncode(config);
    return jsonString.length * 2 + configPath.length * 2;
  }
}

/// 缓存策略配置
class CacheConfig {
  /// 语音列表缓存的过期时间
  final Duration voiceCacheExpiry;

  /// 音频数据缓存的过期时间
  final Duration audioCacheExpiry;

  /// 配置缓存的过期时间
  final Duration configCacheExpiry;

  /// 最大缓存大小（字节）
  final int maxCacheSize;

  /// 最大缓存条目数
  final int maxCacheEntries;

  /// 是否启用音频缓存
  final bool enableAudioCache;

  /// 是否启用语音缓存
  final bool enableVoiceCache;

  /// 是否启用配置缓存
  final bool enableConfigCache;

  const CacheConfig({
    this.voiceCacheExpiry = const Duration(hours: 24),
    this.audioCacheExpiry = const Duration(hours: 1),
    this.configCacheExpiry = const Duration(minutes: 30),
    this.maxCacheSize = 50 * 1024 * 1024, // 50MB
    this.maxCacheEntries = 1000,
    this.enableAudioCache = true,
    this.enableVoiceCache = true,
    this.enableConfigCache = true,
  });
}

/// 缓存管理器
/// 管理语音列表、音频数据和配置的缓存
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  CacheConfig _config = const CacheConfig();

  final Map<String, VoiceCacheEntry> _voiceCache = {};
  final Map<String, AudioCacheEntry> _audioCache = {};
  final Map<String, ConfigCacheEntry> _configCache = {};

  /// 更新缓存配置
  void updateConfig(CacheConfig config) {
    _config = config;
    ttsLogger.d('[CACHE] Cache configuration updated');
    _enforceSize();
  }

  /// 获取当前缓存配置
  CacheConfig get config => _config;

  // ============ 语音缓存管理 ============

  /// Cache voice list
  void cacheVoices(String engineType, List<VoiceModel> voices) {
    if (!_config.enableVoiceCache) return;

    final key = _generateVoiceCacheKey(engineType);
    final expiresAt = DateTime.now().add(_config.voiceCacheExpiry);

    _voiceCache[key] = VoiceCacheEntry(
      voices: voices,
      engineType: engineType,
      expiresAt: expiresAt,
    );

    ttsLogger.d('[CACHE] Cached ${voices.length} voices for $engineType');
    _enforceSize();
  }

  /// Get cached voice list
  List<VoiceModel>? getCachedVoices(String engineType) {
    if (!_config.enableVoiceCache) return null;

    final key = _generateVoiceCacheKey(engineType);
    final entry = _voiceCache[key];

    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _voiceCache.remove(key);
        ttsLogger.d('[CACHE] Removed expired voice cache for $engineType');
      }
      return null;
    }

    ttsLogger.d('[CACHE] Retrieved ${entry.voices.length} cached voices for $engineType');
    return entry.voices;
  }

  /// 清除语音缓存
  void clearVoiceCache([String? engineType]) {
    if (engineType != null) {
      final key = _generateVoiceCacheKey(engineType);
      _voiceCache.remove(key);
      ttsLogger.d('[CACHE] Cleared voice cache for $engineType');
    } else {
      _voiceCache.clear();
      ttsLogger.d('[CACHE] Cleared all voice caches');
    }
  }

  String _generateVoiceCacheKey(String engineType) {
    return 'voices_$engineType';
  }

  // ============ 音频缓存管理 ============

  /// 缓存音频数据
  void cacheAudio(
    String text,
    String voiceName,
    String format,
    Uint8List audioData,
  ) {
    if (!_config.enableAudioCache) return;

    final key = _generateAudioCacheKey(text, voiceName, format);
    final textHash = _generateTextHash(text);
    final expiresAt = DateTime.now().add(_config.audioCacheExpiry);

    _audioCache[key] = AudioCacheEntry(
      audioData: audioData,
      textHash: textHash,
      voiceName: voiceName,
      format: format,
      expiresAt: expiresAt,
    );

    ttsLogger.d('[CACHE] Cached audio data - Text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...", Voice: $voiceName, Size: ${audioData.length} bytes');
    _enforceSize();
  }

  /// 获取缓存的音频数据
  Uint8List? getCachedAudio(String text, String voiceName, String format) {
    if (!_config.enableAudioCache) return null;

    final key = _generateAudioCacheKey(text, voiceName, format);
    final entry = _audioCache[key];

    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _audioCache.remove(key);
        ttsLogger.d('[CACHE] Removed expired audio cache - Text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...", Voice: $voiceName');
      }
      return null;
    }

    ttsLogger.d('[CACHE] Using cached audio - Text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...", Voice: $voiceName, Size: ${entry.audioData.length} bytes');
    return entry.audioData;
  }

  /// 清除音频缓存
  void clearAudioCache() {
    _audioCache.clear();
    ttsLogger.d('[CACHE] Cleared all audio caches');
  }

  /// 清除特定的音频缓存项
  void clearAudioCacheItem(String text, String voiceName, String format) {
    if (!_config.enableAudioCache) return;

    final key = _generateAudioCacheKey(text, voiceName, format);
    final removed = _audioCache.remove(key);
    
    if (removed != null) {
      ttsLogger.d('[CACHE] Cleared specific audio cache: text=${text.substring(0, text.length > 20 ? 20 : text.length)}..., voice=$voiceName');
    }
  }

  String _generateAudioCacheKey(String text, String voiceName, String format) {
    final textHash = _generateTextHash(text);
    return 'audio_${textHash}_${voiceName}_$format';
  }

  String _generateTextHash(String text) {
    // 使用简单的哈希算法
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = ((hash << 5) - hash + text.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.abs().toString();
  }

  // ============ 配置缓存管理 ============

  /// 缓存配置数据
  void cacheConfig(String configPath, Map<String, dynamic> config) {
    if (!_config.enableConfigCache) return;

    final key = _generateConfigCacheKey(configPath);
    final expiresAt = DateTime.now().add(_config.configCacheExpiry);

    _configCache[key] = ConfigCacheEntry(
      config: Map.from(config),
      configPath: configPath,
      expiresAt: expiresAt,
    );

    ttsLogger.d('[CACHE] Cached configuration for $configPath');
    _enforceSize();
  }

  /// 获取缓存的配置数据
  Map<String, dynamic>? getCachedConfig(String configPath) {
    if (!_config.enableConfigCache) return null;

    final key = _generateConfigCacheKey(configPath);
    final entry = _configCache[key];

    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _configCache.remove(key);
        ttsLogger.d('[CACHE] Removed expired config cache for $configPath');
      }
      return null;
    }

    ttsLogger.d('[CACHE] Retrieved cached configuration for $configPath');
    return Map.from(entry.config);
  }

  /// 清除配置缓存
  void clearConfigCache([String? configPath]) {
    if (configPath != null) {
      final key = _generateConfigCacheKey(configPath);
      _configCache.remove(key);
      ttsLogger.d('[CACHE] Cleared config cache for $configPath');
    } else {
      _configCache.clear();
      ttsLogger.d('[CACHE] Cleared all config caches');
    }
  }

  String _generateConfigCacheKey(String configPath) {
    return 'config_$configPath';
  }

  // ============ 通用缓存管理 ============

  /// 清除所有缓存
  void clearAll() {
    _voiceCache.clear();
    _audioCache.clear();
    _configCache.clear();
    ttsLogger.i('[CACHE] Cleared all caches');
  }

  /// 清除过期的缓存条目
  void clearExpired() {
    int removedCount = 0;

    // 清除过期的语音缓存
    _voiceCache.removeWhere((key, entry) {
      if (entry.isExpired) {
        removedCount++;
        return true;
      }
      return false;
    });

    // 清除过期的音频缓存
    _audioCache.removeWhere((key, entry) {
      if (entry.isExpired) {
        removedCount++;
        return true;
      }
      return false;
    });

    // 清除过期的配置缓存
    _configCache.removeWhere((key, entry) {
      if (entry.isExpired) {
        removedCount++;
        return true;
      }
      return false;
    });

    if (removedCount > 0) {
      ttsLogger.d('[CACHE] Removed $removedCount expired cache entries');
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    final totalSize = _calculateTotalSize();
    final totalEntries =
        _voiceCache.length + _audioCache.length + _configCache.length;

    return {
      'totalEntries': totalEntries,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'voiceEntries': _voiceCache.length,
      'audioEntries': _audioCache.length,
      'configEntries': _configCache.length,
      'maxSizeBytes': _config.maxCacheSize,
      'maxSizeMB': (_config.maxCacheSize / (1024 * 1024)).toStringAsFixed(2),
      'maxEntries': _config.maxCacheEntries,
      'utilizationPercent': ((totalSize / _config.maxCacheSize) * 100)
          .toStringAsFixed(1),
    };
  }

  /// 检查缓存健康状态
  Map<String, dynamic> getHealthCheck() {
    final stats = getStats();
    final totalSize = stats['totalSizeBytes'] as int;
    final totalEntries = stats['totalEntries'] as int;

    final sizeOk = totalSize <= _config.maxCacheSize;
    final entriesOk = totalEntries <= _config.maxCacheEntries;

    return {
      'healthy': sizeOk && entriesOk,
      'sizeOk': sizeOk,
      'entriesOk': entriesOk,
      'recommendations': _getHealthRecommendations(totalSize, totalEntries),
    };
  }

  List<String> _getHealthRecommendations(int totalSize, int totalEntries) {
    final recommendations = <String>[];

    if (totalSize > _config.maxCacheSize * 0.9) {
      recommendations.add(
        'Cache size is approaching limit, consider clearing old entries',
      );
    }

    if (totalEntries > _config.maxCacheEntries * 0.9) {
      recommendations.add('Cache entry count is approaching limit');
    }

    if (_audioCache.length > 100) {
      recommendations.add(
        'Large number of audio cache entries, consider reducing audio cache expiry',
      );
    }

    return recommendations;
  }

  /// 强制执行缓存大小限制
  void _enforceSize() {
    clearExpired();

    final totalSize = _calculateTotalSize();
    final totalEntries =
        _voiceCache.length + _audioCache.length + _configCache.length;

    // 如果超出大小限制，清除最旧的音频缓存条目
    if (totalSize > _config.maxCacheSize ||
        totalEntries > _config.maxCacheEntries) {
      _evictOldestEntries();
    }
  }

  /// 清除最旧的缓存条目
  void _evictOldestEntries() {
    // 优先清除音频缓存（通常最大）
    final audioEntries = _audioCache.entries.toList();
    audioEntries.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    int removedCount = 0;
    for (final entry in audioEntries) {
      _audioCache.remove(entry.key);
      removedCount++;

      final newSize = _calculateTotalSize();
      final newEntries =
          _voiceCache.length + _audioCache.length + _configCache.length;

      if (newSize <= _config.maxCacheSize &&
          newEntries <= _config.maxCacheEntries) {
        break;
      }
    }

    if (removedCount > 0) {
      ttsLogger.d('[CACHE] Evicted $removedCount cache entries to enforce size limits');
    }
  }

  /// 计算总缓存大小
  int _calculateTotalSize() {
    int totalSize = 0;

    for (final entry in _voiceCache.values) {
      totalSize += entry.sizeInBytes;
    }

    for (final entry in _audioCache.values) {
      totalSize += entry.sizeInBytes;
    }

    for (final entry in _configCache.values) {
      totalSize += entry.sizeInBytes;
    }

    return totalSize;
  }
}
