/// TTS Configuration class
///
/// Defines configuration parameters for TTS operations including
/// voice settings, output preferences, and feature toggles.
class TTSConfig {
  /// Default voice to use for synthesis
  final String defaultVoice;

  /// Default audio format (mp3, wav, etc.)
  final String defaultFormat;

  /// Default speech rate (0.1 to 3.0)
  final double defaultRate;

  /// Default pitch (0.5 to 2.0)
  final double defaultPitch;

  /// Default volume (0.0 to 1.0)
  final double defaultVolume;

  /// Current speech rate (0.1 to 3.0)
  final double speechRate;

  /// Current pitch (0.5 to 2.0)
  final double pitch;

  /// Current volume (0.0 to 1.0)
  final double volume;

  /// Directory for output files
  final String outputDirectory;

  /// Whether to enable audio caching
  final bool enableCaching;

  /// Whether to enable automatic playback after synthesis
  final bool enablePlayback;

  const TTSConfig({
    this.defaultVoice = 'en-US-AriaNeural',
    this.defaultFormat = 'mp3',
    this.defaultRate = 1.0,
    this.defaultPitch = 1.0,
    this.defaultVolume = 1.0,
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.outputDirectory = 'output',
    this.enableCaching = true,
    this.enablePlayback = false,
  });

  /// Create TTSConfig from JSON map
  ///
  /// Provides default values for missing keys and validates input types.
  factory TTSConfig.fromJson(Map<String, dynamic> json) {
    return TTSConfig(
      defaultVoice: _validateString(json['defaultVoice'], 'en-US-AriaNeural'),
      defaultFormat: _validateString(json['defaultFormat'], 'mp3'),
      defaultRate: _validateDouble(json['defaultRate'], 1.0),
      defaultPitch: _validateDouble(json['defaultPitch'], 1.0),
      defaultVolume: _validateDouble(json['defaultVolume'], 1.0),
      speechRate: _validateDouble(json['speechRate'], 1.0),
      pitch: _validateDouble(json['pitch'], 1.0),
      volume: _validateDouble(json['volume'], 1.0),
      outputDirectory: _validateString(json['outputDirectory'], 'output'),
      enableCaching: _validateBool(json['enableCaching'], true),
      enablePlayback: _validateBool(json['enablePlayback'], false),
    );
  }



  /// Convert TTSConfig to JSON map
  Map<String, dynamic> toJson() {
    return {
      'defaultVoice': defaultVoice,
      'defaultFormat': defaultFormat,
      'defaultRate': defaultRate,
      'defaultPitch': defaultPitch,
      'defaultVolume': defaultVolume,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'outputDirectory': outputDirectory,
      'enableCaching': enableCaching,
      'enablePlayback': enablePlayback,
    };
  }



  /// Create a copy of this config with updated values
  TTSConfig copyWith({
    String? defaultVoice,
    String? defaultFormat,
    double? defaultRate,
    double? defaultPitch,
    double? defaultVolume,
    double? speechRate,
    double? pitch,
    double? volume,
    String? outputDirectory,
    bool? enableCaching,
    bool? enablePlayback,
  }) {
    return TTSConfig(
      defaultVoice: defaultVoice ?? this.defaultVoice,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultRate: defaultRate ?? this.defaultRate,
      defaultPitch: defaultPitch ?? this.defaultPitch,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      enableCaching: enableCaching ?? this.enableCaching,
      enablePlayback: enablePlayback ?? this.enablePlayback,
    );
  }

  /// Validate configuration parameters
  ///
  /// Returns a list of validation errors, empty if valid.
  List<String> validate() {
    final errors = <String>[];

    if (defaultVoice.isEmpty) {
      errors.add('defaultVoice cannot be empty');
    }

    if (defaultFormat.isEmpty) {
      errors.add('defaultFormat cannot be empty');
    }

    if (!_isValidFormat(defaultFormat)) {
      errors.add('defaultFormat must be one of: mp3, wav, ogg, flac');
    }

    if (!_isValidRate(defaultRate)) {
      errors.add('defaultRate must be a number between 0.1 and 3.0');
    }

    if (!_isValidPitch(defaultPitch)) {
      errors.add('defaultPitch must be a number between 0.5 and 2.0');
    }

    if (!_isValidVolume(defaultVolume)) {
      errors.add('defaultVolume must be a number between 0.0 and 1.0');
    }

    if (!_isValidRate(speechRate)) {
      errors.add('speechRate must be a number between 0.1 and 3.0');
    }

    if (!_isValidPitch(pitch)) {
      errors.add('pitch must be a number between 0.5 and 2.0');
    }

    if (!_isValidVolume(volume)) {
      errors.add('volume must be a number between 0.0 and 1.0');
    }

    if (outputDirectory.isEmpty) {
      errors.add('outputDirectory cannot be empty');
    }

    return errors;
  }

  /// Check if this config is valid
  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TTSConfig &&
        other.defaultVoice == defaultVoice &&
        other.defaultFormat == defaultFormat &&
        other.defaultRate == defaultRate &&
        other.defaultPitch == defaultPitch &&
        other.defaultVolume == defaultVolume &&
        other.speechRate == speechRate &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.outputDirectory == outputDirectory &&
        other.enableCaching == enableCaching &&
        other.enablePlayback == enablePlayback;
  }

  @override
  int get hashCode {
    return Object.hash(
      defaultVoice,
      defaultFormat,
      defaultRate,
      defaultPitch,
      defaultVolume,
      speechRate,
      pitch,
      volume,
      outputDirectory,
      enableCaching,
      enablePlayback,
    );
  }

  @override
  String toString() {
    return 'TTSConfig('
        'defaultVoice: $defaultVoice, '
        'defaultFormat: $defaultFormat, '
        'defaultRate: $defaultRate, '
        'defaultPitch: $defaultPitch, '
        'defaultVolume: $defaultVolume, '
        'speechRate: $speechRate, '
        'pitch: $pitch, '
        'volume: $volume, '
        'outputDirectory: $outputDirectory, '
        'enableCaching: $enableCaching, '
        'enablePlaybook: $enablePlayback'
        ')';
  }

  // Private validation helpers
  static String _validateString(dynamic value, String defaultValue) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return defaultValue;
  }

  static bool _validateBool(dynamic value, bool defaultValue) {
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }

  static double _validateDouble(dynamic value, double defaultValue) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return defaultValue;
  }

  static bool _isValidFormat(String format) {
    const validFormats = {'mp3', 'wav', 'ogg', 'flac'};
    return validFormats.contains(format.toLowerCase());
  }

  static bool _isValidRate(double rate) {
    return rate >= 0.1 && rate <= 3.0;
  }

  static bool _isValidPitch(double pitch) {
    return pitch >= 0.5 && pitch <= 2.0;
  }

  static bool _isValidVolume(double volume) {
    return volume >= 0.0 && volume <= 1.0;
  }
}
