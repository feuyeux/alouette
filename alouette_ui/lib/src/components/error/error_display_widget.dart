import 'package:flutter/material.dart';

/// Widget for displaying user-friendly error messages with recovery actions
class ErrorDisplayWidget extends StatelessWidget {
  /// The error to display
  final dynamic error;

  /// Custom title for the error (optional)
  final String? title;

  /// Custom message for the error (optional)
  final String? message;

  /// Callback for retry action
  final VoidCallback? onRetry;

  /// Callback for dismiss action
  final VoidCallback? onDismiss;

  /// Additional custom actions
  final List<ErrorAction>? customActions;

  /// Whether to show technical details
  final bool showTechnicalDetails;

  /// Whether to show recovery suggestions
  final bool showRecoveryActions;

  /// Icon to display with the error
  final IconData? icon;

  /// Color scheme for the error display
  final ErrorDisplayType type;

  const ErrorDisplayWidget({
    Key? key,
    required this.error,
    this.title,
    this.message,
    this.onRetry,
    this.onDismiss,
    this.customActions,
    this.showTechnicalDetails = false,
    this.showRecoveryActions = true,
    this.icon,
    this.type = ErrorDisplayType.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorInfo = _extractErrorInfo();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Row(
              children: [
                Icon(
                  icon ?? _getDefaultIcon(),
                  color: _getColor(theme),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title ?? errorInfo.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getColor(theme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // User-friendly message
            Text(
              message ?? errorInfo.userMessage,
              style: theme.textTheme.bodyMedium,
            ),

            // Recovery actions
            if (showRecoveryActions &&
                errorInfo.recoveryActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Suggested actions:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...errorInfo.recoveryActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(action)),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons
            if (_hasActions()) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  if (onRetry != null && errorInfo.isRecoverable)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ...?customActions?.map(
                    (action) => action.isElevated
                        ? ElevatedButton.icon(
                            onPressed: action.onPressed,
                            icon: action.icon != null
                                ? Icon(action.icon)
                                : null,
                            label: Text(action.label),
                          )
                        : TextButton.icon(
                            onPressed: action.onPressed,
                            icon: action.icon != null
                                ? Icon(action.icon)
                                : null,
                            label: Text(action.label),
                          ),
                  ),
                ],
              ),
            ],

            // Technical details (expandable)
            if (showTechnicalDetails) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorInfo.errorCode != null) ...[
                          Text(
                            'Error Code: ${errorInfo.errorCode}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Technical Message: ${errorInfo.technicalMessage}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (errorInfo.timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Timestamp: ${errorInfo.timestamp}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasActions() {
    return (onRetry != null) ||
        (customActions != null && customActions!.isNotEmpty);
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case ErrorDisplayType.error:
        return Icons.error;
      case ErrorDisplayType.warning:
        return Icons.warning;
      case ErrorDisplayType.info:
        return Icons.info;
    }
  }

  Color _getColor(ThemeData theme) {
    switch (type) {
      case ErrorDisplayType.error:
        return theme.colorScheme.error;
      case ErrorDisplayType.warning:
        return theme.colorScheme.onSurfaceVariant;
      case ErrorDisplayType.info:
        return theme.colorScheme.primary;
    }
  }

  ErrorInfo _extractErrorInfo() {
    // Try to extract information from Alouette errors
    if (error != null) {
      try {
        final dynamic dynError = error;

        // Check if it has Alouette error properties
        if (error.runtimeType.toString().contains('Alouette')) {
          return ErrorInfo(
            title: _getErrorTitle(),
            userMessage: dynError.userMessage ?? dynError.toString(),
            technicalMessage: dynError.technicalMessage ?? dynError.toString(),
            errorCode: dynError.code,
            isRecoverable: dynError.isRecoverable ?? false,
            recoveryActions: List<String>.from(dynError.recoveryActions ?? []),
            timestamp: dynError.timestamp?.toString(),
          );
        }
      } catch (e) {
        // Fallback to basic error handling
      }
    }

    // Fallback for non-Alouette errors
    return ErrorInfo(
      title: _getErrorTitle(),
      userMessage: _getGenericUserMessage(),
      technicalMessage: error?.toString() ?? 'Unknown error',
      errorCode: null,
      isRecoverable: _isGenericErrorRecoverable(),
      recoveryActions: _getGenericRecoveryActions(),
      timestamp: DateTime.now().toString(),
    );
  }

  String _getErrorTitle() {
    if (error == null) return 'Unknown Error';

    final errorType = error.runtimeType.toString();

    if (errorType.contains('Translation')) {
      return 'Translation Error';
    } else if (errorType.contains('TTS')) {
      return 'Text-to-Speech Error';
    } else if (errorType.contains('Network') ||
        errorType.contains('Connection')) {
      return 'Connection Error';
    } else if (errorType.contains('Timeout')) {
      return 'Timeout Error';
    } else {
      return 'Application Error';
    }
  }

  String _getGenericUserMessage() {
    if (error == null) return 'An unknown error occurred.';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Unable to connect to the service. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'The operation took too long to complete. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your system settings.';
    } else if (errorString.contains('not found')) {
      return 'The requested resource was not found.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  bool _isGenericErrorRecoverable() {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();

    return errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('temporary');
  }

  List<String> _getGenericRecoveryActions() {
    if (error == null) return ['Contact support'];

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection') || errorString.contains('network')) {
      return ['Check internet connection', 'Try again'];
    } else if (errorString.contains('timeout')) {
      return ['Try again', 'Check network speed'];
    } else if (errorString.contains('permission')) {
      return ['Check system permissions', 'Restart application'];
    } else {
      return ['Try again', 'Contact support if problem persists'];
    }
  }
}

/// Information extracted from an error for display
class ErrorInfo {
  final String title;
  final String userMessage;
  final String technicalMessage;
  final String? errorCode;
  final bool isRecoverable;
  final List<String> recoveryActions;
  final String? timestamp;

  const ErrorInfo({
    required this.title,
    required this.userMessage,
    required this.technicalMessage,
    this.errorCode,
    required this.isRecoverable,
    required this.recoveryActions,
    this.timestamp,
  });
}

/// Custom action for error display
class ErrorAction {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isElevated;

  const ErrorAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isElevated = false,
  });
}

/// Type of error display
enum ErrorDisplayType { error, warning, info }

/// Compact error banner widget
class ErrorBannerWidget extends StatelessWidget {
  final dynamic error;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final ErrorDisplayType type;

  const ErrorBannerWidget({
    Key? key,
    required this.error,
    this.message,
    this.onRetry,
    this.onDismiss,
    this.type = ErrorDisplayType.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorInfo = _extractErrorInfo();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme),
        border: Border(
          left: BorderSide(color: _getAccentColor(theme), width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getAccentColor(theme), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? errorInfo.userMessage,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null && errorInfo.isRecoverable) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              iconSize: 18,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ErrorDisplayType.error:
        return Icons.error_outline;
      case ErrorDisplayType.warning:
        return Icons.warning_amber_outlined;
      case ErrorDisplayType.info:
        return Icons.info_outline;
    }
  }

  Color _getAccentColor(ThemeData theme) {
    switch (type) {
      case ErrorDisplayType.error:
        return theme.colorScheme.error;
      case ErrorDisplayType.warning:
        return Colors.orange;
      case ErrorDisplayType.info:
        return theme.colorScheme.primary;
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (type) {
      case ErrorDisplayType.error:
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      case ErrorDisplayType.warning:
        return Colors.orange.withValues(alpha: 0.1);
      case ErrorDisplayType.info:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
    }
  }

  ErrorInfo _extractErrorInfo() {
    // Simplified version of error extraction for banner
    if (error != null) {
      try {
        final dynamic dynError = error;
        if (error.runtimeType.toString().contains('Alouette')) {
          return ErrorInfo(
            title: 'Error',
            userMessage: dynError.userMessage ?? dynError.toString(),
            technicalMessage: dynError.toString(),
            errorCode: dynError.code,
            isRecoverable: dynError.isRecoverable ?? false,
            recoveryActions: [],
            timestamp: null,
          );
        }
      } catch (e) {
        // Fallback
      }
    }

    return ErrorInfo(
      title: 'Error',
      userMessage: error?.toString() ?? 'An error occurred',
      technicalMessage: error?.toString() ?? 'Unknown error',
      errorCode: null,
      isRecoverable: true,
      recoveryActions: [],
      timestamp: null,
    );
  }
}
