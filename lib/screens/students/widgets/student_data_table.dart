/// EduX School Management System
/// Student Data Table - Displays students in a data table format
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../repositories/student_repository.dart';

/// Data table widget for displaying students
class StudentDataTable extends StatelessWidget {
  final List<StudentWithEnrollment> students;
  final void Function(int id) onView;
  final void Function(int id) onEdit;
  final void Function(int id) onDelete;
  final bool showCheckboxColumn;
  final int startIndex;
  final Set<int> selectedIds;
  final ValueChanged<int>? onSelect;
  final ValueChanged<bool?>? onSelectAll;

  const StudentDataTable({
    super.key,
    required this.students,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.showCheckboxColumn = true,
    this.startIndex = 0,
    this.selectedIds = const {},
    this.onSelect,
    this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => theme.colorScheme.surfaceContainerHighest,
                ),
                onSelectAll: showCheckboxColumn ? onSelectAll : null,
                columns: [
                  const DataColumn(label: Text('Roll No'), numeric: true),
                  const DataColumn(label: Text('Adm. No'), numeric: false),
                  const DataColumn(label: Text('Student Name'), numeric: false),
                  const DataColumn(label: Text('Father Name'), numeric: false),
                  const DataColumn(label: Text('Class'), numeric: false),
                  const DataColumn(label: Text('Gender'), numeric: false),
                  const DataColumn(label: Text('Phone'), numeric: false),
                  const DataColumn(
                    label: Text('Admission Date'),
                    numeric: false,
                  ),
                  const DataColumn(label: Text('Status'), numeric: false),
                  const DataColumn(label: Text('Actions'), numeric: false),
                ],
                rows: students.asMap().entries.map((entry) {
                  final index = entry.key;
                  final studentData = entry.value;
                  final student = studentData.student;

                  return DataRow(
                    selected:
                        showCheckboxColumn && selectedIds.contains(student.id),
                    onSelectChanged: showCheckboxColumn && onSelect != null
                        ? (value) => onSelect!(student.id)
                        : null,
                    cells: [
                      DataCell(
                        Text(
                          (startIndex + index + 1).toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          student.admissionNumber,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () => onView(student.id),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                '${student.studentName[0]}${(student.fatherName ?? '?')[0]}'
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(student.studentName),
                          ],
                        ),
                        onTap: () => onView(student.id),
                      ),
                      DataCell(
                        Text(student.fatherName ?? ''),
                        onTap: () => onView(student.id),
                      ),
                      DataCell(
                        Text(studentData.classSection),
                        onTap: () => onView(student.id),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              student.gender.toLowerCase() == 'male'
                                  ? Icons.male
                                  : Icons.female,
                              size: 16,
                              color: student.gender.toLowerCase() == 'male'
                                  ? Colors.blue
                                  : Colors.pink,
                            ),
                            const SizedBox(width: 4),
                            Text(_capitalize(student.gender)),
                          ],
                        ),
                      ),
                      DataCell(Text(student.phone ?? '-')),
                      DataCell(Text(dateFormat.format(student.admissionDate))),
                      DataCell(_buildStatusChip(student.status, theme)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              tooltip: 'View Details',
                              onPressed: () => onView(student.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: 'Edit Student',
                              onPressed: () => onEdit(student.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              tooltip: 'Delete Student',
                              color: Colors.red,
                              onPressed: () => onDelete(student.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        break;
      case 'withdrawn':
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade700;
        break;
      case 'transferred':
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade700;
        break;
      case 'graduated':
        backgroundColor = Colors.purple.withValues(alpha: 0.15);
        textColor = Colors.purple.shade700;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _capitalize(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
