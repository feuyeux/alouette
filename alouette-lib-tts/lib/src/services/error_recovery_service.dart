import 'dart:async';
import 'dart:math';

import '../interfaces/i_tts_service.dart';
import '../interfaces/i_platform_detector.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../exceptions/tts_exception.dart';
import '../enums/tts_error_code.dart';
import '../enums/tts_platform.dart';

/// Configuration for error recovery behavior
class ErrorRecoveryConfig {
  /// Maximum number of retry attempts
  final int maxRetries;

  /// Base delay for exponential backoff (in milliseconds)
  final int baseDelayMs;

  /// Maximum delay for exponential backoff (in milliseconds)
  final int maxDelayMs;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Whether to enable platform fallback
  final bool enablePlatformFallback;

  /// Whether to enable voice fallback
  final bool enableVoiceFallback;

  /// Timeout for individual retry attempts
  final Duration retryTimeout;

  /// Whether to add jitter to backoff delays
  final bool enableJitter;

  const ErrorRecoveryConfig({
    this.maxRetries = 3,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.backoffMultiplier = 2.0,
    this.enablePlatformFallback = true,
    this.enableVoiceFallback = true,
    this.retryTimeout = const Duration(seconds: 30),
    this.enableJitter = true,
  });

  ErrorRecoveryConfig copyWith({
    int? maxRetries,
    int? baseDelayMs,
    int? maxDelayMs,
    double? backoffMultiplier,
    bool? enablePlatformFallback,
    bool? enableVoiceFallback,
    Duration? retryTimeout,
    bool? enableJitter,
  }) {
    return ErrorRecoveryConfig(
      maxRetries: maxRetries ?? this.maxRetries,
      baseDelayMs: baseDelayMs ?? this.baseDelayMs,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      enablePlatformFallback:
          enablePlatformFallback ?? this.enablePlatformFallback,
      enableVoiceFallback: enableVoiceFallback ?? this.enableVoiceFallback,
      retryTimeout: retryTimeout ?? this.retryTimeout,
      enableJitter: enableJitter ?? this.enableJitter,
    );
  }
}

/// Service for handling automatic error recovery and retry logic
class ErrorRecoveryService {
  final ErrorRecoveryConfig _config;
  final IPlatformDetector _platformDetector;
  final Random _random = Random();

  /// Cache of fallback services by platform
  final Map<TTSPlatform, ITTSService> _fallbackServices = {};

  /// Cache of available voices by service
  final Map<ITTSService, List<AlouetteVoice>> _voiceCache = {};

  /// Cache expiry time for voices
  final Map<ITTSService, DateTime> _voiceCacheExpiry = {};

  static const Duration _voiceCacheTimeout = Duration(minutes: 30);

  ErrorRecoveryService({
    ErrorRecoveryConfig? config,
    required IPlatformDetector platformDetector,
  })  : _config = config ?? const ErrorRecoveryConfig(),
        _platformDetector = platformDetector;

  /// Executes an operation with automatic retry and recovery
  Future<T> executeWithRecovery<T>(
    Future<T> Function() operation, {
    ITTSService? primaryService,
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= _config.maxRetries; attempt++) {
      try {
        // Add timeout to the operation
        return await operation().timeout(_config.retryTimeout);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Don't retry on the last attempt
        if (attempt == _config.maxRetries) {
          break;
        }

        // Check if error is retryable
        if (!_isRetryableError(e)) {
          break;
        }

        // Apply exponential backoff delay
        final delay = _calculateBackoffDelay(attempt);
        await Future.delayed(Duration(milliseconds: delay));

        // Try recovery strategies if this is a TTS exception
        if (e is TTSException && primaryService != null) {
          await _attemptRecovery(e, primaryService, operationName, context);
        }
      }
    }

    // All retries failed, throw the last exception
    throw lastException!;
  }

  /// Executes a TTS operation with automatic platform and voice fallback
  Future<T> executeWithFallback<T>(
    Future<T> Function(ITTSService service, AlouetteTTSConfig config) operation,
    ITTSService primaryService,
    AlouetteTTSConfig config, {
    String? operationName,
  }) async {
    // Try with primary service first
    try {
      return await executeWithRecovery(
        () => operation(primaryService, config),
        primaryService: primaryService,
        operationName: operationName,
      );
    } catch (e) {
      // If platform fallback is disabled, rethrow
      if (!_config.enablePlatformFallback) {
        rethrow;
      }

      // Try platform fallback
      final fallbackService = await _getFallbackService(primaryService);
      if (fallbackService != null) {
        try {
          return await executeWithRecovery(
            () => operation(fallbackService, config),
            primaryService: fallbackService,
            operationName: '$operationName (platform fallback)',
          );
        } catch (fallbackError) {
          // Both primary and fallback failed, throw original error
          rethrow;
        }
      }

      rethrow;
    }
  }

  /// Finds and returns an alternative voice when the requested voice is unavailable
  Future<AlouetteVoice?> findFallbackVoice(
    ITTSService service,
    String requestedVoiceName,
    String? languageCode,
  ) async {
    if (!_config.enableVoiceFallback) {
      return null;
    }

    try {
      final availableVoices = await _getCachedVoices(service);

      // First, try to find voices in the same language
      if (languageCode != null) {
        final sameLanguageVoices = availableVoices
            .where((voice) => voice.languageCode == languageCode)
            .toList();

        if (sameLanguageVoices.isNotEmpty) {
          // Prefer default voice for the language
          final defaultVoice =
              sameLanguageVoices.where((voice) => voice.isDefault).firstOrNull;

          if (defaultVoice != null) {
            return defaultVoice;
          }

          // Otherwise, return the first available voice in the language
          return sameLanguageVoices.first;
        }
      }

      // If no same-language voice found, try to find any default voice
      final defaultVoices =
          availableVoices.where((voice) => voice.isDefault).toList();

      if (defaultVoices.isNotEmpty) {
        return defaultVoices.first;
      }

      // Last resort: return any available voice
      return availableVoices.isNotEmpty ? availableVoices.first : null;
    } catch (e) {
      // Voice discovery failed, return null
      return null;
    }
  }

  /// Attempts to recover from a TTS error using various strategies
  Future<void> _attemptRecovery(
    TTSException exception,
    ITTSService service,
    String? operationName,
    Map<String, dynamic>? context,
  ) async {
    switch (exception.errorCode) {
      case TTSErrorCode.voiceNotFound:
      case TTSErrorCode.voiceNotAvailable:
        await _attemptVoiceRecovery(service, exception);
        break;

      case TTSErrorCode.networkTimeout:
      case TTSErrorCode.connectionFailed:
        await _attemptNetworkRecovery(service, exception);
        break;

      case TTSErrorCode.edgeTtsUnavailable:
      case TTSErrorCode.platformNotSupported:
        await _attemptPlatformRecovery(service, exception);
        break;

      default:
        // No specific recovery strategy for this error type
        break;
    }
  }

  /// Attempts to recover from voice-related errors
  Future<void> _attemptVoiceRecovery(
    ITTSService service,
    TTSException exception,
  ) async {
    if (!_config.enableVoiceFallback) {
      return;
    }

    try {
      // Clear voice cache to force refresh
      _voiceCache.remove(service);
      _voiceCacheExpiry.remove(service);

      // Try to refresh voice list
      await service.getAvailableVoices();
    } catch (e) {
      // Voice refresh failed, but we'll let the retry mechanism handle it
    }
  }

  /// Attempts to recover from network-related errors
  Future<void> _attemptNetworkRecovery(
    ITTSService service,
    TTSException exception,
  ) async {
    // For network errors, we mainly rely on exponential backoff
    // Additional recovery strategies could be added here, such as:
    // - Checking network connectivity
    // - Switching to different endpoints
    // - Clearing connection pools
  }

  /// Attempts to recover from platform-related errors
  Future<void> _attemptPlatformRecovery(
    ITTSService service,
    TTSException exception,
  ) async {
    if (!_config.enablePlatformFallback) {
      return;
    }

    // Platform recovery is handled by the fallback service mechanism
    // This method could be extended to perform platform-specific recovery actions
  }

  /// Gets a fallback TTS service for the given primary service
  Future<ITTSService?> _getFallbackService(ITTSService primaryService) async {
    final currentPlatform = _platformDetector.getCurrentPlatform();
    // Policy: desktop platforms MUST use Edge TTS. Do not provide a
    // platform-level fallback to Flutter TTS on desktop. Returning null
    // ensures that callers will not attempt to create or switch to
    // FlutterTTS when running on Linux / macOS / Windows.
    if (currentPlatform.isDesktop) {
      return null;
    }

    // For non-desktop platforms (mobile/web) there is no alternate
    // platform-level fallback available — return null.
    return null;
  }

  /// Gets cached voices for a service, refreshing if necessary
  Future<List<AlouetteVoice>> _getCachedVoices(ITTSService service) async {
    final now = DateTime.now();

    // Check if cache is valid
    if (_voiceCache.containsKey(service) &&
        _voiceCacheExpiry.containsKey(service) &&
        now.isBefore(_voiceCacheExpiry[service]!)) {
      return _voiceCache[service]!;
    }

    // Refresh voice cache
    try {
      final voices = await service.getAvailableVoices();
      _voiceCache[service] = voices;
      _voiceCacheExpiry[service] = now.add(_voiceCacheTimeout);
      return voices;
    } catch (e) {
      // Return cached voices if available, even if expired
      return _voiceCache[service] ?? [];
    }
  }

  /// Calculates the delay for exponential backoff
  int _calculateBackoffDelay(int attempt) {
    // Calculate base delay with exponential backoff
    final baseDelay =
        _config.baseDelayMs * pow(_config.backoffMultiplier, attempt);

    // Apply maximum delay limit
    var delay = min(baseDelay, _config.maxDelayMs.toDouble()).round();

    // Add jitter if enabled (±25% of the delay)
    if (_config.enableJitter) {
      final jitterRange = (delay * 0.25).round();
      final jitter = _random.nextInt(jitterRange * 2) - jitterRange;
      delay = max(0, delay + jitter);
    }

    return delay;
  }

  /// Checks if an error is retryable
  bool _isRetryableError(dynamic error) {
    if (error is TTSException) {
      return error.isRetryable;
    }

    if (error is TimeoutException) {
      return true;
    }

    // Check for common retryable error patterns
    final errorString = error.toString().toLowerCase();

    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('server') ||
        errorString.contains('temporary');
  }

  /// Disposes of the error recovery service and cleans up resources
  void dispose() {
    // Dispose of cached fallback services
    for (final service in _fallbackServices.values) {
      service.dispose();
    }

    _fallbackServices.clear();
    _voiceCache.clear();
    _voiceCacheExpiry.clear();
  }
}

/// Extension to add null-safe firstOrNull method
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
