import 'package:meta/meta.dart';
import 'alouette_tts_config.dart';

/// Request model for batch TTS processing
@immutable
class TTSRequest {
  /// Unique identifier for this request
  final String id;
  
  /// Text to be synthesized
  final String text;
  
  /// Configuration for this specific request (optional)
  final AlouetteTTSConfig? config;
  
  /// Whether the text contains SSML markup
  final bool isSSML;
  
  /// Output file path for saving audio (optional)
  final String? outputPath;

  const TTSRequest({
    required this.id,
    required this.text,
    this.config,
    this.isSSML = false,
    this.outputPath,
  });

  /// Creates a simple text request
  factory TTSRequest.text({
    required String id,
    required String text,
    AlouetteTTSConfig? config,
    String? outputPath,
  }) {
    return TTSRequest(
      id: id,
      text: text,
      config: config,
      isSSML: false,
      outputPath: outputPath,
    );
  }

  /// Creates an SSML request
  factory TTSRequest.ssml({
    required String id,
    required String ssml,
    AlouetteTTSConfig? config,
    String? outputPath,
  }) {
    return TTSRequest(
      id: id,
      text: ssml,
      config: config,
      isSSML: true,
      outputPath: outputPath,
    );
  }

  /// Validates the request
  bool isValid() {
    if (id.isEmpty || text.isEmpty) return false;
    if (config != null && !config!.isValid()) return false;
    return true;
  }

  /// Creates a copy with modified values
  TTSRequest copyWith({
    String? id,
    String? text,
    AlouetteTTSConfig? config,
    bool? isSSML,
    String? outputPath,
  }) {
    return TTSRequest(
      id: id ?? this.id,
      text: text ?? this.text,
      config: config ?? this.config,
      isSSML: isSSML ?? this.isSSML,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  /// Converts to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'config': config?.toMap(),
      'isSSML': isSSML,
      'outputPath': outputPath,
    };
  }

  /// Creates an instance from a Map
  factory TTSRequest.fromMap(Map<String, dynamic> map) {
    return TTSRequest(
      id: map['id'] as String,
      text: map['text'] as String,
      config: map['config'] != null 
          ? AlouetteTTSConfig.fromMap(map['config'] as Map<String, dynamic>)
          : null,
      isSSML: map['isSSML'] as bool? ?? false,
      outputPath: map['outputPath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSRequest &&
        other.id == id &&
        other.text == text &&
        other.config == config &&
        other.isSSML == isSSML &&
        other.outputPath == outputPath;
  }

  @override
  int get hashCode {
    return Object.hash(id, text, config, isSSML, outputPath);
  }

  @override
  String toString() {
    return 'TTSRequest('
        'id: $id, '
        'text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'isSSML: $isSSML, '
        'outputPath: $outputPath)';
  }
}