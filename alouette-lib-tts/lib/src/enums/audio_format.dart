/// Enumeration of supported audio formats
enum AudioFormat {
  /// MP3 audio format
  mp3,
  
  /// WAV audio format
  wav,
  
  /// OGG audio format
  ogg;

  /// Returns the format name as a string
  String get formatName {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.wav:
        return 'WAV';
      case AudioFormat.ogg:
        return 'OGG';
    }
  }

  /// Returns the file extension for this format
  String get fileExtension {
    switch (this) {
      case AudioFormat.mp3:
        return '.mp3';
      case AudioFormat.wav:
        return '.wav';
      case AudioFormat.ogg:
        return '.ogg';
    }
  }

  /// Returns the MIME type for this format
  String get mimeType {
    switch (this) {
      case AudioFormat.mp3:
        return 'audio/mpeg';
      case AudioFormat.wav:
        return 'audio/wav';
      case AudioFormat.ogg:
        return 'audio/ogg';
    }
  }

  /// Creates an AudioFormat from a string representation
  static AudioFormat fromString(String format) {
    switch (format.toLowerCase()) {
      case 'mp3':
      case 'mpeg':
        return AudioFormat.mp3;
      case 'wav':
      case 'wave':
        return AudioFormat.wav;
      case 'ogg':
      case 'vorbis':
        return AudioFormat.ogg;
      default:
        return AudioFormat.mp3; // Default to MP3
    }
  }

  /// Returns true if this format is supported on the given platform
  bool isSupportedOnPlatform(String platform) {
    switch (this) {
      case AudioFormat.mp3:
        return true; // MP3 is supported on all platforms
      case AudioFormat.wav:
        return true; // WAV is supported on all platforms
      case AudioFormat.ogg:
        // OGG support varies by platform
        return platform != 'ios' && platform != 'macos';
    }
  }
}