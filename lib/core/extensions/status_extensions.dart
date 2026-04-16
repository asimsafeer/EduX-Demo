/// EduX School Management System
/// Status Extensions - Centralized status color and icon helpers
library;

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Extension methods for status strings to get colors and icons
extension InvoiceStatusHelpers on String {
  /// Get color for invoice status
  Color get invoiceStatusColor {
    switch (this) {
      case FeeConstants.invoiceStatusPaid:
        return Colors.green;
      case FeeConstants.invoiceStatusPartial:
        return Colors.orange;
      case FeeConstants.invoiceStatusOverdue:
        return Colors.red;
      case FeeConstants.invoiceStatusPending:
        return Colors.blue;
      case FeeConstants.invoiceStatusCancelled:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Get text color for invoice status (darker for text)
  Color get invoiceStatusTextColor {
    switch (this) {
      case FeeConstants.invoiceStatusPaid:
        return Colors.green.shade700;
      case FeeConstants.invoiceStatusPartial:
        return Colors.orange.shade800;
      case FeeConstants.invoiceStatusOverdue:
        return Colors.red.shade700;
      case FeeConstants.invoiceStatusPending:
        return Colors.blue.shade700;
      case FeeConstants.invoiceStatusCancelled:
        return Colors.grey.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  /// Get icon for invoice status
  IconData get invoiceStatusIcon {
    switch (this) {
      case FeeConstants.invoiceStatusPaid:
        return Icons.check_circle;
      case FeeConstants.invoiceStatusPartial:
        return Icons.pending;
      case FeeConstants.invoiceStatusOverdue:
        return Icons.warning;
      case FeeConstants.invoiceStatusPending:
        return Icons.receipt_long;
      case FeeConstants.invoiceStatusCancelled:
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
}

/// Extension methods for student status
extension StudentStatusHelpers on String {
  /// Get color for student status
  Color get studentStatusColor {
    switch (this) {
      case StudentStatus.active:
        return Colors.green;
      case StudentStatus.inactive:
        return Colors.grey;
      case StudentStatus.graduated:
        return Colors.blue;
      case StudentStatus.withdrawn:
        return Colors.orange;
      case StudentStatus.transferred:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for student status
  IconData get studentStatusIcon {
    switch (this) {
      case StudentStatus.active:
        return Icons.check_circle;
      case StudentStatus.inactive:
        return Icons.cancel;
      case StudentStatus.graduated:
        return Icons.school;
      case StudentStatus.withdrawn:
        return Icons.exit_to_app;
      case StudentStatus.transferred:
        return Icons.transfer_within_a_station;
      default:
        return Icons.person;
    }
  }
}

/// Extension methods for exam status
extension ExamStatusHelpers on String {
  /// Get color for exam status
  Color get examStatusColor {
    switch (this) {
      case ExamConstants.statusActive:
        return Colors.green;
      case ExamConstants.statusDraft:
        return Colors.orange;
      case ExamConstants.statusCompleted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for exam status
  IconData get examStatusIcon {
    switch (this) {
      case ExamConstants.statusActive:
        return Icons.play_circle;
      case ExamConstants.statusDraft:
        return Icons.edit;
      case ExamConstants.statusCompleted:
        return Icons.check_circle;
      default:
        return Icons.assignment;
    }
  }
}

/// Extension methods for attendance status
extension AttendanceStatusHelpers on String {
  /// Get color for attendance status
  Color get attendanceStatusColor {
    switch (this) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.leave:
        return Colors.blue;
      case AttendanceStatus.halfDay:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for attendance status
  IconData get attendanceStatusIcon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.leave:
        return Icons.event_busy;
      case AttendanceStatus.halfDay:
        return Icons.timelapse;
      default:
        return Icons.help;
    }
  }
}

/// Helper class for status-related utilities
class StatusHelpers {
  StatusHelpers._();

  /// Capitalize first letter of status
  static String capitalize(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Get invoice status chip widget
  static Widget buildInvoiceStatusChip(String status, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.invoiceStatusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 12 : 20),
        border: Border.all(
          color: status.invoiceStatusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.invoiceStatusIcon,
            size: small ? 12 : 14,
            color: status.invoiceStatusTextColor,
          ),
          SizedBox(width: small ? 4 : 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: status.invoiceStatusTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
