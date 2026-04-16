/// EduX School Management System
/// Academic Reports Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/report_service.dart';
import 'report_card.dart';
import 'selector_dialogs.dart';

/// Academic reports tab content
class AcademicReportsTab extends ConsumerWidget {
  final String searchQuery;
  const AcademicReportsTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ref.watch(reportServiceProvider);

    final reports = [
      ReportItem(
        title: 'Exam Results',
        description: 'Results for a specific exam',
        icon: LucideIcons.clipboardCheck,
        exportFormats: ['pdf'],
        onGenerate: () => _showExamAndClassSelector(
          context,
          (examId, classId, sectionId) => reportService.generateExamResults(
            context,
            examId,
            classId,
            sectionId,
          ),
        ),
      ),
      ReportItem(
        title: 'Class Report Cards',
        description: 'Report cards for all students in a class',
        icon: LucideIcons.fileText,
        exportFormats: ['pdf'],
        onGenerate: () => _showExamAndClassSelector(
          context,
          (examId, classId, sectionId) =>
              reportService.generateClassReportCards(
                context,
                examId,
                classId,
                sectionId: sectionId,
              ),
        ),
      ),
      ReportItem(
        title: 'Grade Distribution',
        description: 'Grade-wise analysis of exam results',
        icon: LucideIcons.pieChart,
        exportFormats: ['pdf'],
        onGenerate: () => _showExamAndClassSelector(
          context,
          (examId, classId, sectionId) => reportService
              .generateGradeDistributionReport(context, examId, classId),
        ),
      ),
      ReportItem(
        title: 'Subject-wise Analysis',
        description: 'Performance analysis by subject',
        icon: LucideIcons.bookOpen,
        exportFormats: ['pdf'],
        onGenerate: () =>
            _showExamClassAndSubjectSelector(context, reportService),
      ),
      ReportItem(
        title: 'Topper List',
        description: 'Top performers in each class/exam',
        icon: LucideIcons.award,
        exportFormats: ['pdf'],
        onGenerate: () => _showExamAndClassSelector(
          context,
          (examId, classId, sectionId) =>
              reportService.generateTopperListReport(context, examId, classId),
        ),
      ),
      ReportItem(
        title: 'Timetable',
        description: 'Class timetable export',
        icon: LucideIcons.clock,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showClassSelector(context, reportService),
      ),
      ReportItem(
        title: 'Subject Assignment Report',
        description: 'Teacher-subject assignments by class or teacher',
        icon: LucideIcons.userCheck,
        exportFormats: ['pdf'],
        onGenerate: () =>
            _showSubjectAssignmentSelector(context, reportService),
      ),
    ];

    return ReportGrid(reports: reports, searchQuery: searchQuery);
  }

  void _showExamAndClassSelector(
    BuildContext context,
    Future<void> Function(int examId, int classId, int? sectionId) onSelected,
  ) {
    // Select Exam first
    showDialog(
      context: context,
      builder: (context) => ExamSelectorDialog(
        onSelected: (examId) {
          // Then Select Class
          showDialog(
            context: context,
            builder: (context) => ClassSelectorDialog(
              onSelected: (classId, sectionId) {
                _generateReport(
                  context,
                  () => onSelected(examId, classId, sectionId),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showClassSelector(BuildContext context, ReportService reportService) {
    showDialog(
      context: context,
      builder: (context) => ClassSelectorDialog(
        onSelected: (classId, sectionId) {
          _generateReport(
            context,
            () => reportService.generateTimetableReport(
              context,
              classId,
              sectionId,
            ),
          );
        },
      ),
    );
  }

  void _showExamClassAndSubjectSelector(
    BuildContext context,
    ReportService reportService,
  ) {
    showDialog(
      context: context,
      builder: (context) => ExamSelectorDialog(
        onSelected: (examId) {
          showDialog(
            context: context,
            builder: (context) => ClassSelectorDialog(
              onSelected: (classId, sectionId) {
                showDialog(
                  context: context,
                  builder: (context) => SubjectSelectorDialog(
                    classId: classId,
                    onSelected: (subjectId) {
                      _generateReport(
                        context,
                        () => reportService.generateSubjectAnalysis(
                          context,
                          examId,
                          classId,
                          subjectId,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showSubjectAssignmentSelector(
    BuildContext context,
    ReportService reportService,
  ) {
    // Show dialog to choose report type
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subject Assignment Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.users),
              title: const Text('By Teacher'),
              subtitle: const Text(
                'Show all subjects assigned to each teacher',
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
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.school),
              title: const Text('By Class'),
              subtitle: const Text(
                'Show all subjects and teachers for each class',
              ),
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
