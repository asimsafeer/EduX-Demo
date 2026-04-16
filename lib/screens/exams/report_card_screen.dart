/// EduX School Management System
/// Report Card Screen - View and generate PDF report cards
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;

import '../../core/theme/theme.dart';
import '../../core/utils/pdf_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/exam_provider.dart';
import '../../repositories/marks_repository.dart';
import '../../services/report_card_service.dart';
import 'widgets/exam_status_badge.dart';

class ReportCardScreen extends ConsumerStatefulWidget {
  final int examId;
  final int? studentId;

  const ReportCardScreen({super.key, required this.examId, this.studentId});

  @override
  ConsumerState<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends ConsumerState<ReportCardScreen> {
  bool _isGenerating = false;
  List<int> _selectedStudents = [];
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedExamIdProvider.notifier).state = widget.examId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examAsync = ref.watch(currentExamProvider);
    final resultsAsync = ref.watch(classRankingsProvider);

    // If a specific student is provided, show single report card
    if (widget.studentId != null) {
      return _buildSingleReportCard(context, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedStudents.isNotEmpty) ...[
            Text(
              '${_selectedStudents.length} selected',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 16),
            AppButton.secondary(
              text: 'Print Selected',
              icon: Icons.print,
              size: AppButtonSize.small,
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _printSelected,
            ),
            const SizedBox(width: 8),
            AppButton.primary(
              text: 'Download Selected',
              icon: Icons.download,
              size: AppButtonSize.small,
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _downloadSelected,
            ),
            const SizedBox(width: 16),
          ] else ...[
            AppButton.secondary(
              text: 'Print All',
              icon: Icons.print,
              size: AppButtonSize.small,
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _printAll,
            ),
            const SizedBox(width: 8),
            AppButton.primary(
              text: 'Download All',
              icon: Icons.download,
              size: AppButtonSize.small,
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _downloadAll,
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: examAsync.when(
        data: (exam) {
          if (exam == null) {
            return const Center(child: Text('Exam not found'));
          }

          return Column(
            children: [
              // Exam header
              _buildExamHeader(context, theme, exam.exam.name),

              // Student list
              Expanded(
                child: resultsAsync.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'No Results',
                        description:
                            'No exam results found. Complete marks entry first.',
                      );
                    }

                    return Column(
                      children: [
                        // Select all header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selectAll,
                                onChanged: (value) {
                                  setState(() {
                                    _selectAll = value ?? false;
                                    if (_selectAll) {
                                      _selectedStudents = results
                                          .map((r) => r.student.id)
                                          .toList();
                                    } else {
                                      _selectedStudents = [];
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Select All',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                '${results.length} students',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Student list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              return _StudentReportCard(
                                result: result,
                                index: index,
                                totalStudents: results.length,
                                isSelected: _selectedStudents.contains(
                                  result.student.id,
                                ),
                                onSelectionChanged: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedStudents.add(result.student.id);
                                    } else {
                                      _selectedStudents.remove(
                                        result.student.id,
                                      );
                                    }
                                    _selectAll =
                                        _selectedStudents.length ==
                                        results.length;
                                  });
                                },
                                onViewReport: () {
                                  context.go(
                                    '/exams/${widget.examId}/report-cards/${result.student.id}',
                                  );
                                },
                                onPrint: () => _printSingle(result.student.id),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: AppLoadingIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSingleReportCard(BuildContext context, ThemeData theme) {
    final reportDataAsync = ref.watch(
      reportCardDataProvider((
        examId: widget.examId,
        studentId: widget.studentId!,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          AppButton.secondary(
            text: 'Print',
            icon: Icons.print,
            size: AppButtonSize.small,
            onPressed: () => _printSingle(widget.studentId!),
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            text: 'Download PDF',
            icon: Icons.download,
            size: AppButtonSize.small,
            onPressed: () => _downloadSingle(widget.studentId!),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: reportDataAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Report card not available'));
          }

          // Show PDF preview
          return FutureBuilder(
            future: ref
                .read(reportCardServiceProvider)
                .generateReportCard(data),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              return PdfPreview(
                build: (format) async => snapshot.data!,
                pdfFileName:
                    'report_card_${data.result.student.studentName}_${data.result.student.fatherName}.pdf',
                canDebug: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                initialPageFormat: PdfPageFormat.a4,
              );
            },
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildExamHeader(
    BuildContext context,
    ThemeData theme,
    String examName,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Generate and print report cards',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printSingle(int studentId) async {
    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final data = await service.getReportCardData(
        examId: widget.examId,
        studentId: studentId,
      );

      if (data == null) {
        _showError('Report card data not found');
        return;
      }

      if (!mounted) return;
      await service.printReportCard(context, data);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadSingle(int studentId) async {
    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final data = await service.getReportCardData(
        examId: widget.examId,
        studentId: studentId,
      );

      if (data == null) {
        _showError('Report card data not found');
        return;
      }

      final pdfBytes = await service.generateReportCard(data);
      await _savePdf(
        pdfBytes,
        'report_card_${data.result.student.studentName}_${data.result.student.fatherName}.pdf',
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _printSelected() async {
    if (_selectedStudents.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final dataList = <ReportCardData>[];

      for (final studentId in _selectedStudents) {
        final data = await service.getReportCardData(
          examId: widget.examId,
          studentId: studentId,
        );
        if (data != null) dataList.add(data);
      }

      if (dataList.isEmpty) {
        _showError('No report cards available');
        return;
      }

      if (!mounted) return;
      await service.printBulkReportCards(context, dataList);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadSelected() async {
    if (_selectedStudents.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final dataList = <ReportCardData>[];

      for (final studentId in _selectedStudents) {
        final data = await service.getReportCardData(
          examId: widget.examId,
          studentId: studentId,
        );
        if (data != null) dataList.add(data);
      }

      if (dataList.isEmpty) {
        _showError('No report cards available');
        return;
      }

      final pdfBytes = await service.generateBulkReportCards(dataList);
      if (!mounted) return;
      await _savePdf(pdfBytes, 'report_cards_${widget.examId}_selected.pdf');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _printAll() async {
    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final dataList = await service.getBulkReportCardData(widget.examId);

      if (dataList.isEmpty) {
        _showError('No report cards available');
        return;
      }

      if (!mounted) return;
      await service.printBulkReportCards(context, dataList);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadAll() async {
    setState(() => _isGenerating = true);

    try {
      final service = ref.read(reportCardServiceProvider);
      final dataList = await service.getBulkReportCardData(widget.examId);

      if (dataList.isEmpty) {
        _showError('No report cards available');
        return;
      }

      final pdfBytes = await service.generateBulkReportCards(dataList);
      if (!mounted) return;
      await _savePdf(pdfBytes, 'report_cards_${widget.examId}_all.pdf');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _savePdf(List<int> pdfBytes, String fileName) async {
    try {
      final saved = await PdfHelper.savePdf(
        Uint8List.fromList(pdfBytes),
        fileName.replaceAll('.pdf', ''),
      );

      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }
}

class _StudentReportCard extends StatelessWidget {
  final StudentExamResult result;
  final int index;
  final int totalStudents;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onViewReport;
  final VoidCallback onPrint;

  const _StudentReportCard({
    required this.result,
    required this.index,
    required this.totalStudents,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onViewReport,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = result.student;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelectionChanged(!isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged(value ?? false),
              ),
              const SizedBox(width: 8),

              // Rank badge
              SizedBox(
                width: 110,
                child: RankBadge(
                  rank: result.classRank,
                  totalStudents: totalStudents,
                ),
              ),
              const SizedBox(width: 16),

              // Student info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.studentName} ${student.fatherName}'.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          result.enrollment.rollNumber ?? '-',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          student.admissionNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${result.percentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getPercentageColor(result.percentage),
                          ),
                        ),
                        Text(
                          'Percentage',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    GradeBadge(
                      grade: result.overallGrade,
                      showGpa: true,
                      gpa: result.gpa,
                    ),
                    PassFailBadge(isPassed: result.isPassed),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: 'View Report Card',
                    onPressed: onViewReport,
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print',
                    onPressed: onPrint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.primary;
    if (percentage >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
