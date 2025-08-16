import 'dart:typed_data';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';

/// Main TTS service interface that all implementations must follow
abstract class ITTSService {
  /// Initializes the TTS service with callbacks and optional configuration
  /// 
  /// [onStart] - Called when TTS synthesis/playback starts
  /// [onComplete] - Called when TTS synthesis/playback completes
  /// [onError] - Called when an error occurs during TTS operations
  /// [config] - Optional initial configuration
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  });

  /// Synthesizes and speaks the given text
  /// 
  /// [text] - Plain text to be spoken
  /// [config] - Optional configuration override for this operation
  Future<void> speak(String text, {AlouetteTTSConfig? config});

  /// Synthesizes and speaks the given SSML markup
  /// 
  /// [ssml] - SSML markup to be spoken
  /// [config] - Optional configuration override for this operation
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config});

  /// Synthesizes text to audio data without playing it
  /// 
  /// [text] - Text to be synthesized
  /// [config] - Optional configuration override for this operation
  /// Returns the audio data as bytes
  Future<Uint8List> synthesizeToAudio(String text, {AlouetteTTSConfig? config});

  /// Stops the current TTS operation
  Future<void> stop();

  /// Pauses the current TTS playback (if supported)
  Future<void> pause();

  /// Resumes paused TTS playback (if supported)
  Future<void> resume();

  /// Updates the TTS configuration
  /// 
  /// [config] - New configuration to apply
  Future<void> updateConfig(AlouetteTTSConfig config);

  /// Gets the current TTS configuration
  AlouetteTTSConfig get currentConfig;

  /// Gets the current TTS state
  TTSState get currentState;

  /// Gets all available voices for the current platform
  Future<List<AlouetteVoice>> getAvailableVoices();

  /// Gets voices filtered by language code
  /// 
  /// [languageCode] - BCP 47 language tag (e.g., 'en-US')
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode);

  /// Saves audio data to a file
  /// 
  /// [audioData] - Audio data to save
  /// [filePath] - Destination file path
  Future<void> saveAudioToFile(Uint8List audioData, String filePath);

  /// Processes multiple TTS requests in batch
  /// 
  /// [requests] - List of TTS requests to process
  /// Returns a list of results corresponding to each request
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests);

  /// Disposes of the TTS service and releases resources
  void dispose();
}

/// Callback type for TTS events
typedef VoidCallback = void Function();