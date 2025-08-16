import 'dart:typed_data';
import '../enums/audio_format.dart';
import '../exceptions/tts_exceptions.dart';

/// Utility class for audio format conversion and validation
class AudioFormatConverter {
  /// Validates that audio data matches the expected format
  /// 
  /// [audioData] - The audio data to validate
  /// [expectedFormat] - The expected audio format
  /// 
  /// Returns true if the format matches
  static bool validateAudioFormat(Uint8List audioData, AudioFormat expectedFormat) {
    if (audioData.isEmpty) return false;
    
    try {
      switch (expectedFormat) {
        case AudioFormat.wav:
          return _isValidWav(audioData);
        case AudioFormat.mp3:
          return _isValidMp3(audioData);
        case AudioFormat.ogg:
          return _isValidOgg(audioData);
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Detects the audio format from the data
  /// 
  /// [audioData] - The audio data to analyze
  /// 
  /// Returns the detected format or null if unknown
  static AudioFormat? detectAudioFormat(Uint8List audioData) {
    if (audioData.isEmpty) return null;
    
    if (_isValidWav(audioData)) return AudioFormat.wav;
    if (_isValidMp3(audioData)) return AudioFormat.mp3;
    if (_isValidOgg(audioData)) return AudioFormat.ogg;
    
    return null;
  }
  
  /// Converts audio data to the specified format
  /// 
  /// [audioData] - The source audio data
  /// [sourceFormat] - The source format (if known)
  /// [targetFormat] - The target format
  /// 
  /// Returns converted audio data
  static Future<Uint8List> convertToFormat(
    Uint8List audioData,
    AudioFormat targetFormat, {
    AudioFormat? sourceFormat,
  }) async {
    if (audioData.isEmpty) {
      throw TTSException('Cannot convert empty audio data');
    }
    
    // Detect source format if not provided
    sourceFormat ??= detectAudioFormat(audioData);
    if (sourceFormat == null) {
      throw TTSException('Unable to detect source audio format');
    }
    
    // No conversion needed if formats match
    if (sourceFormat == targetFormat) {
      return audioData;
    }
    
    // Perform format conversion
    return await _performConversion(audioData, sourceFormat, targetFormat);
  }
  
  /// Adds format-specific headers if needed
  /// 
  /// [audioData] - Raw audio data
  /// [format] - Target format
  /// [sampleRate] - Sample rate (default 22050 Hz)
  /// [channels] - Number of channels (default 1 for mono)
  /// [bitsPerSample] - Bits per sample (default 16)
  /// 
  /// Returns audio data with proper headers
  static Uint8List addFormatHeaders(
    Uint8List audioData,
    AudioFormat format, {
    int sampleRate = 22050,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    switch (format) {
      case AudioFormat.wav:
        return _addWavHeader(audioData, sampleRate, channels, bitsPerSample);
      case AudioFormat.mp3:
        // MP3 headers are complex and require encoding
        return audioData;
      case AudioFormat.ogg:
        // OGG headers are complex and require encoding
        return audioData;
    }
  }
  
  /// Gets format-specific quality settings
  /// 
  /// [format] - The audio format
  /// [quality] - Quality level (0.0 to 1.0)
  /// 
  /// Returns format-specific settings
  static Map<String, dynamic> getQualitySettings(AudioFormat format, double quality) {
    quality = quality.clamp(0.0, 1.0);
    
    switch (format) {
      case AudioFormat.wav:
        return {
          'sampleRate': (22050 + (quality * 22050)).round(), // 22050 to 44100 Hz
          'bitsPerSample': quality > 0.5 ? 16 : 8,
          'channels': 1,
        };
      case AudioFormat.mp3:
        return {
          'bitrate': (64 + (quality * 256)).round(), // 64 to 320 kbps
          'sampleRate': (22050 + (quality * 22050)).round(),
          'channels': 1,
        };
      case AudioFormat.ogg:
        return {
          'quality': (quality * 10).round(), // 0 to 10 quality scale
          'sampleRate': (22050 + (quality * 22050)).round(),
          'channels': 1,
        };
    }
  }
  
  // Private helper methods
  
  /// Checks if data is valid WAV format
  static bool _isValidWav(Uint8List data) {
    if (data.length < 44) return false;
    
    // Check RIFF header
    final riffHeader = String.fromCharCodes(data.sublist(0, 4));
    if (riffHeader != 'RIFF') return false;
    
    // Check WAVE format
    final waveHeader = String.fromCharCodes(data.sublist(8, 12));
    if (waveHeader != 'WAVE') return false;
    
    // Check fmt chunk
    final fmtHeader = String.fromCharCodes(data.sublist(12, 16));
    return fmtHeader == 'fmt ';
  }
  
  /// Checks if data is valid MP3 format
  static bool _isValidMp3(Uint8List data) {
    if (data.length < 4) return false;
    
    // Look for MP3 frame sync pattern
    for (int i = 0; i < data.length - 3 && i < 1000; i++) {
      if (data[i] == 0xFF && (data[i + 1] & 0xE0) == 0xE0) {
        // Found potential MP3 frame header
        final header = (data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | data[i + 3];
        if (_isValidMp3Header(header)) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Checks if data is valid OGG format
  static bool _isValidOgg(Uint8List data) {
    if (data.length < 4) return false;
    
    // Check OGG page header
    final oggHeader = String.fromCharCodes(data.sublist(0, 4));
    return oggHeader == 'OggS';
  }
  
  /// Validates MP3 frame header
  static bool _isValidMp3Header(int header) {
    // Check sync pattern (11 bits)
    if ((header & 0xFFE00000) != 0xFFE00000) return false;
    
    // Check version (2 bits) - should not be 01 (reserved)
    final version = (header >> 19) & 0x3;
    if (version == 1) return false;
    
    // Check layer (2 bits) - should not be 00 (reserved)
    final layer = (header >> 17) & 0x3;
    if (layer == 0) return false;
    
    // Check bitrate (4 bits) - should not be 0000 or 1111
    final bitrate = (header >> 12) & 0xF;
    if (bitrate == 0 || bitrate == 15) return false;
    
    // Check sample rate (2 bits) - should not be 11 (reserved)
    final sampleRate = (header >> 10) & 0x3;
    if (sampleRate == 3) return false;
    
    return true;
  }
  
  /// Performs actual format conversion
  static Future<Uint8List> _performConversion(
    Uint8List audioData,
    AudioFormat sourceFormat,
    AudioFormat targetFormat,
  ) async {
    // This is a simplified conversion implementation
    // In production, you would use proper audio processing libraries
    
    switch (sourceFormat) {
      case AudioFormat.wav:
        return await _convertFromWav(audioData, targetFormat);
      case AudioFormat.mp3:
        return await _convertFromMp3(audioData, targetFormat);
      case AudioFormat.ogg:
        return await _convertFromOgg(audioData, targetFormat);
    }
  }
  
  /// Converts from WAV format
  static Future<Uint8List> _convertFromWav(Uint8List wavData, AudioFormat targetFormat) async {
    switch (targetFormat) {
      case AudioFormat.wav:
        return wavData;
      case AudioFormat.mp3:
        // Extract PCM data from WAV and encode as MP3
        final pcmData = _extractPcmFromWav(wavData);
        return _encodePcmToMp3(pcmData);
      case AudioFormat.ogg:
        // Extract PCM data from WAV and encode as OGG
        final pcmData = _extractPcmFromWav(wavData);
        return _encodePcmToOgg(pcmData);
    }
  }
  
  /// Converts from MP3 format
  static Future<Uint8List> _convertFromMp3(Uint8List mp3Data, AudioFormat targetFormat) async {
    switch (targetFormat) {
      case AudioFormat.mp3:
        return mp3Data;
      case AudioFormat.wav:
        // Decode MP3 to PCM and add WAV header
        final pcmData = await _decodeMp3ToPcm(mp3Data);
        return _addWavHeader(pcmData, 22050, 1, 16);
      case AudioFormat.ogg:
        // Decode MP3 to PCM and encode as OGG
        final pcmData = await _decodeMp3ToPcm(mp3Data);
        return _encodePcmToOgg(pcmData);
    }
  }
  
  /// Converts from OGG format
  static Future<Uint8List> _convertFromOgg(Uint8List oggData, AudioFormat targetFormat) async {
    switch (targetFormat) {
      case AudioFormat.ogg:
        return oggData;
      case AudioFormat.wav:
        // Decode OGG to PCM and add WAV header
        final pcmData = await _decodeOggToPcm(oggData);
        return _addWavHeader(pcmData, 22050, 1, 16);
      case AudioFormat.mp3:
        // Decode OGG to PCM and encode as MP3
        final pcmData = await _decodeOggToPcm(oggData);
        return _encodePcmToMp3(pcmData);
    }
  }
  
  /// Extracts PCM data from WAV file
  static Uint8List _extractPcmFromWav(Uint8List wavData) {
    if (wavData.length < 44) {
      throw TTSException('Invalid WAV file: too small');
    }
    
    // Find data chunk
    int dataOffset = 44; // Standard WAV header size
    
    // Look for 'data' chunk marker
    for (int i = 12; i < wavData.length - 8; i += 4) {
      final chunkId = String.fromCharCodes(wavData.sublist(i, i + 4));
      if (chunkId == 'data') {
        dataOffset = i + 8;
        break;
      }
    }
    
    return Uint8List.fromList(wavData.sublist(dataOffset));
  }
  
  /// Adds WAV header to PCM data
  static Uint8List _addWavHeader(
    Uint8List pcmData,
    int sampleRate,
    int channels,
    int bitsPerSample,
  ) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final byteRate = sampleRate * channels * bytesPerSample;
    final blockAlign = channels * bytesPerSample;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    
    final header = ByteData(44);
    
    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'
    
    // fmt chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    
    // data chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);
    
    // Combine header and data
    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, pcmData);
    
    return result;
  }
  
  /// Placeholder for MP3 encoding (requires external library)
  static Uint8List _encodePcmToMp3(Uint8List pcmData) {
    // In a real implementation, this would use an MP3 encoder library
    throw TTSException('MP3 encoding not implemented - requires external library');
  }
  
  /// Placeholder for OGG encoding (requires external library)
  static Uint8List _encodePcmToOgg(Uint8List pcmData) {
    // In a real implementation, this would use an OGG encoder library
    throw TTSException('OGG encoding not implemented - requires external library');
  }
  
  /// Placeholder for MP3 decoding (requires external library)
  static Future<Uint8List> _decodeMp3ToPcm(Uint8List mp3Data) async {
    // In a real implementation, this would use an MP3 decoder library
    throw TTSException('MP3 decoding not implemented - requires external library');
  }
  
  /// Placeholder for OGG decoding (requires external library)
  static Future<Uint8List> _decodeOggToPcm(Uint8List oggData) async {
    // In a real implementation, this would use an OGG decoder library
    throw TTSException('OGG decoding not implemented - requires external library');
  }
}