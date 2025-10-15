/// Base error class for all Alouette TTS-related errors
abstract class AlouetteTTSError extends Error {
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

  AlouetteTTSError(this.message, this.code, {this.details, this.originalError})
    : timestamp = DateTime.now();

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
      case TTSErrorCodes.engineNotAvailable:
        return 'Text-to-speech engine is not available on this platform.';
      case TTSErrorCodes.voiceNotFound:
        return 'The selected voice is not available.';
      case TTSErrorCodes.synthesisFailure:
        return 'Failed to generate speech audio.';
      case TTSErrorCodes.audioPlaybackError:
        return 'Unable to play the generated audio.';
      case TTSErrorCodes.platformNotSupported:
        return 'Text-to-speech is not supported on this platform.';
      case TTSErrorCodes.configurationError:
        return 'TTS configuration error.';
      case TTSErrorCodes.networkError:
        return 'Network error while accessing TTS service.';
      case TTSErrorCodes.permissionDenied:
        return 'Permission denied for audio access.';
      case TTSErrorCodes.engineSwitchFailed:
        return 'Failed to switch TTS engine.';
      case TTSErrorCodes.initializationFailed:
        return 'Failed to initialize TTS service.';
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
      case TTSErrorCodes.engineNotAvailable:
      case TTSErrorCodes.voiceNotFound:
      case TTSErrorCodes.synthesisFailure:
      case TTSErrorCodes.audioPlaybackError:
      case TTSErrorCodes.networkError:
      case TTSErrorCodes.engineSwitchFailed:
        return true;
      case TTSErrorCodes.platformNotSupported:
      case TTSErrorCodes.configurationError:
      case TTSErrorCodes.permissionDenied:
      case TTSErrorCodes.initializationFailed:
        return false;
      default:
        return false;
    }
  }

  List<String> _getRecoveryActions() {
    switch (code) {
      case TTSErrorCodes.engineNotAvailable:
        return ['Try alternative TTS engine', 'Check system TTS settings'];
      case TTSErrorCodes.voiceNotFound:
        return ['Select a different voice', 'Refresh voice list'];
      case TTSErrorCodes.synthesisFailure:
        return ['Try shorter text', 'Switch to different engine', 'Try again'];
      case TTSErrorCodes.audioPlaybackError:
        return ['Check audio settings', 'Restart application'];
      case TTSErrorCodes.networkError:
        return ['Check internet connection', 'Try again'];
      case TTSErrorCodes.engineSwitchFailed:
        return ['Restart application', 'Reset TTS settings'];
      case TTSErrorCodes.permissionDenied:
        return ['Grant audio permissions', 'Check system settings'];
      case TTSErrorCodes.configurationError:
        return ['Reset TTS configuration', 'Check settings'];
      default:
        return ['Contact support'];
    }
  }

  @override
  String toString() => technicalMessage;
}

/// Standard error codes for TTS errors
class TTSErrorCodes {
  static const String engineNotAvailable = 'TTS_ENGINE_NOT_AVAILABLE';
  static const String voiceNotFound = 'TTS_VOICE_NOT_FOUND';
  static const String synthesisFailure = 'TTS_SYNTHESIS_FAILURE';
  static const String audioPlaybackError = 'TTS_AUDIO_PLAYBACK_ERROR';
  static const String platformNotSupported = 'TTS_PLATFORM_NOT_SUPPORTED';
  static const String configurationError = 'TTS_CONFIG_ERROR';
  static const String networkError = 'TTS_NETWORK_ERROR';
  static const String permissionDenied = 'TTS_PERMISSION_DENIED';
  static const String engineSwitchFailed = 'TTS_ENGINE_SWITCH_FAILED';
  static const String initializationFailed = 'TTS_INITIALIZATION_FAILED';
  static const String invalidParameters = 'TTS_INVALID_PARAMETERS';
  static const String resourceNotFound = 'TTS_RESOURCE_NOT_FOUND';
  static const String noFallbackAvailable = 'TTS_NO_FALLBACK_AVAILABLE';
  static const String synthesisError = 'TTS_SYNTHESIS_ERROR';
  static const String stopFailed = 'TTS_STOP_FAILED';
  static const String notInitialized = 'TTS_NOT_INITIALIZED';

  // Additional error codes used in the codebase
  static const String noVoicesAvailable = 'TTS_NO_VOICES_AVAILABLE';
  static const String speakError = 'TTS_SPEAK_ERROR';
  static const String voiceListError = 'TTS_VOICE_LIST_ERROR';
  static const String voiceListFailed = 'TTS_VOICE_LIST_FAILED';
  static const String emptyText = 'TTS_EMPTY_TEXT';
  static const String emptyVoiceName = 'TTS_EMPTY_VOICE_NAME';
  static const String synthesisFailed = 'TTS_SYNTHESIS_FAILED';
  static const String outputFileNotCreated = 'TTS_OUTPUT_FILE_NOT_CREATED';
  static const String voiceParseError = 'TTS_VOICE_PARSE_ERROR';
  static const String speakFailed = 'TTS_SPEAK_FAILED';
  static const String playbackFailed = 'TTS_PLAYBACK_FAILED';
  static const String disposeFailed = 'TTS_DISPOSE_FAILED';
  static const String tempFileCreationFailed = 'TTS_TEMP_FILE_CREATION_FAILED';
  static const String tempFileCleanupFailed = 'TTS_TEMP_FILE_CLEANUP_FAILED';
}

/// Exception thrown when TTS engine is not available
class TTSEngineNotAvailableException extends AlouetteTTSError {
  /// The engine type that was not available
  final String engineType;

  TTSEngineNotAvailableException(
    String message,
    this.engineType, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.engineNotAvailable,
         details: {'engineType': engineType, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when a voice is not found
class TTSVoiceNotFoundException extends AlouetteTTSError {
  /// The voice ID that was not found
  final String voiceId;

  /// Available voices (if any)
  final List<String>? availableVoices;

  TTSVoiceNotFoundException(
    String message,
    this.voiceId, {
    this.availableVoices,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.voiceNotFound,
         details: {
           'voiceId': voiceId,
           if (availableVoices != null) 'availableVoices': availableVoices,
           ...?details,
         },
         originalError: originalError,
       );
}

/// Exception thrown when speech synthesis fails
class TTSSynthesisException extends AlouetteTTSError {
  /// The text that failed to synthesize
  final String text;

  /// The voice used for synthesis
  final String? voiceId;

  TTSSynthesisException(
    String message,
    this.text, {
    this.voiceId,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.synthesisFailure,
         details: {
           'textLength': text.length,
           if (voiceId != null) 'voiceId': voiceId,
           ...?details,
         },
         originalError: originalError,
       );
}

/// Exception thrown when audio playback fails
class TTSAudioPlaybackException extends AlouetteTTSError {
  /// The audio file path (if applicable)
  final String? audioPath;

  TTSAudioPlaybackException(
    String message, {
    this.audioPath,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.audioPlaybackError,
         details: {if (audioPath != null) 'audioPath': audioPath, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when platform is not supported
class TTSPlatformNotSupportedException extends AlouetteTTSError {
  /// The platform that is not supported
  final String platform;

  TTSPlatformNotSupportedException(
    String message,
    this.platform, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.platformNotSupported,
         details: {'platform': platform, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when TTS configuration is invalid
class TTSConfigurationException extends AlouetteTTSError {
  /// The configuration field that caused the error
  final String? field;

  TTSConfigurationException(
    String message, {
    this.field,
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.configurationError,
         details: {if (field != null) 'field': field, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when network operations fail
class TTSNetworkException extends AlouetteTTSError {
  TTSNetworkException(
    String message, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.networkError,
         details: details,
         originalError: originalError,
       );
}

/// Exception thrown when permissions are denied
class TTSPermissionDeniedException extends AlouetteTTSError {
  /// The permission that was denied
  final String permission;

  TTSPermissionDeniedException(
    String message,
    this.permission, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.permissionDenied,
         details: {'permission': permission, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when engine switching fails
class TTSEngineSwitchException extends AlouetteTTSError {
  /// The source engine
  final String fromEngine;

  /// The target engine
  final String toEngine;

  TTSEngineSwitchException(
    String message,
    this.fromEngine,
    this.toEngine, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.engineSwitchFailed,
         details: {'fromEngine': fromEngine, 'toEngine': toEngine, ...?details},
         originalError: originalError,
       );
}

/// Exception thrown when TTS initialization fails
class TTSInitializationException extends AlouetteTTSError {
  TTSInitializationException(
    String message, {
    Map<String, dynamic>? details,
    dynamic originalError,
  }) : super(
         message,
         TTSErrorCodes.initializationFailed,
         details: details,
         originalError: originalError,
       );
}
