import 'package:meta/meta.dart';
import '../enums/audio_format.dart';
import '../enums/tts_platform.dart';

/// Configuration class for Alouette TTS that works across all platforms
@immutable
class AlouetteTTSConfig {
  /// Speech rate (0.0 - 2.0, where 1.0 is normal speed)
  final double speechRate;
  
  /// Volume level (0.0 - 1.0, where 1.0 is maximum volume)
  final double volume;
  
  /// Pitch level (0.0 - 2.0, where 1.0 is normal pitch)
  final double pitch;
  
  /// BCP 47 language tag (e.g., 'en-US', 'es-ES')
  final String languageCode;
  
  /// Platform-specific voice identifier (optional)
  final String? voiceName;
  
  /// Audio format for synthesis output
  final AudioFormat audioFormat;
  
  /// Whether to wait for completion before returning
  final bool awaitCompletion;
  
  /// Whether SSML support is enabled
  final bool enableSSML;
  
  /// Platform-specific configuration options
  final Map<String, dynamic> platformSpecific;

  const AlouetteTTSConfig({
    this.speechRate = 1.0,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.languageCode = 'en-US',
    this.voiceName,
    this.audioFormat = AudioFormat.mp3,
    this.awaitCompletion = true,
    this.enableSSML = true,
    this.platformSpecific = const {},
  });

  /// Creates a default configuration
  factory AlouetteTTSConfig.defaultConfig() {
    return const AlouetteTTSConfig();
  }

  /// Creates a platform-optimized configuration
  factory AlouetteTTSConfig.forPlatform(TTSPlatform platform) {
    switch (platform) {
      case TTSPlatform.android:
        return const AlouetteTTSConfig(
          audioFormat: AudioFormat.mp3,
          platformSpecific: {
            'androidAudioAttributes': {
              'usage': 'media',
              'contentType': 'speech',
            },
          },
        );
      case TTSPlatform.ios:
        return const AlouetteTTSConfig(
          audioFormat: AudioFormat.wav,
          platformSpecific: {
            'iosAudioSession': {
              'category': 'playback',
              'mode': 'spokenAudio',
            },
          },
        );
      case TTSPlatform.web:
        return const AlouetteTTSConfig(
          audioFormat: AudioFormat.mp3,
          enableSSML: false,
          platformSpecific: {
            'webSpeechAPI': {
              'useNativeAPI': true,
            },
          },
        );
      case TTSPlatform.linux:
      case TTSPlatform.macos:
      case TTSPlatform.windows:
        return const AlouetteTTSConfig(
          audioFormat: AudioFormat.wav,
          enableSSML: true,
          platformSpecific: {
            'edgeTTS': {
              'useWebSocket': true,
              'connectionTimeout': 30000,
            },
          },
        );
    }
  }

  /// Validates the configuration values
  bool isValid() {
    if (speechRate < 0.0 || speechRate > 2.0) return false;
    if (volume < 0.0 || volume > 1.0) return false;
    if (pitch < 0.0 || pitch > 2.0) return false;
    if (languageCode.isEmpty) return false;
    
    // Validate language code format (basic BCP 47 check)
    final languageRegex = RegExp(r'^[a-z]{2,3}(-[A-Z]{2})?$');
    if (!languageRegex.hasMatch(languageCode)) return false;
    
    return true;
  }

  /// Converts to Flutter TTS configuration format
  Map<String, dynamic> toFlutterTTSConfig() {
    return {
      'speechRate': speechRate,
      'volume': volume,
      'pitch': pitch,
      'language': languageCode,
      'voice': voiceName,
      'awaitSpeakCompletion': awaitCompletion,
      'enableLogs': false,
      ...platformSpecific,
    };
  }

  /// Converts to Edge TTS configuration format
  Map<String, dynamic> toEdgeTTSConfig() {
    return {
      'voice': voiceName ?? _getDefaultEdgeVoiceForLanguage(languageCode),
      'rate': _convertRateToEdgeFormat(speechRate),
      'volume': _convertVolumeToEdgeFormat(volume),
      'pitch': _convertPitchToEdgeFormat(pitch),
      'outputFormat': _getEdgeAudioFormat(audioFormat),
      'enableSSML': enableSSML,
      'connectionTimeout': platformSpecific['edgeTTS']?['connectionTimeout'] ?? 30000,
      'useWebSocket': platformSpecific['edgeTTS']?['useWebSocket'] ?? true,
      ...platformSpecific,
    };
  }

  /// Helper method to get default Edge TTS voice for a language
  String _getDefaultEdgeVoiceForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en-us':
        return 'en-US-AriaNeural';
      case 'en-gb':
        return 'en-GB-SoniaNeural';
      case 'es-es':
        return 'es-ES-ElviraNeural';
      case 'fr-fr':
        return 'fr-FR-DeniseNeural';
      case 'de-de':
        return 'de-DE-KatjaNeural';
      case 'it-it':
        return 'it-IT-ElsaNeural';
      case 'pt-br':
        return 'pt-BR-FranciscaNeural';
      case 'ja-jp':
        return 'ja-JP-NanamiNeural';
      case 'ko-kr':
        return 'ko-KR-SunHiNeural';
      case 'zh-cn':
        return 'zh-CN-XiaoxiaoNeural';
      case 'ru-ru':
        return 'ru-RU-SvetlanaNeural';
      case 'el-gr':
        return 'el-GR-AthinaNeural';
      case 'ar-sa':
        return 'ar-SA-ZariyahNeural';
      case 'hi-in':
        return 'hi-IN-SwaraNeural';
      default:
        return 'en-US-AriaNeural';
    }
  }

  /// Converts speech rate to Edge TTS format
  String _convertRateToEdgeFormat(double rate) {
    // Edge TTS expects rate as percentage string
    final percentage = ((rate - 1.0) * 100).round();
    if (percentage >= 0) {
      return '+${percentage}%';
    } else {
      return '${percentage}%';
    }
  }

  /// Converts volume to Edge TTS format
  String _convertVolumeToEdgeFormat(double volume) {
    // Edge TTS expects volume as percentage string
    final percentage = (volume * 100).round();
    return '${percentage}%';
  }

  /// Converts pitch to Edge TTS format
  String _convertPitchToEdgeFormat(double pitch) {
    // Edge TTS expects pitch as percentage string
    final percentage = ((pitch - 1.0) * 100).round();
    if (percentage >= 0) {
      return '+${percentage}%';
    } else {
      return '${percentage}%';
    }
  }

  /// Gets Edge TTS audio format string
  String _getEdgeAudioFormat(AudioFormat format) {
    switch (format) {
      case AudioFormat.mp3:
        return 'audio-24khz-48kbitrate-mono-mp3';
      case AudioFormat.wav:
        return 'riff-24khz-16bit-mono-pcm';
      case AudioFormat.ogg:
        return 'ogg-24khz-16bit-mono-opus';
    }
  }

  /// Creates a copy with modified values
  AlouetteTTSConfig copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
    String? languageCode,
    String? voiceName,
    AudioFormat? audioFormat,
    bool? awaitCompletion,
    bool? enableSSML,
    Map<String, dynamic>? platformSpecific,
  }) {
    return AlouetteTTSConfig(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      languageCode: languageCode ?? this.languageCode,
      voiceName: voiceName ?? this.voiceName,
      audioFormat: audioFormat ?? this.audioFormat,
      awaitCompletion: awaitCompletion ?? this.awaitCompletion,
      enableSSML: enableSSML ?? this.enableSSML,
      platformSpecific: platformSpecific ?? this.platformSpecific,
    );
  }

  /// Converts to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'speechRate': speechRate,
      'volume': volume,
      'pitch': pitch,
      'languageCode': languageCode,
      'voiceName': voiceName,
      'audioFormat': audioFormat.name,
      'awaitCompletion': awaitCompletion,
      'enableSSML': enableSSML,
      'platformSpecific': platformSpecific,
    };
  }

  /// Creates an instance from a Map
  factory AlouetteTTSConfig.fromMap(Map<String, dynamic> map) {
    return AlouetteTTSConfig(
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 1.0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 1.0,
      languageCode: map['languageCode'] as String? ?? 'en-US',
      voiceName: map['voiceName'] as String?,
      audioFormat: AudioFormat.values.firstWhere(
        (format) => format.name == map['audioFormat'],
        orElse: () => AudioFormat.mp3,
      ),
      awaitCompletion: map['awaitCompletion'] as bool? ?? true,
      enableSSML: map['enableSSML'] as bool? ?? true,
      platformSpecific: Map<String, dynamic>.from(map['platformSpecific'] as Map? ?? {}),
    );
  }

  /// Creates an instance from JSON string
  factory AlouetteTTSConfig.fromJson(String json) {
    // In a real implementation, you'd use dart:convert
    // For now, we'll return a default config
    return AlouetteTTSConfig.defaultConfig();
  }

  /// Converts to JSON string
  String toJson() {
    // In a real implementation, you'd use dart:convert
    // For now, we'll return the string representation
    return toMap().toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AlouetteTTSConfig &&
        other.speechRate == speechRate &&
        other.volume == volume &&
        other.pitch == pitch &&
        other.languageCode == languageCode &&
        other.voiceName == voiceName &&
        other.audioFormat == audioFormat &&
        other.awaitCompletion == awaitCompletion &&
        other.enableSSML == enableSSML &&
        _mapEquals(other.platformSpecific, platformSpecific);
  }

  @override
  int get hashCode {
    return Object.hash(
      speechRate,
      volume,
      pitch,
      languageCode,
      voiceName,
      audioFormat,
      awaitCompletion,
      enableSSML,
      platformSpecific,
    );
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'AlouetteTTSConfig('
        'speechRate: $speechRate, '
        'volume: $volume, '
        'pitch: $pitch, '
        'languageCode: $languageCode, '
        'voiceName: $voiceName, '
        'audioFormat: $audioFormat, '
        'awaitCompletion: $awaitCompletion, '
        'enableSSML: $enableSSML, '
        'platformSpecific: $platformSpecific)';
  }
}