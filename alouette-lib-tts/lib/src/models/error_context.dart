import '../enums/tts_platform.dart';

/// Provides detailed context information for TTS errors
class TTSErrorContext {
  /// Timestamp when the error occurred
  final DateTime timestamp;

  /// Platform where the error occurred
  final TTSPlatform platform;

  /// Operation that was being performed when error occurred
  final String operation;

  /// Additional context data
  final Map<String, dynamic> contextData;

  /// Stack trace information
  final StackTrace? stackTrace;

  /// Session ID for tracking related operations
  final String? sessionId;

  /// Request ID for tracking specific requests
  final String? requestId;

  const TTSErrorContext({
    required this.timestamp,
    required this.platform,
    required this.operation,
    this.contextData = const {},
    this.stackTrace,
    this.sessionId,
    this.requestId,
  });

  /// Creates error context for the current moment
  factory TTSErrorContext.now({
    required TTSPlatform platform,
    required String operation,
    Map<String, dynamic> contextData = const {},
    StackTrace? stackTrace,
    String? sessionId,
    String? requestId,
  }) {
    return TTSErrorContext(
      timestamp: DateTime.now(),
      platform: platform,
      operation: operation,
      contextData: contextData,
      stackTrace: stackTrace,
      sessionId: sessionId,
      requestId: requestId,
    );
  }

  /// Creates a copy with updated context data
  TTSErrorContext copyWith({
    DateTime? timestamp,
    TTSPlatform? platform,
    String? operation,
    Map<String, dynamic>? contextData,
    StackTrace? stackTrace,
    String? sessionId,
    String? requestId,
  }) {
    return TTSErrorContext(
      timestamp: timestamp ?? this.timestamp,
      platform: platform ?? this.platform,
      operation: operation ?? this.operation,
      contextData: contextData ?? this.contextData,
      stackTrace: stackTrace ?? this.stackTrace,
      sessionId: sessionId ?? this.sessionId,
      requestId: requestId ?? this.requestId,
    );
  }

  /// Adds additional context data
  TTSErrorContext withContext(String key, dynamic value) {
    final newContextData = Map<String, dynamic>.from(contextData);
    newContextData[key] = value;
    return copyWith(contextData: newContextData);
  }

  /// Converts to a map for logging/serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'platform': platform.platformName,
      'operation': operation,
      'contextData': contextData,
      'sessionId': sessionId,
      'requestId': requestId,
      'hasStackTrace': stackTrace != null,
    };
  }

  /// Creates a formatted string for debugging
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('TTS Error Context:');
    buffer.writeln('  Timestamp: ${timestamp.toIso8601String()}');
    buffer.writeln('  Platform: ${platform.platformName}');
    buffer.writeln('  Operation: $operation');

    if (sessionId != null) {
      buffer.writeln('  Session ID: $sessionId');
    }

    if (requestId != null) {
      buffer.writeln('  Request ID: $requestId');
    }

    if (contextData.isNotEmpty) {
      buffer.writeln('  Context Data:');
      contextData.forEach((key, value) {
        buffer.writeln('    $key: $value');
      });
    }

    if (stackTrace != null) {
      buffer.writeln('  Stack Trace Available: Yes');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'TTSErrorContext(platform: ${platform.platformName}, operation: $operation, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TTSErrorContext &&
        other.timestamp == timestamp &&
        other.platform == platform &&
        other.operation == operation &&
        other.sessionId == sessionId &&
        other.requestId == requestId;
  }

  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      platform,
      operation,
      sessionId,
      requestId,
    );
  }
}

/// Builder class for creating TTSErrorContext instances
class TTSErrorContextBuilder {
  TTSPlatform? _platform;
  String? _operation;
  final Map<String, dynamic> _contextData = {};
  StackTrace? _stackTrace;
  String? _sessionId;
  String? _requestId;

  /// Sets the platform
  TTSErrorContextBuilder platform(TTSPlatform platform) {
    _platform = platform;
    return this;
  }

  /// Sets the operation
  TTSErrorContextBuilder operation(String operation) {
    _operation = operation;
    return this;
  }

  /// Adds context data
  TTSErrorContextBuilder context(String key, dynamic value) {
    _contextData[key] = value;
    return this;
  }

  /// Adds multiple context entries
  TTSErrorContextBuilder contexts(Map<String, dynamic> contexts) {
    _contextData.addAll(contexts);
    return this;
  }

  /// Sets the stack trace
  TTSErrorContextBuilder stackTrace(StackTrace stackTrace) {
    _stackTrace = stackTrace;
    return this;
  }

  /// Sets the session ID
  TTSErrorContextBuilder sessionId(String sessionId) {
    _sessionId = sessionId;
    return this;
  }

  /// Sets the request ID
  TTSErrorContextBuilder requestId(String requestId) {
    _requestId = requestId;
    return this;
  }

  /// Builds the error context
  TTSErrorContext build() {
    if (_platform == null) {
      throw ArgumentError('Platform is required');
    }
    if (_operation == null) {
      throw ArgumentError('Operation is required');
    }

    return TTSErrorContext.now(
      platform: _platform!,
      operation: _operation!,
      contextData: Map.from(_contextData),
      stackTrace: _stackTrace,
      sessionId: _sessionId,
      requestId: _requestId,
    );
  }
}
