import 'package:flutter/material.dart';
import 'error_handler.dart';

/// UI utility extensions for common operations
extension UIUtils on BuildContext {
  /// Show an error message using unified error handling
  void showErrorMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(this).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show a success message
  void showSuccessMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: duration,
      ),
    );
  }

  /// Show an info message
  void showInfoMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(
      this,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  /// Show configuration dialog for LLM
  Future<T?> showLLMConfigDialog<T>() async {
    // This would be implemented to show the unified config dialog
    // For now, return null as a placeholder
    return null;
  }
}

/// Unified error handling utilities
class ErrorUtils {
  /// Handle an error with automatic recovery and user notification
  static Future<void> handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
  }) async {
    final errorHandler = AlouetteErrorHandler.instance;

    // Use the unified error handler
    await errorHandler.handleError(
      error,
      context: 'UI',
      recoveryOperation: onRetry != null
          ? () async {
              onRetry();
              return null;
            }
          : null,
    );

    // Show user-friendly message
    final message = customMessage ?? _getErrorMessage(error);
    if (context.mounted) {
      context.showErrorMessage(message, onRetry: onRetry);
    }
  }

  static String _getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('configure') ||
        errorString.contains('configuration')) {
      return 'Please configure the service settings';
    } else if (errorString.contains('connection') ||
        errorString.contains('network')) {
      return 'Connection error. Please check your network';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else {
      return error.toString();
    }
  }
}
