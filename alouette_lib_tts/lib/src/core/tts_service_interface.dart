import 'dart:typed_data';
import '../models/voice_model.dart';
import '../enums/tts_engine_type.dart';

/// Interface for TTS services to ensure compatibility between different implementations
abstract class TTSServiceInterface {
  /// Get current engine type
  TTSEngineType? get currentEngine;

  /// Get current engine name
  String? get currentEngineName;

  /// Get current backend name (alias for currentEngineName)
  String? get currentBackend;

  /// Check if service is initialized
  bool get isInitialized;

  /// Get available voices
  Future<List<VoiceModel>> getVoices();

  /// Synthesize text to audio bytes
  Future<Uint8List> synthesizeText(
    String text,
    String voiceName, {
    String format = 'mp3',
  });

  /// Speak text directly with audio playback
  /// Supports optional parameters; when omitted, defaults are used (0.5 for rate/pitch, 1.0 for volume)
  Future<void> speakText(
    String text, {
    String? voiceName,
    String? languageName,
    String? languageCode,
    String format = 'mp3',
    double? rate,
    double? pitch,
    double? volume,
  });

  /// Stop current TTS operation
  Future<void> stop();

  /// Get platform and engine information
  Future<Map<String, dynamic>> getPlatformInfo();

  /// Switch to different TTS engine
  Future<void> switchEngine(TTSEngineType engineType);

  /// Dispose service and release resources
  void dispose();
}
