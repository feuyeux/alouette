import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

import '../enums/audio_format.dart';
import '../exceptions/tts_exceptions.dart';

/// Utility class for managing audio file operations
class AudioFileManager {
  /// Validates a file path for audio output
  /// 
  /// [filePath] - The file path to validate
  /// [format] - The expected audio format
  /// 
  /// Throws [TTSException] if the path is invalid
  static void validateFilePath(String filePath, AudioFormat format) {
    if (filePath.isEmpty) {
      throw TTSException('File path cannot be empty');
    }
    
    // Check if path is absolute or relative
    if (!path.isAbsolute(filePath) && !filePath.startsWith('./') && !filePath.startsWith('../')) {
      throw TTSException('File path must be absolute or explicitly relative');
    }
    
    // Validate file extension matches format
    final expectedExtension = format.fileExtension;
    final actualExtension = path.extension(filePath).toLowerCase();
    
    if (actualExtension != expectedExtension) {
      throw TTSException(
        'File extension "$actualExtension" does not match expected format "$expectedExtension"'
      );
    }
    
    // Check for invalid characters in filename
    final fileName = path.basename(filePath);
    final invalidChars = RegExp(r'[<>:"|?*]');
    if (invalidChars.hasMatch(fileName)) {
      throw TTSException('File name contains invalid characters');
    }
    
    // Check path length (Windows has 260 character limit)
    if (filePath.length > 250) {
      throw TTSException('File path is too long (maximum 250 characters)');
    }
  }
  
  /// Checks if a file path has write permissions
  /// 
  /// [filePath] - The file path to check
  /// 
  /// Returns true if the path is writable
  static Future<bool> hasWritePermission(String filePath) async {
    try {
      final file = File(filePath);
      final directory = file.parent;
      
      // Check if directory exists and is writable
      if (!await directory.exists()) {
        // Try to create the directory
        try {
          await directory.create(recursive: true);
        } catch (e) {
          return false;
        }
      }
      
      // Test write permission by creating a temporary file with unique name
      final tempFileName = '.temp_write_test_${DateTime.now().millisecondsSinceEpoch}';
      final tempFile = File(path.join(directory.path, tempFileName));
      try {
        await tempFile.writeAsBytes([0]);
        await tempFile.delete();
        return true;
      } catch (e) {
        // Clean up temp file if it exists
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {
          // Ignore cleanup errors
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Checks available storage space at the given path
  /// 
  /// [filePath] - The file path to check
  /// [requiredBytes] - Minimum required bytes
  /// 
  /// Returns true if sufficient space is available
  static Future<bool> hasStorageSpace(String filePath, int requiredBytes) async {
    try {
      final file = File(filePath);
  final directory = file.parent;
  // Note: Dart doesn't provide direct access to free space
  // This is a simplified check - in production, you'd use platform channels
  // For now, we'll assume space is available if directory exists
  return await directory.exists() || requiredBytes < 100 * 1024 * 1024; // 100MB limit
    } catch (e) {
      return false;
    }
  }
  
  /// Handles file overwrite conflicts
  /// 
  /// [filePath] - The target file path
  /// [overwriteMode] - How to handle existing files
  /// 
  /// Returns the final file path to use
  static Future<String> handleFileConflict(
    String filePath, 
    FileOverwriteMode overwriteMode,
  ) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      return filePath; // No conflict
    }
    
    switch (overwriteMode) {
      case FileOverwriteMode.overwrite:
        return filePath;
        
      case FileOverwriteMode.skip:
        throw TTSException('File already exists: $filePath');
        
      case FileOverwriteMode.rename:
        return _generateUniqueFileName(filePath);
        
      case FileOverwriteMode.error:
        throw TTSException('File already exists and overwrite is disabled: $filePath');
    }
  }
  
  /// Generates a unique file name by appending a number
  /// 
  /// [originalPath] - The original file path
  /// 
  /// Returns a unique file path
  static String _generateUniqueFileName(String originalPath) {
    final directory = path.dirname(originalPath);
    final baseName = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);
    
    var counter = 1;
    String newPath;
    
    do {
      newPath = path.join(directory, '${baseName}_$counter$extension');
      counter++;
    } while (File(newPath).existsSync() && counter < 1000);
    
    if (counter >= 1000) {
      throw TTSException('Unable to generate unique filename after 1000 attempts');
    }
    
    return newPath;
  }
  
  /// Saves audio data to a file with format validation
  /// 
  /// [audioData] - The audio data to save
  /// [filePath] - The destination file path
  /// [format] - The audio format
  /// [overwriteMode] - How to handle existing files
  /// 
  /// Returns the actual file path used (may differ if renamed)
  static Future<String> saveAudioToFile(
    Uint8List audioData,
    String filePath,
    AudioFormat format, {
    FileOverwriteMode overwriteMode = FileOverwriteMode.error,
  }) async {
    // Validate inputs
    if (audioData.isEmpty) {
      throw TTSException('Audio data is empty');
    }
    
    validateFilePath(filePath, format);
    
    // Check permissions
    if (!await hasWritePermission(filePath)) {
      throw TTSException('No write permission for path: $filePath');
    }
    
    // Check storage space (estimate 10% overhead)
    final requiredSpace = (audioData.length * 1.1).round();
    if (!await hasStorageSpace(filePath, requiredSpace)) {
      throw TTSException('Insufficient storage space for file: $filePath');
    }
    
    // Handle file conflicts
    final finalPath = await handleFileConflict(filePath, overwriteMode);
    
    try {
      // Ensure directory exists
      final file = File(finalPath);
      await file.parent.create(recursive: true);
      
      // Validate audio format if possible
      _validateAudioData(audioData, format);
      
      // Write the file
      await file.writeAsBytes(audioData);
      
      // Verify the file was written correctly
      final writtenSize = await file.length();
      if (writtenSize != audioData.length) {
        throw TTSException(
          'File write verification failed: expected ${audioData.length} bytes, got $writtenSize bytes'
        );
      }
      
      return finalPath;
    } catch (e) {
      if (e is TTSException) {
        rethrow;
      }
      throw TTSException('Failed to save audio file: $e');
    }
  }
  
  /// Validates audio data format (basic validation)
  /// 
  /// [audioData] - The audio data to validate
  /// [format] - The expected format
  static void _validateAudioData(Uint8List audioData, AudioFormat format) {
    if (audioData.length < 44) {
      throw TTSException('Audio data too small to be valid');
    }
    
    switch (format) {
      case AudioFormat.wav:
        _validateWavFormat(audioData);
        break;
      case AudioFormat.mp3:
        _validateMp3Format(audioData);
        break;
      case AudioFormat.ogg:
        _validateOggFormat(audioData);
        break;
    }
  }
  
  /// Validates WAV format header
  static void _validateWavFormat(Uint8List data) {
    // Check RIFF header
    if (data.length < 12) return;
    
    final riffHeader = String.fromCharCodes(data.sublist(0, 4));
    final waveHeader = String.fromCharCodes(data.sublist(8, 12));
    
    if (riffHeader != 'RIFF' || waveHeader != 'WAVE') {
      throw TTSException('Invalid WAV format: missing RIFF/WAVE headers');
    }
  }
  
  /// Validates MP3 format header
  static void _validateMp3Format(Uint8List data) {
    // Check for MP3 frame sync (11 bits set)
    if (data.length < 4) return;
    
    // Look for MP3 frame header (0xFF followed by 0xE0-0xFF)
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && (data[i + 1] & 0xE0) == 0xE0) {
        return; // Found valid MP3 frame header
      }
    }
    
    throw TTSException('Invalid MP3 format: no valid frame header found');
  }
  
  /// Validates OGG format header
  static void _validateOggFormat(Uint8List data) {
    // Check OGG page header
    if (data.length < 4) return;
    
    final oggHeader = String.fromCharCodes(data.sublist(0, 4));
    if (oggHeader != 'OggS') {
      throw TTSException('Invalid OGG format: missing OggS header');
    }
  }
  
  /// Converts audio data between formats (basic conversion)
  /// 
  /// [audioData] - The source audio data
  /// [sourceFormat] - The source format
  /// [targetFormat] - The target format
  /// 
  /// Returns converted audio data
  static Future<Uint8List> convertAudioFormat(
    Uint8List audioData,
    AudioFormat sourceFormat,
    AudioFormat targetFormat,
  ) async {
    if (sourceFormat == targetFormat) {
      return audioData;
    }
    
    // Note: This is a placeholder for audio format conversion
    // In a real implementation, you would use audio processing libraries
    // like FFmpeg or platform-specific audio converters
    
    throw TTSException(
      'Audio format conversion from ${sourceFormat.formatName} to ${targetFormat.formatName} is not yet implemented'
    );
  }
  
  /// Gets the estimated file size for given text and configuration
  /// 
  /// [text] - The text to be synthesized
  /// [format] - The target audio format
  /// [config] - TTS configuration (affects duration)
  /// 
  /// Returns estimated file size in bytes
  static int estimateFileSize(String text, AudioFormat format, {double speechRate = 1.0}) {
    // Rough estimation based on text length and format
    final wordCount = text.split(RegExp(r'\s+')).length;
    final estimatedDurationSeconds = (wordCount / (150 * speechRate)) * 60; // 150 WPM base rate
    
    int bytesPerSecond;
    switch (format) {
      case AudioFormat.mp3:
        bytesPerSecond = 16000; // ~128 kbps
        break;
      case AudioFormat.wav:
        bytesPerSecond = 176400; // 44.1kHz, 16-bit, stereo
        break;
      case AudioFormat.ogg:
        bytesPerSecond = 12000; // ~96 kbps
        break;
    }
    
    return (estimatedDurationSeconds * bytesPerSecond).round();
  }
}

/// Enumeration for file overwrite handling modes
enum FileOverwriteMode {
  /// Overwrite existing files
  overwrite,
  
  /// Skip existing files (throw error)
  skip,
  
  /// Rename to avoid conflicts
  rename,
  
  /// Throw error if file exists
  error,
}