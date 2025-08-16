import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'alouette_voice.dart';

/// Result model for TTS operations
@immutable
class TTSResult {
  /// ID of the original request
  final String requestId;
  
  /// Whether the operation was successful
  final bool success;
  
  /// Generated audio data (if successful and requested)
  final Uint8List? audioData;
  
  /// File path where audio was saved (if applicable)
  final String? filePath;
  
  /// Error message (if operation failed)
  final String? error;
  
  /// Time taken to process the request
  final Duration processingTime;
  
  /// Voice that was used for synthesis
  final AlouetteVoice? usedVoice;

  const TTSResult({
    required this.requestId,
    required this.success,
    this.audioData,
    this.filePath,
    this.error,
    required this.processingTime,
    this.usedVoice,
  });

  /// Creates a successful result
  factory TTSResult.success({
    required String requestId,
    required Duration processingTime,
    Uint8List? audioData,
    String? filePath,
    AlouetteVoice? usedVoice,
  }) {
    return TTSResult(
      requestId: requestId,
      success: true,
      audioData: audioData,
      filePath: filePath,
      processingTime: processingTime,
      usedVoice: usedVoice,
    );
  }

  /// Creates a failed result
  factory TTSResult.failure({
    required String requestId,
    required String error,
    required Duration processingTime,
  }) {
    return TTSResult(
      requestId: requestId,
      success: false,
      error: error,
      processingTime: processingTime,
    );
  }

  /// Returns the size of audio data in bytes
  int? get audioSizeBytes => audioData?.length;

  /// Returns the processing time in milliseconds
  int get processingTimeMs => processingTime.inMilliseconds;

  /// Returns a human-readable processing time
  String get processingTimeFormatted {
    if (processingTime.inSeconds > 0) {
      return '${processingTime.inSeconds}.${(processingTime.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
    }
    return '${processingTime.inMilliseconds}ms';
  }

  /// Creates a copy with modified values
  TTSResult copyWith({
    String? requestId,
    bool? success,
    Uint8List? audioData,
    String? filePath,
    String? error,
    Duration? processingTime,
    AlouetteVoice? usedVoice,
  }) {
    return TTSResult(
      requestId: requestId ?? this.requestId,
      success: success ?? this.success,
      audioData: audioData ?? this.audioData,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
      processingTime: processingTime ?? this.processingTime,
      usedVoice: usedVoice ?? this.usedVoice,
    );
  }

  /// Converts to a Map for serialization (excluding binary audio data)
  Map<String, dynamic> toMap({bool includeAudioData = false}) {
    return {
      'requestId': requestId,
      'success': success,
      'audioData': includeAudioData ? audioData : null,
      'filePath': filePath,
      'error': error,
      'processingTimeMs': processingTimeMs,
      'usedVoice': usedVoice?.toMap(),
    };
  }

  /// Creates an instance from a Map
  factory TTSResult.fromMap(Map<String, dynamic> map) {
    return TTSResult(
      requestId: map['requestId'] as String,
      success: map['success'] as bool,
      audioData: map['audioData'] as Uint8List?,
      filePath: map['filePath'] as String?,
      error: map['error'] as String?,
      processingTime: Duration(milliseconds: map['processingTimeMs'] as int? ?? 0),
      usedVoice: map['usedVoice'] != null 
          ? AlouetteVoice.fromMap(map['usedVoice'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSResult &&
        other.requestId == requestId &&
        other.success == success &&
        other.filePath == filePath &&
        other.error == error &&
        other.processingTime == processingTime &&
        other.usedVoice == usedVoice;
  }

  @override
  int get hashCode {
    return Object.hash(
      requestId,
      success,
      filePath,
      error,
      processingTime,
      usedVoice,
    );
  }

  @override
  String toString() {
    return 'TTSResult('
        'requestId: $requestId, '
        'success: $success, '
        'processingTime: $processingTimeFormatted'
        '${error != null ? ', error: $error' : ''}'
        '${filePath != null ? ', filePath: $filePath' : ''})';
  }
}