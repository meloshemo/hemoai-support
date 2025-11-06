import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/localization_service.dart';
import '../services/network_service.dart';

/// Global error handler for the application
/// Provides centralized error handling and user-friendly error messages
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger();

  /// Handle and display error to user
  Future<void> handleError(
    BuildContext? context,
    dynamic error, {
    StackTrace? stackTrace,
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool logError = true,
  }) async {
    // Log error
    if (logError) {
      _logError(error, stackTrace);
    }

    // Don't show UI if context is not available
    if (context == null || !context.mounted) {
      return;
    }

    // Get user-friendly message
    final message = customMessage ?? _getErrorMessage(error);

    // Show error to user
    if (showSnackBar) {
      _showErrorSnackBar(context, message, onRetry);
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final loc = LocalizationService();
    if (error is NetworkException) {
      return loc.getString('no_internet_connection');
    }

    if (error is FormatException) {
      return loc.getString('invalid_data_format');
    }

    if (error is TimeoutException) {
      return loc.getString('request_timed_out');
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is DatabaseException) {
      return loc.getString('database_error_occurred');
    }

    if (error is PermissionException) {
      return loc.getString('permission_denied_message');
    }

    // Generic error message
    if (error is Exception) {
      return loc.getStringWithParams('error_occurred_with_details', {'error': error.toString()});
    }

    return loc.getString('unexpected_error_occurred');
  }

  /// Show error snackbar with optional retry
  void _showErrorSnackBar(
    BuildContext context,
    String message, [
    VoidCallback? onRetry,
  ]) {
    final localizationService = LocalizationService();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: onRetry != null ? 5 : 3),
        action: onRetry != null
            ? SnackBarAction(
                label: localizationService.getString('retry'),
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Log error with stack trace
  void _logError(dynamic error, StackTrace? stackTrace) {
    if (stackTrace != null) {
      _logger.e(
        'Error: $error',
        error: error is Exception ? error : Exception(error.toString()),
        stackTrace: stackTrace,
      );
    } else {
      _logger.e('Error: $error');
    }
  }

  /// Show error dialog (for critical errors)
  Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            if (onAction != null)
              TextButton(
                child: Text(actionLabel ?? LocalizationService().getString('retry')),
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
              ),
            TextButton(
              child: Text(LocalizationService().getString('ok')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Wrap async function with error handling
  Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    BuildContext? context,
    String? customErrorMessage,
    T? defaultValue,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (showError && context != null) {
        await handleError(
          context,
          error,
          stackTrace: stackTrace,
          customMessage: customErrorMessage,
        );
      }
      return defaultValue;
    }
  }

  /// Execute with network check
  Future<T?> withNetworkCheck<T>(
    BuildContext? context,
    Future<T> Function() operation, {
    String? customErrorMessage,
    T? defaultValue,
  }) async {
    final networkService = NetworkService();
    if (!networkService.isInitialized) {
      await networkService.initialize();
    }

    if (!networkService.isConnected) {
      if (context != null && context.mounted) {
        await handleError(
          context,
          NetworkException('No internet connection'),
          customMessage: customErrorMessage ?? 'No internet connection. Please check your network settings.',
        );
      }
      return defaultValue;
    }

    return safeAsync(
      operation,
      context: context,
      customErrorMessage: customErrorMessage,
      defaultValue: defaultValue,
    );
  }
}

/// Custom exceptions for better error handling
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => 'PermissionException: $message';
}

/// Timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration? timeout;
  
  TimeoutException(this.message, [this.timeout]);
  
  @override
  String toString() => 'TimeoutException: $message';
}

