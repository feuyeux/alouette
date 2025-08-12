/// Base exception for all translation-related errors
class TranslationException implements Exception {
  /// The error message
  final String message;
  
  /// Optional error code for programmatic handling
  final String? code;
  
  /// Optional additional details about the error
  final Map<String, dynamic>? details;

  const TranslationException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return 'TranslationException [$code]: $message';
    }
    return 'TranslationException: $message';
  }
}

/// Exception thrown when there are network/connection issues with the LLM provider
class LLMConnectionException extends TranslationException {
  const LLMConnectionException(
    String message, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'LLMConnectionException [$code]: $message';
    }
    return 'LLMConnectionException: $message';
  }
}

/// Exception thrown when authentication with the LLM provider fails
class LLMAuthenticationException extends TranslationException {
  const LLMAuthenticationException(
    String message, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'LLMAuthenticationException [$code]: $message';
    }
    return 'LLMAuthenticationException: $message';
  }
}

/// Exception thrown when the requested model is not found or available
class LLMModelNotFoundException extends TranslationException {
  /// The model name that was not found
  final String modelName;

  const LLMModelNotFoundException(
    String message,
    this.modelName, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'LLMModelNotFoundException [$code]: $message (Model: $modelName)';
    }
    return 'LLMModelNotFoundException: $message (Model: $modelName)';
  }
}

/// Exception thrown when a translation request times out
class TranslationTimeoutException extends TranslationException {
  /// The timeout duration that was exceeded
  final Duration? timeout;

  const TranslationTimeoutException(
    String message, {
    this.timeout,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'TranslationTimeoutException [$code]: $message${timeout != null ? ' (Timeout: ${timeout!.inSeconds}s)' : ''}';
    }
    return 'TranslationTimeoutException: $message${timeout != null ? ' (Timeout: ${timeout!.inSeconds}s)' : ''}';
  }
}

/// Exception thrown when the translation result is invalid or empty
class InvalidTranslationException extends TranslationException {
  /// The original text that failed to translate
  final String originalText;
  
  /// The target language that failed
  final String targetLanguage;

  const InvalidTranslationException(
    String message,
    this.originalText,
    this.targetLanguage, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'InvalidTranslationException [$code]: $message (Language: $targetLanguage)';
    }
    return 'InvalidTranslationException: $message (Language: $targetLanguage)';
  }
}

/// Exception thrown when there are configuration-related errors
class ConfigurationException extends TranslationException {
  /// The configuration field that caused the error
  final String? field;

  const ConfigurationException(
    String message, {
    this.field,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'ConfigurationException [$code]: $message${field != null ? ' (Field: $field)' : ''}';
    }
    return 'ConfigurationException: $message${field != null ? ' (Field: $field)' : ''}';
  }
}

/// Exception thrown when a provider is not supported
class UnsupportedProviderException extends TranslationException {
  /// The provider name that is not supported
  final String providerName;
  
  /// List of supported providers
  final List<String> supportedProviders;

  const UnsupportedProviderException(
    String message,
    this.providerName,
    this.supportedProviders, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'UnsupportedProviderException [$code]: $message (Provider: $providerName, Supported: ${supportedProviders.join(', ')})';
    }
    return 'UnsupportedProviderException: $message (Provider: $providerName, Supported: ${supportedProviders.join(', ')})';
  }
}

/// Exception thrown when rate limits are exceeded
class RateLimitException extends TranslationException {
  /// When the rate limit will reset (if available)
  final DateTime? resetTime;
  
  /// Number of requests remaining (if available)
  final int? remainingRequests;

  const RateLimitException(
    String message, {
    this.resetTime,
    this.remainingRequests,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);

  @override
  String toString() {
    if (code != null) {
      return 'RateLimitException [$code]: $message${resetTime != null ? ' (Reset: $resetTime)' : ''}';
    }
    return 'RateLimitException: $message${resetTime != null ? ' (Reset: $resetTime)' : ''}';
  }
}