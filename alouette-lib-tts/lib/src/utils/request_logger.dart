import 'dart:convert';
import 'dart:io';

/// Simple request/response logger for TTS operations.
/// Logs are appended to a file under the package's working directory.
class RequestLogger {
  final String logFilePath;

  RequestLogger({String? path}) : logFilePath = path ?? 'alouette_tts_requests.log';

  Future<void> logRequest(Map<String, dynamic> req) async {
    final entry = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'type': 'request',
      'payload': req,
    };
    await _append(entry);
    // Also print a concise line to the console for real-time visibility
    try {
      final op = req['operation'] ?? req['op'] ?? 'unknown';
      final lang = (req['config'] is Map) ? (req['config']['language'] ?? req['config']['languageCode']) : null;
      print('[TTS][request] $op ${lang ?? ''} ${req['text'] ?? ''}');
    } catch (_) {}
  }

  Future<void> logResponse(Map<String, dynamic> res) async {
    final entry = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'type': 'response',
      'payload': res,
    };
    await _append(entry);
    // Also print a concise response line so terminal shows the result immediately
    try {
      final op = res['operation'] ?? 'response';
      final status = res['status'] ?? '';
      final lang = res['requestedLanguage'] ?? res['language'] ?? '';
      final size = res['audioSizeBytes'] != null ? ' size=${res['audioSizeBytes']}' : '';
      print('[TTS][response] $op $status $lang$size');
    } catch (_) {}
  }

  Future<void> _append(Map<String, dynamic> entry) async {
    try {
      final file = File(logFilePath);
      await file.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Swallow IO errors to avoid breaking TTS flow during logging
    }
  }
}
