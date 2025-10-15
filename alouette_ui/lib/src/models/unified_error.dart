/// Unified error model for consistent error handling across all Alouette applications
///
/// This is the standardized error model used across all Alouette applications
/// for error reporting and handling. It includes comprehensive validation and serialization.
class UnifiedError extends Error {
  /// Error message
  final String message;

  /// Error code for programmatic handling
  final String? code;

  /// Error category (translation, tts, ui, network, etc.)
  final ErrorCategory category;

  /// Error severity level
  final ErrorSeverity severity;

  /// Original error object (if any)
  final dynamic originalError;

  /// Stack trace (if available)
  final StackTrace? stackTrace;

  /// Timestamp when error occurred
  final DateTime timestamp;

  /// Additional context information
  final Map<String, dynamic>? context;

  /// Suggested recovery actions
  final List<String> recoveryActions;

  UnifiedError({
    required this.message,
    this.code,
    this.category = ErrorCategory.general,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
    this.context,
    this.recoveryActions = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a translation error
  factory UnifiedError.translation({
    required String message,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String> recoveryActions = const [],
  }) {
    return UnifiedError(
      message: message,
      code: code,
      category: ErrorCategory.translation,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      context: context,
      recoveryActions: recoveryActions,
    );
  }

  /// Create a TTS error
  factory UnifiedError.tts({
    required String message,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String> recoveryActions = const [],
  }) {
    return UnifiedError(
      message: message,
      code: code,
      category: ErrorCategory.tts,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      context: context,
      recoveryActions: recoveryActions,
    );
  }

  /// Create a UI error
  factory UnifiedError.ui({
    required String message,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String> recoveryActions = const [],
  }) {
    return UnifiedError(
      message: message,
      code: code,
      category: ErrorCategory.ui,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      context: context,
      recoveryActions: recoveryActions,
    );
  }

  /// Create a network error
  factory UnifiedError.network({
    required String message,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String> recoveryActions = const [],
  }) {
    return UnifiedError(
      message: message,
      code: code,
      category: ErrorCategory.network,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      context: context,
      recoveryActions: recoveryActions,
    );
  }

  /// Create a configuration error
  factory UnifiedError.configuration({
    required String message,
    String? code,
    ErrorSeverity severity = ErrorSeverity.error,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    List<String> recoveryActions = const [],
  }) {
    return UnifiedError(
      message: message,
      code: code,
      category: ErrorCategory.configuration,
      severity: severity,
      originalError: originalError,
      stackTrace: stackTrace,
      context: context,
      recoveryActions: recoveryActions,
    );
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'category': category.name,
      'severity': severity.name,
      'original_error': originalError?.toString(),
      'stack_trace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'recovery_actions': recoveryActions,
    };
  }

  /// Create from JSON representation
  factory UnifiedError.fromJson(Map<String, dynamic> json) {
    return UnifiedError(
      message: json['message'] ?? 'Unknown error',
      code: json['code'],
      category: ErrorCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ErrorCategory.general,
      ),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      originalError: json['original_error'],
      stackTrace: json['stack_trace'] != null
          ? StackTrace.fromString(json['stack_trace'])
          : null,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      context: json['context'] != null
          ? Map<String, dynamic>.from(json['context'])
          : null,
      recoveryActions: json['recovery_actions'] != null
          ? List<String>.from(json['recovery_actions'])
          : [],
    );
  }

  /// Create a copy with modified fields
  UnifiedError copyWith({
    String? message,
    String? code,
    ErrorCategory? category,
    ErrorSeverity? severity,
    dynamic originalError,
    StackTrace? stackTrace,
    DateTime? timestamp,
    Map<String, dynamic>? context,
    List<String>? recoveryActions,
  }) {
    return UnifiedError(
      message: message ?? this.message,
      code: code ?? this.code,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      originalError: originalError ?? this.originalError,
      stackTrace: stackTrace ?? this.stackTrace,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      recoveryActions: recoveryActions ?? this.recoveryActions,
    );
  }

  /// Check if this is a critical error
  bool get isCritical => severity == ErrorSeverity.critical;

  /// Check if this is a warning
  bool get isWarning => severity == ErrorSeverity.warning;

  /// Check if this error is recoverable
  bool get isRecoverable => recoveryActions.isNotEmpty;

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (category) {
      case ErrorCategory.translation:
        return 'Translation error: $message';
      case ErrorCategory.tts:
        return 'Text-to-speech error: $message';
      case ErrorCategory.network:
        return 'Network error: $message';
      case ErrorCategory.configuration:
        return 'Configuration error: $message';
      case ErrorCategory.ui:
        return 'Interface error: $message';
      case ErrorCategory.general:
      default:
        return message;
    }
  }

  @override
  String toString() {
    return 'UnifiedError(${category.name}/${severity.name}): $message${code != null ? ' (Code: $code)' : ''}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedError &&
        other.message == message &&
        other.code == code &&
        other.category == category &&
        other.severity == severity &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(message, code, category, severity, timestamp);
  }
}

/// Error category enumeration
enum ErrorCategory {
  general,
  translation,
  tts,
  ui,
  network,
  configuration,
  validation,
  authentication,
  permission,
  storage,
}

/// Error severity enumeration
enum ErrorSeverity { info, warning, error, critical }

/// Extension methods for ErrorCategory
extension ErrorCategoryExtension on ErrorCategory {
  /// Get display name for the category
  String get displayName {
    switch (this) {
      case ErrorCategory.general:
        return 'General';
      case ErrorCategory.translation:
        return 'Translation';
      case ErrorCategory.tts:
        return 'Text-to-Speech';
      case ErrorCategory.ui:
        return 'User Interface';
      case ErrorCategory.network:
        return 'Network';
      case ErrorCategory.configuration:
        return 'Configuration';
      case ErrorCategory.validation:
        return 'Validation';
      case ErrorCategory.authentication:
        return 'Authentication';
      case ErrorCategory.permission:
        return 'Permission';
      case ErrorCategory.storage:
        return 'Storage';
    }
  }

  /// Get icon name for the category
  String get iconName {
    switch (this) {
      case ErrorCategory.general:
        return 'error';
      case ErrorCategory.translation:
        return 'translate';
      case ErrorCategory.tts:
        return 'volume_up';
      case ErrorCategory.ui:
        return 'interface';
      case ErrorCategory.network:
        return 'wifi_off';
      case ErrorCategory.configuration:
        return 'settings';
      case ErrorCategory.validation:
        return 'check_circle';
      case ErrorCategory.authentication:
        return 'lock';
      case ErrorCategory.permission:
        return 'security';
      case ErrorCategory.storage:
        return 'storage';
    }
  }
}

/// Extension methods for ErrorSeverity
extension ErrorSeverityExtension on ErrorSeverity {
  /// Get display name for the severity
  String get displayName {
    switch (this) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical';
    }
  }

  /// Get color for the severity
  String get colorName {
    switch (this) {
      case ErrorSeverity.info:
        return 'blue';
      case ErrorSeverity.warning:
        return 'orange';
      case ErrorSeverity.error:
        return 'red';
      case ErrorSeverity.critical:
        return 'darkred';
    }
  }

  /// Get priority level (higher number = higher priority)
  int get priority {
    switch (this) {
      case ErrorSeverity.info:
        return 1;
      case ErrorSeverity.warning:
        return 2;
      case ErrorSeverity.error:
        return 3;
      case ErrorSeverity.critical:
        return 4;
    }
  }
}
