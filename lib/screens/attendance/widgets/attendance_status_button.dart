/// EduX School Management System
/// Attendance Status Button Widget
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Button for selecting attendance status (P/A/L/LV)
class AttendanceStatusButton extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;
  final bool disabled;

  const AttendanceStatusButton({
    super.key,
    required this.status,
    required this.isSelected,
    this.onTap,
    this.compact = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(status, theme);
    final shortCode = AttendanceStatus.getShortCode(status);

    return Tooltip(
      message: AttendanceStatus.getDisplayName(status),
      child: Material(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: compact ? 32 : 44,
            height: compact ? 32 : 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 4 : 8),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                shortCode,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (disabled ? color.withValues(alpha: 0.4) : color),
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
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
        return theme.colorScheme.outline;
    }
  }
}

/// Row of status buttons for quick selection
class AttendanceStatusButtonRow extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final bool compact;
  final bool disabled;

  const AttendanceStatusButtonRow({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.compact = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AttendanceStatus.studentStatuses.map((status) {
        return Padding(
          padding: EdgeInsets.only(right: compact ? 4 : 8),
          child: AttendanceStatusButton(
            status: status,
            isSelected: selectedStatus == status,
            onTap: () => onStatusChanged(status),
            compact: compact,
            disabled: disabled,
          ),
        );
      }).toList(),
    );
  }
}
