import 'dart:typed_data';
import '../interfaces/i_tts_service.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';
import '../exceptions/tts_exceptions.dart';
import '../enums/tts_platform.dart';

/// Fallback stub used on non-web platforms to prevent accidental use of browser APIs.
class WebTTSService implements ITTSService {
  @override
  void dispose() {}

  @override
  AlouetteTTSConfig get currentConfig => AlouetteTTSConfig.defaultConfig();

  @override
  TTSState get currentState => TTSState.disposed;

  @override
  Future<List<AlouetteVoice>> getAvailableVoices() async => [];

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async => throw TTSPlatformException('getVoicesByLanguage not supported', TTSPlatform.web);

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async => throw TTSPlatformException('saveAudioToFile not supported', TTSPlatform.web);

  @override
  Future<void> initialize({required VoidCallback onStart, required VoidCallback onComplete, required void Function(String error) onError, AlouetteTTSConfig? config}) async {
    throw const TTSInitializationException('WebTTSService is not available on this platform', 'WebTTS');
  }

  @override
  Future<void> pause() async => throw TTSPlatformException('Pause not supported', TTSPlatform.web);

  @override
  Future<void> resume() async => throw TTSPlatformException('Resume not supported', TTSPlatform.web);

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async => throw TTSPlatformException('Speak not supported', TTSPlatform.web);

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async => throw TTSPlatformException('SpeakSSML not supported', TTSPlatform.web);

  @override
  Future<Uint8List> synthesizeToAudio(String text, {AlouetteTTSConfig? config}) async => throw TTSPlatformException('SynthesizeToAudio not supported', TTSPlatform.web);

  @override
  Future<void> stop() async => throw TTSPlatformException('Stop not supported', TTSPlatform.web);

  @override
  Future<void> updateConfig(AlouetteTTSConfig config) async => throw TTSPlatformException('UpdateConfig not supported', TTSPlatform.web);

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async => [];
}
