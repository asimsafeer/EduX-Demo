/// EduX School Management System
/// Attendance Screen - Main attendance module screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/attendance_provider.dart';
import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assigned_classes_provider.dart';

import 'widgets/class_section_selector.dart';
import 'widgets/date_picker_button.dart';
import 'widgets/attendance_stats_card.dart';
import 'widgets/attendance_calendar.dart';

/// Main attendance screen with tabs for different views
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(context, theme),

          // Tab bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.edit_calendar), text: 'Mark Attendance'),
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
                Tab(icon: Icon(Icons.assessment), text: 'Reports'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _MarkAttendanceTab(),
                _CalendarTab(),
                _ReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Management',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Mark and track student attendance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Today's unmarked classes alert
          const _UnmarkedClassesAlert(),
        ],
      ),
    );
  }
}

/// Alert widget showing today's unmarked classes
class _UnmarkedClassesAlert extends ConsumerWidget {
  const _UnmarkedClassesAlert();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unmarkedAsync = ref.watch(todayUnmarkedClassesProvider);

    return unmarkedAsync.when(
      data: (unmarked) {
        if (unmarked.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'All classes marked for today',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${unmarked.length} class${unmarked.length > 1 ? 'es' : ''} not marked today',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

/// Tab for marking attendance
class _MarkAttendanceTab extends ConsumerWidget {
  const _MarkAttendanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(attendanceSelectedDateProvider);
    final selectedClass = ref.watch(attendanceSelectedClassProvider);
    final selectedSection = ref.watch(attendanceSelectedSectionProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection Row
          Card(
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
                  // Date picker
                  DatePickerButton(
                    selectedDate: selectedDate,
                    onDateChanged: (date) {
                      ref.read(attendanceSelectedDateProvider.notifier).state =
                          date;
                    },
                  ),
                  const SizedBox(width: 24),
                  // Class and Section selector
                  ClassSectionSelector(
                    selectedClassId: selectedClass,
                    selectedSectionId: selectedSection,
                    assignedClassIds: assignedClassIds,
                    onClassChanged: (classId) {
                      ref.read(attendanceSelectedClassProvider.notifier).state =
                          classId;
                    },
                    onSectionChanged: (sectionId) {
                      ref
                              .read(attendanceSelectedSectionProvider.notifier)
                              .state =
                          sectionId;
                    },
                  ),
                  const Spacer(),
                  // Open Full Screen Button
                  if (selectedClass != null && selectedSection != null)
                    FilledButton.icon(
                      onPressed: () {
                        context.go(
                          '/attendance/mark/$selectedClass/$selectedSection',
                        );
                      },
                      icon: const Icon(Icons.open_in_full),
                      label: const Text('Open Full Screen'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: selectedClass == null || selectedSection == null
                ? _buildEmptyState(context, theme)
                : _buildAttendancePreview(
                    context,
                    ref,
                    theme,
                    selectedDate,
                    selectedClass,
                    selectedSection,
                    academicYearAsync.valueOrNull ?? '',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a class and section to mark attendance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePreview(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DateTime date,
    int classId,
    int sectionId,
    String academicYear,
  ) {
    final summaryAsync = ref.watch(
      dailySummaryProvider((
        classId: classId,
        sectionId: sectionId,
        date: date,
      )),
    );

    final lockStatusAsync = ref.watch(
      dailyAttendanceStatusProvider((
        classId: classId,
        sectionId: sectionId,
        date: date,
      )),
    );

    final isLocked = lockStatusAsync.valueOrNull?.isLocked ?? false;
    final operationState = ref.watch(attendanceOperationProvider);

    // Listen for operation success/error
    ref.listen(attendanceOperationProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
        ref.read(attendanceOperationProvider.notifier).clearMessages();
      }
      if (next.error != null && prev?.error != next.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
          );
        }
        ref.read(attendanceOperationProvider.notifier).clearMessages();
      }
    });

    return summaryAsync.when(
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceStatsCard(summary: summary),
          const SizedBox(height: 24),
          if (!summary.isMarked)
            _buildNotMarkedMessage(context, theme, classId, sectionId)
          else
            _buildMarkedMessage(
              context,
              ref,
              theme,
              classId,
              sectionId,
              date,
              isLocked,
              operationState.isLoading,
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildNotMarkedMessage(
    BuildContext context,
    ThemeData theme,
    int classId,
    int sectionId,
  ) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.pending_actions,
              color: Colors.orange.shade600,
              size: 48,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Not Marked',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click "Open Full Screen" to mark attendance for this class.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkedMessage(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    int classId,
    int sectionId,
    DateTime date,
    bool isLocked,
    bool isLoading,
  ) {
    final currentUser = ref.watch(currentUserProvider);

    return Card(
      elevation: 0,
      color: isLocked ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.check_circle,
              color: isLocked ? Colors.red.shade600 : Colors.green.shade600,
              size: 48,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLocked ? 'Attendance Locked' : 'Attendance Marked',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLocked
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked
                        ? 'Attendance is locked.'
                        : 'You can edit the attendance by opening full screen view.',

                    style: TextStyle(
                      color: isLocked
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (currentUser != null) ...[
              if (isLocked)
                // Unlock button removed as per requirement
                const SizedBox.shrink() // Placeholder or empty
              else ...[
                // Lock Button
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref
                              .read(attendanceOperationProvider.notifier)
                              .lockAttendance(
                                classId: classId,
                                sectionId: sectionId,
                                date: date,
                                lockedBy: currentUser.id,
                              );
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock),
                  label: const Text('Lock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit Button
                FilledButton.icon(
                  onPressed: () {
                    context.go('/attendance/mark/$classId/$sectionId');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Tab for calendar view
class _CalendarTab extends ConsumerWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(attendanceCalendarMonthProvider);
    final selectedClass = ref.watch(attendanceSelectedClassProvider);
    final selectedSection = ref.watch(attendanceSelectedSectionProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Class selector
          Card(
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
                  Text('Select Class:', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 16),
                  ClassSectionSelector(
                    selectedClassId: selectedClass,
                    selectedSectionId: selectedSection,
                    assignedClassIds: ref
                        .watch(assignedClassIdsProvider)
                        .valueOrNull,
                    onClassChanged: (classId) {
                      ref.read(attendanceSelectedClassProvider.notifier).state =
                          classId;
                    },
                    onSectionChanged: (sectionId) {
                      ref
                              .read(attendanceSelectedSectionProvider.notifier)
                              .state =
                          sectionId;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Calendar
          Expanded(
            child: selectedClass == null || selectedSection == null
                ? Center(
                    child: Text(
                      'Select a class and section to view calendar',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : _buildCalendar(
                    context,
                    ref,
                    selectedMonth,
                    selectedClass,
                    selectedSection,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
    int classId,
    int sectionId,
  ) {
    final indicatorsAsync = ref.watch(
      calendarIndicatorsProvider((
        classId: classId,
        sectionId: sectionId,
        year: month.year,
        month: month.month,
      )),
    );

    return indicatorsAsync.when(
      data: (indicators) => AttendanceCalendar(
        selectedMonth: month,
        indicators: indicators,
        onMonthChanged: (newMonth) {
          ref.read(attendanceCalendarMonthProvider.notifier).state = newMonth;
        },
        onDayTap: (date) {
          ref.read(attendanceSelectedDateProvider.notifier).state = date;
          context.go('/attendance/mark/$classId/$sectionId');
        },
      ),
      loading: () => AttendanceCalendar(
        selectedMonth: month,
        indicators: const [],
        onMonthChanged: (_) {},
        isLoading: true,
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

/// Tab for reports
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Reports',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildReportCard(
                context,
                'Daily Report',
                Icons.today,
                'Generate attendance report for a single day',
                () {
                  context.go('/attendance/reports?type=daily');
                },
              ),
              _buildReportCard(
                context,
                'Monthly Report',
                Icons.calendar_month,
                'Generate monthly attendance grid',
                () {
                  context.go('/attendance/reports?type=monthly');
                },
              ),
              _buildReportCard(
                context,
                'Student Report',
                Icons.person,
                'Individual student attendance history',
                () {
                  context.go('/attendance/reports?type=student');
                },
              ),
              _buildReportCard(
                context,
                'Class Summary',
                Icons.summarize,
                'Compare attendance across classes',
                () {
                  context.go('/attendance/reports?type=class');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
