import 'package:flutter/services.dart';

import '../../enums/tts_platform.dart';
import '../../models/alouette_tts_config.dart';
import '../../exceptions/tts_exceptions.dart';

/// Abstract base class for platform-specific audio management
abstract class PlatformAudioManager {
  /// Initializes the audio manager for the specific platform
  Future<void> initialize(AlouetteTTSConfig config);

  /// Configures audio session settings
  Future<void> configureAudioSession(Map<String, dynamic> settings);

  /// Prepares audio for synthesis
  Future<void> prepareForSynthesis();

  /// Cleans up audio resources
  Future<void> cleanup();

  /// Gets platform-specific audio capabilities
  Map<String, dynamic> getAudioCapabilities();

  /// Factory method to create appropriate audio manager
  static PlatformAudioManager create(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
        return AndroidAudioManager();
      case TTSPlatform.ios:
        return IOSAudioManager();
      case TTSPlatform.web:
        return WebAudioManager();
      default:
        return DefaultAudioManager();
    }
  }
}

/// Android-specific audio session management
class AndroidAudioManager extends PlatformAudioManager {
  static const MethodChannel _channel =
      MethodChannel('alouette_tts/android_audio');

  bool _isInitialized = false;
  Map<String, dynamic>? _currentSettings;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final androidConfig = config.platformSpecific['androidAudioAttributes']
          as Map<String, dynamic>?;

      if (androidConfig != null) {
        await _configureAndroidAudioAttributes(androidConfig);
      } else {
        await _configureDefaultAndroidAudio();
      }

      _isInitialized = true;
    } catch (e) {
      throw TTSPlatformException(
        'Failed to initialize Android audio manager: $e',
        TTSPlatform.android,
      );
    }
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    if (!_isInitialized) {
      throw TTSException('Audio manager not initialized');
    }

    try {
      _currentSettings = settings;

      // Configure Android AudioAttributes
      await _channel.invokeMethod('configureAudioAttributes', {
        'usage': settings['usage'] ?? 'media',
        'contentType': settings['contentType'] ?? 'speech',
        'flags': settings['flags'] ?? [],
      });

      // Configure AudioManager settings
      await _channel.invokeMethod('configureAudioManager', {
        'streamType': settings['streamType'] ?? 'music',
        'mode': settings['mode'] ?? 'normal',
      });
    } catch (e) {
      throw TTSPlatformException(
        'Failed to configure Android audio session: $e',
        TTSPlatform.android,
      );
    }
  }

  @override
  Future<void> prepareForSynthesis() async {
    if (!_isInitialized) return;

    try {
      // Request audio focus
      await _channel.invokeMethod('requestAudioFocus', {
        'focusGain': 'transient_may_duck',
        'streamType': 'music',
      });

      // Set audio routing preferences
      await _channel.invokeMethod('setAudioRouting', {
        'preferSpeaker': true,
        'allowBluetooth': true,
      });
    } catch (e) {
      // Continue without audio focus if it fails
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) return;

    try {
      // Abandon audio focus
      await _channel.invokeMethod('abandonAudioFocus');

      _isInitialized = false;
      _currentSettings = null;
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Map<String, dynamic> getAudioCapabilities() {
    return {
      'supportsAudioFocus': true,
      'supportsAudioAttributes': true,
      'supportsBluetoothRouting': true,
      'supportsSpeakerRouting': true,
      'supportsVolumeControl': true,
      'maxConcurrentStreams': 10,
      'supportedSampleRates': [8000, 16000, 22050, 44100, 48000],
      'supportedChannels': [1, 2], // Mono and stereo
    };
  }

  Future<void> _configureAndroidAudioAttributes(
      Map<String, dynamic> config) async {
    await _channel.invokeMethod('setAudioAttributes', {
      'usage': config['usage'] ?? 'media',
      'contentType': config['contentType'] ?? 'speech',
      'flags': config['flags'] ?? [],
    });
  }

  Future<void> _configureDefaultAndroidAudio() async {
    await _configureAndroidAudioAttributes({
      'usage': 'media',
      'contentType': 'speech',
      'flags': [],
    });
  }
}

/// iOS-specific audio session management
class IOSAudioManager extends PlatformAudioManager {
  static const MethodChannel _channel = MethodChannel('alouette_tts/ios_audio');

  bool _isInitialized = false;
  String? _currentCategory;
  String? _currentMode;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final iosConfig =
          config.platformSpecific['iosAudioSession'] as Map<String, dynamic>?;

      if (iosConfig != null) {
        await _configureIOSAudioSession(iosConfig);
      } else {
        await _configureDefaultIOSAudio();
      }

      _isInitialized = true;
    } catch (e) {
      throw TTSPlatformException(
        'Failed to initialize iOS audio manager: $e',
        TTSPlatform.ios,
      );
    }
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    if (!_isInitialized) {
      throw TTSException('Audio manager not initialized');
    }

    try {
      final category = settings['category'] as String? ?? 'playback';
      final mode = settings['mode'] as String? ?? 'spokenAudio';
      final options = settings['options'] as List<String>? ?? [];

      await _channel.invokeMethod('setAudioSessionCategory', {
        'category': category,
        'mode': mode,
        'options': options,
      });

      _currentCategory = category;
      _currentMode = mode;
    } catch (e) {
      throw TTSPlatformException(
        'Failed to configure iOS audio session: $e',
        TTSPlatform.ios,
      );
    }
  }

  @override
  Future<void> prepareForSynthesis() async {
    if (!_isInitialized) return;

    try {
      // Activate audio session
      await _channel.invokeMethod('activateAudioSession');

      // Configure for speech synthesis
      await _channel.invokeMethod('prepareForSpeech', {
        'duckOthers': true,
        'interruptSpokenAudio': false,
      });
    } catch (e) {
      // Continue without audio session activation if it fails
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) return;

    try {
      // Deactivate audio session
      await _channel.invokeMethod('deactivateAudioSession');

      _isInitialized = false;
      _currentCategory = null;
      _currentMode = null;
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Map<String, dynamic> getAudioCapabilities() {
    return {
      'supportsAudioSession': true,
      'supportsInterruption': true,
      'supportsRouteChange': true,
      'supportsSilenceSecondaryAudio': true,
      'supportsVolumeControl': true,
      'maxConcurrentStreams': 5,
      'supportedSampleRates': [8000, 16000, 22050, 44100, 48000],
      'supportedChannels': [1, 2], // Mono and stereo
      'availableCategories': [
        'ambient',
        'soloAmbient',
        'playback',
        'record',
        'playAndRecord',
        'multiRoute'
      ],
      'availableModes': [
        'default',
        'voiceChat',
        'gameChat',
        'videoRecording',
        'measurement',
        'moviePlayback',
        'videoChat',
        'spokenAudio'
      ],
    };
  }

  Future<void> _configureIOSAudioSession(Map<String, dynamic> config) async {
    await _channel.invokeMethod('setAudioSessionCategory', {
      'category': config['category'] ?? 'playback',
      'mode': config['mode'] ?? 'spokenAudio',
      'options': config['options'] ?? [],
    });
  }

  Future<void> _configureDefaultIOSAudio() async {
    await _configureIOSAudioSession({
      'category': 'playback',
      'mode': 'spokenAudio',
      'options': ['duckOthers'],
    });
  }
}

/// Web-specific audio context handling
class WebAudioManager extends PlatformAudioManager {
  bool _isInitialized = false;
  Map<String, dynamic>? _audioContext;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final webConfig =
          config.platformSpecific['webSpeechAPI'] as Map<String, dynamic>?;

      if (webConfig != null) {
        await _configureWebAudio(webConfig);
      } else {
        await _configureDefaultWebAudio();
      }

      _isInitialized = true;
    } catch (e) {
      throw TTSPlatformException(
        'Failed to initialize Web audio manager: $e',
        TTSPlatform.web,
      );
    }
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    if (!_isInitialized) {
      throw TTSException('Audio manager not initialized');
    }

    try {
      _audioContext = settings;

      // Web audio configuration is limited
      // Most settings are handled by the browser
    } catch (e) {
      throw TTSPlatformException(
        'Failed to configure Web audio context: $e',
        TTSPlatform.web,
      );
    }
  }

  @override
  Future<void> prepareForSynthesis() async {
    if (!_isInitialized) return;

    try {
      // Web Speech API preparation
      // Check if user gesture is required
      await _ensureUserGesture();
    } catch (e) {
      // Continue without user gesture check if it fails
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) return;

    try {
      _isInitialized = false;
      _audioContext = null;
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Map<String, dynamic> getAudioCapabilities() {
    return {
      'supportsWebSpeechAPI': true,
      'requiresUserGesture': true,
      'supportsVolumeControl': true,
      'supportsPitchControl': true,
      'supportsRateControl': true,
      'maxConcurrentStreams': 1, // Web Speech API limitation
      'supportedSampleRates': [22050, 44100], // Browser dependent
      'supportedChannels': [1, 2], // Mono and stereo
      'browserLimitations': {
        'maxTextLength': 2000,
        'requiresHTTPS': true,
        'autoplayPolicy': 'user-gesture-required',
      },
    };
  }

  Future<void> _configureWebAudio(Map<String, dynamic> config) async {
    // Web-specific audio configuration
    final useNativeAPI = config['useNativeAPI'] as bool? ?? true;

    if (useNativeAPI) {
      // Use Web Speech API
      _audioContext = {
        'useNativeAPI': true,
        'fallbackToPolyfill': config['fallbackToPolyfill'] ?? false,
      };
    }
  }

  Future<void> _configureDefaultWebAudio() async {
    await _configureWebAudio({
      'useNativeAPI': true,
      'fallbackToPolyfill': false,
    });
  }

  Future<void> _ensureUserGesture() async {
    // In a real implementation, this would check if a user gesture
    // has occurred to enable audio playback
    // For now, we'll assume it's handled by the calling code
  }
}

/// Default audio manager for unsupported platforms
class DefaultAudioManager extends PlatformAudioManager {
  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    // No-op for default implementation
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    // No-op for default implementation
  }

  @override
  Future<void> prepareForSynthesis() async {
    // No-op for default implementation
  }

  @override
  Future<void> cleanup() async {
    // No-op for default implementation
  }

  @override
  Map<String, dynamic> getAudioCapabilities() {
    return {
      'supportsBasicPlayback': true,
      'platformSpecificFeatures': false,
      'maxConcurrentStreams': 1,
      'supportedSampleRates': [44100],
      'supportedChannels': [1, 2],
    };
  }
}
