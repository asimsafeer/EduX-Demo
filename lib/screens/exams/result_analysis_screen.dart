/// EduX School Management System
/// Result Analysis Screen - Charts and statistics for exam results
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../providers/exam_provider.dart';
import '../../repositories/marks_repository.dart';
import 'widgets/exam_status_badge.dart';

class ResultAnalysisScreen extends ConsumerStatefulWidget {
  final int examId;

  const ResultAnalysisScreen({super.key, required this.examId});

  @override
  ConsumerState<ResultAnalysisScreen> createState() =>
      _ResultAnalysisScreenState();
}

class _ResultAnalysisScreenState extends ConsumerState<ResultAnalysisScreen> {
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
    final statsAsync = ref.watch(examStatsProvider);
    final rankingsAsync = ref.watch(classRankingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          AppButton.secondary(
            text: 'Report Cards',
            icon: Icons.print,
            size: AppButtonSize.small,
            onPressed: () => context.go('/exams/${widget.examId}/report-cards'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: examAsync.when(
        data: (exam) {
          if (exam == null) {
            return const Center(child: Text('Exam not found'));
          }

          return statsAsync.when(
            data: (stats) {
              if (stats == null) {
                return const Center(child: Text('No results available'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exam header
                    _buildExamHeader(
                      context,
                      theme,
                      exam.exam.name,
                      exam.classInfo.name,
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    _buildSummaryCards(context, theme, stats),
                    const SizedBox(height: 24),

                    // Charts row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grade distribution pie chart
                        Expanded(
                          child: _buildGradeDistributionChart(
                            context,
                            theme,
                            stats,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Pass/Fail chart
                        Expanded(
                          child: _buildPassFailChart(context, theme, stats),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Subject performance bar chart
                    _buildSubjectPerformanceChart(
                      context,
                      theme,
                      stats.subjectStats,
                    ),
                    const SizedBox(height: 24),

                    // Top performers
                    rankingsAsync.when(
                      data: (rankings) =>
                          _buildTopPerformers(context, theme, rankings),
                      loading: () => const AppLoadingIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
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
    String className,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.class_, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      className,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ExamStatusBadge(status: 'completed'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    ThemeData theme,
    ExamOverallStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 200,
              child: _StatCard(
                title: 'Total Students',
                value: stats.totalStudents.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: 200,
              child: _StatCard(
                title: 'Passed',
                value: stats.passedStudents.toString(),
                subtitle: '${stats.passPercentage.toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: 200,
              child: _StatCard(
                title: 'Failed',
                value: stats.failedStudents.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
            SizedBox(
              width: 200,
              child: _StatCard(
                title: 'Absent',
                value: stats.absentStudents.toString(),
                icon: Icons.person_off,
                color: Colors.orange,
              ),
            ),
            SizedBox(
              width: 200,
              child: _StatCard(
                title: 'Average %',
                value: '${stats.averagePercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeDistributionChart(
    BuildContext context,
    ThemeData theme,
    ExamOverallStats stats,
  ) {
    final gradeColors = {
      'A+': const Color(0xFF4CAF50),
      'A': const Color(0xFF8BC34A),
      'B+': const Color(0xFF03A9F4),
      'B': const Color(0xFF00BCD4),
      'C+': const Color(0xFFFFEB3B),
      'C': const Color(0xFFFFC107),
      'D': const Color(0xFFFF9800),
      'F': const Color(0xFFF44336),
    };

    final sections = stats.gradeDistribution.entries.map((entry) {
      final color = gradeColors[entry.key] ?? theme.colorScheme.primary;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: entry.value > 0 ? '${entry.key}\n${entry.value}' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: sections.isEmpty
                  ? const Center(child: Text('No data available'))
                  : PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: stats.gradeDistribution.entries.map((entry) {
                  final color =
                      gradeColors[entry.key] ?? theme.colorScheme.primary;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassFailChart(
    BuildContext context,
    ThemeData theme,
    ExamOverallStats stats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pass/Fail Ratio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: AppColors.success,
                      value: stats.passedStudents.toDouble(),
                      title: stats.passedStudents > 0
                          ? 'Pass\n${stats.passedStudents}'
                          : '',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppColors.error,
                      value: stats.failedStudents.toDouble(),
                      title: stats.failedStudents > 0
                          ? 'Fail\n${stats.failedStudents}'
                          : '',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (stats.absentStudents > 0)
                      PieChartSectionData(
                        color: AppColors.warning,
                        value: stats.absentStudents.toDouble(),
                        title: 'Absent\n${stats.absentStudents}',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Summary text
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: stats.passPercentage >= 60
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pass Rate: ${stats.passPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: stats.passPercentage >= 60
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformanceChart(
    BuildContext context,
    ThemeData theme,
    List<ExamSubjectStats> subjectStats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject-wise Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat = subjectStats[group.x.toInt()];
                        return BarTooltipItem(
                          '${stat.subject.name}\n',
                          const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text:
                                  'Avg: ${stat.averageMarks?.toStringAsFixed(1) ?? "N/A"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= subjectStats.length) {
                            return const SizedBox.shrink();
                          }
                          final stat = subjectStats[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              stat.subject.name.length > 10
                                  ? '${stat.subject.name.substring(0, 10)}...'
                                  : stat.subject.name,
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: theme.textTheme.labelSmall,
                          );
                        },
                        reservedSize: 40,
                        interval: 20,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: subjectStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final avgPercentage = stat.averageMarks != null
                        ? (stat.averageMarks! / stat.maxMarks) * 100
                        : 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: avgPercentage,
                          color: _getPerformanceColor(avgPercentage),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legendItem('Excellent (80%+)', AppColors.success),
                _legendItem('Good (60-79%)', AppColors.primary),
                _legendItem('Average (40-59%)', AppColors.warning),
                _legendItem('Poor (<40%)', AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.primary;
    if (percentage >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildTopPerformers(
    BuildContext context,
    ThemeData theme,
    List<StudentExamResult> rankings,
  ) {
    final topPerformers = rankings.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Performers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rankings.length > 10)
                  TextButton(
                    onPressed: () {
                      // Could show full rankings dialog
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      'Rank',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Student',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Marks',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '%',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Grade',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Table rows
            ...topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              final isOdd = index.isOdd;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isOdd
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        )
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: RankBadge(
                        rank: result.classRank,
                        totalStudents: rankings.length,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result.student.studentName} ${result.student.fatherName}'
                                .trim(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            result.enrollment.rollNumber ??
                                result.student.admissionNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${result.totalMarksObtained.toStringAsFixed(1)}/${result.totalMaxMarks.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${result.percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPerformanceColor(result.percentage),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: GradeBadge(grade: result.overallGrade),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: PassFailBadge(isPassed: result.isPassed),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (subtitle != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
