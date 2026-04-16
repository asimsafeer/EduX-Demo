/// EduX School Management System
/// Import Error List - Display validation errors
library;

import 'package:flutter/material.dart';

import '../../../services/student_import_service.dart';

/// Widget to display import validation errors
class ImportErrorList extends StatelessWidget {
  final List<ImportError> errors;

  const ImportErrorList({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade600),
            const SizedBox(height: 12),
            Text(
              'No errors found!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Group errors by row
    final groupedErrors = <int, List<ImportError>>{};
    for (final error in errors) {
      groupedErrors.putIfAbsent(error.rowIndex, () => []).add(error);
    }

    final sortedRows = groupedErrors.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedRows.length,
      itemBuilder: (context, index) {
        final rowIndex = sortedRows[index];
        final rowErrors = groupedErrors[rowIndex]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              radius: 16,
              child: Text(
                '${rowIndex + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
            title: Text(
              'Row ${rowIndex + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${rowErrors.length} error${rowErrors.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
            children: rowErrors.map((error) {
              return ListTile(
                leading: Icon(
                  _getErrorIcon(error.type),
                  size: 20,
                  color: _getErrorColor(error.severity),
                ),
                title: Text(
                  error.field ?? 'General',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(error.message, style: theme.textTheme.bodySmall),
                dense: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.required:
        return Icons.error_outline;
      case ErrorType.invalid:
        return Icons.warning_amber;
      case ErrorType.duplicate:
        return Icons.copy;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.format:
        return Icons.text_format;
    }
  }

  Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.error:
        return Colors.red.shade600;
      case ErrorSeverity.warning:
        return Colors.orange.shade600;
      case ErrorSeverity.info:
        return Colors.blue.shade600;
    }
  }
}

/// Summary widget for errors
class ImportErrorSummary extends StatelessWidget {
  final List<ImportError> errors;
  final VoidCallback? onViewDetails;

  const ImportErrorSummary({
    super.key,
    required this.errors,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (errors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Text(
              'All rows are valid',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Count by severity
    final errorCount = errors
        .where((e) => e.severity == ErrorSeverity.error)
        .length;
    final warningCount = errors
        .where((e) => e.severity == ErrorSeverity.warning)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorCount > 0
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            errorCount > 0 ? Icons.error : Icons.warning,
            color: errorCount > 0
                ? Colors.red.shade600
                : Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${errors.length} issue${errors.length > 1 ? 's' : ''} found',
                  style: TextStyle(
                    color: errorCount > 0
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$errorCount error${errorCount != 1 ? 's' : ''}, '
                  '$warningCount warning${warningCount != 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onViewDetails != null)
            TextButton(
              onPressed: onViewDetails,
              child: const Text('View Details'),
            ),
        ],
      ),
    );
  }
}

/// Inline error display widget
class InlineImportError extends StatelessWidget {
  final ImportError error;

  const InlineImportError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final color = error.severity == ErrorSeverity.error
        ? Colors.red
        : error.severity == ErrorSeverity.warning
        ? Colors.orange
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error.severity == ErrorSeverity.error ? Icons.error : Icons.warning,
            size: 14,
            color: color.shade600,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              error.message,
              style: TextStyle(fontSize: 12, color: color.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
