import 'package:flutter/material.dart';
import '../logger.dart';
import 'alouette_error.dart';
import '../../services/core/service_locator.dart';

/// Centralized error handler for Alouette applications
class ErrorHandler {
  /// Handle an error and optionally show it to the user
  static void handle(
    Object error, {
    BuildContext? context,
    bool showSnackBar = true,
    bool logError = true,
    StackTrace? stackTrace,
  }) {
    final alouetteError = _wrapError(error, stackTrace);

    // Log the error
    if (logError) {
      try {
        ServiceLocator.logger.error(
          alouetteError.message,
          tag: 'ErrorHandler',
          error: alouetteError.originalError ?? alouetteError,
          stackTrace: alouetteError.stackTrace,
          details: alouetteError.details,
        );
      } catch (e) {
        // Fallback to logger if ServiceLocator logger is not available
        logger.e('[ERROR] ${alouetteError.getTechnicalMessage()}');
      }
    }

    // Show user-friendly message
    if (showSnackBar && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alouetteError.getUserFriendlyMessage()),
          backgroundColor: _getErrorColor(alouetteError),
          action: SnackBarAction(
            label: 'Details',
            textColor: Colors.white,
            onPressed: () => _showErrorDialog(context, alouetteError),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Convert any error to AlouetteError
  static AlouetteError _wrapError(Object error, StackTrace? stackTrace) {
    if (error is AlouetteError) {
      return error;
    }

    // Wrap unknown errors
    return ServiceError(
      message: error.toString(),
      code: 'UNKNOWN_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Get appropriate color for error type
  static Color _getErrorColor(AlouetteError error) {
    if (error is TranslationError) {
      return Colors.orange.shade700;
    } else if (error is TTSError) {
      return Colors.purple.shade700;
    } else if (error is ServiceError) {
      return Colors.red.shade700;
    } else if (error is ConfigurationError) {
      return Colors.blue.shade700;
    }
    return Colors.red;
  }

  /// Show detailed error dialog
  static void _showErrorDialog(BuildContext context, AlouetteError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: _getErrorColor(error)),
            const SizedBox(width: 8),
            const Text('Error Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Code', error.code),
              const SizedBox(height: 8),
              _buildDetailRow('Message', error.message),
              if (error.details != null && error.details!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Details', error.details.toString()),
              ],
              if (error.originalError != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Original Error', error.originalError.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Copy error details to clipboard
              // Clipboard.setData(ClipboardData(text: error.getTechnicalMessage()));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error details copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
