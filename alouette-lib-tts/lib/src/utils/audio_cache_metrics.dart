import 'package:meta/meta.dart';

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

@immutable
class AudioCacheOptimizationResult {
  final dynamic initialStats;
  final dynamic finalStats;
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

  @override
  String toString() {
    return 'AudioCacheOptimizationResult('
      'utilization: ${(initialStats.sizeUtilization * 100).toStringAsFixed(1)}% → '
      '${(finalStats.sizeUtilization * 100).toStringAsFixed(1)}%, '
      'expiredRemoved: $removedExpiredEntries, '
      'lruRemoved: $removedLRUEntries, '
      'spaceSaved: ${(spaceSavedBytes / 1024).toStringAsFixed(1)}KB'
      ')';
  }
}
