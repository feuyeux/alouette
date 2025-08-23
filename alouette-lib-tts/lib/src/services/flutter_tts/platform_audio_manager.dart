import 'package:flutter/services.dart';

import '../../enums/tts_platform.dart';
import '../../models/alouette_tts_config.dart';
import '../../exceptions/tts_exceptions.dart';

/// Abstract base class for platform-specific audio management.
abstract class PlatformAudioManager {
  Future<void> initialize(AlouetteTTSConfig config);
  Future<void> configureAudioSession(Map<String, dynamic> settings);
  Future<void> prepareForSynthesis();
  Future<void> cleanup();
  Map<String, dynamic> getAudioCapabilities();

  /// Factory for creating platform-specific implementations.
  static PlatformAudioManager create(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
        return AndroidAudioManager();
      case TTSPlatform.ios:
        return IOSAudioManager();
      default:
        throw UnimplementedError('Platform $platform not supported');
    }
  }
}

/// Android-specific audio session management.
class AndroidAudioManager extends PlatformAudioManager {
  static const MethodChannel _channel = MethodChannel('alouette_tts/android_audio');

  bool _isInitialized = false;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final androidConfig = config.platformSpecific['androidAudioAttributes'] as Map<String, dynamic>?;

      if (androidConfig != null) {
        await _configureAndroidAudioAttributes(androidConfig);
      } else {
        await _configureDefaultAndroidAudio();
      }

      _isInitialized = true;
    } catch (e) {
      throw TTSPlatformException('Failed to initialize Android audio manager: $e', TTSPlatform.android);
    }
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    if (!_isInitialized) throw TTSException('Audio manager not initialized');

    try {

      await _channel.invokeMethod('configureAudioAttributes', {
        'usage': settings['usage'] ?? 'media',
        'contentType': settings['contentType'] ?? 'speech',
        'flags': settings['flags'] ?? [],
      });

      await _channel.invokeMethod('configureAudioManager', {
        'streamType': settings['streamType'] ?? 'music',
        'mode': settings['mode'] ?? 'normal',
      });
    } catch (e) {
      throw TTSPlatformException('Failed to configure Android audio session: $e', TTSPlatform.android);
    }
  }

  @override
  Future<void> prepareForSynthesis() async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('requestAudioFocus', {
        'focusGain': 'transient_may_duck',
        'streamType': 'music',
      });

      await _channel.invokeMethod('setAudioRouting', {
        'preferSpeaker': true,
        'allowBluetooth': true,
      });
    } catch (_) {
      // Non-fatal: continue without audio focus.
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('abandonAudioFocus');
      _isInitialized = false;
    } catch (_) {
      // Ignore cleanup errors.
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
      'supportedChannels': [1, 2],
    };
  }

  Future<void> _configureAndroidAudioAttributes(Map<String, dynamic> config) async {
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

/// iOS-specific audio session management.
class IOSAudioManager extends PlatformAudioManager {
  static const MethodChannel _channel = MethodChannel('alouette_tts/ios_audio');
  bool _isInitialized = false;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final iosConfig = config.platformSpecific['iosAudioSession'] as Map<String, dynamic>?;
      if (iosConfig != null) {
        await _configureIOSAudioSession(iosConfig);
      } else {
        await _configureDefaultIOSAudio();
      }
      _isInitialized = true;
    } catch (e) {
      throw TTSPlatformException('Failed to initialize iOS audio manager: $e', TTSPlatform.ios);
    }
  }

  @override
  Future<void> configureAudioSession(Map<String, dynamic> settings) async {
    if (!_isInitialized) throw TTSException('Audio manager not initialized');
    try {
      final category = settings['category'] as String? ?? 'playback';
      final mode = settings['mode'] as String? ?? 'spokenAudio';
      final options = settings['options'] as List<String>? ?? [];

      await _channel.invokeMethod('setAudioSessionCategory', {
        'category': category,
        'mode': mode,
        'options': options,
      });

    } catch (e) {
      throw TTSPlatformException('Failed to configure iOS audio session: $e', TTSPlatform.ios);
    }
  }

  @override
  Future<void> prepareForSynthesis() async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('activateAudioSession');
      await _channel.invokeMethod('prepareForSpeech', {
        'duckOthers': true,
        'interruptSpokenAudio': false,
      });
    } catch (_) {
      // Non-fatal; continue.
    }
  }

  @override
  Future<void> cleanup() async {
    if (!_isInitialized) return;
    try {
      await _channel.invokeMethod('deactivateAudioSession');
      _isInitialized = false;
    } catch (_) {
      // Ignore cleanup errors.
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
      'supportedChannels': [1, 2],
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

/// Default audio manager for unsupported platforms.
}

/// Default audio manager for unsupported platforms.
class DefaultAudioManager extends PlatformAudioManager {
  bool _isInitialized = false;

  @override
  Future<void> initialize(AlouetteTTSConfig config) async {
    try {
      final iosConfig = config.platformSpecific['iosAudioSession'] as Map<String, dynamic>?;
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

            await IOSAudioManager._channel.invokeMethod('setAudioSessionCategory', {
              'category': category,
              'mode': mode,
              'options': options,
            });

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
            await IOSAudioManager._channel.invokeMethod('activateAudioSession');

            // Configure for speech synthesis
            await IOSAudioManager._channel.invokeMethod('prepareForSpeech', {
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
            await IOSAudioManager._channel.invokeMethod('deactivateAudioSession');

            _isInitialized = false;
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
          await IOSAudioManager._channel.invokeMethod('setAudioSessionCategory', {
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
