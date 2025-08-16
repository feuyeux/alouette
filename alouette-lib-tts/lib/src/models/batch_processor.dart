import 'dart:math';
import 'package:meta/meta.dart';
import 'tts_request.dart';
import 'tts_result.dart';

/// Batch processing utilities for TTS operations
@immutable
class BatchProcessor {
  const BatchProcessor();

  /// Validates a batch of TTS requests
  BatchValidationResult validateBatch(List<TTSRequest> requests) {
    final errors = <String>[];
    final duplicateIds = <String>[];
    final seenIds = <String>{};

    if (requests.isEmpty) {
      errors.add('Batch cannot be empty');
    }

    for (int i = 0; i < requests.length; i++) {
      final request = requests[i];

      // Check for duplicate IDs
      if (seenIds.contains(request.id)) {
        duplicateIds.add(request.id);
      } else {
        seenIds.add(request.id);
      }

      // Validate individual request
      if (!request.isValid()) {
        errors.add('Request at index $i (id: ${request.id}) is invalid');
      }

      // Check text length
      if (request.text.length > 5000) {
        errors.add(
            'Request ${request.id} text exceeds maximum length (5000 characters)');
      }
    }

    return BatchValidationResult(
      isValid: errors.isEmpty && duplicateIds.isEmpty,
      errors: errors,
      duplicateIds: duplicateIds,
      requestCount: requests.length,
    );
  }

  /// Splits a large batch into smaller chunks for processing
  List<List<TTSRequest>> chunkBatch(
    List<TTSRequest> requests, {
    int maxChunkSize = 10,
  }) {
    if (requests.isEmpty) return [];

    final chunks = <List<TTSRequest>>[];
    for (int i = 0; i < requests.length; i += maxChunkSize) {
      final end = min(i + maxChunkSize, requests.length);
      chunks.add(requests.sublist(i, end));
    }

    return chunks;
  }

  /// Aggregates results from batch processing
  BatchResult aggregateResults(List<TTSResult> results) {
    if (results.isEmpty) {
      return BatchResult(
        totalRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        results: [],
        totalProcessingTime: Duration.zero,
        averageProcessingTime: Duration.zero,
        errors: [],
      );
    }

    final successful = results.where((r) => r.success).length;
    final failed = results.length - successful;
    final totalTime = results.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.processingTime,
    );
    final averageTime = Duration(
      milliseconds: totalTime.inMilliseconds ~/ results.length,
    );

    final errors = results
        .where((r) => !r.success && r.error != null)
        .map((r) => BatchError(
              requestId: r.requestId,
              error: r.error!,
              processingTime: r.processingTime,
            ))
        .toList();

    return BatchResult(
      totalRequests: results.length,
      successfulRequests: successful,
      failedRequests: failed,
      results: results,
      totalProcessingTime: totalTime,
      averageProcessingTime: averageTime,
      errors: errors,
    );
  }

  /// Creates a progress tracker for batch operations
  BatchProgressTracker createProgressTracker(int totalRequests) {
    return BatchProgressTracker(totalRequests);
  }

  /// Estimates processing time for a batch
  Duration estimateProcessingTime(
    List<TTSRequest> requests, {
    Duration averageTimePerRequest = const Duration(milliseconds: 500),
    int concurrency = 1,
  }) {
    if (requests.isEmpty) return Duration.zero;

    final totalCharacters = requests.fold<int>(
      0,
      (sum, request) => sum + request.text.length,
    );

    // Estimate based on character count (roughly 10ms per character)
    final characterBasedTime = Duration(milliseconds: totalCharacters * 10);

    // Use the higher of character-based or request-based estimate
    final requestBasedTime = Duration(
      milliseconds: (requests.length * averageTimePerRequest.inMilliseconds) ~/
          concurrency,
    );

    return characterBasedTime > requestBasedTime
        ? characterBasedTime
        : requestBasedTime;
  }

  /// Sorts requests by priority (shorter texts first for better user experience)
  List<TTSRequest> sortByPriority(List<TTSRequest> requests) {
    final sorted = List<TTSRequest>.from(requests);
    sorted.sort((a, b) => a.text.length.compareTo(b.text.length));
    return sorted;
  }

  /// Groups requests by configuration for optimized processing
  Map<String, List<TTSRequest>> groupByConfiguration(
      List<TTSRequest> requests) {
    final groups = <String, List<TTSRequest>>{};

    for (final request in requests) {
      final configKey = _getConfigurationKey(request);
      groups.putIfAbsent(configKey, () => <TTSRequest>[]);
      groups[configKey]!.add(request);
    }

    return groups;
  }

  /// Generates a configuration key for grouping
  String _getConfigurationKey(TTSRequest request) {
    if (request.config == null) return 'default';

    final config = request.config!;
    return '${config.languageCode}_${config.voiceName ?? 'default'}_${config.audioFormat.name}';
  }
}

/// Result of batch validation
@immutable
class BatchValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> duplicateIds;
  final int requestCount;

  const BatchValidationResult({
    required this.isValid,
    required this.errors,
    required this.duplicateIds,
    required this.requestCount,
  });

  /// Returns a summary of validation issues
  String get summary {
    if (isValid) return 'Batch is valid ($requestCount requests)';

    final issues = <String>[];
    if (errors.isNotEmpty) {
      issues.add('${errors.length} validation errors');
    }
    if (duplicateIds.isNotEmpty) {
      issues.add('${duplicateIds.length} duplicate IDs');
    }

    return 'Batch validation failed: ${issues.join(', ')}';
  }
}

/// Aggregated results from batch processing
@immutable
class BatchResult {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final List<TTSResult> results;
  final Duration totalProcessingTime;
  final Duration averageProcessingTime;
  final List<BatchError> errors;

  const BatchResult({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.results,
    required this.totalProcessingTime,
    required this.averageProcessingTime,
    required this.errors,
  });

  /// Success rate as a percentage
  double get successRate {
    if (totalRequests == 0) return 0.0;
    return (successfulRequests / totalRequests) * 100;
  }

  /// Failure rate as a percentage
  double get failureRate => 100.0 - successRate;

  /// Whether the batch was completely successful
  bool get isCompletelySuccessful => failedRequests == 0;

  /// Whether the batch had partial success
  bool get hasPartialSuccess => successfulRequests > 0 && failedRequests > 0;

  /// Total audio data size in bytes
  int get totalAudioSize {
    return results
        .where((r) => r.success && r.audioData != null)
        .fold<int>(0, (sum, result) => sum + result.audioData!.length);
  }

  /// Gets successful results only
  List<TTSResult> get successfulResults {
    return results.where((r) => r.success).toList();
  }

  /// Gets failed results only
  List<TTSResult> get failedResults {
    return results.where((r) => !r.success).toList();
  }

  /// Returns a summary string
  String get summary {
    return 'Batch completed: $successfulRequests/$totalRequests successful '
        '(${successRate.toStringAsFixed(1)}%) in ${totalProcessingTime.inMilliseconds}ms';
  }

  /// Converts to a Map for serialization
  Map<String, dynamic> toMap({bool includeResults = true}) {
    return {
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'successRate': successRate,
      'totalProcessingTimeMs': totalProcessingTime.inMilliseconds,
      'averageProcessingTimeMs': averageProcessingTime.inMilliseconds,
      'totalAudioSize': totalAudioSize,
      'errors': errors.map((e) => e.toMap()).toList(),
      if (includeResults) 'results': results.map((r) => r.toMap()).toList(),
    };
  }
}

/// Error information for batch processing
@immutable
class BatchError {
  final String requestId;
  final String error;
  final Duration processingTime;

  const BatchError({
    required this.requestId,
    required this.error,
    required this.processingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'error': error,
      'processingTimeMs': processingTime.inMilliseconds,
    };
  }

  @override
  String toString() {
    return 'BatchError(requestId: $requestId, error: $error)';
  }
}

/// Progress tracker for batch operations
class BatchProgressTracker {
  final int totalRequests;
  int _completedRequests = 0;
  int _failedRequests = 0;
  final DateTime _startTime = DateTime.now();

  BatchProgressTracker(this.totalRequests);

  /// Current progress as a percentage (0.0 to 1.0)
  double get progress {
    if (totalRequests == 0) return 1.0;
    return _completedRequests / totalRequests;
  }

  /// Progress as a percentage (0 to 100)
  double get progressPercentage => progress * 100;

  /// Number of completed requests
  int get completedRequests => _completedRequests;

  /// Number of failed requests
  int get failedRequests => _failedRequests;

  /// Number of successful requests
  int get successfulRequests => _completedRequests - _failedRequests;

  /// Number of remaining requests
  int get remainingRequests => totalRequests - _completedRequests;

  /// Elapsed time since start
  Duration get elapsedTime => DateTime.now().difference(_startTime);

  /// Estimated time remaining
  Duration get estimatedTimeRemaining {
    if (_completedRequests == 0) return Duration.zero;

    final averageTimePerRequest =
        elapsedTime.inMilliseconds / _completedRequests;
    final remainingMs = (remainingRequests * averageTimePerRequest).round();

    return Duration(milliseconds: remainingMs);
  }

  /// Whether the batch is complete
  bool get isComplete => _completedRequests >= totalRequests;

  /// Records a successful request completion
  void recordSuccess() {
    if (!isComplete) {
      _completedRequests++;
    }
  }

  /// Records a failed request completion
  void recordFailure() {
    if (!isComplete) {
      _completedRequests++;
      _failedRequests++;
    }
  }

  /// Returns a progress summary string
  String get summary {
    return 'Progress: $_completedRequests/$totalRequests '
        '(${progressPercentage.toStringAsFixed(1)}%) - '
        'ETA: ${estimatedTimeRemaining.inSeconds}s';
  }

  /// Converts to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'completedRequests': completedRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'remainingRequests': remainingRequests,
      'progress': progress,
      'progressPercentage': progressPercentage,
      'elapsedTimeMs': elapsedTime.inMilliseconds,
      'estimatedTimeRemainingMs': estimatedTimeRemaining.inMilliseconds,
      'isComplete': isComplete,
    };
  }
}
