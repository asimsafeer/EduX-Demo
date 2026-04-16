/// EduX School Management System
/// Fee Reports Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/report_service.dart';
import 'report_card.dart';

/// Fee reports tab content
class FeeReportsTab extends ConsumerWidget {
  final String searchQuery;
  const FeeReportsTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ref.watch(reportServiceProvider);

    final reports = [
      ReportItem(
        title: 'Fee Collection Summary',
        description: 'Total fee collection for a period',
        icon: LucideIcons.trendingUp,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showDateRangePicker(context, (start, end) {
          return reportService.generateFeeCollectionReport(context, start, end);
        }),
      ),
      ReportItem(
        title: 'Outstanding Fees Report',
        description: 'Students with pending fee payments',
        icon: LucideIcons.alertCircle,
        exportFormats: ['pdf'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateOutstandingFeesReport(context),
        ),
      ),
      ReportItem(
        title: 'Fee Defaulters List',
        description: 'Students with overdue payments',
        icon: LucideIcons.userX,
        exportFormats: ['pdf'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateDefaultersReport(context),
        ),
      ),
      ReportItem(
        title: 'Daily Collection Report',
        description: 'Fee collected on a specific date',
        icon: LucideIcons.fileSpreadsheet,
        exportFormats: ['pdf'],
        onGenerate: () => _showDatePicker(context, (date) {
          return reportService.generateDailyCollectionReport(context, date);
        }),
      ),
      ReportItem(
        title: 'Class-wise Fee Status',
        description: 'Fee payment status by class',
        icon: LucideIcons.layoutGrid,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateClasswiseFeeStatus(context),
        ),
      ),
      ReportItem(
        title: 'Concession Report',
        description: 'List of fee concessions granted',
        icon: LucideIcons.barChart3,
        exportFormats: ['pdf'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateConcessionReport(context),
        ),
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
