/// Base error class for all Alouette translation-related errors
abstract class AlouetteTranslationError extends Error {
  /// The error message
  final String message;

  /// Consistent error code for programmatic handling
  final String code;

  /// Optional additional details about the error
  final Map<String, dynamic>? details;

  /// The original error that caused this error (if any)
  final dynamic originalError;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  AlouetteTranslationError(
    this.message,
    this.code, {
    this.details,
    this.originalError,
  }) : timestamp = DateTime.now();

  /// Get user-friendly error message
  String get userMessage => _getUserMessage();

  /// Get technical error message for logging
  String get technicalMessage => _getTechnicalMessage();

  /// Check if this error is recoverable
  bool get isRecoverable => _isRecoverable();

  /// Get suggested recovery actions
  List<String> get recoveryActions => _getRecoveryActions();

  String _getUserMessage() {
    switch (code) {
      case TranslationErrorCodes.connectionFailed:
        return 'Unable to connect to translation service. Please check your internet connection.';
      case TranslationErrorCodes.authenticationFailed:
        return 'Authentication failed. Please check your credentials.';
      case TranslationErrorCodes.modelNotFound:
        return 'The selected translation model is not available.';
      case TranslationErrorCodes.requestTimeout:
        return 'Translation request timed out. Please try again.';
      case TranslationErrorCodes.invalidTranslation:
        return 'Translation failed to complete successfully.';
      case TranslationErrorCodes.configurationError:
        return 'Translation service configuration error.';
      case TranslationErrorCodes.unsupportedProvider:
        return 'The selected translation provider is not supported.';
      case TranslationErrorCodes.rateLimitExceeded:
        return 'Too many requests. Please wait before trying again.';
      default:
        return message;
    }
  }

  String _getTechnicalMessage() {
    final buffer = StringBuffer();
    buffer.write('[$code] $message');
    if (originalError != null) {
      buffer.write(' | Original: $originalError');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(' | Details: $details');
    }
    return buffer.toString();
  }

  bool _isRecoverable() {
    switch (code) {
      case TranslationErrorCodes.connectionFailed:
      case TranslationErrorCodes.requestTimeout:
      case TranslationErrorCodes.rateLimitExceeded:
        return true;
      case TranslationErrorCodes.authenticationFailed:
      case TranslationErrorCodes.modelNotFound:
      case TranslationErrorCodes.configurationError:
      case TranslationErrorCodes.unsupportedProvider:
        return false;
      default:
        return false;
    }
  }

  List<String> _getRecoveryActions() {
    switch (code) {
      case TranslationErrorCodes.connectionFailed:
        return ['Check internet connection', 'Verify server URL', 'Try again'];
      case TranslationErrorCodes.requestTimeout:
        return ['Try again with shorter text', 'Check network speed'];
      case TranslationErrorCodes.rateLimitExceeded:
        return ['Wait before retrying', 'Reduce request frequency'];
      case TranslationErrorCodes.modelNotFound:
        return ['Select a different model', 'Check model availability'];
      case TranslationErrorCodes.authenticationFailed:
        return ['Check credentials', 'Verify API key'];
      case TranslationErrorCodes.configurationError:
        return ['Review configuration settings', 'Reset to defaults'];
      default:
        return ['Contact support'];
    }
  }

  @override
  String toString() => technicalMessage;
}

/// Standard error codes for translation errors
class TranslationErrorCodes {
  static const String connectionFailed = 'TRANS_CONNECTION_FAILED';
  static const String authenticationFailed = 'TRANS_AUTH_FAILED';
  static const String modelNotFound = 'TRANS_MODEL_NOT_FOUND';
  static const String requestTimeout = 'TRANS_REQUEST_TIMEOUT';
  static const String invalidTranslation = 'TRANS_INVALID_RESULT';
  static const String configurationError = 'TRANS_CONFIG_ERROR';
  static const String unsupportedProvider = 'TRANS_UNSUPPORTED_PROVIDER';
  static const String rateLimitExceeded = 'TRANS_RATE_LIMIT';
  static const String networkError = 'TRANS_NETWORK_ERROR';
  static const String serverError = 'TRANS_SERVER_ERROR';
}

/// Base exception for all translation-related errors (for backward compatibility)
class TranslationException extends AlouetteTranslationError {
  TranslationException(
    String message, {
    String? code,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         code ?? TranslationErrorCodes.networkError,
         details: details,
         originalError: originalError,
       );
}

/// Exception thrown when there are network/connection issues with the LLM provider
class LLMConnectionException extends AlouetteTranslationError {
  LLMConnectionException(
    String message, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.connectionFailed,
         details: details,
         originalError: originalError,
       );
}

/// Exception thrown when authentication with the LLM provider fails
class LLMAuthenticationException extends AlouetteTranslationError {
  LLMAuthenticationException(
    String message, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.authenticationFailed,
         details: details,
         originalError: originalError,
       );
}

/// Exception thrown when the requested model is not found or available
class LLMModelNotFoundException extends AlouetteTranslationError {
  /// The model name that was not found
  final String modelName;

  LLMModelNotFoundException(
    String message,
    this.modelName, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.modelNotFound,
         details: {'modelName': modelName, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when a translation request times out
class TranslationTimeoutException extends AlouetteTranslationError {
  /// The timeout duration that was exceeded
  final Duration? timeout;

  TranslationTimeoutException(
    String message, {
    this.timeout,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.requestTimeout,
         details: {
           if (timeout != null) 'timeoutSeconds': timeout.inSeconds,
           ...?details,
         },
         originalError: originalError,
       );
}

/// Exception thrown when the translation result is invalid or empty
class InvalidTranslationException extends AlouetteTranslationError {
  /// The original text that failed to translate
  final String originalText;

  /// The target language that failed
  final String targetLanguage;

  InvalidTranslationException(
    String message,
    this.originalText,
    this.targetLanguage, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.invalidTranslation,
         details: {
           'originalText': originalText,
           'targetLanguage': targetLanguage,
           ...?details,
         },
         originalError: originalError,
       );
}

/// Exception thrown when there are configuration-related errors
class ConfigurationException extends AlouetteTranslationError {
  /// The configuration field that caused the error
  final String? field;

  ConfigurationException(
    String message, {
    this.field,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.configurationError,
         details: {if (field != null) 'field': field, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when a provider is not supported
class UnsupportedProviderException extends AlouetteTranslationError {
  /// The provider name that is not supported
  final String providerName;

  /// List of supported providers
  final List<String> supportedProviders;

  UnsupportedProviderException(
    String message,
    this.providerName,
    this.supportedProviders, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.unsupportedProvider,
         details: {
           'providerName': providerName,
           'supportedProviders': supportedProviders,
           ...?details,
         },
         originalError: originalError,
       );
}

/// Exception thrown when rate limits are exceeded
class RateLimitException extends AlouetteTranslationError {
  /// When the rate limit will reset (if available)
  final DateTime? resetTime;

  /// Number of requests remaining (if available)
  final int? remainingRequests;

  RateLimitException(
    String message, {
    this.resetTime,
    this.remainingRequests,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TranslationErrorCodes.rateLimitExceeded,
         details: {
           if (resetTime != null) 'resetTime': resetTime.toIso8601String(),
           if (remainingRequests != null)
             'remainingRequests': remainingRequests,
           ...?details,
         },
         originalError: originalError,
       );
}
