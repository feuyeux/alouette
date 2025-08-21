import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../exceptions/tts_exception.dart';
import '../../enums/tts_error_code.dart';
import '../../models/alouette_tts_config.dart';
import 'edge_tts_connection_pool.dart';

/// WebSocket client for Edge TTS service
class EdgeTTSWebSocketClient {
  static const String _edgeTTSUrl =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/realtimestreaming/edge/v1';
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';

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
    print('DEBUG: Using edge-tts command line fallback instead of WebSocket');
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
  // Log the local audio file path for debugging playback issues
  print('DEBUG: edge-tts temp audio path -> ${tempFile.path}');
      
      try {
        // Try edge-tts command first
        final result = await Process.run('edge-tts', [
          '--voice', config.voiceName ?? 'Microsoft Server Speech Text to Speech Voice (en-US, JennyNeural)',
          '--text', text,
          '--write-media', tempFile.path,
        ]);
        
        if (result.exitCode != 0) {
          // Try with python -m edge_tts if direct command fails
          final pythonResult = await Process.run('python', [
            '-m', 'edge_tts',
            '--voice', config.voiceName ?? 'Microsoft Server Speech Text to Speech Voice (en-US, JennyNeural)',
            '--text', text,
            '--write-media', tempFile.path,
          ]);
          
          if (pythonResult.exitCode != 0) {
            throw TTSSynthesisException('Edge TTS failed: ${pythonResult.stderr}', text: text);
          }
        }
        
        // Read the generated audio file
        if (await tempFile.exists()) {
          print('DEBUG: edge-tts generated audio file found at ${tempFile.path}');
          final audioData = await tempFile.readAsBytes();
          return Uint8List.fromList(audioData);
        } else {
          print('DEBUG: edge-tts did not generate audio at expected path: ${tempFile.path}');
          throw TTSSynthesisException('Audio file was not generated', text: text);
        }
        
      } finally {
        // Preserve a copy for debugging, then clean up temporary file
        if (await tempFile.exists()) {
          try {
            final savedPath = '/tmp/alouette_last_tts.mp3';
            final savedFile = File(savedPath);
            await tempFile.copy(savedFile.path);
            print('DEBUG: Copied temporary audio to $savedPath');
          } catch (e) {
            print('DEBUG: Failed to copy temporary audio file for debugging: $e');
          }

          print('DEBUG: Deleting temporary audio file ${tempFile.path}');
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
    print('DEBUG: Disconnected from Edge TTS service');
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
