/// Base exception for all TTS-related errors
abstract class TTSException implements Exception {
  final String message;
  final dynamic originalError;

  const TTSException(this.message, [this.originalError]);

  @override
  String toString() => 'TTSException: $message';
}

/// Exception thrown when TTS initialization fails
class TTSInitializationException extends TTSException {
  const TTSInitializationException(String message, [dynamic originalError])
      : super(message, originalError);

  @override
  String toString() => 'TTSInitializationException: $message';
}

/// Exception thrown for platform-specific TTS errors
class TTSPlatformException extends TTSException {
  final String platform;

  const TTSPlatformException(String message, this.platform, [dynamic originalError])
      : super(message, originalError);

  @override
  String toString() => 'TTSPlatformException [$platform]: $message';
}

/// Exception thrown when requested language is not supported
class TTSLanguageNotSupportedException extends TTSException {
  final String languageCode;

  const TTSLanguageNotSupportedException(String message, this.languageCode, [dynamic originalError])
      : super(message, originalError);

  @override
  String toString() => 'TTSLanguageNotSupportedException [$languageCode]: $message';
}

/// Exception thrown when TTS configuration is invalid
class TTSConfigurationException extends TTSException {
  final String configField;

  const TTSConfigurationException(String message, this.configField, [dynamic originalError])
      : super(message, originalError);

  @override
  String toString() => 'TTSConfigurationException [$configField]: $message';
}

/// Exception thrown when TTS engine encounters an error during speech
class TTSSpeechException extends TTSException {
  const TTSSpeechException(String message, [dynamic originalError])
      : super(message, originalError);

  @override
  String toString() => 'TTSSpeechException: $message';
}

/// Exception thrown when TTS engine is not properly initialized
class TTSNotInitializedException extends TTSException {
  const TTSNotInitializedException([String? message])
      : super(message ?? 'TTS service has not been initialized. Call initialize() first.');

  @override
  String toString() => 'TTSNotInitializedException: $message';
}