/// EduX School Management System
/// Student Attendance History Screen - View individual student attendance
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../database/app_database.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../core/constants/app_constants.dart';
import 'widgets/attendance_stats_card.dart';
import 'widgets/attendance_chart.dart';
import 'widgets/date_picker_button.dart';

/// Screen for viewing individual student attendance history
class StudentAttendanceHistoryScreen extends ConsumerStatefulWidget {
  final int studentId;

  const StudentAttendanceHistoryScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentAttendanceHistoryScreen> createState() =>
      _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState
    extends ConsumerState<StudentAttendanceHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month - 3, 1); // Last 3 months
    _endDate = now;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Student Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReport(),
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: FutureBuilder<Student?>(
        future: (db.select(
          db.students,
        )..where((t) => t.id.equals(widget.studentId))).getSingleOrNull(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final student = snapshot.data;
          if (student == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Student not found', style: theme.textTheme.titleLarge),
                ],
              ),
            );
          }

          return _buildContent(context, theme, student);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, Student student) {
    final statsAsync = ref.watch(
      studentAttendanceStatsProvider((
        studentId: widget.studentId,
        startDate: _startDate,
        endDate: _endDate,
      )),
    );

    final historyAsync = ref.watch(
      studentAttendanceHistoryProvider((
        studentId: widget.studentId,
        startDate: _startDate,
        endDate: _endDate,
      )),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info card
          _buildStudentInfoCard(theme, student),
          const SizedBox(height: 24),

          // Date range filter
          _buildDateFilter(theme),
          const SizedBox(height: 24),

          // Stats and chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats card
              Expanded(
                flex: 2,
                child: statsAsync.when(
                  data: (stats) => AttendanceStatsCard(stats: stats),
                  loading: () => const Card(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) =>
                      Card(child: Center(child: Text('Error: $e'))),
                ),
              ),
              const SizedBox(width: 24),
              // Pie chart
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: statsAsync.when(
                      data: (stats) => SizedBox(
                        height: 200,
                        child: AttendancePieChart(stats: stats, radius: 70),
                      ),
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // History table
          _buildHistorySection(theme, historyAsync),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard(ThemeData theme, Student student) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              // Student photo is stored as blob, display initials for now
              child: Text(
                '${student.studentName[0]}${(student.fatherName ?? '')[0]}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.studentName} ${student.fatherName ?? ''}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.badge,
                        'Adm: ${student.admissionNumber}',
                      ),
                      const SizedBox(width: 16),
                      _buildInfoChip(
                        Icons.person,
                        student.gender.toUpperCase(),
                      ),
                      const SizedBox(width: 16),
                      _buildEnrollmentInfo(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentInfo() {
    final db = ref.watch(databaseProvider);

    return FutureBuilder(
      future: _getEnrollmentInfo(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        final info = snapshot.data;
        if (info == null) return const SizedBox();

        return _buildInfoChip(Icons.class_, '${info.$1} - ${info.$2}');
      },
    );
  }

  Future<(String, String)?> _getEnrollmentInfo(AppDatabase db) async {
    final query = db.select(db.enrollments)
      ..where((t) => t.studentId.equals(widget.studentId))
      ..where((t) => t.isCurrent.equals(true));
    final enrollment = await query.getSingleOrNull();

    if (enrollment == null) return null;

    final classData = await (db.select(
      db.classes,
    )..where((t) => t.id.equals(enrollment.classId))).getSingle();
    final sectionData = await (db.select(
      db.sections,
    )..where((t) => t.id.equals(enrollment.sectionId))).getSingle();

    return (classData.name, sectionData.name);
  }

  Widget _buildDateFilter(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('Date Range:', style: theme.textTheme.titleSmall),
            const SizedBox(width: 16),
            DatePickerButton(
              selectedDate: _startDate,
              onDateChanged: (date) => setState(() => _startDate = date),
              isCompact: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('to', style: theme.textTheme.bodyMedium),
            ),
            DatePickerButton(
              selectedDate: _endDate,
              onDateChanged: (date) => setState(() => _endDate = date),
              isCompact: true,
            ),
            const SizedBox(width: 24),
            Text('Filter:', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'present', label: Text('Present')),
                ButtonSegment(value: 'absent', label: Text('Absent')),
                ButtonSegment(value: 'late', label: Text('Late')),
              ],
              selected: {_filterStatus},
              onSelectionChanged: (selected) =>
                  setState(() => _filterStatus = selected.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    ThemeData theme,
    AsyncValue<List<StudentAttendanceData>> historyAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (history) {
                final filtered = _filterStatus == 'all'
                    ? history
                    : history.where((h) => h.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No attendance records found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  );
                }

                return _buildHistoryTable(theme, filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(
    ThemeData theme,
    List<StudentAttendanceData> history,
  ) {
    final dateFormat = DateFormat(AppConstants.displayDateFormat);

    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Day')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Remarks')),
      ],
      rows: history.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final data = entry.value;
        final dayName = DateFormat('EEEE').format(data.date);

        return DataRow(
          cells: [
            DataCell(Text(index.toString())),
            DataCell(Text(dateFormat.format(data.date))),
            DataCell(Text(dayName)),
            DataCell(_buildStatusBadge(data.status)),
            DataCell(Text(data.remarks ?? '-')),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final displayName = AttendanceStatus.getDisplayName(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  void _printReport() {
    context.go('/attendance/reports?type=student');
  }
}
