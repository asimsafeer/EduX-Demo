/// EduX School Management System
/// Import Preview Table - Preview Excel import data
library;

import 'package:flutter/material.dart';

import '../../../services/student_import_service.dart';

/// Table widget to preview imported student data
class ImportPreviewTable extends StatelessWidget {
  final List<ImportPreviewItem> previewItems;
  final List<ImportError> errors;

  const ImportPreviewTable({
    super.key,
    required this.previewItems,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (previewItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No valid data found in file',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('Row')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Student Name'), numeric: false),
            DataColumn(label: Text('Father Name'), numeric: false),
            DataColumn(label: Text('Gender')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Section')),
            DataColumn(label: Text('Admission Date')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Email')),
          ],
          rows: previewItems.map((item) {
            final rowErrors = errors
                .where((e) => e.rowIndex == item.rowIndex)
                .toList();
            final hasErrors = rowErrors.isNotEmpty;

            return DataRow(
              color: WidgetStateProperty.all(
                hasErrors ? Colors.red.withValues(alpha: 0.08) : null,
              ),
              cells: [
                DataCell(Text('${item.rowIndex + 1}')),
                DataCell(_buildStatusCell(item.isValid, rowErrors, theme)),
                DataCell(_buildDataCell(item.data['studentName'], theme)),
                DataCell(_buildDataCell(item.data['fatherName'], theme)),
                DataCell(_buildDataCell(item.data['gender'], theme)),
                DataCell(_buildDataCell(item.data['class'], theme)),
                DataCell(_buildDataCell(item.data['section'], theme)),
                DataCell(_buildDataCell(item.data['admissionDate'], theme)),
                DataCell(_buildDataCell(item.data['phone'], theme)),
                DataCell(_buildDataCell(item.data['email'], theme)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusCell(
    bool isValid,
    List<ImportError> rowErrors,
    ThemeData theme,
  ) {
    if (isValid) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            'Valid',
            style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: rowErrors.map((e) => e.message).join('\n'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 4),
          Text(
            '${rowErrors.length} error${rowErrors.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(dynamic value, ThemeData theme) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) {
      return Text(
        '-',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

/// Compact preview list for smaller displays
class ImportPreviewList extends StatelessWidget {
  final List<ImportPreviewItem> previewItems;
  final List<ImportError> errors;

  const ImportPreviewList({
    super.key,
    required this.previewItems,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      itemCount: previewItems.length,
      itemBuilder: (context, index) {
        final item = previewItems[index];
        final rowErrors = errors
            .where((e) => e.rowIndex == item.rowIndex)
            .toList();
        final hasErrors = rowErrors.isNotEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: hasErrors ? Colors.red.withValues(alpha: 0.05) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: hasErrors
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Icon(
                hasErrors ? Icons.error : Icons.check,
                color: hasErrors ? Colors.red.shade700 : Colors.green.shade700,
                size: 20,
              ),
            ),
            title: Text(
              '${item.data['studentName'] ?? ''} ${item.data['fatherName'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.data['class'] ?? ''} - ${item.data['section'] ?? ''} • '
                  '${item.data['gender'] ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (hasErrors)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      rowErrors.first.message,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            isThreeLine: hasErrors,
          ),
        );
      },
    );
  }
}
