import '../enums/tts_platform.dart';
import '../enums/tts_error_code.dart';
import '../models/error_context.dart';

/// Base exception class for all TTS-related errors
class TTSException implements Exception {
  /// Error message
  final String message;
  
  /// Standardized error code
  final TTSErrorCode errorCode;
  
  /// Original error that caused this exception (if any)
  final dynamic originalError;
  
  /// Error context with debugging information
  final TTSErrorContext? context;

  const TTSException(
    this.message, {
    this.errorCode = TTSErrorCode.unknown,
    this.originalError,
    this.context,
  });

  /// Creates a TTSException with error code mapping from platform error
  factory TTSException.fromPlatformError(
    String message,
    String platformError,
    String platform, {
    dynamic originalError,
    TTSErrorContext? context,
  }) {
    final errorCode = TTSErrorCode.fromPlatformError(platformError, platform);
    return TTSException(
      message,
      errorCode: errorCode,
      originalError: originalError,
      context: context,
    );
  }

  /// Legacy constructor for backward compatibility
  factory TTSException.withCode(
    String message, {
    String? code,
    dynamic originalError,
  }) {
    // Try to find matching error code by code string
    TTSErrorCode errorCode = TTSErrorCode.unknown;
    if (code != null) {
      try {
        errorCode = TTSErrorCode.values.firstWhere(
          (e) => e.code == code,
          orElse: () => TTSErrorCode.unknown,
        );
      } catch (_) {
        errorCode = TTSErrorCode.unknown;
      }
    }
    
    return TTSException(
      message,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  /// Returns the legacy code string for backward compatibility
  String? get code => errorCode.code;

  /// Returns true if this error is typically retryable
  bool get isRetryable => errorCode.isRetryable;

  /// Returns the error category
  TTSErrorCategory get category => errorCode.category;

  /// Creates a detailed error report
  Map<String, dynamic> toErrorReport() {
    return {
      'message': message,
      'errorCode': errorCode.code,
      'errorDescription': errorCode.description,
      'category': category.displayName,
      'isRetryable': isRetryable,
      'originalError': originalError?.toString(),
      'context': context?.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSException: $message');
    buffer.write(' (Code: ${errorCode.code})');
    if (originalError != null) {
      buffer.write(' - Original error: $originalError');
    }
    if (context != null) {
      buffer.write(' - Context: ${context!.operation} on ${context!.platform.platformName}');
    }
    return buffer.toString();
  }
}

/// Exception thrown during TTS service initialization
class TTSInitializationException extends TTSException {
  /// Platform where initialization failed
  final String platform;

  const TTSInitializationException(
    String message,
    this.platform, {
    TTSErrorCode errorCode = TTSErrorCode.initializationFailed,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode,
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSInitializationException.withCode(
    String message,
    String platform, {
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode errorCode = TTSErrorCode.initializationFailed;
    if (code != null) {
      switch (code) {
        case 'PLATFORM_NOT_SUPPORTED':
          errorCode = TTSErrorCode.platformNotSupported;
          break;
        case 'DEPENDENCY_MISSING':
          errorCode = TTSErrorCode.dependencyMissing;
          break;
        case 'PERMISSION_DENIED':
          errorCode = TTSErrorCode.permissionDenied;
          break;
      }
    }
    
    return TTSInitializationException(
      message,
      platform,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    return 'TTSInitializationException: $message (Platform: $platform, Code: ${errorCode.code})';
  }
}

/// Exception thrown for platform-specific errors
class TTSPlatformException extends TTSException {
  /// Platform where the error occurred
  final TTSPlatform platform;
  
  /// Platform version information
  final String? platformVersion;

  TTSPlatformException(
    String message,
    this.platform, {
    this.platformVersion,
    TTSErrorCode? errorCode,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode ?? _getDefaultErrorCode(platform),
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSPlatformException.withCode(
    String message,
    TTSPlatform platform, {
    String? platformVersion,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode? errorCode;
    if (code != null) {
      errorCode = TTSErrorCode.values.cast<TTSErrorCode?>().firstWhere(
        (e) => e?.code == code,
        orElse: () => null,
      );
    }
    
    return TTSPlatformException(
      message,
      platform,
      platformVersion: platformVersion,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  static TTSErrorCode _getDefaultErrorCode(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
        return TTSErrorCode.androidTtsError;
      case TTSPlatform.ios:
        return TTSErrorCode.iosTtsError;
      case TTSPlatform.web:
        return TTSErrorCode.webSpeechApiError;
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        return TTSErrorCode.edgeTtsUnavailable;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSPlatformException: $message (Platform: ${platform.platformName}');
    if (platformVersion != null) {
      buffer.write(', Version: $platformVersion');
    }
    buffer.write(', Code: ${errorCode.code})');
    return buffer.toString();
  }
}

/// Exception thrown during text synthesis operations
class TTSSynthesisException extends TTSException {
  /// Text that failed to synthesize
  final String text;
  
  /// Voice name that was requested (if any)
  final String? voiceName;
  
  /// Timeout duration (if applicable)
  final Duration? timeoutDuration;

  const TTSSynthesisException(
    String message, {
    required this.text,
    this.voiceName,
    this.timeoutDuration,
    TTSErrorCode errorCode = TTSErrorCode.synthesisEngineError,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode,
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSSynthesisException.withCode(
    String message, {
    required String text,
    String? voiceName,
    Duration? timeoutDuration,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode errorCode = TTSErrorCode.synthesisEngineError;
    if (code != null) {
      switch (code) {
        case 'TIMEOUT':
          errorCode = TTSErrorCode.synthesisTimeout;
          break;
        case 'TEXT_TOO_LONG':
          errorCode = TTSErrorCode.textTooLong;
          break;
        case 'SSML_ERROR':
          errorCode = TTSErrorCode.ssmlParsingError;
          break;
        case 'AUDIO_GENERATION_FAILED':
          errorCode = TTSErrorCode.audioGenerationFailed;
          break;
      }
    }
    
    return TTSSynthesisException(
      message,
      text: text,
      voiceName: voiceName,
      timeoutDuration: timeoutDuration,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSSynthesisException: $message');
    buffer.write(' (Text length: ${text.length}');
    if (voiceName != null) {
      buffer.write(', Voice: $voiceName');
    }
    if (timeoutDuration != null) {
      buffer.write(', Timeout: ${timeoutDuration!.inSeconds}s');
    }
    buffer.write(', Code: ${errorCode.code})');
    return buffer.toString();
  }
}

/// Exception thrown for network-related errors
class TTSNetworkException extends TTSException {
  /// Network endpoint that failed
  final String endpoint;
  
  /// HTTP status code (if applicable)
  final int? statusCode;

  TTSNetworkException(
    String message, {
    required this.endpoint,
    this.statusCode,
    TTSErrorCode? errorCode,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode ?? _getErrorCodeFromStatus(statusCode),
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSNetworkException.withCode(
    String message, {
    required String endpoint,
    int? statusCode,
    bool isRetryable = true,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode? errorCode;
    if (code != null) {
      switch (code) {
        case 'TIMEOUT':
          errorCode = TTSErrorCode.networkTimeout;
          break;
        case 'CONNECTION_FAILED':
          errorCode = TTSErrorCode.connectionFailed;
          break;
        case 'SERVER_ERROR':
          errorCode = TTSErrorCode.serverError;
          break;
        case 'RATE_LIMIT':
          errorCode = TTSErrorCode.rateLimitExceeded;
          break;
        case 'AUTH_FAILED':
          errorCode = TTSErrorCode.authenticationFailed;
          break;
      }
    }
    
    return TTSNetworkException(
      message,
      endpoint: endpoint,
      statusCode: statusCode,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  static TTSErrorCode _getErrorCodeFromStatus(int? statusCode) {
    if (statusCode == null) return TTSErrorCode.connectionFailed;
    
    switch (statusCode) {
      case 401:
      case 403:
        return TTSErrorCode.authenticationFailed;
      case 429:
        return TTSErrorCode.rateLimitExceeded;
      case >= 500:
        return TTSErrorCode.serverError;
      default:
        return TTSErrorCode.connectionFailed;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSNetworkException: $message');
    buffer.write(' (Endpoint: $endpoint');
    if (statusCode != null) {
      buffer.write(', Status: $statusCode');
    }
    buffer.write(', Code: ${errorCode.code}, Retryable: $isRetryable)');
    return buffer.toString();
  }
}

/// Exception thrown for voice-related errors
class TTSVoiceException extends TTSException {
  /// Voice that was requested
  final String requestedVoice;
  
  /// List of available voices (if known)
  final List<String> availableVoices;

  const TTSVoiceException(
    String message, {
    required this.requestedVoice,
    this.availableVoices = const [],
    TTSErrorCode errorCode = TTSErrorCode.voiceNotFound,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode,
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSVoiceException.withCode(
    String message, {
    required String requestedVoice,
    List<String> availableVoices = const [],
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode errorCode = TTSErrorCode.voiceNotFound;
    if (code != null) {
      switch (code) {
        case 'VOICE_NOT_AVAILABLE':
          errorCode = TTSErrorCode.voiceNotAvailable;
          break;
        case 'VOICE_LOAD_FAILED':
          errorCode = TTSErrorCode.voiceLoadFailed;
          break;
        case 'LANGUAGE_NOT_SUPPORTED':
          errorCode = TTSErrorCode.languageNotSupported;
          break;
      }
    }
    
    return TTSVoiceException(
      message,
      requestedVoice: requestedVoice,
      availableVoices: availableVoices,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSVoiceException: $message');
    buffer.write(' (Requested: $requestedVoice');
    if (availableVoices.isNotEmpty) {
      buffer.write(', Available: ${availableVoices.length} voices');
    }
    buffer.write(', Code: ${errorCode.code})');
    return buffer.toString();
  }
}

/// Exception thrown for configuration-related errors
class TTSConfigurationException extends TTSException {
  /// Configuration field that caused the error
  final String? field;
  
  /// Invalid value that was provided
  final dynamic invalidValue;

  const TTSConfigurationException(
    String message, {
    this.field,
    this.invalidValue,
    TTSErrorCode errorCode = TTSErrorCode.invalidConfiguration,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode,
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSConfigurationException.withCode(
    String message, {
    String? field,
    dynamic invalidValue,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode errorCode = TTSErrorCode.invalidConfiguration;
    if (code != null) {
      switch (code) {
        case 'INVALID_VOICE':
          errorCode = TTSErrorCode.invalidVoice;
          break;
        case 'INVALID_AUDIO_FORMAT':
          errorCode = TTSErrorCode.invalidAudioFormat;
          break;
        case 'INVALID_SPEECH_RATE':
          errorCode = TTSErrorCode.invalidSpeechRate;
          break;
        case 'INVALID_PITCH':
          errorCode = TTSErrorCode.invalidPitch;
          break;
        case 'INVALID_VOLUME':
          errorCode = TTSErrorCode.invalidVolume;
          break;
      }
    }
    
    return TTSConfigurationException(
      message,
      field: field,
      invalidValue: invalidValue,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSConfigurationException: $message');
    if (field != null) {
      buffer.write(' (Field: $field');
      if (invalidValue != null) {
        buffer.write(', Value: $invalidValue');
      }
      buffer.write(', Code: ${errorCode.code})');
    }
    return buffer.toString();
  }
}

/// Exception thrown for file operation errors
class TTSFileException extends TTSException {
  /// File path that caused the error
  final String filePath;
  
  /// File operation that failed
  final String operation;

  TTSFileException(
    String message, {
    required this.filePath,
    required this.operation,
    TTSErrorCode? errorCode,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode ?? _getErrorCodeFromOperation(operation),
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSFileException.withCode(
    String message, {
    required String filePath,
    required String operation,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode? errorCode;
    if (code != null) {
      switch (code) {
        case 'FILE_NOT_FOUND':
          errorCode = TTSErrorCode.fileNotFound;
          break;
        case 'ACCESS_DENIED':
          errorCode = TTSErrorCode.fileAccessDenied;
          break;
        case 'DISK_SPACE':
          errorCode = TTSErrorCode.diskSpaceInsufficient;
          break;
        case 'FORMAT_UNSUPPORTED':
          errorCode = TTSErrorCode.fileFormatUnsupported;
          break;
        case 'WRITE_FAILED':
          errorCode = TTSErrorCode.fileWriteFailed;
          break;
      }
    }
    
    return TTSFileException(
      message,
      filePath: filePath,
      operation: operation,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  static TTSErrorCode _getErrorCodeFromOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'read':
        return TTSErrorCode.fileNotFound;
      case 'write':
        return TTSErrorCode.fileWriteFailed;
      case 'access':
        return TTSErrorCode.fileAccessDenied;
      default:
        return TTSErrorCode.fileWriteFailed;
    }
  }

  @override
  String toString() {
    return 'TTSFileException: $message (Operation: $operation, Path: $filePath, Code: ${errorCode.code})';
  }
}

/// Exception thrown for audio playback errors
class TTSPlaybackException extends TTSException {
  /// Audio data that failed to play (if available)
  final dynamic audioData;
  
  /// Audio format information
  final String? audioFormat;

  const TTSPlaybackException(
    String message, {
    this.audioData,
    this.audioFormat,
    TTSErrorCode errorCode = TTSErrorCode.playbackFailed,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: errorCode,
          originalError: originalError,
          context: context,
        );

  /// Legacy constructor for backward compatibility
  factory TTSPlaybackException.withCode(
    String message, {
    dynamic audioData,
    String? audioFormat,
    String? code,
    dynamic originalError,
  }) {
    TTSErrorCode errorCode = TTSErrorCode.playbackFailed;
    if (code != null) {
      switch (code) {
        case 'AUDIO_DEVICE_ERROR':
          errorCode = TTSErrorCode.audioDeviceError;
          break;
        case 'AUDIO_FORMAT_ERROR':
          errorCode = TTSErrorCode.audioFormatError;
          break;
        case 'PLAYBACK_INTERRUPTED':
          errorCode = TTSErrorCode.playbackInterrupted;
          break;
      }
    }
    
    return TTSPlaybackException(
      message,
      audioData: audioData,
      audioFormat: audioFormat,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TTSPlaybackException: $message');
    if (audioFormat != null) {
      buffer.write(' (Format: $audioFormat');
    }
    buffer.write(', Code: ${errorCode.code})');
    return buffer.toString();
  }
}

/// Exception thrown when operations are cancelled
class TTSOperationCancelledException extends TTSException {
  /// Operation that was cancelled
  final String operation;
  
  /// Reason for cancellation
  final String? reason;

  const TTSOperationCancelledException(
    String message, {
    required this.operation,
    this.reason,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: TTSErrorCode.operationCancelled,
          originalError: originalError,
          context: context,
        );

  @override
  String toString() {
    final buffer = StringBuffer('TTSOperationCancelledException: $message');
    buffer.write(' (Operation: $operation');
    if (reason != null) {
      buffer.write(', Reason: $reason');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// Exception thrown when resources are unavailable
class TTSResourceUnavailableException extends TTSException {
  /// Resource that is unavailable
  final String resource;
  
  /// Expected availability time (if known)
  final DateTime? expectedAvailability;

  const TTSResourceUnavailableException(
    String message, {
    required this.resource,
    this.expectedAvailability,
    dynamic originalError,
    TTSErrorContext? context,
  }) : super(
          message,
          errorCode: TTSErrorCode.resourceUnavailable,
          originalError: originalError,
          context: context,
        );

  @override
  String toString() {
    final buffer = StringBuffer('TTSResourceUnavailableException: $message');
    buffer.write(' (Resource: $resource');
    if (expectedAvailability != null) {
      buffer.write(', Expected: ${expectedAvailability!.toIso8601String()}');
    }
    buffer.write(')');
    return buffer.toString();
  }
}