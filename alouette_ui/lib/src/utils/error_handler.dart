import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/core/logging_service.dart';
import '../services/core/service_locator.dart';

/// Centralized error handler for all Alouette applications
class AlouetteErrorHandler {
  static AlouetteErrorHandler? _instance;

  /// Get the singleton instance
  static AlouetteErrorHandler get instance {
    _instance ??= AlouetteErrorHandler._internal();
    return _instance!;
  }

  AlouetteErrorHandler._internal();

  /// List of error listeners
  final List<ErrorHandlerListener> _listeners = [];

  /// Error recovery strategies
  final Map<String, ErrorRecoveryStrategy> _recoveryStrategies = {};

  /// Initialize the error handler
  void initialize() {
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      handlePlatformError(error, stack);
      return true;
    };

    // Register default recovery strategies
    _registerDefaultRecoveryStrategies();

    final logger = ServiceLocator.logger;
    logger.info('AlouetteErrorHandler initialized', tag: 'ErrorHandler');
  }

  /// Handle Flutter framework errors
  void handleFlutterError(FlutterErrorDetails details) {
    final logger = ServiceLocator.logger;

    logger.error(
      'Flutter Error: ${details.exception}',
      tag: 'FlutterError',
      details: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
      error: details.exception,
      stackTrace: details.stack,
    );

    // Notify listeners
    _notifyListeners(
      AlouetteErrorEvent(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework',
        isRecoverable: false,
      ),
    );

    // Call original error handler for debugging
    FlutterError.presentError(details);
  }

  /// Handle platform errors (outside Flutter framework)
  void handlePlatformError(Object error, StackTrace stackTrace) {
    final logger = ServiceLocator.logger;

    logger.error(
      'Platform Error: $error',
      tag: 'PlatformError',
      error: error,
      stackTrace: stackTrace,
    );

    // Notify listeners
    _notifyListeners(
      AlouetteErrorEvent(
        error: error,
        stackTrace: stackTrace,
        context: 'Platform',
        isRecoverable: _isPlatformErrorRecoverable(error),
      ),
    );
  }

  /// Handle application errors with automatic recovery
  Future<T?> handleError<T>(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalDetails,
    Future<T> Function()? recoveryOperation,
    bool logError = true,
  }) async {
    if (logError) {
      final logger = ServiceLocator.logger;

      // Use Alouette error logging if available
      if (error.runtimeType.toString().contains('Alouette')) {
        logger.logAlouetteError(
          error,
          tag: context,
          additionalDetails: additionalDetails,
        );
      } else {
        logger.error(
          'Application Error: $error',
          tag: context ?? 'AppError',
          details: additionalDetails,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Determine if error is recoverable
    bool isRecoverable = false;
    String? errorCode;

    try {
      if (error.runtimeType.toString().contains('Alouette')) {
        final dynamic dynError = error;
        isRecoverable = dynError.isRecoverable ?? false;
        errorCode = dynError.code;
      } else {
        isRecoverable = _isGenericErrorRecoverable(error);
      }
    } catch (e) {
      // Fallback
      isRecoverable = false;
    }

    // Create error event
    final errorEvent = AlouetteErrorEvent(
      error: error,
      stackTrace: stackTrace,
      context: context,
      isRecoverable: isRecoverable,
      errorCode: errorCode,
      additionalDetails: additionalDetails,
    );

    // Notify listeners
    _notifyListeners(errorEvent);

    // Attempt recovery
    if (isRecoverable) {
      try {
        // Try custom recovery operation first
        if (recoveryOperation != null) {
          return await recoveryOperation();
        }

        // Try registered recovery strategy
        if (errorCode != null && _recoveryStrategies.containsKey(errorCode)) {
          final strategy = _recoveryStrategies[errorCode]!;
          return await strategy.recover<T>(error, context);
        }

        // Try generic recovery
        return await _attemptGenericRecovery<T>(error, context);
      } catch (recoveryError) {
        final logger = ServiceLocator.logger;
        logger.warning(
          'Error recovery failed: $recoveryError',
          tag: 'ErrorRecovery',
          error: recoveryError,
        );
      }
    }

    return null;
  }

  /// Register an error recovery strategy
  void registerRecoveryStrategy(
    String errorCode,
    ErrorRecoveryStrategy strategy,
  ) {
    _recoveryStrategies[errorCode] = strategy;

    final logger = ServiceLocator.logger;
    logger.debug(
      'Recovery strategy registered for error code: $errorCode',
      tag: 'ErrorHandler',
    );
  }

  /// Add an error listener
  void addListener(ErrorHandlerListener listener) {
    _listeners.add(listener);
  }

  /// Remove an error listener
  void removeListener(ErrorHandlerListener listener) {
    _listeners.remove(listener);
  }

  /// Get error statistics
  ErrorStatistics getStatistics() {
    final logger = ServiceLocator.logger;
    final recentLogs = logger.getRecentLogs(
      minLevel: LogLevel.error,
      limit: 100,
    );

    final errorCounts = <String, int>{};
    final recoverableCount = recentLogs
        .where((log) => log.details?['isRecoverable'] == true)
        .length;

    for (final log in recentLogs) {
      final errorCode = log.details?['errorCode'] as String?;
      if (errorCode != null) {
        errorCounts[errorCode] = (errorCounts[errorCode] ?? 0) + 1;
      }
    }

    return ErrorStatistics(
      totalErrors: recentLogs.length,
      recoverableErrors: recoverableCount,
      errorsByCode: errorCounts,
      lastErrorTime: recentLogs.isNotEmpty ? recentLogs.first.timestamp : null,
    );
  }

  void _registerDefaultRecoveryStrategies() {
    // Translation error recovery strategies
    registerRecoveryStrategy(
      'TRANS_CONNECTION_FAILED',
      RetryRecoveryStrategy(maxAttempts: 3),
    );
    registerRecoveryStrategy(
      'TRANS_REQUEST_TIMEOUT',
      RetryRecoveryStrategy(maxAttempts: 2),
    );
    registerRecoveryStrategy(
      'TRANS_RATE_LIMIT',
      DelayedRetryRecoveryStrategy(delay: Duration(seconds: 10)),
    );

    // TTS error recovery strategies
    registerRecoveryStrategy(
      'TTS_ENGINE_NOT_AVAILABLE',
      FallbackRecoveryStrategy(),
    );
    registerRecoveryStrategy(
      'TTS_SYNTHESIS_FAILURE',
      RetryRecoveryStrategy(maxAttempts: 2),
    );
    registerRecoveryStrategy('TTS_VOICE_NOT_FOUND', FallbackRecoveryStrategy());
  }

  void _notifyListeners(AlouetteErrorEvent event) {
    for (final listener in _listeners) {
      try {
        listener.onError(event);
      } catch (e) {
        // Don't let listener errors break error handling
        final logger = ServiceLocator.logger;
        logger.warning('Error in error listener: $e', tag: 'ErrorHandler');
      }
    }
  }

  bool _isPlatformErrorRecoverable(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  bool _isGenericErrorRecoverable(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('temporary');
  }

  Future<T?> _attemptGenericRecovery<T>(dynamic error, String? context) async {
    // Generic recovery logic - wait and retry
    await Future.delayed(const Duration(seconds: 1));
    return null; // No generic recovery available
  }
}

/// Error event passed to listeners
class AlouetteErrorEvent {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final bool isRecoverable;
  final String? errorCode;
  final Map<String, dynamic>? additionalDetails;
  final DateTime timestamp;

  AlouetteErrorEvent({
    required this.error,
    this.stackTrace,
    this.context,
    required this.isRecoverable,
    this.errorCode,
    this.additionalDetails,
  }) : timestamp = DateTime.now();
}

/// Interface for error listeners
abstract class ErrorHandlerListener {
  void onError(AlouetteErrorEvent event);
}

/// Interface for error recovery strategies
abstract class ErrorRecoveryStrategy {
  Future<T?> recover<T>(dynamic error, String? context);
}

/// Retry recovery strategy
class RetryRecoveryStrategy implements ErrorRecoveryStrategy {
  final int maxAttempts;
  final Duration delay;

  RetryRecoveryStrategy({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
  });

  @override
  Future<T?> recover<T>(dynamic error, String? context) async {
    // This is a placeholder - actual retry logic would need the original operation
    await Future.delayed(delay);
    return null;
  }
}

/// Delayed retry recovery strategy
class DelayedRetryRecoveryStrategy implements ErrorRecoveryStrategy {
  final Duration delay;

  DelayedRetryRecoveryStrategy({required this.delay});

  @override
  Future<T?> recover<T>(dynamic error, String? context) async {
    await Future.delayed(delay);
    return null;
  }
}

/// Fallback recovery strategy
class FallbackRecoveryStrategy implements ErrorRecoveryStrategy {
  @override
  Future<T?> recover<T>(dynamic error, String? context) async {
    // This would implement fallback logic specific to the error type
    return null;
  }
}

/// Error statistics
class ErrorStatistics {
  final int totalErrors;
  final int recoverableErrors;
  final Map<String, int> errorsByCode;
  final DateTime? lastErrorTime;

  ErrorStatistics({
    required this.totalErrors,
    required this.recoverableErrors,
    required this.errorsByCode,
    this.lastErrorTime,
  });

  double get recoveryRate {
    if (totalErrors == 0) return 0.0;
    return recoverableErrors / totalErrors;
  }
}

/// UI Error listener for showing error messages
class UIErrorListener implements ErrorHandlerListener {
  final void Function(AlouetteErrorEvent event) onErrorCallback;

  UIErrorListener(this.onErrorCallback);

  @override
  void onError(AlouetteErrorEvent event) {
    onErrorCallback(event);
  }
}
