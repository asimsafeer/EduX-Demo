/// EduX School Management System
/// Attendance Report Screen - Generate attendance PDFs
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/pdf_helper.dart';

import '../../providers/attendance_provider.dart';

import '../../providers/academics_provider.dart';
import '../../providers/school_settings_provider.dart'
    hide currentAcademicYearProvider;
import '../../repositories/attendance_repository.dart';
import '../../providers/assigned_classes_provider.dart';
import 'widgets/class_section_selector.dart';
import 'widgets/date_picker_button.dart';

/// Screen for generating attendance reports
class AttendanceReportScreen extends ConsumerStatefulWidget {
  final String? reportType;

  const AttendanceReportScreen({super.key, this.reportType});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String _selectedReportType = 'daily';
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedStudentId;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.reportType != null) {
      _selectedReportType = widget.reportType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/attendance'),
        ),
        title: const Text('Generate Attendance Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            _buildReportTypeSelector(theme),
            const SizedBox(height: 24),

            // Dynamic options based on report type
            _buildReportOptions(theme),
            const SizedBox(height: 32),

            // Generate Button
            Center(
              child: FilledButton.icon(
                onPressed: _canGenerate() && !_isGenerating
                    ? () => _generateReport()
                    : null,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate PDF Report',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector(ThemeData theme) {
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
              'Report Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _buildTypeChip('daily', 'Daily Report', Icons.today),
                _buildTypeChip(
                  'monthly',
                  'Monthly Report',
                  Icons.calendar_month,
                ),
                _buildTypeChip('student', 'Student Report', Icons.person),
                _buildTypeChip('class', 'Class Summary', Icons.summarize),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedReportType == type;
    final theme = Theme.of(context);

    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedReportType = type);
      },
      avatar: isSelected ? null : Icon(icon, size: 18),
      label: Text(label),
      selectedColor: theme.colorScheme.primaryContainer,
      // checkmarkColor: theme.colorScheme.primary, // Not needed for ChoiceChip usually, or handled by theme
    );
  }

  Widget _buildReportOptions(ThemeData theme) {
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
              'Report Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildOptionFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    switch (_selectedReportType) {
      case 'daily':
        return [
          _buildDateField('Date'),
          const SizedBox(height: 16),
          _buildClassSectionField(),
        ];
      case 'monthly':
        return [
          _buildMonthYearField(),
          const SizedBox(height: 16),
          _buildClassSectionField(),
        ];
      case 'student':
        return [
          _buildDateRangeField(),
          const SizedBox(height: 16),
          _buildStudentSelector(),
        ];
      case 'class':
        return [_buildDateRangeField()];
      default:
        return [];
    }
  }

  Widget _buildDateField(String label) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 16),
        DatePickerButton(
          selectedDate: _selectedDate,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildMonthYearField() {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('MMMM yyyy');

    return Row(
      children: [
        Text('Month: ', style: theme.textTheme.bodyLarge),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _selectMonth(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(monthFormat.format(_selectedDate)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeField() {
    return Row(
      children: [
        Text('From: ', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 8),
        DatePickerButton(
          selectedDate: _startDate,
          onDateChanged: (date) => setState(() => _startDate = date),
          isCompact: true,
        ),
        const SizedBox(width: 16),
        Text('To: ', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 8),
        DatePickerButton(
          selectedDate: _endDate,
          onDateChanged: (date) => setState(() => _endDate = date),
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildClassSectionField() {
    return Row(
      children: [
        Text('Class: ', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(width: 16),
        ClassSectionSelector(
          selectedClassId: _selectedClassId,
          selectedSectionId: _selectedSectionId,
          onClassChanged: (id) => setState(() => _selectedClassId = id),
          onSectionChanged: (id) => setState(() => _selectedSectionId = id),
          assignedClassIds: ref.watch(assignedClassIdsProvider).valueOrNull,
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildStudentSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Class: ', style: theme.textTheme.bodyLarge),
            const SizedBox(width: 16),
            ClassSectionSelector(
              selectedClassId: _selectedClassId,
              selectedSectionId: _selectedSectionId,
              onClassChanged: (id) => setState(() {
                _selectedClassId = id;
                _selectedStudentId = null;
              }),
              onSectionChanged: (id) => setState(() {
                _selectedSectionId = id;
                _selectedStudentId = null;
              }),
              assignedClassIds: ref.watch(assignedClassIdsProvider).valueOrNull,
              isCompact: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedClassId != null && _selectedSectionId != null)
          _StudentSelector(
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            selectedStudentId: _selectedStudentId,
            onStudentChanged: (id) => setState(() => _selectedStudentId = id),
          ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, 1));
    }
  }

  bool _canGenerate() {
    switch (_selectedReportType) {
      case 'daily':
      case 'monthly':
        return _selectedClassId != null && _selectedSectionId != null;
      case 'student':
        return _selectedStudentId != null;
      case 'class':
        return true;
      default:
        return false;
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final pdfService = ref.read(attendancePdfServiceProvider);
      final db = ref.read(databaseProvider);
      final service = ref.read(attendanceServiceProvider);

      // Get school name from settings
      final settings = await ref.read(schoolSettingsProvider.future);
      final schoolName = settings?.schoolName ?? 'School';

      late final List<int> bytes;
      late final String fileName;

      switch (_selectedReportType) {
        case 'daily':
          final academicYear = await db.getCurrentAcademicYear();
          final entries = await service.getClassAttendance(
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            date: _selectedDate,
            academicYear: academicYear?.name ?? '',
          );
          final summary = await service.getDailySummary(
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            date: _selectedDate,
          );
          final classData = await (db.select(
            db.classes,
          )..where((t) => t.id.equals(_selectedClassId!))).getSingle();
          final sectionData = await (db.select(
            db.sections,
          )..where((t) => t.id.equals(_selectedSectionId!))).getSingle();

          bytes = await pdfService.generateDailyReport(
            schoolName: schoolName,
            className: classData.name,
            sectionName: sectionData.name,
            date: _selectedDate,
            attendanceData: entries,
            summary: summary,
          );
          fileName =
              'daily_attendance_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.pdf';
          break;

        case 'monthly':
          final academicYear = await db.getCurrentAcademicYear();
          final entries = await service.getClassAttendance(
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            date: DateTime(_selectedDate.year, _selectedDate.month, 1),
            academicYear: academicYear?.name ?? '',
          );

          // Build attendance grid
          final grid = <int, Map<int, String>>{};
          for (final entry in entries) {
            final history = await service.getStudentHistory(
              studentId: entry.student.id,
              startDate: DateTime(_selectedDate.year, _selectedDate.month, 1),
              endDate: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
            );
            grid[entry.student.id] = {
              for (final h in history) h.date.day: h.status,
            };
          }

          final stats = await service.getClassStats(
            classId: _selectedClassId!,
            sectionId: _selectedSectionId!,
            startDate: DateTime(_selectedDate.year, _selectedDate.month, 1),
            endDate: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
          );

          final classData = await (db.select(
            db.classes,
          )..where((t) => t.id.equals(_selectedClassId!))).getSingle();
          final sectionData = await (db.select(
            db.sections,
          )..where((t) => t.id.equals(_selectedSectionId!))).getSingle();

          bytes = await pdfService.generateMonthlyReport(
            schoolName: schoolName,
            className: classData.name,
            sectionName: sectionData.name,
            year: _selectedDate.year,
            month: _selectedDate.month,
            students: entries,
            attendanceGrid: grid,
            classStats: stats,
          );
          fileName =
              'monthly_attendance_${DateFormat('yyyy-MM').format(_selectedDate)}.pdf';
          break;

        case 'student':
          final student = await (db.select(
            db.students,
          )..where((t) => t.id.equals(_selectedStudentId!))).getSingle();
          final enrollmentQuery = db.select(db.enrollments)
            ..where((t) => t.studentId.equals(_selectedStudentId!))
            ..where((t) => t.isCurrent.equals(true));
          final enrollment = await enrollmentQuery.getSingleOrNull();

          String className = 'N/A', sectionName = 'N/A';
          if (enrollment != null) {
            final classData = await (db.select(
              db.classes,
            )..where((t) => t.id.equals(enrollment.classId))).getSingle();
            final sectionData = await (db.select(
              db.sections,
            )..where((t) => t.id.equals(enrollment.sectionId))).getSingle();
            className = classData.name;
            sectionName = sectionData.name;
          }

          final history = await service.getStudentHistory(
            studentId: _selectedStudentId!,
            startDate: _startDate,
            endDate: _endDate,
          );
          final stats = await service.getStudentStats(
            studentId: _selectedStudentId!,
            startDate: _startDate,
            endDate: _endDate,
          );

          bytes = await pdfService.generateStudentHistoryReport(
            schoolName: schoolName,
            student: student,
            className: className,
            sectionName: sectionName,
            startDate: _startDate,
            endDate: _endDate,
            attendanceHistory: history,
            stats: stats,
          );
          fileName = 'student_attendance_${student.admissionNumber}.pdf';
          break;

        case 'class':
          // Get all class-section stats
          final sections = await db.select(db.sections).get();
          final summaries =
              <
                ({
                  String className,
                  String sectionName,
                  int totalStudents,
                  AttendanceStats stats,
                })
              >[];

          for (final section in sections) {
            final classData = await (db.select(
              db.classes,
            )..where((t) => t.id.equals(section.classId))).getSingle();

            // Get student count for this section
            final enrollmentQuery = db.select(db.enrollments)
              ..where((t) => t.classId.equals(section.classId))
              ..where((t) => t.sectionId.equals(section.id))
              ..where((t) => t.isCurrent.equals(true));
            final enrollments = await enrollmentQuery.get();
            final studentCount = enrollments.length;

            final stats = await service.getClassStats(
              classId: section.classId,
              sectionId: section.id,
              startDate: _startDate,
              endDate: _endDate,
            );

            summaries.add((
              className: classData.name,
              sectionName: section.name,
              totalStudents: studentCount,
              stats: stats,
            ));
          }

          bytes = await pdfService.generateClassSummaryReport(
            schoolName: schoolName,
            startDate: _startDate,
            endDate: _endDate,
            classSummaries: summaries,
          );
          fileName =
              'class_summary_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
          break;

        default:
          throw Exception('Unknown report type');
      }

      // Show PDF Preview
      if (mounted) {
        // Stop generating spinner before opening preview
        setState(() => _isGenerating = false);
        await PdfHelper.previewPdf(
          context,
          Uint8List.fromList(bytes),
          fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

/// Student selector widget
class _StudentSelector extends ConsumerWidget {
  final int classId;
  final int sectionId;
  final int? selectedStudentId;
  final ValueChanged<int?> onStudentChanged;

  const _StudentSelector({
    required this.classId,
    required this.sectionId,
    required this.selectedStudentId,
    required this.onStudentChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);

    return academicYearAsync.when(
      data: (academicYear) {
        final attendanceQuery = AttendanceQuery(
          classId: classId,
          sectionId: sectionId,
          date: DateTime.now(),
          academicYear: academicYear,
        );
        final studentsAsync = ref.watch(
          classAttendanceProvider(attendanceQuery),
        );

        return studentsAsync.when(
          data: (students) => Row(
            children: [
              Text('Student: ', style: theme.textTheme.bodyLarge),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedStudentId,
                  hint: const Text('Select Student'),
                  items: students
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.student.id,
                          child: Text(
                            '${s.student.studentName} ${s.student.fatherName}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onStudentChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
