import 'dart:math';
import 'package:meta/meta.dart';
import '../models/tts_result.dart';
import '../models/tts_request.dart';
import '../models/batch_processor.dart';

/// Detailed metrics for batch processing operations
@immutable
class BatchMetrics {
  /// Total processing time for the entire batch
  final Duration totalProcessingTime;

  /// Average processing time per request
  final Duration averageProcessingTime;

  /// Minimum processing time among all requests
  final Duration minProcessingTime;

  /// Maximum processing time among all requests
  final Duration maxProcessingTime;

  /// Standard deviation of processing times
  final Duration processingTimeStdDev;

  /// Throughput in requests per second
  final double throughput;

  /// Total audio data size in bytes
  final int totalAudioSize;

  /// Average audio size per successful request
  final double averageAudioSize;

  /// Memory efficiency (audio size / processing time)
  final double memoryEfficiency;

  /// Success rate as a percentage (0-100)
  final double successRate;

  /// Error rate as a percentage (0-100)
  final double errorRate;

  /// Most common error type
  final String? mostCommonError;

  /// Number of retries performed
  final int totalRetries;

  /// Retry success rate as a percentage (0-100)
  final double retrySuccessRate;

  const BatchMetrics({
    required this.totalProcessingTime,
    required this.averageProcessingTime,
    required this.minProcessingTime,
    required this.maxProcessingTime,
    required this.processingTimeStdDev,
    required this.throughput,
    required this.totalAudioSize,
    required this.averageAudioSize,
    required this.memoryEfficiency,
    required this.successRate,
    required this.errorRate,
    this.mostCommonError,
    required this.totalRetries,
    required this.retrySuccessRate,
  });

  /// Converts metrics to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'totalProcessingTimeMs': totalProcessingTime.inMilliseconds,
      'averageProcessingTimeMs': averageProcessingTime.inMilliseconds,
      'minProcessingTimeMs': minProcessingTime.inMilliseconds,
      'maxProcessingTimeMs': maxProcessingTime.inMilliseconds,
      'processingTimeStdDevMs': processingTimeStdDev.inMilliseconds,
      'throughput': throughput,
      'totalAudioSize': totalAudioSize,
      'averageAudioSize': averageAudioSize,
      'memoryEfficiency': memoryEfficiency,
      'successRate': successRate,
      'errorRate': errorRate,
      'mostCommonError': mostCommonError,
      'totalRetries': totalRetries,
      'retrySuccessRate': retrySuccessRate,
    };
  }

  /// Returns a human-readable summary of the metrics
  String get summary {
    return 'Batch Metrics: ${successRate.toStringAsFixed(1)}% success, '
        '${throughput.toStringAsFixed(2)} req/s, '
        '${(totalAudioSize / 1024 / 1024).toStringAsFixed(2)}MB total audio, '
        '${totalProcessingTime.inSeconds}s total time';
  }
}

/// Detailed error analysis for batch processing
@immutable
class BatchErrorAnalysis {
  /// Categorized errors by type
  final Map<String, List<BatchError>> errorsByType;

  /// Errors by request ID
  final Map<String, BatchError> errorsByRequestId;

  /// Most frequent error types
  final List<ErrorFrequency> errorFrequencies;

  /// Requests that failed after all retries
  final List<String> permanentFailures;

  /// Requests that succeeded after retries
  final List<String> recoveredRequests;

  /// Average time to failure
  final Duration averageTimeToFailure;

  /// Failure patterns (e.g., network issues, timeout patterns)
  final List<FailurePattern> failurePatterns;

  const BatchErrorAnalysis({
    required this.errorsByType,
    required this.errorsByRequestId,
    required this.errorFrequencies,
    required this.permanentFailures,
    required this.recoveredRequests,
    required this.averageTimeToFailure,
    required this.failurePatterns,
  });

  /// Gets the most common error type
  String? get mostCommonErrorType {
    if (errorFrequencies.isEmpty) return null;
    return errorFrequencies.first.errorType;
  }

  /// Gets the total number of errors
  int get totalErrors => errorsByRequestId.length;

  /// Gets the number of different error types
  int get uniqueErrorTypes => errorsByType.length;

  /// Converts to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'errorsByType': errorsByType
          .map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList())),
      'errorsByRequestId':
          errorsByRequestId.map((k, v) => MapEntry(k, v.toMap())),
      'errorFrequencies': errorFrequencies.map((e) => e.toMap()).toList(),
      'permanentFailures': permanentFailures,
      'recoveredRequests': recoveredRequests,
      'averageTimeToFailureMs': averageTimeToFailure.inMilliseconds,
      'failurePatterns': failurePatterns.map((p) => p.toMap()).toList(),
    };
  }
}

/// Error frequency information
@immutable
class ErrorFrequency {
  final String errorType;
  final int count;
  final double percentage;

  const ErrorFrequency({
    required this.errorType,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'errorType': errorType,
      'count': count,
      'percentage': percentage,
    };
  }
}

/// Failure pattern analysis
@immutable
class FailurePattern {
  final String patternType;
  final String description;
  final List<String> affectedRequestIds;
  final double confidence;

  const FailurePattern({
    required this.patternType,
    required this.description,
    required this.affectedRequestIds,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'patternType': patternType,
      'description': description,
      'affectedRequestIds': affectedRequestIds,
      'confidence': confidence,
    };
  }
}

/// Detailed batch result with enhanced analysis
@immutable
class DetailedBatchResult extends BatchResult {
  /// Detailed metrics for the batch operation
  final BatchMetrics metrics;

  /// Error analysis if there were failures
  final BatchErrorAnalysis? errorAnalysis;

  /// Partial failure recovery information
  final PartialFailureRecovery? recoveryInfo;

  /// Performance recommendations based on the results
  final List<String> recommendations;

  const DetailedBatchResult({
    required super.totalRequests,
    required super.successfulRequests,
    required super.failedRequests,
    required super.results,
    required super.totalProcessingTime,
    required super.averageProcessingTime,
    required super.errors,
    required this.metrics,
    this.errorAnalysis,
    this.recoveryInfo,
    required this.recommendations,
  });

  /// Creates a detailed result from a basic batch result
  factory DetailedBatchResult.fromBatchResult(
    BatchResult batchResult,
    List<TTSRequest> originalRequests, {
    List<TTSResult>? retryResults,
  }) {
    final aggregator = ResultCollector();
    return aggregator.createResult(
      batchResult,
      originalRequests,
      retryResults: retryResults,
    );
  }

  @override
  Map<String, dynamic> toMap({bool includeResults = true}) {
    final baseMap = super.toMap(includeResults: includeResults);
    return {
      ...baseMap,
      'metrics': metrics.toMap(),
      'errorAnalysis': errorAnalysis?.toMap(),
      'recoveryInfo': recoveryInfo?.toMap(),
      'recommendations': recommendations,
    };
  }
}

/// Information about partial failure recovery
@immutable
class PartialFailureRecovery {
  /// Number of requests that were recovered through retries
  final int recoveredRequests;

  /// Number of requests that remained failed after all recovery attempts
  final int permanentFailures;

  /// Recovery strategies that were applied
  final List<String> appliedStrategies;

  /// Time spent on recovery operations
  final Duration recoveryTime;

  /// Success rate of recovery operations (0-100)
  final double recoverySuccessRate;

  const PartialFailureRecovery({
    required this.recoveredRequests,
    required this.permanentFailures,
    required this.appliedStrategies,
    required this.recoveryTime,
    required this.recoverySuccessRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'recoveredRequests': recoveredRequests,
      'permanentFailures': permanentFailures,
      'appliedStrategies': appliedStrategies,
      'recoveryTimeMs': recoveryTime.inMilliseconds,
      'recoverySuccessRate': recoverySuccessRate,
    };
  }
}

/// Collects and analyzes batch processing results
class ResultCollector {
  /// Creates a detailed batch result with enhanced analysis
  DetailedBatchResult createResult(
    BatchResult batchResult,
    List<TTSRequest> originalRequests, {
    List<TTSResult>? retryResults,
  }) {
    final metrics = _calculateMetrics(batchResult, originalRequests);
    final errorAnalysis = _analyzeErrors(batchResult, originalRequests);
    final recoveryInfo = _analyzeRecovery(batchResult, retryResults);
    final recommendations = _generateRecommendations(
      batchResult,
      metrics,
      errorAnalysis,
    );

    return DetailedBatchResult(
      totalRequests: batchResult.totalRequests,
      successfulRequests: batchResult.successfulRequests,
      failedRequests: batchResult.failedRequests,
      results: batchResult.results,
      totalProcessingTime: batchResult.totalProcessingTime,
      averageProcessingTime: batchResult.averageProcessingTime,
      errors: batchResult.errors,
      metrics: metrics,
      errorAnalysis: errorAnalysis,
      recoveryInfo: recoveryInfo,
      recommendations: recommendations,
    );
  }

  /// Calculates detailed metrics for the batch operation
  BatchMetrics _calculateMetrics(
    BatchResult batchResult,
    List<TTSRequest> originalRequests,
  ) {
    if (batchResult.results.isEmpty) {
      return const BatchMetrics(
        totalProcessingTime: Duration.zero,
        averageProcessingTime: Duration.zero,
        minProcessingTime: Duration.zero,
        maxProcessingTime: Duration.zero,
        processingTimeStdDev: Duration.zero,
        throughput: 0.0,
        totalAudioSize: 0,
        averageAudioSize: 0.0,
        memoryEfficiency: 0.0,
        successRate: 0.0,
        errorRate: 0.0,
        totalRetries: 0,
        retrySuccessRate: 0.0,
      );
    }

    final processingTimes = batchResult.results
        .map((r) => r.processingTime.inMilliseconds)
        .toList();

    final minTime = Duration(milliseconds: processingTimes.reduce(min));
    final maxTime = Duration(milliseconds: processingTimes.reduce(max));

    // Calculate standard deviation
    final mean =
        processingTimes.reduce((a, b) => a + b) / processingTimes.length;
    final variance = processingTimes
            .map((time) => pow(time - mean, 2))
            .reduce((a, b) => a + b) /
        processingTimes.length;
    final stdDev = Duration(milliseconds: sqrt(variance).round());

    // Calculate throughput
    final throughput = batchResult.totalProcessingTime.inMilliseconds > 0
        ? (batchResult.totalRequests * 1000.0) /
            batchResult.totalProcessingTime.inMilliseconds
        : 0.0;

    // Calculate audio metrics
    final successfulResults = batchResult.results.where((r) => r.success);
    final totalAudioSize = successfulResults
        .where((r) => r.audioData != null)
        .fold<int>(0, (sum, r) => sum + r.audioData!.length);

    final averageAudioSize = successfulResults.isNotEmpty
        ? totalAudioSize / successfulResults.length
        : 0.0;

    // Calculate memory efficiency (bytes per millisecond)
    final memoryEfficiency = batchResult.totalProcessingTime.inMilliseconds > 0
        ? totalAudioSize / batchResult.totalProcessingTime.inMilliseconds
        : 0.0;

    return BatchMetrics(
      totalProcessingTime: batchResult.totalProcessingTime,
      averageProcessingTime: batchResult.averageProcessingTime,
      minProcessingTime: minTime,
      maxProcessingTime: maxTime,
      processingTimeStdDev: stdDev,
      throughput: throughput,
      totalAudioSize: totalAudioSize,
      averageAudioSize: averageAudioSize,
      memoryEfficiency: memoryEfficiency,
      successRate: batchResult.successRate,
      errorRate: batchResult.failureRate,
      mostCommonError: _findMostCommonError(batchResult.errors),
      totalRetries: 0, // This would be tracked by the batch engine
      retrySuccessRate: 0.0, // This would be calculated from retry results
    );
  }

  /// Analyzes errors in the batch operation
  BatchErrorAnalysis? _analyzeErrors(
    BatchResult batchResult,
    List<TTSRequest> originalRequests,
  ) {
    if (batchResult.errors.isEmpty) {
      return null;
    }

    // Group errors by type
    final errorsByType = <String, List<BatchError>>{};
    final errorsByRequestId = <String, BatchError>{};

    for (final error in batchResult.errors) {
      final errorType = _categorizeError(error.error);
      errorsByType.putIfAbsent(errorType, () => []);
      errorsByType[errorType]!.add(error);
      errorsByRequestId[error.requestId] = error;
    }

    // Calculate error frequencies
    final totalErrors = batchResult.errors.length;
    final errorFrequencies = errorsByType.entries
        .map((entry) => ErrorFrequency(
              errorType: entry.key,
              count: entry.value.length,
              percentage: (entry.value.length / totalErrors) * 100,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Calculate average time to failure
    final failureTimes =
        batchResult.errors.map((e) => e.processingTime.inMilliseconds).toList();
    final averageTimeToFailure = failureTimes.isNotEmpty
        ? Duration(
            milliseconds:
                (failureTimes.reduce((a, b) => a + b) / failureTimes.length)
                    .round())
        : Duration.zero;

    // Detect failure patterns
    final failurePatterns =
        _detectFailurePatterns(batchResult.errors, originalRequests);

    return BatchErrorAnalysis(
      errorsByType: errorsByType,
      errorsByRequestId: errorsByRequestId,
      errorFrequencies: errorFrequencies,
      permanentFailures: batchResult.errors.map((e) => e.requestId).toList(),
      recoveredRequests: [], // Would be populated from retry results
      averageTimeToFailure: averageTimeToFailure,
      failurePatterns: failurePatterns,
    );
  }

  /// Analyzes recovery information from retry results
  PartialFailureRecovery? _analyzeRecovery(
    BatchResult batchResult,
    List<TTSResult>? retryResults,
  ) {
    if (retryResults == null || retryResults.isEmpty) {
      return null;
    }

    final recoveredCount = retryResults.where((r) => r.success).length;
    final permanentFailures = retryResults.where((r) => !r.success).length;

    final recoverySuccessRate = retryResults.isNotEmpty
        ? (recoveredCount / retryResults.length) * 100
        : 0.0;

    final recoveryTime = retryResults.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.processingTime,
    );

    return PartialFailureRecovery(
      recoveredRequests: recoveredCount,
      permanentFailures: permanentFailures,
      appliedStrategies: [
        'retry_with_backoff',
        'fallback_voice'
      ], // Example strategies
      recoveryTime: recoveryTime,
      recoverySuccessRate: recoverySuccessRate,
    );
  }

  /// Generates performance recommendations based on results
  List<String> _generateRecommendations(
    BatchResult batchResult,
    BatchMetrics metrics,
    BatchErrorAnalysis? errorAnalysis,
  ) {
    final recommendations = <String>[];

    // Performance recommendations
    if (metrics.throughput < 1.0) {
      recommendations
          .add('Consider increasing concurrency to improve throughput');
    }

    if (metrics.processingTimeStdDev.inMilliseconds >
        metrics.averageProcessingTime.inMilliseconds) {
      recommendations.add(
          'High variance in processing times - consider request batching by size');
    }

    if (metrics.memoryEfficiency < 1000) {
      recommendations.add(
          'Low memory efficiency - consider optimizing audio format or compression');
    }

    // Error-based recommendations
    if (errorAnalysis != null) {
      if (errorAnalysis.mostCommonErrorType?.contains('timeout') == true) {
        recommendations.add(
            'Frequent timeouts detected - consider increasing timeout duration');
      }

      if (errorAnalysis.mostCommonErrorType?.contains('network') == true) {
        recommendations.add(
            'Network issues detected - implement retry with exponential backoff');
      }

      if (errorAnalysis.uniqueErrorTypes > 3) {
        recommendations.add(
            'Multiple error types detected - review input validation and error handling');
      }
    }

    // Success rate recommendations
    if (batchResult.successRate < 90) {
      recommendations.add(
          'Low success rate - review error patterns and implement better error recovery');
    } else if (batchResult.successRate > 99) {
      recommendations
          .add('Excellent success rate - current configuration is optimal');
    }

    return recommendations;
  }

  /// Categorizes an error message into a type
  String _categorizeError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('timeout')) return 'timeout';
    if (lowerError.contains('network') || lowerError.contains('connection'))
      return 'network';
    if (lowerError.contains('voice') || lowerError.contains('not found'))
      return 'voice_not_found';
    if (lowerError.contains('permission') || lowerError.contains('access'))
      return 'permission';
    if (lowerError.contains('memory') || lowerError.contains('out of'))
      return 'memory';
    if (lowerError.contains('format') || lowerError.contains('invalid'))
      return 'format';
    if (lowerError.contains('synthesis') || lowerError.contains('tts'))
      return 'synthesis';

    return 'unknown';
  }

  /// Finds the most common error message
  String? _findMostCommonError(List<BatchError> errors) {
    if (errors.isEmpty) return null;

    final errorCounts = <String, int>{};
    for (final error in errors) {
      final errorType = _categorizeError(error.error);
      errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
    }

    return errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Detects failure patterns in the batch results
  List<FailurePattern> _detectFailurePatterns(
    List<BatchError> errors,
    List<TTSRequest> originalRequests,
  ) {
    final patterns = <FailurePattern>[];

    // Pattern 1: Consecutive failures (might indicate system issue)
    final consecutiveFailures =
        _findConsecutiveFailures(errors, originalRequests);
    if (consecutiveFailures.isNotEmpty) {
      patterns.add(FailurePattern(
        patternType: 'consecutive_failures',
        description:
            'Multiple consecutive requests failed, indicating possible system issue',
        affectedRequestIds: consecutiveFailures,
        confidence: 0.8,
      ));
    }

    // Pattern 2: Large text failures (might indicate size limits)
    final largeTextFailures = _findLargeTextFailures(errors, originalRequests);
    if (largeTextFailures.isNotEmpty) {
      patterns.add(FailurePattern(
        patternType: 'large_text_failures',
        description:
            'Requests with large text content failed, consider text chunking',
        affectedRequestIds: largeTextFailures,
        confidence: 0.9,
      ));
    }

    // Pattern 3: Same configuration failures
    final configFailures = _findConfigurationFailures(errors, originalRequests);
    if (configFailures.isNotEmpty) {
      patterns.add(FailurePattern(
        patternType: 'configuration_failures',
        description:
            'Requests with specific configuration failed, review settings',
        affectedRequestIds: configFailures,
        confidence: 0.7,
      ));
    }

    return patterns;
  }

  /// Finds consecutive failures that might indicate system issues
  List<String> _findConsecutiveFailures(
    List<BatchError> errors,
    List<TTSRequest> originalRequests,
  ) {
    // This is a simplified implementation
    // In a real scenario, you'd analyze the temporal order of failures
    if (errors.length >= 3) {
      return errors.take(3).map((e) => e.requestId).toList();
    }
    return [];
  }

  /// Finds failures related to large text content
  List<String> _findLargeTextFailures(
    List<BatchError> errors,
    List<TTSRequest> originalRequests,
  ) {
    final largeTextThreshold = 1000; // characters
    final largeTextFailures = <String>[];

    for (final error in errors) {
      final request = originalRequests.firstWhere(
        (r) => r.id == error.requestId,
        orElse: () => const TTSRequest(id: '', text: ''),
      );

      if (request.text.length > largeTextThreshold) {
        largeTextFailures.add(error.requestId);
      }
    }

    return largeTextFailures;
  }

  /// Finds failures related to specific configurations
  List<String> _findConfigurationFailures(
    List<BatchError> errors,
    List<TTSRequest> originalRequests,
  ) {
    // Group errors by configuration and find patterns
    final configGroups = <String, List<String>>{};

    for (final error in errors) {
      final request = originalRequests.firstWhere(
        (r) => r.id == error.requestId,
        orElse: () => const TTSRequest(id: '', text: ''),
      );

      final configKey = request.config?.toString() ?? 'default';
      configGroups.putIfAbsent(configKey, () => []);
      configGroups[configKey]!.add(error.requestId);
    }

    // Return the largest group if it has multiple failures
    final largestGroup = configGroups.values
        .where((group) => group.length > 1)
        .fold<List<String>>([],
            (prev, current) => current.length > prev.length ? current : prev);

    return largestGroup;
  }
}
