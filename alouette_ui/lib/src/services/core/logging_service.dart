import 'dart:developer' as developer;

/// Centralized logging service for all Alouette applications
class LoggingService {
  static LoggingService? _instance;

  /// Get the singleton instance
  static LoggingService get instance {
    _instance ??= LoggingService._internal();
    return _instance!;
  }

  LoggingService._internal();

  /// Current log level
  LogLevel _logLevel = LogLevel.info;

  /// List of log listeners for custom handling
  final List<LogListener> _listeners = [];

  /// Maximum number of logs to keep in memory
  static const int _maxLogEntries = 1000;

  /// In-memory log storage for debugging
  final List<LogEntry> _logEntries = [];

  /// Set the minimum log level
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// Add a log listener for custom handling
  void addListener(LogListener listener) {
    _listeners.add(listener);
  }

  /// Remove a log listener
  void removeListener(LogListener listener) {
    _listeners.remove(listener);
  }

  /// Log a debug message
  void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? details,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: tag,
      details: details,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an info message
  void info(String message, {String? tag, Map<String, dynamic>? details}) {
    _log(LogLevel.info, message, tag: tag, details: details);
  }

  /// Log a warning message
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? details,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      details: details,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? details,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      details: details,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a fatal error message
  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? details,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      details: details,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an Alouette error with automatic error code extraction
  void logAlouetteError(
    dynamic alouetteError, {
    String? tag,
    Map<String, dynamic>? additionalDetails,
  }) {
    if (alouetteError == null) return;

    String message;
    String? errorCode;
    Map<String, dynamic>? details;
    bool isRecoverable = false;
    List<String> recoveryActions = [];

    // Check if it's an Alouette error with our standard interface
    if (alouetteError is Error) {
      try {
        // Use reflection-like approach to get properties
        final errorString = alouetteError.toString();
        message = errorString;

        // Try to extract error code from string format [CODE]
        final codeMatch = RegExp(r'\[([A-Z_]+)\]').firstMatch(errorString);
        if (codeMatch != null) {
          errorCode = codeMatch.group(1);
        }

        // Try to get additional properties if they exist
        if (alouetteError.runtimeType.toString().contains('Alouette')) {
          try {
            // Use dynamic access to get properties
            final dynamic dynError = alouetteError;
            if (dynError.userMessage != null) {
              message = dynError.userMessage;
            }
            if (dynError.code != null) {
              errorCode = dynError.code;
            }
            if (dynError.details != null) {
              details = Map<String, dynamic>.from(dynError.details);
            }
            if (dynError.isRecoverable != null) {
              isRecoverable = dynError.isRecoverable;
            }
            if (dynError.recoveryActions != null) {
              recoveryActions = List<String>.from(dynError.recoveryActions);
            }
          } catch (e) {
            // Fallback to basic error handling
          }
        }
      } catch (e) {
        message = alouetteError.toString();
      }
    } else {
      message = alouetteError.toString();
    }

    final combinedDetails = <String, dynamic>{
      if (errorCode != null) 'errorCode': errorCode,
      if (details != null) ...details,
      if (additionalDetails != null) ...additionalDetails,
      'isRecoverable': isRecoverable,
      if (recoveryActions.isNotEmpty) 'recoveryActions': recoveryActions,
    };

    error(
      message,
      tag: tag ?? 'AlouetteError',
      details: combinedDetails,
      error: alouetteError,
    );
  }

  /// Get recent log entries for debugging
  List<LogEntry> getRecentLogs({LogLevel? minLevel, String? tag, int? limit}) {
    var filtered = _logEntries.where((entry) {
      if (minLevel != null && entry.level.index < minLevel.index) return false;
      if (tag != null && entry.tag != tag) return false;
      return true;
    }).toList();

    // Sort by timestamp (most recent first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  /// Clear all stored log entries
  void clearLogs() {
    _logEntries.clear();
  }

  /// Export logs as formatted string
  String exportLogs({LogLevel? minLevel, String? tag}) {
    final logs = getRecentLogs(minLevel: minLevel, tag: tag);
    final buffer = StringBuffer();

    buffer.writeln('=== Alouette Application Logs ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln();

    for (final log in logs) {
      buffer.writeln(
        '${log.timestamp.toIso8601String()} [${log.level.name.toUpperCase()}] ${log.tag ?? 'APP'}: ${log.message}',
      );
      if (log.details != null && log.details!.isNotEmpty) {
        buffer.writeln('  Details: ${log.details}');
      }
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  Stack: ${log.stackTrace}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? details,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.index < _logLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      details: details,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Add to in-memory storage
    _logEntries.add(entry);

    // Maintain max entries limit
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeAt(0);
    }

    // Log to system console
    _logToConsole(entry);

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener.onLog(entry);
      } catch (e) {
        // Don't let listener errors break logging
        developer.log('Error in log listener: $e', name: 'LoggingService');
      }
    }
  }

  void _logToConsole(LogEntry entry) {
    final prefix = '[${entry.level.name.toUpperCase()}]';
    final tag = entry.tag != null ? ' ${entry.tag}:' : '';
    final message = '$prefix$tag ${entry.message}';

    switch (entry.level) {
      case LogLevel.debug:
        developer.log(message, name: 'Alouette', level: 500);
        break;
      case LogLevel.info:
        developer.log(message, name: 'Alouette', level: 800);
        break;
      case LogLevel.warning:
        developer.log(
          message,
          name: 'Alouette',
          level: 900,
          error: entry.error,
          stackTrace: entry.stackTrace,
        );
        break;
      case LogLevel.error:
        developer.log(
          message,
          name: 'Alouette',
          level: 1000,
          error: entry.error,
          stackTrace: entry.stackTrace,
        );
        break;
      case LogLevel.fatal:
        developer.log(
          message,
          name: 'Alouette',
          level: 1200,
          error: entry.error,
          stackTrace: entry.stackTrace,
        );
        break;
    }

    if (entry.details != null && entry.details!.isNotEmpty) {
      developer.log('Details: ${entry.details}', name: 'Alouette');
    }
  }
}

/// Log levels in order of severity
enum LogLevel { debug, info, warning, error, fatal }

/// A single log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? details;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.details,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] ${tag ?? 'APP'}: $message';
  }
}

/// Interface for custom log listeners
abstract class LogListener {
  void onLog(LogEntry entry);
}

/// File-based log listener (for persistent logging)
class FileLogListener implements LogListener {
  final String filePath;
  final LogLevel minLevel;

  FileLogListener(this.filePath, {this.minLevel = LogLevel.info});

  @override
  void onLog(LogEntry entry) {
    if (entry.level.index < minLevel.index) return;

    // File writing implementation would go here
    // This would require platform-specific file I/O implementation
  }
}

/// Network log listener (for remote logging)
class NetworkLogListener implements LogListener {
  final String endpoint;
  final LogLevel minLevel;

  NetworkLogListener(this.endpoint, {this.minLevel = LogLevel.warning});

  @override
  void onLog(LogEntry entry) {
    if (entry.level.index < minLevel.index) return;

    // Network logging implementation would go here
    // This would send logs to a remote endpoint
  }
}
