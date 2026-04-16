/// EduX School Management System
/// Attendance Reports Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/report_service.dart';
import 'report_card.dart';
import 'selector_dialogs.dart';

/// Attendance reports tab content
class AttendanceReportsTab extends ConsumerWidget {
  final String searchQuery;
  const AttendanceReportsTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ref.watch(reportServiceProvider);

    final reports = [
      ReportItem(
        title: 'Daily Attendance Summary',
        description: 'Attendance summary for a specific date',
        icon: LucideIcons.calendarDays,
        exportFormats: ['pdf'],
        onGenerate: () => _showDatePicker(context, (date) {
          return reportService.generateDailyAttendanceReport(context, date);
        }),
      ),
      ReportItem(
        title: 'Monthly Attendance Report',
        description: 'Class-wise attendance for a month',
        icon: LucideIcons.calendar,
        exportFormats: ['pdf'],
        onGenerate: () => _showMonthPicker(context, reportService),
      ),
      ReportItem(
        title: 'Student Attendance History',
        description: 'Individual student attendance record',
        icon: LucideIcons.userCheck,
        exportFormats: ['pdf'],
        onGenerate: () => _showStudentSelector(context),
      ),
      ReportItem(
        title: 'Low Attendance Alert',
        description: 'Students with attendance below threshold',
        icon: LucideIcons.alertTriangle,
        exportFormats: ['pdf'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateLowAttendanceReport(context),
        ),
      ),
      ReportItem(
        title: 'Staff Attendance Report',
        description: 'Staff attendance summary for a period',
        icon: LucideIcons.briefcase,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showDateRangePicker(context, (start, end) {
          return reportService.generateStaffAttendanceReport(
            context,
            start,
            end,
          );
        }),
      ),
    ];

    return ReportGrid(reports: reports, searchQuery: searchQuery);
  }

  void _showDatePicker(
    BuildContext context,
    Future<void> Function(DateTime) onSelect,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating report...')));
      try {
        await onSelect(date);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showMonthPicker(BuildContext context, ReportService reportService) {
    // First select class
    showDialog(
      context: context,
      builder: (context) => ClassSelectorDialog(
        onSelected: (classId, sectionId) {
          // Then select month
          showDialog(
            context: context,
            builder: (context) => MonthPickerDialog(
              onSelected: (date) {
                _generateReport(
                  context,
                  () => reportService.generateMonthlyAttendanceReport(
                    context,
                    classId,
                    sectionId!,
                    date.month,
                    date.year,
                  ),
                );
              },
            ),
          );
        },
        requireSection: true,
      ),
    );
  }

  void _showStudentSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StudentSelectorDialog(
        onSelected: (studentId) {
          final reportService = ProviderScope.containerOf(
            context,
          ).read(reportServiceProvider);
          _generateReport(
            context,
            () => reportService.generateStudentAttendanceHistory(
              context,
              studentId,
            ),
          );
        },
      ),
    );
  }

  void _showDateRangePicker(
    BuildContext context,
    Future<void> Function(DateTime, DateTime) onSelect,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
    if (range != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating report...')));
      try {
        await onSelect(range.start, range.end);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _generateReport(
    BuildContext context,
    Future<void> Function() generator,
  ) async {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating report...')));
    }
    try {
      await generator();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
