/// Connection status model for LLM provider connectivity testing
class ConnectionStatus {
  /// Whether the connection was successful
  final bool success;

  /// Human-readable message describing the connection status
  final String message;

  /// Number of available models (if connection was successful)
  final int? modelCount;

  /// Timestamp when the connection test was performed
  final DateTime timestamp;

  /// Response time in milliseconds (if available)
  final int? responseTimeMs;

  /// Additional details about the connection test
  final Map<String, dynamic>? details;

  const ConnectionStatus({
    required this.success,
    required this.message,
    this.modelCount,
    required this.timestamp,
    this.responseTimeMs,
    this.details,
  });

  /// Create a successful connection status
  factory ConnectionStatus.success({
    required String message,
    int? modelCount,
    int? responseTimeMs,
    Map<String, dynamic>? details,
  }) {
    return ConnectionStatus(
      success: true,
      message: message,
      modelCount: modelCount,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      details: details,
    );
  }

  /// Create a failed connection status
  factory ConnectionStatus.failure({
    required String message,
    int? responseTimeMs,
    Map<String, dynamic>? details,
  }) {
    return ConnectionStatus(
      success: false,
      message: message,
      modelCount: null,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      details: details,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'model_count': modelCount,
      'timestamp': timestamp.toIso8601String(),
      'response_time_ms': responseTimeMs,
      'details': details,
    };
  }

  /// Create from JSON representation
  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      modelCount: json['model_count'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      responseTimeMs: json['response_time_ms'],
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : null,
    );
  }

  /// Create a copy with modified fields
  ConnectionStatus copyWith({
    bool? success,
    String? message,
    int? modelCount,
    DateTime? timestamp,
    int? responseTimeMs,
    Map<String, dynamic>? details,
  }) {
    return ConnectionStatus(
      success: success ?? this.success,
      message: message ?? this.message,
      modelCount: modelCount ?? this.modelCount,
      timestamp: timestamp ?? this.timestamp,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      details: details ?? this.details,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionStatus &&
        other.success == success &&
        other.message == message &&
        other.modelCount == modelCount &&
        other.timestamp == timestamp &&
        other.responseTimeMs == responseTimeMs;
  }

  @override
  int get hashCode {
    return Object.hash(success, message, modelCount, timestamp, responseTimeMs);
  }

  @override
  String toString() {
    return 'ConnectionStatus(success: $success, message: $message, '
        'modelCount: $modelCount, responseTime: ${responseTimeMs}ms)';
  }
}
