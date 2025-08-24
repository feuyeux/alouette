// Conditional import: only use dart:html on web
import 'dart:async';
import 'dart:typed_data';
import '../interfaces/i_tts_service.dart';
import '../models/alouette_tts_config.dart';
import '../models/alouette_voice.dart';
import '../models/tts_request.dart';
import '../models/tts_result.dart';
import '../models/tts_state.dart';
import '../exceptions/tts_exceptions.dart';
import '../enums/voice_gender.dart';
import '../enums/voice_quality.dart';
import '../enums/tts_platform.dart';

// Only import dart:html if running on web
// ignore: uri_does_not_exist
import 'dart:html' as html;

// Only compile this implementation on web
// On non-web platforms, this file should not be used; use web_tts_service_stub.dart instead.
/// Thin wrapper around the browser SpeechSynthesis API.
class _WebSpeechInterface {
  /// Ensure the browser has loaded available voices. Some browsers return an
  /// empty list until the 'voiceschanged' event fires — wait briefly for that
  /// event to avoid false negatives when querying available voices.
  Future<void> _ensureVoicesLoaded({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;

      final initial = synth.getVoices() ?? <html.SpeechSynthesisVoice>[];
      if (initial.isNotEmpty) return;

      final completer = Completer<void>();

      void listener(html.Event _) {
        if (!completer.isCompleted) completer.complete();
      }

      try {
        synth.addEventListener('voiceschanged', listener);
      } catch (_) {}

      try {
        await Future.any([completer.future, Future.delayed(timeout)]);
      } catch (_) {
        // ignore
      } finally {
        try {
          synth.removeEventListener('voiceschanged', listener);
        } catch (_) {}
      }
    } catch (_) {
      // ignore
    }
  }
  Future<void> speak(
    String text, {
    String? lang,
    double? rate,
    double? pitch,
    double? volume,
    String? voiceName,
  }) async {
    final synth = html.window.speechSynthesis;

    if (synth == null) {
      throw Exception('Browser SpeechSynthesis not available');
    }

    final completer = Completer<void>();

    final utterance = html.SpeechSynthesisUtterance(text);
    if (lang != null) utterance.lang = lang;
    if (rate != null) utterance.rate = rate;
    if (pitch != null) utterance.pitch = pitch;
    if (volume != null) utterance.volume = volume;

    // Ensure voices are loaded (some browsers populate voices asynchronously)
    await _ensureVoicesLoaded();

    // Try to select a matching voice by name or language primary subtag.
    try {
      final voices = synth.getVoices() ?? <html.SpeechSynthesisVoice>[];

      // Prefer exact voice name match when provided
      if (voiceName != null) {
        final matches = voices.where((v) => (v.name ?? '').toLowerCase() == voiceName.toLowerCase());
        if (matches.isNotEmpty) {
          utterance.voice = matches.first;
        }
      }

      // If no voice selected yet, try to match by language primary subtag
      if (utterance.voice == null && lang != null && lang.isNotEmpty) {
        final targetPrimary = lang.split('-').first.toLowerCase();
        final matches = voices.where((v) {
          final vLang = (v.lang ?? '').toLowerCase();
          if (vLang.isEmpty) return false;
          final vPrimary = vLang.split('-').first;
          return vPrimary == targetPrimary || vLang == lang.toLowerCase();
        }).toList(growable: false);

        if (matches.isNotEmpty) {
          utterance.voice = matches.first;
        }
      }
    } catch (_) {
      // ignore voice selection failures
    }

    // Use generic event listeners to be compatible across Dart versions
    try {
      utterance.addEventListener('end', (e) {
        if (!completer.isCompleted) completer.complete();
      });
      utterance.addEventListener('error', (e) {
        if (!completer.isCompleted) completer.completeError(Exception('SpeechSynthesis error'));
      });
      utterance.addEventListener('abort', (e) {
        if (!completer.isCompleted) completer.complete();
      });
    } catch (_) {
      // ignore if addEventListener is not available
    }

    try {
      synth.speak(utterance);
    } catch (e) {
      // Some browsers require user gesture; surface as error
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future;
  }

  void cancel() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }

  void pause() {
    try {
      html.window.speechSynthesis?.pause();
    } catch (_) {}
  }

  void resume() {
    try {
      html.window.speechSynthesis?.resume();
    } catch (_) {}
  }

  List<Map<String, String>> getVoices() {
    try {
      final synth = html.window.speechSynthesis;
      // Ensure voices are loaded before returning the list. Use a synchronous
      // path when possible but attempt a short wait if voices are not yet
      // available. This method is synchronous in signature so we try to
      // proactively fetch, but if the browser hasn't loaded voices yet the
      // caller should use the async speak path which awaits loading.
      final voices = synth?.getVoices() ?? <html.SpeechSynthesisVoice>[];
      return voices.map((v) {
        return {
          'name': v.name ?? '',
          'lang': v.lang ?? '',
          'uri': (v.name ?? ''),
          'default': 'false',
        };
      }).toList(growable: false);
    } catch (_) {
      return <Map<String, String>>[];
    }
  }
}

/// Web TTS service implementation that uses the browser SpeechSynthesis API.
class WebTTSService implements ITTSService {
  final _WebSpeechInterface _web = _WebSpeechInterface();

  AlouetteTTSConfig _config = AlouetteTTSConfig.defaultConfig();
  TTSState _state = TTSState.stopped;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  void Function(String error)? _onError;

  bool _isInitialized = false;

  @override
  void dispose() {
    _web.cancel();
    _state = TTSState.disposed;
  }

  @override
  Future<List<AlouetteVoice>> getAvailableVoices() async {
    try {
      final list = _web.getVoices();
      return list.map((m) => AlouetteVoice.fromPlatformData(
            id: m['uri'] ?? m['name'] ?? '',
            name: m['name'] ?? '',
            languageCode: m['lang'] ?? '',
            platform: TTSPlatform.web,
            countryCode: null,
            metadata: {'default': m['default'] ?? 'false'},
          )).toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<AlouetteVoice>> getVoicesByLanguage(String languageCode) async {
    final voices = await getAvailableVoices();
    if (languageCode.isEmpty) return voices;

    final target = languageCode.toLowerCase();
    final targetPrimary = target.split('-').first;

    return voices.where((v) {
      final vLang = v.languageCode.toLowerCase();
      if (vLang == target) return true;
      final vPrimary = vLang.split('-').first;
      return vPrimary == targetPrimary;
    }).toList(growable: false);
  }

  @override
  TTSState get currentState => _state;

  @override
  AlouetteTTSConfig get currentConfig => _config;

  @override
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(String error) onError,
    AlouetteTTSConfig? config,
  }) async {
    _onStart = onStart;
    _onComplete = onComplete;
    _onError = onError;

    if (config != null) _config = config;

    // Browser API requires no heavy initialization; mark ready
    _isInitialized = true;
    _state = TTSState.ready;
  }

  @override
  Future<void> pause() async {
    try {
      _web.pause();
      _state = TTSState.paused;
    } catch (e) {
      throw TTSException('Failed to pause TTS: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      _web.resume();
      _state = TTSState.playing;
    } catch (e) {
      throw TTSException('Failed to resume TTS: $e');
    }
  }

  @override
  Future<void> speak(String text, {AlouetteTTSConfig? config}) async {
    if (!_isInitialized) {
      throw const TTSInitializationException('Service not initialized', 'WebTTS');
    }

    final effective = config ?? _config;

    try {
      _state = TTSState.synthesizing;
      _onStart?.call();

      // Ensure browser voices are loaded before selecting
      await _web._ensureVoicesLoaded();

      // Debug: list available browser voices and log selected voice
      List<Map<String, String>> available = <Map<String, String>>[];
      try {
        available = _web.getVoices();
  // Do not log voice lists in normal operation; only keep errors.
      } catch (e) {
        // suppressed: voice enumeration may fail silently on some browsers
      }

      // Determine selected browser voice: prefer exact voiceName, else match primary language subtag
      String? selectedBrowserVoice;
      final requestedVoice = effective.voiceName?.toLowerCase();
      final requestedLang = effective.languageCode;

      if (requestedVoice != null && requestedVoice.isNotEmpty) {
        final match = available.firstWhere(
          (v) => (v['name'] ?? '').toLowerCase() == requestedVoice,
          orElse: () => {},
        );
        if ((match['name'] ?? '').isNotEmpty) selectedBrowserVoice = match['name'];
      }

      if (selectedBrowserVoice == null && requestedLang.isNotEmpty) {
        final targetPrimary = requestedLang.split('-').first.toLowerCase();
        final langMatch = available.firstWhere((v) {
          final vLang = (v['lang'] ?? '').toLowerCase();
          if (vLang.isEmpty) return false;
          final vPrimary = vLang.split('-').first;
          return vPrimary == targetPrimary || vLang == requestedLang.toLowerCase();
        }, orElse: () => {});

        if ((langMatch['name'] ?? '').isNotEmpty) selectedBrowserVoice = langMatch['name'];
      }

      if (selectedBrowserVoice != null && selectedBrowserVoice.isNotEmpty) {
  // selection successful; do not print in normal operation
        await _web.speak(
          text,
          lang: effective.languageCode,
          rate: effective.speechRate,
          pitch: effective.pitch,
          volume: effective.volume,
          voiceName: selectedBrowserVoice,
        );
      } else {
        // No suitable browser voice available — surface clear error
        final msg = 'No browser TTS voice available for language ${effective.languageCode} (requested: ${effective.voiceName}).';
  // surface to onError and throw exception; no console print
        _state = TTSState.error;
        _onError?.call(msg);
        throw TTSPlatformException(msg, TTSPlatform.web);
      }

      _state = TTSState.ready;
      _onComplete?.call();
    } catch (e) {
      _state = TTSState.error;
      _onError?.call('Failed to speak: $e');
      throw TTSSynthesisException('Failed to speak: $e', text: text);
    }
  }

  @override
  Future<void> speakSSML(String ssml, {AlouetteTTSConfig? config}) async {
    // Web Speech API has limited SSML support; fallback to plain text
    final plain = ssml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return speak(plain, config: config);
  }

  @override
  Future<Uint8List> synthesizeToAudio(String text, {AlouetteTTSConfig? config}) async {
    throw TTSPlatformException('Synthesize to audio not supported on web',
        TTSPlatform.web);
  }

  @override
  Future<void> stop() async {
    try {
      _web.cancel();
      _state = TTSState.stopped;
    } catch (e) {
      _onError?.call('Failed to stop TTS: $e');
    }
  }

  @override
  Future<void> updateConfig(AlouetteTTSConfig config) async {
    _config = config;
  }

  @override
  Future<List<TTSResult>> processBatch(List<TTSRequest> requests) async {
    if (!_isInitialized) throw const TTSInitializationException('Not initialized', 'WebTTS');
    final results = <TTSResult>[];
    for (final r in requests) {
      try {
        final stopwatch = Stopwatch()..start();
        await speak(r.text, config: r.config);
        stopwatch.stop();
        results.add(TTSResult.success(
          requestId: r.id,
          processingTime: stopwatch.elapsed,
        ));
      } catch (e) {
        results.add(TTSResult.failure(
          requestId: r.id,
          error: e.toString(),
          processingTime: Duration.zero,
        ));
      }
    }
    return results;
  }

  @override
  Future<void> saveAudioToFile(Uint8List audioData, String filePath) async {
    throw TTSPlatformException('Saving audio to file not supported on web', TTSPlatform.web);
  }
}
