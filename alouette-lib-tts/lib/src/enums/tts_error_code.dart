/// Enumeration of standardized TTS error codes
enum TTSErrorCode {
  // Initialization errors (1000-1099)
  initializationFailed('INIT_001', 'TTS service initialization failed'),
  platformNotSupported('INIT_002', 'Platform not supported'),
  dependencyMissing('INIT_003', 'Required dependency missing'),
  permissionDenied('INIT_004', 'Required permissions not granted'),

  // Configuration errors (1100-1199)
  invalidConfiguration('CONFIG_001', 'Invalid configuration provided'),
  invalidVoice('CONFIG_002', 'Invalid voice configuration'),
  invalidAudioFormat('CONFIG_003', 'Invalid audio format specified'),
  invalidSpeechRate('CONFIG_004', 'Invalid speech rate value'),
  invalidPitch('CONFIG_005', 'Invalid pitch value'),
  invalidVolume('CONFIG_006', 'Invalid volume value'),

  // Synthesis errors (1200-1299)
  synthesisTimeout('SYNTH_001', 'Synthesis operation timed out'),
  textTooLong('SYNTH_002', 'Text exceeds maximum length'),
  ssmlParsingError('SYNTH_003', 'SSML parsing failed'),
  synthesisEngineError('SYNTH_004', 'TTS engine synthesis error'),
  audioGenerationFailed('SYNTH_005', 'Audio generation failed'),

  // Network errors (1300-1399)
  networkTimeout('NET_001', 'Network operation timed out'),
  connectionFailed('NET_002', 'Failed to establish connection'),
  serverError('NET_003', 'Server returned error'),
  rateLimitExceeded('NET_004', 'Rate limit exceeded'),
  authenticationFailed('NET_005', 'Authentication failed'),

  // Voice errors (1400-1499)
  voiceNotFound('VOICE_001', 'Requested voice not found'),
  voiceNotAvailable('VOICE_002', 'Voice not available on platform'),
  voiceLoadFailed('VOICE_003', 'Failed to load voice'),
  languageNotSupported('VOICE_004', 'Language not supported'),

  // File operation errors (1500-1599)
  fileNotFound('FILE_001', 'File not found'),
  fileAccessDenied('FILE_002', 'File access denied'),
  diskSpaceInsufficient('FILE_003', 'Insufficient disk space'),
  fileFormatUnsupported('FILE_004', 'File format not supported'),
  fileWriteFailed('FILE_005', 'Failed to write file'),

  // Playback errors (1600-1699)
  playbackFailed('PLAY_001', 'Audio playback failed'),
  audioDeviceError('PLAY_002', 'Audio device error'),
  audioFormatError('PLAY_003', 'Audio format error'),
  playbackInterrupted('PLAY_004', 'Playback interrupted'),

  // Platform-specific errors (1700-1799)
  edgeTtsUnavailable('PLATFORM_001', 'Edge TTS not available'),
  flutterTtsError('PLATFORM_002', 'Flutter TTS error'),
  webSpeechApiError('PLATFORM_003', 'Web Speech API error'),
  androidTtsError('PLATFORM_004', 'Android TTS error'),
  iosTtsError('PLATFORM_005', 'iOS TTS error'),

  // General errors (1900-1999)
  unknown('UNKNOWN_001', 'Unknown error occurred'),
  operationCancelled('GENERAL_001', 'Operation was cancelled'),
  resourceUnavailable('GENERAL_002', 'Required resource unavailable'),
  internalError('GENERAL_003', 'Internal system error');

  const TTSErrorCode(this.code, this.description);

  /// Unique error code identifier
  final String code;

  /// Human-readable error description
  final String description;

  /// Returns true if this error is typically retryable
  bool get isRetryable {
    switch (this) {
      case TTSErrorCode.networkTimeout:
      case TTSErrorCode.connectionFailed:
      case TTSErrorCode.serverError:
      case TTSErrorCode.rateLimitExceeded:
      case TTSErrorCode.synthesisTimeout:
      case TTSErrorCode.audioDeviceError:
      case TTSErrorCode.playbackInterrupted:
        return true;
      default:
        return false;
    }
  }

  /// Returns the category of this error code
  TTSErrorCategory get category {
    final prefix = code.split('_').first;
    switch (prefix) {
      case 'INIT':
        return TTSErrorCategory.initialization;
      case 'CONFIG':
        return TTSErrorCategory.configuration;
      case 'SYNTH':
        return TTSErrorCategory.synthesis;
      case 'NET':
        return TTSErrorCategory.network;
      case 'VOICE':
        return TTSErrorCategory.voice;
      case 'FILE':
        return TTSErrorCategory.file;
      case 'PLAY':
        return TTSErrorCategory.playback;
      case 'PLATFORM':
        return TTSErrorCategory.platform;
      case 'GENERAL':
      case 'UNKNOWN':
      default:
        return TTSErrorCategory.general;
    }
  }

  /// Maps platform-specific error codes to standardized codes
  static TTSErrorCode fromPlatformError(String platformError, String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return _mapAndroidError(platformError);
      case 'ios':
        return _mapIosError(platformError);
      case 'web':
        return _mapWebError(platformError);
      case 'edge-tts':
        return _mapEdgeTtsError(platformError);
      case 'flutter-tts':
        return _mapFlutterTtsError(platformError);
      default:
        return TTSErrorCode.unknown;
    }
  }

  static TTSErrorCode _mapAndroidError(String error) {
    if (error.contains('ERROR_NETWORK')) return TTSErrorCode.networkTimeout;
    if (error.contains('ERROR_SYNTHESIS'))
      return TTSErrorCode.synthesisEngineError;
    if (error.contains('ERROR_SERVICE'))
      return TTSErrorCode.initializationFailed;
    if (error.contains('ERROR_OUTPUT'))
      return TTSErrorCode.audioGenerationFailed;
    if (error.contains('ERROR_NETWORK_TIMEOUT'))
      return TTSErrorCode.networkTimeout;
    return TTSErrorCode.androidTtsError;
  }

  static TTSErrorCode _mapIosError(String error) {
    if (error.contains('AVSpeechSynthesisVoice'))
      return TTSErrorCode.voiceNotFound;
    if (error.contains('AVAudioSession')) return TTSErrorCode.audioDeviceError;
    if (error.contains('synthesis')) return TTSErrorCode.synthesisEngineError;
    return TTSErrorCode.iosTtsError;
  }

  static TTSErrorCode _mapWebError(String error) {
    if (error.contains('not-allowed')) return TTSErrorCode.permissionDenied;
    if (error.contains('network')) return TTSErrorCode.networkTimeout;
    if (error.contains('synthesis-failed'))
      return TTSErrorCode.synthesisEngineError;
    if (error.contains('voice-unavailable'))
      return TTSErrorCode.voiceNotAvailable;
    return TTSErrorCode.webSpeechApiError;
  }

  static TTSErrorCode _mapEdgeTtsError(String error) {
    if (error.contains('WebSocket')) return TTSErrorCode.connectionFailed;
    if (error.contains('timeout')) return TTSErrorCode.networkTimeout;
    if (error.contains('voice')) return TTSErrorCode.voiceNotFound;
    if (error.contains('synthesis')) return TTSErrorCode.synthesisEngineError;
    return TTSErrorCode.edgeTtsUnavailable;
  }

  static TTSErrorCode _mapFlutterTtsError(String error) {
    if (error.contains('init')) return TTSErrorCode.initializationFailed;
    if (error.contains('voice')) return TTSErrorCode.voiceNotFound;
    if (error.contains('speak')) return TTSErrorCode.synthesisEngineError;
    return TTSErrorCode.flutterTtsError;
  }
}

/// Categories of TTS errors
enum TTSErrorCategory {
  initialization,
  configuration,
  synthesis,
  network,
  voice,
  file,
  playback,
  platform,
  general;

  /// Returns the display name for this category
  String get displayName {
    switch (this) {
      case TTSErrorCategory.initialization:
        return 'Initialization';
      case TTSErrorCategory.configuration:
        return 'Configuration';
      case TTSErrorCategory.synthesis:
        return 'Synthesis';
      case TTSErrorCategory.network:
        return 'Network';
      case TTSErrorCategory.voice:
        return 'Voice';
      case TTSErrorCategory.file:
        return 'File Operation';
      case TTSErrorCategory.playback:
        return 'Playback';
      case TTSErrorCategory.platform:
        return 'Platform';
      case TTSErrorCategory.general:
        return 'General';
    }
  }
}
