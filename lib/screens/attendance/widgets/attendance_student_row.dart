/// EduX School Management System
/// Attendance Student Row Widget
library;

import 'package:flutter/material.dart';
import '../../../repositories/attendance_repository.dart';
import 'attendance_status_button.dart';

/// Row widget for displaying and editing a student's attendance
class AttendanceStudentRow extends StatelessWidget {
  final int index;
  final StudentAttendanceEntry entry;
  final String? currentStatus;
  final String? currentRemarks;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onRemarksChanged;
  final bool isEditing;

  const AttendanceStudentRow({
    super.key,
    required this.index,
    required this.entry,
    required this.currentStatus,
    required this.currentRemarks,
    required this.onStatusChanged,
    required this.onRemarksChanged,
    this.isEditing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = entry.student;
    final rollNumber = entry.enrollment?.rollNumber ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),

            // Roll Number
            SizedBox(
              width: 80,
              child: Text(
                rollNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Student Name with Photo
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    // Student photo is stored as blob, display initials for now
                    child: Text(
                      _getInitials(student.studentName, student.fatherName ?? ''),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${student.studentName} ${student.fatherName ?? ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.isMarked && !isEditing) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Marked: ${_getStatusDisplayName(entry.status)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(entry.status),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status Buttons
            AttendanceStatusButtonRow(
              selectedStatus: currentStatus,
              onStatusChanged: onStatusChanged,
              disabled: !isEditing,
            ),

            // Remarks
            if (isEditing)
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Remarks...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  controller: TextEditingController(text: currentRemarks ?? ''),
                  onChanged: onRemarksChanged,
                  style: theme.textTheme.bodySmall,
                ),
              )
            else if (entry.remarks != null && entry.remarks!.isNotEmpty)
              SizedBox(
                width: 180,
                child: Text(
                  entry.remarks!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  String _getStatusDisplayName(String? status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'leave':
        return 'Leave';
      default:
        return 'Not Marked';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade600;
      case 'late':
        return Colors.orange.shade600;
      case 'leave':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }
}
