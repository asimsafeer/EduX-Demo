/// EduX School Management System
/// Staff Import Preview Table - Preview Excel import data
library;

import 'package:flutter/material.dart';

import '../../../services/staff_import_service.dart';

/// Table widget to preview imported staff data
class StaffImportPreviewTable extends StatelessWidget {
  final List<ImportPreviewItem> previewItems;
  final List<ImportError> errors;

  const StaffImportPreviewTable({
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
            DataColumn(label: Text('First Name'), numeric: false),
            DataColumn(label: Text('Last Name'), numeric: false),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Gender')),
            DataColumn(label: Text('Designation')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Joining Date')),
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
                DataCell(_buildDataCell(item.data['firstName'], theme)),
                DataCell(_buildDataCell(item.data['lastName'], theme)),
                DataCell(_buildDataCell(item.data['phone'], theme)),
                DataCell(_buildDataCell(item.data['gender'], theme)),
                DataCell(_buildDataCell(item.data['designation'], theme)),
                DataCell(_buildDataCell(item.data['role'], theme)),
                DataCell(_buildDataCell(item.data['joiningDate'], theme)),
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
