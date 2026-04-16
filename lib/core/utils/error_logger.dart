/// EduX School Management System
/// Error Logger Service
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../services/activity_log_service.dart';

/// Error severity levels
enum ErrorSeverity { low, medium, high, critical }

/// Error log entry
class ErrorLogEntry {
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final ErrorSeverity severity;
  final String? context;
  final Map<String, dynamic>? metadata;

  const ErrorLogEntry({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.severity = ErrorSeverity.medium,
    this.context,
    this.metadata,
  });

  @override
  String toString() {
    return '[${severity.name.toUpperCase()}] $timestamp - $error\n$stackTrace';
  }
}

/// Error logging service
class ErrorLogger {
  final AppDatabase _db;
  final List<ErrorLogEntry> _recentErrors = [];
  static const int _maxRecentErrors = 50;

  ErrorLogger(this._db);

  /// Log an error
  Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      severity: severity,
      context: context,
      metadata: metadata,
    );

    // Add to recent errors
    _recentErrors.insert(0, entry);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeLast();
    }

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('ERROR: ${entry.error}');
      if (entry.context != null) debugPrint('Context: ${entry.context}');
      if (entry.stackTrace != null) debugPrint('Stack: ${entry.stackTrace}');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    // Log to activity log for critical errors
    if (severity == ErrorSeverity.critical || severity == ErrorSeverity.high) {
      try {
        final activityService = ActivityLogService(_db);
        await activityService.log(
          module: 'system',
          action: 'error',
          description:
              'System error: ${error.toString().substring(0, error.toString().length.clamp(0, 200))}',
          details: {
            'severity': severity.name,
            if (context != null) 'context': context,
            if (metadata != null) ...metadata,
          },
        );
      } catch (e) {
        // Silently fail - don't create infinite loop
        debugPrint('Failed to log error to activity log: $e');
      }
    }
  }

  /// Get recent errors
  List<ErrorLogEntry> get recentErrors => List.unmodifiable(_recentErrors);

  /// Clear recent errors
  void clearRecentErrors() => _recentErrors.clear();

  /// Setup Flutter error handling
  static void setupFlutterErrorHandling(ErrorLogger logger) {
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      logger.logError(
        details.exception,
        stackTrace: details.stack,
        severity: ErrorSeverity.high,
        context: 'Flutter Framework',
        metadata: {'library': details.library, 'silent': details.silent},
      );
    };

    // Catch async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.logError(
        error,
        stackTrace: stack,
        severity: ErrorSeverity.high,
        context: 'Platform Dispatcher',
      );
      return true; // Return true to prevent app crash
    };
  }
}

/// Provider for error logger
final errorLoggerProvider = Provider<ErrorLogger>((ref) {
  return ErrorLogger(AppDatabase.instance);
});

/// Utility extension for wrapping async operations with error logging
extension ErrorLoggingExtension<T> on Future<T> {
  /// Wrap a future with error logging
  Future<T> logErrors(ErrorLogger logger, {String? context}) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      await logger.logError(error, stackTrace: stackTrace, context: context);
      rethrow;
    }
  }

  /// Wrap a future with error logging, returning null on error
  Future<T?> logErrorsOrNull(ErrorLogger logger, {String? context}) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      await logger.logError(error, stackTrace: stackTrace, context: context);
      return null;
    }
  }
}
