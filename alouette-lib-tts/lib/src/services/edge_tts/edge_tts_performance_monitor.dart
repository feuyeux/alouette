import 'dart:collection';

/// Performance monitoring for Edge TTS operations
class EdgeTTSPerformanceMonitor {
  static const int _maxMetricsHistory = 100;

  final Queue<_OperationMetric> _synthesisMetrics = Queue<_OperationMetric>();
  final Queue<_OperationMetric> _connectionMetrics = Queue<_OperationMetric>();
  final Map<String, int> _errorCounts = <String, int>{};

  DateTime? _startTime;
  int _totalOperations = 0;
  int _successfulOperations = 0;
  int _failedOperations = 0;

  EdgeTTSPerformanceMonitor() {
    _startTime = DateTime.now();
  }

  /// Records a synthesis operation metric
  void recordSynthesis({
    required Duration duration,
    required int textLength,
    required bool success,
    String? errorType,
    Map<String, dynamic>? metadata,
  }) {
    final metric = _OperationMetric(
      duration: duration,
      success: success,
      timestamp: DateTime.now(),
      metadata: {
        'textLength': textLength,
        'errorType': errorType,
        ...?metadata,
      },
    );

    _synthesisMetrics.add(metric);
    if (_synthesisMetrics.length > _maxMetricsHistory) {
      _synthesisMetrics.removeFirst();
    }

    _totalOperations++;
    if (success) {
      _successfulOperations++;
    } else {
      _failedOperations++;
      if (errorType != null) {
        _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
      }
    }
  }

  /// Records a connection operation metric
  void recordConnection({
    required Duration duration,
    required bool success,
    String? errorType,
    Map<String, dynamic>? metadata,
  }) {
    final metric = _OperationMetric(
      duration: duration,
      success: success,
      timestamp: DateTime.now(),
      metadata: {
        'errorType': errorType,
        ...?metadata,
      },
    );

    _connectionMetrics.add(metric);
    if (_connectionMetrics.length > _maxMetricsHistory) {
      _connectionMetrics.removeFirst();
    }
  }

  /// Records a file operation metric
  void recordFileOperation({
    required String operation,
    required String filePath,
    required int fileSize,
    required bool success,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    // For now, we'll record file operations as synthesis metrics
    // In a more complete implementation, you might want a separate queue for file operations
    final metric = _OperationMetric(
      duration: Duration.zero, // File operations are typically fast
      success: success,
      timestamp: DateTime.now(),
      metadata: {
        'operation': operation,
        'filePath': filePath,
        'fileSize': fileSize,
        'error': error,
        ...?metadata,
      },
    );

    _synthesisMetrics.add(metric);
    if (_synthesisMetrics.length > _maxMetricsHistory) {
      _synthesisMetrics.removeFirst();
    }

    _totalOperations++;
    if (success) {
      _successfulOperations++;
    } else {
      _failedOperations++;
      if (error != null) {
        _errorCounts[error] = (_errorCounts[error] ?? 0) + 1;
      }
    }
  }

  /// Gets synthesis performance statistics
  Map<String, dynamic> getSynthesisStats() {
    if (_synthesisMetrics.isEmpty) {
      return {
        'totalOperations': 0,
        'averageDurationMs': 0,
        'successRate': 0.0,
        'averageTextLength': 0,
        'operationsPerMinute': 0.0,
      };
    }

    final durations =
        _synthesisMetrics.map((m) => m.duration.inMilliseconds).toList();
    final textLengths = _synthesisMetrics
        .map((m) => m.metadata['textLength'] as int? ?? 0)
        .where((length) => length > 0)
        .toList();

    final successfulMetrics = _synthesisMetrics.where((m) => m.success).length;
    final totalMetrics = _synthesisMetrics.length;

    // Calculate operations per minute
    final timeSpan = DateTime.now().difference(_startTime!);
    final operationsPerMinute =
        timeSpan.inMinutes > 0 ? _totalOperations / timeSpan.inMinutes : 0.0;

    return {
      'totalOperations': totalMetrics,
      'averageDurationMs': durations.isEmpty
          ? 0
          : durations.reduce((a, b) => a + b) ~/ durations.length,
      'minDurationMs':
          durations.isEmpty ? 0 : durations.reduce((a, b) => a < b ? a : b),
      'maxDurationMs':
          durations.isEmpty ? 0 : durations.reduce((a, b) => a > b ? a : b),
      'successRate': totalMetrics > 0 ? successfulMetrics / totalMetrics : 0.0,
      'averageTextLength': textLengths.isEmpty
          ? 0
          : textLengths.reduce((a, b) => a + b) ~/ textLengths.length,
      'operationsPerMinute': operationsPerMinute,
      'recentOperations': _synthesisMetrics.length,
    };
  }

  /// Gets connection performance statistics
  Map<String, dynamic> getConnectionStats() {
    if (_connectionMetrics.isEmpty) {
      return {
        'totalConnections': 0,
        'averageConnectionTimeMs': 0,
        'connectionSuccessRate': 0.0,
      };
    }

    final durations =
        _connectionMetrics.map((m) => m.duration.inMilliseconds).toList();
    final successfulConnections =
        _connectionMetrics.where((m) => m.success).length;
    final totalConnections = _connectionMetrics.length;

    return {
      'totalConnections': totalConnections,
      'averageConnectionTimeMs':
          durations.reduce((a, b) => a + b) ~/ durations.length,
      'minConnectionTimeMs': durations.reduce((a, b) => a < b ? a : b),
      'maxConnectionTimeMs': durations.reduce((a, b) => a > b ? a : b),
      'connectionSuccessRate': successfulConnections / totalConnections,
      'recentConnections': _connectionMetrics.length,
    };
  }

  /// Gets error statistics
  Map<String, dynamic> getErrorStats() {
    final totalErrors =
        _errorCounts.values.fold(0, (sum, count) => sum + count);

    return {
      'totalErrors': totalErrors,
      'errorTypes': Map<String, int>.from(_errorCounts),
      'errorRate': _totalOperations > 0 ? totalErrors / _totalOperations : 0.0,
      'mostCommonError': _errorCounts.isNotEmpty
          ? _errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Gets overall performance summary
  Map<String, dynamic> getOverallStats() {
    final uptime = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return {
      'uptime': {
        'totalMinutes': uptime.inMinutes,
        'totalHours': uptime.inHours,
        'startTime': _startTime?.toIso8601String(),
      },
      'operations': {
        'total': _totalOperations,
        'successful': _successfulOperations,
        'failed': _failedOperations,
        'successRate': _totalOperations > 0
            ? _successfulOperations / _totalOperations
            : 0.0,
      },
      'synthesis': getSynthesisStats(),
      'connections': getConnectionStats(),
      'errors': getErrorStats(),
    };
  }

  /// Gets performance trends over time
  Map<String, dynamic> getPerformanceTrends() {
    if (_synthesisMetrics.length < 2) {
      return {
        'trend': 'insufficient_data',
        'recentAverageDurationMs': 0,
        'historicalAverageDurationMs': 0,
      };
    }

    // Split metrics into recent and historical
    final halfPoint = _synthesisMetrics.length ~/ 2;
    final historicalMetrics = _synthesisMetrics.take(halfPoint).toList();
    final recentMetrics = _synthesisMetrics.skip(halfPoint).toList();

    final historicalAvg = historicalMetrics.isEmpty
        ? 0
        : historicalMetrics
                .map((m) => m.duration.inMilliseconds)
                .reduce((a, b) => a + b) /
            historicalMetrics.length;

    final recentAvg = recentMetrics.isEmpty
        ? 0
        : recentMetrics
                .map((m) => m.duration.inMilliseconds)
                .reduce((a, b) => a + b) /
            recentMetrics.length;

    String trend;
    if (recentAvg < historicalAvg * 0.9) {
      trend = 'improving';
    } else if (recentAvg > historicalAvg * 1.1) {
      trend = 'degrading';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'recentAverageDurationMs': recentAvg.round(),
      'historicalAverageDurationMs': historicalAvg.round(),
      'improvementPercent': historicalAvg > 0
          ? ((historicalAvg - recentAvg) / historicalAvg * 100).round()
          : 0,
    };
  }

  /// Resets all metrics
  void reset() {
    _synthesisMetrics.clear();
    _connectionMetrics.clear();
    _errorCounts.clear();
    _startTime = DateTime.now();
    _totalOperations = 0;
    _successfulOperations = 0;
    _failedOperations = 0;
  }

  /// Gets metrics for a specific time window
  List<_OperationMetric> getMetricsInWindow(Duration window,
      {bool synthesisOnly = true}) {
    final cutoff = DateTime.now().subtract(window);
    final metrics = synthesisOnly ? _synthesisMetrics : _connectionMetrics;

    return metrics.where((metric) => metric.timestamp.isAfter(cutoff)).toList();
  }

  /// Calculates percentiles for operation durations
  Map<String, int> getDurationPercentiles({bool synthesisOnly = true}) {
    final metrics = synthesisOnly ? _synthesisMetrics : _connectionMetrics;
    if (metrics.isEmpty) return {};

    final durations = metrics.map((m) => m.duration.inMilliseconds).toList()
      ..sort();

    return {
      'p50': _getPercentile(durations, 0.5),
      'p90': _getPercentile(durations, 0.9),
      'p95': _getPercentile(durations, 0.95),
      'p99': _getPercentile(durations, 0.99),
    };
  }

  /// Calculates a specific percentile from a sorted list
  int _getPercentile(List<int> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;

    final index = (sortedValues.length * percentile).floor();
    return sortedValues[index.clamp(0, sortedValues.length - 1)];
  }
}

/// Internal class for storing operation metrics
class _OperationMetric {
  final Duration duration;
  final bool success;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const _OperationMetric({
    required this.duration,
    required this.success,
    required this.timestamp,
    this.metadata = const {},
  });
}
