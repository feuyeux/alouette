import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import '../../exceptions/tts_exception.dart';
import '../../models/alouette_tts_config.dart';
import '../../utils/request_logger.dart';

/// WebSocket client for Edge TTS service
class EdgeTTSWebSocketClient {
  bool _isConnected = false;
  DateTime? _lastUsed;

  /// Connects to the Edge TTS WebSocket service
  Future<void> connect() async {
    if (_isConnected) {
      _lastUsed = DateTime.now();
      return;
    }

    // For now, we'll use the edge-tts command line tool as a fallback
    // since direct WebSocket implementation has platform compatibility issues
    _isConnected = true;
    _lastUsed = DateTime.now();
    // Using edge-tts command line fallback instead of WebSocket
  }

  String _getDefaultVoiceForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en-us':
        return 'en-US-AriaNeural';
      case 'en-gb':
        return 'en-GB-SoniaNeural';
      case 'en-au':
        return 'en-AU-NatashaNeural';
      case 'en-ca':
        return 'en-CA-ClaraNeural';
      case 'es-es':
        return 'es-ES-ElviraNeural';
      case 'es-mx':
        return 'es-MX-DaliaNeural';
      case 'fr-fr':
        return 'fr-FR-DeniseNeural';
      case 'fr-ca':
        return 'fr-CA-SylvieNeural';
      case 'de-de':
        return 'de-DE-KatjaNeural';
      case 'it-it':
        return 'it-IT-ElsaNeural';
      case 'pt-br':
        return 'pt-BR-FranciscaNeural';
      case 'pt-pt':
        return 'pt-PT-RaquelNeural';
      case 'ru-ru':
        return 'ru-RU-SvetlanaNeural';
      case 'ja-jp':
        return 'ja-JP-NanamiNeural';
      case 'ko-kr':
        return 'ko-KR-SunHiNeural';
      case 'zh-cn':
        return 'zh-CN-XiaoxiaoNeural';
      case 'zh-tw':
        return 'zh-TW-HsiaoChenNeural';
      case 'ar':
      case 'ar-sa':
        return 'ar-SA-ZariyahNeural';
      case 'hi-in':
        return 'hi-IN-SwaraNeural';
      case 'el-gr':
        return 'el-GR-AthinaNeural';
      default:
        return 'en-US-AriaNeural';
    }
  }

  /// Synthesizes text to audio using the WebSocket connection
  Future<Uint8List> synthesize(String ssml, AlouetteTTSConfig config) async {
    if (!_isConnected) {
      await connect();
    }

    _lastUsed = DateTime.now();

    try {
      // Use edge-tts command line tool as fallback
      return await _synthesizeViaEdgeTTS(ssml, config);
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSSynthesisException(
        'Synthesis failed: $e',
        text: ssml,
      );
    }
  }

  /// Use Python edge-tts library via process execution
  Future<Uint8List> _synthesizeViaEdgeTTS(String ssml, AlouetteTTSConfig config) async {
    try {
      // Extract text from SSML for edge-tts command line
      final text = _extractTextFromSSML(ssml);

      // Create temporary file for output (use MP3 format)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/tts_output_${DateTime.now().millisecondsSinceEpoch}.mp3');

      try {
    // Prepare logger and commands so we can record exact invocation and output
    final logger = RequestLogger();
    final voiceArg = config.voiceName ?? _getDefaultVoiceForLanguage(config.languageCode);

          // Some inputs (very short text or punctuation-only) cause the
          // edge-tts python library to return NoAudioReceived. Normalize and
          // pad very short texts to improve robustness.
          var cliText = text;
          if (cliText.trim().isEmpty) {
            throw TTSSynthesisException('Text cannot be empty', text: text);
          }
          if (cliText.trim().length < 3) {
            // Append a period to force audible output for very short phrases
            cliText = '${cliText.trim()}.';
          }

          final cliCmd = [
            'edge-tts',
            '--voice',
            voiceArg,
            '--text',
            cliText,
            '--write-media',
            tempFile.path,
          ];

        // Record intended CLI invocation (do not record full text if too long)
        await logger.logRequest({
          'operation': 'edge_cli_invoke',
          'method': 'edge-tts',
          'command': cliCmd,
          'voice': voiceArg,
          'textPreview': cliText.length > 200 ? cliText.substring(0, 200) + '...': cliText,
          'tempFile': tempFile.path,
        });

        // Try edge-tts command first
        final result = await Process.run(cliCmd.first, cliCmd.sublist(1));

        // Log stdout/stderr and exit code
        await logger.logResponse({
          'operation': 'edge_cli_invoke_result',
          'method': 'edge-tts',
          'exitCode': result.exitCode,
          'stdout': result.stdout?.toString(),
          'stderr': result.stderr?.toString(),
          'voice': voiceArg,
          'tempFile': tempFile.path,
        });

        if (result.exitCode != 0) {
          // Try with python -m edge_tts if direct command fails
          final pythonCmd = [
            'python',
            '-m',
            'edge_tts',
            '--voice',
            voiceArg,
            '--text',
            text,
            '--write-media',
            tempFile.path,
          ];

          await logger.logRequest({
            'operation': 'edge_cli_invoke',
            'method': 'python -m edge_tts',
            'command': pythonCmd,
            'voice': voiceArg,
            'textPreview': cliText.length > 200 ? cliText.substring(0, 200) + '...': cliText,
            'tempFile': tempFile.path,
          });

          final pythonResult = await Process.run(pythonCmd.first, pythonCmd.sublist(1));

          await logger.logResponse({
            'operation': 'edge_cli_invoke_result',
            'method': 'python -m edge_tts',
            'exitCode': pythonResult.exitCode,
            'stdout': pythonResult.stdout?.toString(),
            'stderr': pythonResult.stderr?.toString(),
            'voice': voiceArg,
            'tempFile': tempFile.path,
          });

          if (pythonResult.exitCode != 0) {
            throw TTSSynthesisException('Edge TTS failed: ${pythonResult.stderr}', text: text);
          }
        }

        // Read the generated audio file
        if (await tempFile.exists()) {
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        } else {
          throw TTSSynthesisException('Audio file was not generated', text: text);
        }

      } finally {
        // Preserve a copy for debugging, then clean up temporary file
        if (await tempFile.exists()) {
          try {
            final savedPath = '/tmp/alouette_last_tts.mp3';
            final savedFile = File(savedPath);
            await tempFile.copy(savedFile.path);
          } catch (e) {
            // Failed to copy temporary audio file for debugging
          }

          await tempFile.delete();
        }
      }

    } catch (e) {
      throw TTSSynthesisException('Failed to synthesize via Edge TTS: $e', text: ssml);
    }
  }

  /// Extract plain text from SSML
  String _extractTextFromSSML(String ssml) {
    // Simple SSML text extraction - remove XML tags
    return ssml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }

  /// Disconnects from the WebSocket service
  Future<void> disconnect() async {
    if (!_isConnected) return;
    _isConnected = false;
  }

  /// Gets the connection status
  bool get isConnected => _isConnected;
  
  /// Gets the last used time for connection management
  DateTime? get lastUsed => _lastUsed;
  
  /// Checks if the connection is idle for too long
  bool isIdleForDuration(Duration duration) {
    if (_lastUsed == null) return false;
    return DateTime.now().difference(_lastUsed!) > duration;
  }
}
