/// Service Configuration for Alouette Applications
///
/// Provides configuration options for service initialization and management.
/// Allows applications to customize which services are initialized and how.
class ServiceConfiguration {
  /// Whether to initialize TTS service
  final bool initializeTTS;

  /// Whether to initialize Translation service
  final bool initializeTranslation;

  /// Whether to enable automatic fallback for TTS engines
  final bool ttsAutoFallback;

  /// Whether to enable verbose logging during initialization
  final bool verboseLogging;

  /// Custom initialization timeout in milliseconds
  final int initializationTimeoutMs;

  const ServiceConfiguration({
    this.initializeTTS = true,
    this.initializeTranslation = true,
    this.ttsAutoFallback = true,
    this.verboseLogging = false,
    this.initializationTimeoutMs = 30000, // 30 seconds
  });

  /// Configuration for TTS-only applications
  static const ServiceConfiguration ttsOnly = ServiceConfiguration(
    initializeTTS: true,
    initializeTranslation: false,
  );

  /// Configuration for Translation-only applications
  static const ServiceConfiguration translationOnly = ServiceConfiguration(
    initializeTTS: false,
    initializeTranslation: true,
  );

  /// Configuration for combined applications
  static const ServiceConfiguration combined = ServiceConfiguration(
    initializeTTS: true,
    initializeTranslation: true,
  );

  /// Configuration for testing (no services initialized)
  static const ServiceConfiguration testing = ServiceConfiguration(
    initializeTTS: false,
    initializeTranslation: false,
  );

  /// Configuration with verbose logging for debugging
  static const ServiceConfiguration debug = ServiceConfiguration(
    initializeTTS: true,
    initializeTranslation: true,
    verboseLogging: true,
  );

  @override
  String toString() {
    return 'ServiceConfiguration('
        'TTS: $initializeTTS, '
        'Translation: $initializeTranslation, '
        'AutoFallback: $ttsAutoFallback, '
        'Verbose: $verboseLogging, '
        'Timeout: ${initializationTimeoutMs}ms)';
  }
}

/// Service initialization result
class ServiceInitializationResult {
  /// Whether the overall initialization was successful
  final bool isSuccessful;

  /// Individual service results
  final Map<String, bool> serviceResults;

  /// Any errors that occurred during initialization
  final List<String> errors;

  /// Initialization duration in milliseconds
  final int durationMs;

  const ServiceInitializationResult({
    required this.isSuccessful,
    required this.serviceResults,
    required this.errors,
    required this.durationMs,
  });

  /// Get a summary of the initialization result
  String getSummary() {
    final successful = serviceResults.values.where((v) => v).length;
    final total = serviceResults.length;

    if (isSuccessful) {
      return 'Successfully initialized $successful/$total services in ${durationMs}ms';
    } else {
      return 'Failed to initialize services ($successful/$total successful). Errors: ${errors.join(', ')}';
    }
  }

  @override
  String toString() => getSummary();
}
