/// TTS Request Model
///
/// Unified request object for all TTS operations.
/// Encapsulates all parameters needed for text-to-speech synthesis and playback.
class TTSRequest {
  /// Text to synthesize
  final String text;

  /// Voice name/ID to use (optional, auto-select if null)
  final String? voiceName;

  /// Language code (optional, used for voice selection)
  final String? languageCode;

  /// Language name (optional, used for voice selection)
  final String? languageName;

  /// Audio format (default: 'mp3')
  final String format;

  /// Speech rate (1.0 = normal speed, <1.0 slower, >1.0 faster)
  /// Typical range: 0.5 - 2.0
  /// Maps to:
  /// - Edge TTS: percentage adjustment (1.0 -> 0%, 0.5 -> -50%, 1.5 -> +50%, 2.0 -> +100%)
  /// - Flutter TTS: platform-specific scale
  final double rate;

  /// Pitch (1.0 = normal pitch, <1.0 lower, >1.0 higher)
  /// Typical range: 0.5 - 2.0
  /// Maps to:
  /// - Edge TTS: Hz adjustment (1.0 -> 0Hz, 0.5 -> -50Hz, 1.5 -> +50Hz)
  /// - Flutter TTS: platform-specific scale
  final double pitch;

  /// Volume (0.0 - 1.0, where 1.0 = 100%)
  final double volume;

  const TTSRequest({
    required this.text,
    this.voiceName,
    this.languageCode,
    this.languageName,
    this.format = 'mp3',
    this.rate = 1.0, // 1.0 = normal speed (no adjustment)
    this.pitch = 1.0, // 1.0 = normal pitch (no adjustment)
    this.volume = 1.0, // 1.0 = 100% volume
  });

  /// Create a copy with updated values
  TTSRequest copyWith({
    String? text,
    String? voiceName,
    String? languageCode,
    String? languageName,
    String? format,
    double? rate,
    double? pitch,
    double? volume,
  }) {
    return TTSRequest(
      text: text ?? this.text,
      voiceName: voiceName ?? this.voiceName,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      format: format ?? this.format,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }



  @override
  String toString() {
    return 'TTSRequest(text: "${text.substring(0, text.length > 20 ? 20 : text.length)}...", '
        'voice: $voiceName, rate: $rate, pitch: $pitch, volume: $volume)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TTSRequest &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          voiceName == other.voiceName &&
          languageCode == other.languageCode &&
          languageName == other.languageName &&
          format == other.format &&
          rate == other.rate &&
          pitch == other.pitch &&
          volume == other.volume;

  @override
  int get hashCode =>
      text.hashCode ^
      voiceName.hashCode ^
      languageCode.hashCode ^
      languageName.hashCode ^
      format.hashCode ^
      rate.hashCode ^
      pitch.hashCode ^
      volume.hashCode;
}
