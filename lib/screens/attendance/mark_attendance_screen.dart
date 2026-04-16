/// EduX School Management System
/// Mark Attendance Screen - Class-wise attendance marking interface
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/attendance_repository.dart';
import 'widgets/attendance_stats_card.dart';
import 'widgets/attendance_student_row.dart';
import 'widgets/date_picker_button.dart';
import 'widgets/quick_action_buttons.dart';

/// Screen for marking attendance for a class
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final int classId;
  final int sectionId;

  const MarkAttendanceScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(attendanceSelectedDateProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    final localState = ref.watch(localAttendanceProvider);
    final operationState = ref.watch(attendanceOperationProvider);

    // Watch lock status
    final lockStatusAsync = ref.watch(
      dailyAttendanceStatusProvider((
        classId: widget.classId,
        sectionId: widget.sectionId,
        date: selectedDate,
      )),
    );
    final isLocked = lockStatusAsync.valueOrNull?.isLocked ?? false;

    // Get class and section names
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsByClassProvider(widget.classId));

    String className = 'Class';
    String sectionName = 'Section';

    classesAsync.whenData((classes) {
      final cls = classes.where((c) => c.id == widget.classId).firstOrNull;
      if (cls != null) className = cls.name;
    });

    sectionsAsync.whenData((sections) {
      final sec = sections.where((s) => s.id == widget.sectionId).firstOrNull;
      if (sec != null) sectionName = sec.name;
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/attendance'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Attendance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$className - $sectionName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          // Save button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed:
                  isLocked || !localState.hasChanges || operationState.isSaving
                  ? null
                  : () => _saveAttendance(academicYearAsync.valueOrNull ?? ''),

              icon: operationState.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                operationState.isSaving ? 'Saving...' : 'Save Attendance',
              ),
            ),
          ),
        ],
      ),
      body: academicYearAsync.when(
        data: (academicYear) =>
            _buildBody(context, theme, selectedDate, academicYear, isLocked),

        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading academic year: $e')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    DateTime selectedDate,
    String academicYear,
    bool isLocked,
  ) {
    final attendanceQuery = AttendanceQuery(
      classId: widget.classId,
      sectionId: widget.sectionId,
      date: selectedDate,
      academicYear: academicYear,
    );

    final attendanceAsync = ref.watch(classAttendanceProvider(attendanceQuery));
    final localState = ref.watch(localAttendanceProvider);
    final operationState = ref.watch(attendanceOperationProvider);

    // Show messages
    ref.listen(attendanceOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(attendanceOperationProvider.notifier).clearMessages();
        ref.read(localAttendanceProvider.notifier).markSaved();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(attendanceOperationProvider.notifier).clearMessages();
      }
    });

    return attendanceAsync.when(
      data: (entries) {
        // Load initial state from entries if not already loaded
        if (!localState.hasChanges &&
            localState.statuses.isEmpty &&
            entries.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(localAttendanceProvider.notifier).loadFromEntries(entries);
          });
        }

        // Filter entries by search
        final filteredEntries = _searchQuery.isEmpty
            ? entries
            : entries.where((e) {
                final name = '${e.student.studentName} ${e.student.fatherName}'
                    .toLowerCase();
                final roll = e.enrollment?.rollNumber?.toLowerCase() ?? '';
                return name.contains(_searchQuery.toLowerCase()) ||
                    roll.contains(_searchQuery.toLowerCase());
              }).toList();

        return Column(
          children: [
            // Top controls
            _buildControls(
              context,
              theme,
              selectedDate,
              entries,
              localState,
              operationState,
              isLocked,
            ),

            if (isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Text(
                        'Attendance is locked and cannot be edited',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Stats card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildLiveStats(localState, entries.length),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 16),

            // Student list
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No student data found for this class',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(classAttendanceProvider);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Data'),
                          ),
                        ],
                      ),
                    )
                  : filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students found matching "$_searchQuery"',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final studentId = entry.student.id;

                        return AttendanceStudentRow(
                          index: index,
                          entry: entry,
                          currentStatus: localState.statuses[studentId],
                          currentRemarks: localState.remarks[studentId],
                          isEditing: !isLocked,
                          onStatusChanged: (status) {
                            ref
                                .read(localAttendanceProvider.notifier)
                                .setStatus(studentId, status);
                          },
                          onRemarksChanged: (remarks) {
                            ref
                                .read(localAttendanceProvider.notifier)
                                .setRemarks(studentId, remarks);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ThemeData theme,
    DateTime selectedDate,
    List<StudentAttendanceEntry> entries,
    LocalAttendanceState localState,
    AttendanceOperationState operationState,
    bool isLocked,
  ) {
    final studentIds = entries.map((e) => e.student.id).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date picker
              DatePickerButton(
                selectedDate: selectedDate,
                onDateChanged: (date) {
                  // Show warning if there are unsaved changes
                  if (localState.hasChanges) {
                    _showUnsavedChangesDialog(context, () {
                      ref.read(attendanceSelectedDateProvider.notifier).state =
                          date;
                      ref.read(localAttendanceProvider.notifier).reset();
                    });
                  } else {
                    ref.read(attendanceSelectedDateProvider.notifier).state =
                        date;
                    ref.read(localAttendanceProvider.notifier).reset();
                  }
                },
              ),
              const Spacer(),
              if (localState.hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Unsaved changes',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick actions
          AttendanceQuickActions(
            onMarkAllPresent: isLocked
                ? null
                : () => ref
                      .read(localAttendanceProvider.notifier)
                      .setAllStatus(studentIds, AttendanceStatus.present),
            onMarkAllAbsent: isLocked
                ? null
                : () => ref
                      .read(localAttendanceProvider.notifier)
                      .setAllStatus(studentIds, AttendanceStatus.absent),
            onClearAll: !isLocked && localState.hasChanges
                ? () => ref
                      .read(localAttendanceProvider.notifier)
                      .loadFromEntries(entries)
                : null,
            isLoading: operationState.isSaving,
            hasChanges: localState.hasChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStats(LocalAttendanceState localState, int total) {
    int present = 0, absent = 0, late = 0, leave = 0;

    for (final status in localState.statuses.values) {
      switch (status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'leave':
          leave++;
          break;
      }
    }

    final summary = DailyAttendanceSummary(
      date: DateTime.now(),
      classId: widget.classId,
      sectionId: widget.sectionId,
      totalStudents: total,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      leaveCount: leave,
      isMarked: localState.statuses.isNotEmpty,
    );

    return AttendanceStatsCard(summary: summary, isCompact: true);
  }

  void _showUnsavedChangesDialog(BuildContext context, VoidCallback onDiscard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDiscard();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance(String academicYear) async {
    final localState = ref.read(localAttendanceProvider);
    final selectedDate = ref.read(attendanceSelectedDateProvider);
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await ref
        .read(attendanceOperationProvider.notifier)
        .saveAttendance(
          classId: widget.classId,
          sectionId: widget.sectionId,
          date: selectedDate,
          academicYear: academicYear,
          markedBy: currentUser.id,
          attendanceData: localState.toMarkDataList(),
        );
  }
}
