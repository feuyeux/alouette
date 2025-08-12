/// TTS configuration model containing all settings for text-to-speech
class TTSConfig {
  /// Speech rate (0.0 to 2.0, where 1.0 is normal speed)
  final double speechRate;
  
  /// Volume level (0.0 to 1.0)
  final double volume;
  
  /// Pitch level (0.0 to 2.0, where 1.0 is normal pitch)
  final double pitch;
  
  /// Language code for TTS (e.g., 'en-US', 'zh-CN')
  final String languageCode;
  
  /// Whether to await completion of speech before returning
  final bool awaitCompletion;
  
  /// Platform-specific configuration options
  final Map<String, dynamic>? platformSpecific;

  const TTSConfig({
    required this.speechRate,
    required this.volume,
    required this.pitch,
    required this.languageCode,
    this.awaitCompletion = true,
    this.platformSpecific,
  });

  /// Create a default TTS configuration
  factory TTSConfig.defaultConfig() {
    return const TTSConfig(
      speechRate: 1.0,
      volume: 1.0,
      pitch: 1.0,
      languageCode: 'en-US',
      awaitCompletion: true,
    );
  }

  /// Create a copy of this TTSConfig with optionally updated values
  TTSConfig copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
    String? languageCode,
    bool? awaitCompletion,
    Map<String, dynamic>? platformSpecific,
  }) {
    return TTSConfig(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      languageCode: languageCode ?? this.languageCode,
      awaitCompletion: awaitCompletion ?? this.awaitCompletion,
      platformSpecific: platformSpecific ?? this.platformSpecific,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'speechRate': speechRate,
      'volume': volume,
      'pitch': pitch,
      'languageCode': languageCode,
      'awaitCompletion': awaitCompletion,
      'platformSpecific': platformSpecific,
    };
  }

  /// Create from JSON representation
  factory TTSConfig.fromJson(Map<String, dynamic> json) {
    return TTSConfig(
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      languageCode: json['languageCode'] as String? ?? 'en-US',
      awaitCompletion: json['awaitCompletion'] as bool? ?? true,
      platformSpecific: json['platformSpecific'] as Map<String, dynamic>?,
    );
  }

  /// Validate configuration values
  bool isValid() {
    return speechRate >= 0.0 && speechRate <= 2.0 &&
           volume >= 0.0 && volume <= 1.0 &&
           pitch >= 0.0 && pitch <= 2.0 &&
           languageCode.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TTSConfig &&
        other.speechRate == speechRate &&
        other.volume == volume &&
        other.pitch == pitch &&
        other.languageCode == languageCode &&
        other.awaitCompletion == awaitCompletion;
  }

  @override
  int get hashCode => Object.hash(
    speechRate,
    volume,
    pitch,
    languageCode,
    awaitCompletion,
  );

  @override
  String toString() {
    return 'TTSConfig(speechRate: $speechRate, volume: $volume, pitch: $pitch, '
           'languageCode: $languageCode, awaitCompletion: $awaitCompletion)';
  }
}