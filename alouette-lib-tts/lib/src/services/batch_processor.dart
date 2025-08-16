import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/batch_processor.dart';
import '../models/alouette_voice.dart';
import '../interfaces/i_tts_service.dart';
import '../exceptions/tts_exception.dart';

/// Callback for batch progress updates
typedef BatchProgressCallback = void Function(BatchProgressUpdate update);

/// Callback for batch cancellation checks
typedef BatchCancellationCallback = bool Function();

/// Progress update information for batch processing
@immutable
class BatchProgressUpdate {
  final int totalRequests;
  final int completedRequests;
  final int successfulRequests;
  final int failedRequests;
  final double progress;
  final Duration elapsedTime;
  final Duration estimatedTimeRemaining;
  final String? currentRequestId;

  const BatchProgressUpdate({
    required this.totalRequests,
    required this.completedRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.progress,
    required this.elapsedTime,
    required this.estimatedTimeRemaining,
    this.currentRequestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'completedRequests': completedRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'progress': progress,
      'elapsedTimeMs': elapsedTime.inMilliseconds,
      'estimatedTimeRemainingMs': estimatedTimeRemaining.inMilliseconds,
      'currentRequestId': currentRequestId,
    };
  }
}

/// Configuration for batch processing
@immutable
class BatchProcessingConfig {
  /// Maximum number of concurrent requests
  final int maxConcurrency;

  /// Maximum memory usage in bytes (0 = no limit)
  final int maxMemoryUsage;

  /// Timeout for individual requests
  final Duration requestTimeout;

  /// Whether to continue processing after failures
  final bool continueOnFailure;

  /// Whether to retry failed requests
  final bool retryFailedRequests;

  /// Maximum number of retries per request
  final int maxRetries;

  /// Delay between retries
  final Duration retryDelay;

  /// Whether to sort requests by priority (shorter texts first)
  final bool sortByPriority;

  /// Whether to group requests by configuration
  final bool groupByConfiguration;

  const BatchProcessingConfig({
    this.maxConcurrency = 3,
    this.maxMemoryUsage = 100 * 1024 * 1024, // 100MB
    this.requestTimeout = const Duration(seconds: 30),
    this.continueOnFailure = true,
    this.retryFailedRequests = true,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
    this.sortByPriority = true,
    this.groupByConfiguration = true,
  });

  BatchProcessingConfig copyWith({
    int? maxConcurrency,
    int? maxMemoryUsage,
    Duration? requestTimeout,
    bool? continueOnFailure,
    bool? retryFailedRequests,
    int? maxRetries,
    Duration? retryDelay,
    bool? sortByPriority,
    bool? groupByConfiguration,
  }) {
    return BatchProcessingConfig(
      maxConcurrency: maxConcurrency ?? this.maxConcurrency,
      maxMemoryUsage: maxMemoryUsage ?? this.maxMemoryUsage,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      continueOnFailure: continueOnFailure ?? this.continueOnFailure,
      retryFailedRequests: retryFailedRequests ?? this.retryFailedRequests,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      sortByPriority: sortByPriority ?? this.sortByPriority,
      groupByConfiguration: groupByConfiguration ?? this.groupByConfiguration,
    );
  }
}

/// Batch engine for TTS operations
class BatchEngine {
  final ITTSService _ttsService;
  final BatchProcessor _batchProcessor;
  final BatchProcessingConfig _config;

  /// Current batch operation cancellation token
  Completer<void>? _cancellationToken;

  /// Current memory usage tracking
  int _currentMemoryUsage = 0;

  /// Progress tracker for current batch
  BatchProgressTracker? _progressTracker;

  /// Timer for progress updates
  Timer? _progressTimer;

  BatchEngine(
    this._ttsService, {
    BatchProcessingConfig? config,
  })  : _batchProcessor = const BatchProcessor(),
        _config = config ?? const BatchProcessingConfig();  /// Processes a batch of TTS requests with progress tracking and cancellation support
  Future<List<TTSResult>> processBatch(
    List<TTSRequest> requests, {
    BatchProgressCallback? onProgress,
    BatchCancellationCallback? shouldCancel,
  }) async {
    if (requests.isEmpty) {
      return [];
    }

    // Validate the batch
    final validationResult = _batchProcessor.validateBatch(requests);
    if (!validationResult.isValid) {
      throw TTSException(
        'Batch validation failed: ${validationResult.summary}',
      );
    }

    // Initialize progress tracking
    _progressTracker = _batchProcessor.createProgressTracker(requests.length);
    final startTime = DateTime.now();

    // Setup cancellation token
    _cancellationToken = Completer<void>();

    // Setup progress timer if callback provided
    if (onProgress != null) {
      _setupProgressTimer(onProgress, startTime);
    }

    try {
      // Preprocess requests
      var processedRequests = _preprocessRequests(requests);

      // Process in chunks to manage memory
      final results = <TTSResult>[];
      final chunks = _batchProcessor.chunkBatch(
        processedRequests,
        maxChunkSize: _config.maxConcurrency * 2,
      );

      for (final chunk in chunks) {
        // Check for cancellation
        if (shouldCancel?.call() == true || _cancellationToken!.isCompleted) {
          break;
        }

        // Process chunk with concurrency control
        final chunkResults = await _processChunkWithConcurrency(
          chunk,
          shouldCancel: shouldCancel,
        );

        results.addAll(chunkResults);

        // Memory management - cleanup if needed
        await _manageMemory();
      }

      // Handle any remaining failed requests with retries
      if (_config.retryFailedRequests) {
        final failedResults = results.where((r) => !r.success).toList();
        if (failedResults.isNotEmpty) {
          final retryResults = await _retryFailedRequests(
            failedResults,
            requests,
            shouldCancel: shouldCancel,
          );

          // Replace failed results with retry results
          for (final retryResult in retryResults) {
            final index =
                results.indexWhere((r) => r.requestId == retryResult.requestId);
            if (index >= 0) {
              results[index] = retryResult;
            }
          }
        }
      }

      // Send final progress update if callback provided
      if (onProgress != null && _progressTracker != null) {
        final finalUpdate = BatchProgressUpdate(
          totalRequests: _progressTracker!.totalRequests,
          completedRequests: _progressTracker!.completedRequests,
          successfulRequests: _progressTracker!.successfulRequests,
          failedRequests: _progressTracker!.failedRequests,
          progress: _progressTracker!.progress,
          elapsedTime: DateTime.now().difference(startTime),
          estimatedTimeRemaining: Duration.zero,
        );
        onProgress(finalUpdate);
      }

      return results;
    } catch (e) {
      throw TTSException(
        'Batch processing failed: $e',
        originalError: e,
      );
    } finally {
      // Cleanup
      _progressTimer?.cancel();
      _progressTimer = null;
      _progressTracker = null;
      _cancellationToken = null;
      _currentMemoryUsage = 0;
    }
  }

  /// Cancels the current batch processing operation
  void cancelBatch() {
    _cancellationToken?.complete();
  }

  /// Estimates processing time for a batch
  Duration estimateBatchProcessingTime(List<TTSRequest> requests) {
    return _batchProcessor.estimateProcessingTime(
      requests,
      concurrency: _config.maxConcurrency,
    );
  }

  /// Gets current memory usage in bytes
  int get currentMemoryUsage => _currentMemoryUsage;

  /// Gets current progress (0.0 to 1.0)
  double get currentProgress => _progressTracker?.progress ?? 0.0;

  /// Preprocesses requests for optimal processing
  List<TTSRequest> _preprocessRequests(List<TTSRequest> requests) {
    var processed = List<TTSRequest>.from(requests);

    // Sort by priority if enabled
    if (_config.sortByPriority) {
      processed = _batchProcessor.sortByPriority(processed);
    }

    return processed;
  }

  /// Processes a chunk of requests with concurrency control
  Future<List<TTSResult>> _processChunkWithConcurrency(
    List<TTSRequest> chunk, {
    BatchCancellationCallback? shouldCancel,
  }) async {
    final results = <TTSResult>[];
    final semaphore = Semaphore(_config.maxConcurrency);

    // Group by configuration if enabled
    Map<String, List<TTSRequest>> groups;
    if (_config.groupByConfiguration) {
      groups = _batchProcessor.groupByConfiguration(chunk);
    } else {
      groups = {'default': chunk};
    }

    // Process each group
    final futures = <Future<TTSResult?>>[];

    for (final group in groups.values) {
      for (final request in group) {
        final future = semaphore.acquire().then((_) async {
          try {
            // Check for cancellation
            if (shouldCancel?.call() == true ||
                _cancellationToken!.isCompleted) {
              return null;
            }

            final result = await _processSingleRequest(request);

            // Update progress
            if (result.success) {
              _progressTracker?.recordSuccess();
            } else {
              _progressTracker?.recordFailure();
            }

            return result;
          } finally {
            semaphore.release();
          }
        });

        futures.add(future);
      }
    }

    // Wait for all requests to complete and collect non-null results
    final completedResults = await Future.wait(futures);
    results.addAll(completedResults.where((r) => r != null).cast<TTSResult>());

    return results;
  }

  /// Processes a single TTS request with timeout and error handling
  Future<TTSResult> _processSingleRequest(TTSRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Apply request-specific configuration if provided
      if (request.config != null) {
        await _ttsService.updateConfig(request.config!);
      }

      // Process with timeout
      final audioData = await Future.any([
        _synthesizeRequest(request),
        Future.delayed(_config.requestTimeout).then((_) =>
            throw TimeoutException('Request timeout', _config.requestTimeout)),
      ]);

      stopwatch.stop();

      // Update memory usage
      _currentMemoryUsage += audioData.length;

      // Save to file if requested
      String? filePath;
      if (request.outputPath != null) {
        await _ttsService.saveAudioToFile(audioData, request.outputPath!);
        filePath = request.outputPath;
      }

      return TTSResult.success(
        requestId: request.id,
        processingTime: stopwatch.elapsed,
        audioData: audioData,
        filePath: filePath,
        usedVoice: await _getCurrentVoice(),
      );
    } catch (e) {
      stopwatch.stop();

      return TTSResult.failure(
        requestId: request.id,
        error: e.toString(),
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// Synthesizes audio for a request
  Future<Uint8List> _synthesizeRequest(TTSRequest request) async {
    if (request.isSSML) {
      return await _ttsService.synthesizeToAudio(request.text);
    } else {
      return await _ttsService.synthesizeToAudio(request.text);
    }
  }

  /// Gets the currently configured voice
  Future<AlouetteVoice?> _getCurrentVoice() async {
    try {
      final voices = await _ttsService.getAvailableVoices();
      final config = _ttsService.currentConfig;

      if (config.voiceName != null) {
        try {
          return voices.firstWhere((v) => v.name == config.voiceName);
        } catch (e) {
          // Voice not found, fall through to default
        }
      }

      return voices.isNotEmpty ? voices.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Retries failed requests
  Future<List<TTSResult>> _retryFailedRequests(
    List<TTSResult> failedResults,
    List<TTSRequest> originalRequests, {
    BatchCancellationCallback? shouldCancel,
  }) async {
    final retryResults = <TTSResult>[];

    for (final failedResult in failedResults) {
      // Check for cancellation
      if (shouldCancel?.call() == true || _cancellationToken!.isCompleted) {
        break;
      }

      final originalRequest = originalRequests.firstWhere(
        (r) => r.id == failedResult.requestId,
      );

      TTSResult? retryResult;
      for (int attempt = 1; attempt <= _config.maxRetries; attempt++) {
        try {
          // Wait before retry
          await Future.delayed(_config.retryDelay);

          // Check for cancellation again
          if (shouldCancel?.call() == true || _cancellationToken!.isCompleted) {
            break;
          }

          retryResult = await _processSingleRequest(originalRequest);

          if (retryResult.success) {
            break; // Success, no need to retry further
          }
        } catch (e) {
          // Continue to next retry attempt
        }
      }

      retryResults.add(retryResult ?? failedResult);
    }

    return retryResults;
  }

  /// Manages memory usage during batch processing
  Future<void> _manageMemory() async {
    if (_config.maxMemoryUsage > 0 &&
        _currentMemoryUsage > _config.maxMemoryUsage) {
      // Force garbage collection
      await Future.delayed(const Duration(milliseconds: 100));

      // Reset memory counter (in a real implementation, you might want more sophisticated tracking)
      _currentMemoryUsage = (_currentMemoryUsage * 0.7).round();
    }
  }

  /// Sets up progress timer for regular updates
  void _setupProgressTimer(
      BatchProgressCallback onProgress, DateTime startTime) {
    // Send initial progress update
    if (_progressTracker != null) {
      final initialUpdate = BatchProgressUpdate(
        totalRequests: _progressTracker!.totalRequests,
        completedRequests: 0,
        successfulRequests: 0,
        failedRequests: 0,
        progress: 0.0,
        elapsedTime: Duration.zero,
        estimatedTimeRemaining: Duration.zero,
      );
      onProgress(initialUpdate);
    }

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_progressTracker != null) {
        final elapsedTime = DateTime.now().difference(startTime);

        final update = BatchProgressUpdate(
          totalRequests: _progressTracker!.totalRequests,
          completedRequests: _progressTracker!.completedRequests,
          successfulRequests: _progressTracker!.successfulRequests,
          failedRequests: _progressTracker!.failedRequests,
          progress: _progressTracker!.progress,
          elapsedTime: elapsedTime,
          estimatedTimeRemaining: _progressTracker!.estimatedTimeRemaining,
        );

        onProgress(update);

        // Stop timer when complete
        if (_progressTracker!.isComplete) {
          timer.cancel();
        }
      }
    });
  }
}

/// Simple semaphore implementation for concurrency control
class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

/// Timeout exception for batch processing
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() =>
      'TimeoutException: $message (timeout: ${timeout.inMilliseconds}ms)';
}
