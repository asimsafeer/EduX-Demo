/// EduX School Management System
/// Staff Reports Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/report_service.dart';
import 'report_card.dart';
import 'selector_dialogs.dart';

/// Staff reports tab content
class StaffReportsTab extends ConsumerWidget {
  final String searchQuery;
  const StaffReportsTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ref.watch(reportServiceProvider);

    final reports = [
      ReportItem(
        title: 'Staff List',
        description: 'Complete list of all staff members',
        icon: LucideIcons.users,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateStaffListReport(context),
        ),
      ),
      ReportItem(
        title: 'Staff Contact Directory',
        description: 'Contact information for all staff',
        icon: LucideIcons.phone,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateStaffContactsReport(context),
        ),
      ),
      ReportItem(
        title: 'Department-wise Staff',
        description: 'Staff grouped by department',
        icon: LucideIcons.building2,
        exportFormats: ['pdf'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateDepartmentwiseStaffReport(context),
        ),
      ),
      ReportItem(
        title: 'Leave Report',
        description: 'Staff leave summary for a period',
        icon: LucideIcons.calendarOff,
        exportFormats: ['pdf'],
        onGenerate: () => _showDateRangePicker(context, (start, end) {
          return reportService.generateLeaveReport(context, start, end);
        }),
      ),
      ReportItem(
        title: 'Teacher-Subject Assignment',
        description: 'Teachers and their assigned subjects',
        icon: LucideIcons.bookMarked,
        exportFormats: ['pdf'],
        onGenerate: () => _showAssignmentReportSelector(context, reportService),
      ),
    ];

    return ReportGrid(reports: reports, searchQuery: searchQuery);
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

  void _showAssignmentReportSelector(
    BuildContext context,
    ReportService reportService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subject Assignment Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose report format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.users),
              title: const Text('By Teacher'),
              subtitle: const Text(
                'Show all teachers with their assigned subjects',
              ),
              onTap: () {
                Navigator.pop(context);
                _generateReport(
                  context,
                  () => reportService.generateSubjectAssignmentReport(
                    context,
                    byTeacher: true,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.school),
              title: const Text('By Class'),
              subtitle: const Text('Show all classes with assigned teachers'),
              onTap: () {
                Navigator.pop(context);
                _showClassSelectorForAssignment(context, reportService);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClassSelectorForAssignment(
    BuildContext context,
    ReportService reportService,
  ) {
    showDialog(
      context: context,
      builder: (context) => ClassSelectorDialog(
        onSelected: (classId, sectionId) {
          _generateReport(
            context,
            () => reportService.generateSubjectAssignmentReport(
              context,
              byTeacher: false,
              classId: classId,
              sectionId: sectionId,
            ),
          );
        },
        requireSection: false,
      ),
    );
  }
}
