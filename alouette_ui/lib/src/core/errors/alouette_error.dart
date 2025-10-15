/// Unified error handling for Alouette applications
///
/// Provides a consistent error hierarchy and user-friendly error messages.
library alouette_ui.errors;

/// Base class for all Alouette errors
abstract class AlouetteError implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? details;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AlouetteError({
    required this.message,
    required this.code,
    this.details,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AlouetteError($code): $message';

  /// Get user-friendly error message
  String getUserFriendlyMessage() {
    switch (code) {
      case 'TRANSLATION_CONNECTION_FAILED':
        return 'Cannot connect to translation server. Please check your connection and ensure the LLM server is running.';
      case 'TRANSLATION_MODEL_NOT_FOUND':
        return 'The selected translation model was not found. Please check your configuration.';
      case 'TRANSLATION_TIMEOUT':
        return 'Translation request timed out. The server may be overloaded.';
      case 'TTS_ENGINE_NOT_AVAILABLE':
        return 'Text-to-speech engine is not available on this device.';
      case 'TTS_INITIALIZATION_FAILED':
        return 'Failed to initialize text-to-speech. Please try again.';
      case 'TTS_SYNTHESIS_FAILED':
        return 'Failed to generate speech audio. Please try again.';
      case 'SERVICE_NOT_INITIALIZED':
        return 'Service not initialized. Please restart the application.';
      case 'CONFIGURATION_INVALID':
        return 'Configuration is invalid. Please check your settings.';
      default:
        return message;
    }
  }

  /// Get technical error message for logging
  String getTechnicalMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Error Code: $code');
    buffer.writeln('Message: $message');
    if (details != null && details!.isNotEmpty) {
      buffer.writeln('Details: $details');
    }
    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Translation-specific errors
class TranslationError extends AlouetteError {
  const TranslationError({
    required super.message,
    required super.code,
    super.details,
    super.originalError,
    super.stackTrace,
  });

  factory TranslationError.connectionFailed(String serverUrl) {
    return TranslationError(
      message: 'Failed to connect to LLM server at $serverUrl',
      code: 'TRANSLATION_CONNECTION_FAILED',
      details: {'serverUrl': serverUrl},
    );
  }

  factory TranslationError.modelNotFound(String model) {
    return TranslationError(
      message: 'Model $model not found',
      code: 'TRANSLATION_MODEL_NOT_FOUND',
      details: {'model': model},
    );
  }

  factory TranslationError.timeout({Duration? duration}) {
    return TranslationError(
      message: 'Translation request timed out${duration != null ? ' after ${duration.inSeconds}s' : ''}',
      code: 'TRANSLATION_TIMEOUT',
      details: duration != null ? {'timeoutSeconds': duration.inSeconds} : null,
    );
  }

  factory TranslationError.invalidInput(String reason) {
    return TranslationError(
      message: 'Invalid translation input: $reason',
      code: 'TRANSLATION_INVALID_INPUT',
      details: {'reason': reason},
    );
  }
}

/// TTS-specific errors
class TTSError extends AlouetteError {
  const TTSError({
    required super.message,
    required super.code,
    super.details,
    super.originalError,
    super.stackTrace,
  });

  factory TTSError.engineNotAvailable(String engineName) {
    return TTSError(
      message: 'TTS engine $engineName is not available',
      code: 'TTS_ENGINE_NOT_AVAILABLE',
      details: {'engineName': engineName},
    );
  }

  factory TTSError.initializationFailed(String reason) {
    return TTSError(
      message: 'Failed to initialize TTS: $reason',
      code: 'TTS_INITIALIZATION_FAILED',
      details: {'reason': reason},
    );
  }

  factory TTSError.synthesisFailed(String reason) {
    return TTSError(
      message: 'Failed to synthesize speech: $reason',
      code: 'TTS_SYNTHESIS_FAILED',
      details: {'reason': reason},
    );
  }
}

/// Service initialization errors
class ServiceError extends AlouetteError {
  const ServiceError({
    required super.message,
    required super.code,
    super.details,
    super.originalError,
    super.stackTrace,
  });

  factory ServiceError.notInitialized(String serviceName) {
    return ServiceError(
      message: '$serviceName not initialized. Call initialize() first.',
      code: 'SERVICE_NOT_INITIALIZED',
      details: {'serviceName': serviceName},
    );
  }

  factory ServiceError.initializationFailed(String serviceName, String reason) {
    return ServiceError(
      message: 'Failed to initialize $serviceName: $reason',
      code: 'SERVICE_INITIALIZATION_FAILED',
      details: {'serviceName': serviceName, 'reason': reason},
    );
  }
}

/// Configuration errors
class ConfigurationError extends AlouetteError {
  const ConfigurationError({
    required super.message,
    required super.code,
    super.details,
    super.originalError,
    super.stackTrace,
  });

  factory ConfigurationError.invalid(String reason) {
    return ConfigurationError(
      message: 'Invalid configuration: $reason',
      code: 'CONFIGURATION_INVALID',
      details: {'reason': reason},
    );
  }

  factory ConfigurationError.loadFailed(String reason) {
    return ConfigurationError(
      message: 'Failed to load configuration: $reason',
      code: 'CONFIGURATION_LOAD_FAILED',
      details: {'reason': reason},
    );
  }
}
