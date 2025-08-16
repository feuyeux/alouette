import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../../exceptions/tts_exception.dart';
import '../../enums/tts_error_code.dart';
import '../../models/alouette_tts_config.dart';

/// WebSocket client for Edge TTS service
class EdgeTTSWebSocketClient {
  static const String _edgeTTSUrl =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/realtimestreaming/edge/v1';
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';

  WebSocketChannel? _channel;
  final Completer<Uint8List> _audioCompleter = Completer<Uint8List>();
  final List<int> _audioBuffer = [];
  bool _isConnected = false;
  String? _requestId;

  /// Connects to the Edge TTS WebSocket service
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final uri = Uri.parse(_edgeTTSUrl).replace(queryParameters: {
        'TrustedClientToken': _trustedClientToken,
        'ConnectionId': const Uuid().v4(),
      });

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      // Listen for incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Send configuration message
      await _sendConfigMessage();
    } catch (e) {
      _isConnected = false;
      throw TTSNetworkException(
        'Failed to connect to Edge TTS service: $e',
        endpoint: _edgeTTSUrl,
        errorCode: TTSErrorCode.connectionFailed,
      );
    }
  }

  /// Synthesizes text to audio using the WebSocket connection
  Future<Uint8List> synthesize(String ssml, AlouetteTTSConfig config) async {
    if (!_isConnected) {
      await connect();
    }

    _requestId = const Uuid().v4();
    _audioBuffer.clear();

    try {
      // Send synthesis request
      await _sendSynthesisRequest(ssml, config);

      // Wait for audio data
      final audioData = await _audioCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TTSSynthesisException(
          'Synthesis timeout after 30 seconds',
          text: ssml,
          timeoutDuration: const Duration(seconds: 30),
        ),
      );

      return audioData;
    } catch (e) {
      if (e is TTSException) rethrow;
      throw TTSSynthesisException(
        'Synthesis failed: $e',
        text: ssml,
      );
    }
  }

  /// Disconnects from the WebSocket service
  Future<void> disconnect() async {
    if (!_isConnected) return;

    _isConnected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Sends the initial configuration message
  Future<void> _sendConfigMessage() async {
    final configMessage =
        'X-Timestamp:${DateTime.now().toUtc().toIso8601String()}\r\n'
        'Content-Type:application/json; charset=utf-8\r\n'
        'Path:speech.config\r\n\r\n'
        '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}';

    _channel?.sink.add(configMessage);
  }

  /// Sends the synthesis request message
  Future<void> _sendSynthesisRequest(
      String ssml, AlouetteTTSConfig config) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final synthesisMessage = 'X-RequestId:$_requestId\r\n'
        'X-Timestamp:$timestamp\r\n'
        'Content-Type:application/ssml+xml\r\n'
        'Path:ssml\r\n\r\n'
        '$ssml';

    _channel?.sink.add(synthesisMessage);
  }

  /// Handles incoming WebSocket messages
  void _handleMessage(dynamic message) {
    if (message is String) {
      _handleTextMessage(message);
    } else if (message is List<int>) {
      _handleBinaryMessage(message);
    }
  }

  /// Handles text messages from the WebSocket
  void _handleTextMessage(String message) {
    final lines = message.split('\r\n');
    final headers = <String, String>{};

    // Parse headers
    for (final line in lines) {
      if (line.isEmpty) break;
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex);
        final value = line.substring(colonIndex + 1);
        headers[key] = value;
      }
    }

    final path = headers['Path'];

    if (path == 'turn.end') {
      // Synthesis complete
      if (!_audioCompleter.isCompleted) {
        _audioCompleter.complete(Uint8List.fromList(_audioBuffer));
      }
    } else if (path == 'response') {
      // Handle response messages (errors, etc.)
      final bodyStart = message.indexOf('\r\n\r\n');
      if (bodyStart >= 0) {
        final body = message.substring(bodyStart + 4);
        try {
          final responseData = jsonDecode(body);
          if (responseData['error'] != null) {
            _handleSynthesisError(responseData['error']);
          }
        } catch (e) {
          // Ignore JSON parsing errors for non-JSON responses
        }
      }
    }
  }

  /// Handles binary messages (audio data) from the WebSocket
  void _handleBinaryMessage(List<int> message) {
    // Edge TTS sends binary messages with headers followed by audio data
    // The audio data starts after the first occurrence of 0x00, 0x67, 0x58
    const audioMarker = [0x00, 0x67, 0x58];

    for (int i = 0; i <= message.length - audioMarker.length; i++) {
      bool found = true;
      for (int j = 0; j < audioMarker.length; j++) {
        if (message[i + j] != audioMarker[j]) {
          found = false;
          break;
        }
      }

      if (found) {
        // Found audio data marker, add the audio data to buffer
        final audioData = message.sublist(i + audioMarker.length);
        _audioBuffer.addAll(audioData);
        break;
      }
    }
  }

  /// Handles synthesis errors
  void _handleSynthesisError(Map<String, dynamic> error) {
    final errorMessage =
        error['message'] as String? ?? 'Unknown synthesis error';

    if (!_audioCompleter.isCompleted) {
      _audioCompleter.completeError(
        TTSSynthesisException(
          errorMessage,
          text: '',
          errorCode: TTSErrorCode.synthesisEngineError,
        ),
      );
    }
  }

  /// Handles WebSocket errors
  void _handleError(dynamic error) {
    _isConnected = false;

    if (!_audioCompleter.isCompleted) {
      _audioCompleter.completeError(
        TTSNetworkException(
          'WebSocket error: $error',
          endpoint: _edgeTTSUrl,
          errorCode: TTSErrorCode.connectionFailed,
        ),
      );
    }
  }

  /// Handles WebSocket disconnection
  void _handleDisconnect() {
    _isConnected = false;

    if (!_audioCompleter.isCompleted) {
      _audioCompleter.completeError(
        TTSNetworkException(
          'WebSocket connection closed unexpectedly',
          endpoint: _edgeTTSUrl,
        ),
      );
    }
  }

  /// Gets the connection status
  bool get isConnected => _isConnected;
}
