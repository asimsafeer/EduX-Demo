/// EduX School Management System
/// Staff Attendance Screen - Mark staff attendance
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/staff_provider.dart';
import '../../repositories/staff_repository.dart';
import '../../repositories/staff_attendance_repository.dart';
import '../../services/staff_attendance_service.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

/// Screen for marking staff attendance
class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  final Map<int, String> _attendanceStatus = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(staffAttendanceDateProvider);
    final attendanceAsync = ref.watch(staffAttendanceForDateProvider);
    final summaryAsync = ref.watch(staffDailySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
        title: const Text('Staff Attendance'),
        actions: [
          // Date selector
          OutlinedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
          ),
          const SizedBox(width: 16),
          // Quick actions
          PopupMenuButton<String>(
            tooltip: 'Quick Actions',
            icon: const Icon(Icons.flash_on),
            onSelected: (action) => _handleQuickAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_present',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Mark All Present'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_absent',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Mark All Absent'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Save button
          FilledButton.icon(
            onPressed: _isSaving || _attendanceStatus.isEmpty
                ? null
                : _saveAttendance,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          summaryAsync.when(
            data: (summary) => _buildSummaryBar(theme, summary),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Attendance list
          Expanded(
            child: attendanceAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return const Center(child: Text('No active staff members'));
                }
                return _buildAttendanceList(records);
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, _) => AppErrorState(
                message: 'Failed to load attendance: $error',
                onRetry: () => ref.invalidate(staffAttendanceForDateProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    ThemeData theme,
    DailyStaffAttendanceSummary summary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Total', summary.total, Colors.blue),
          _buildSummaryItem('Present', summary.present, Colors.green),
          _buildSummaryItem('Absent', summary.absent, Colors.red),
          _buildSummaryItem('Late', summary.late, Colors.orange),
          _buildSummaryItem('Half Day', summary.halfDay, Colors.amber),
          _buildSummaryItem('On Leave', summary.onLeave, Colors.purple),
          const Spacer(),
          if (summary.isMarked)
            Chip(
              avatar: const Icon(Icons.check, size: 16, color: Colors.green),
              label: const Text('Attendance Marked'),
              backgroundColor: Colors.green.withValues(alpha: 0.15),
            )
          else
            Chip(
              avatar: const Icon(Icons.pending, size: 16, color: Colors.orange),
              label: const Text('Not Marked'),
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<StaffAttendanceRecord> records) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        final currentStatus =
            _attendanceStatus[record.staff.staff.id] ?? record.status;

        return _buildAttendanceRow(record, currentStatus);
      },
    );
  }

  Widget _buildAttendanceRow(
    StaffAttendanceRecord record,
    String currentStatus,
  ) {
    final theme = Theme.of(context);
    final staff = record.staff;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(staff),
          const SizedBox(width: 16),

          // Name & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${staff.staff.designation} • ${staff.staff.employeeId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Status buttons
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'present',
                label: Text('P'),
                icon: Icon(Icons.check, size: 16),
              ),
              ButtonSegment(
                value: 'absent',
                label: Text('A'),
                icon: Icon(Icons.close, size: 16),
              ),
              ButtonSegment(
                value: 'late',
                label: Text('L'),
                icon: Icon(Icons.schedule, size: 16),
              ),
              ButtonSegment(
                value: 'half_day',
                label: Text('H'),
                icon: Icon(Icons.timelapse, size: 16),
              ),
              ButtonSegment(
                value: 'leave',
                label: Text('Lv'),
                icon: Icon(Icons.event_busy, size: 16),
              ),
            ],
            selected: {currentStatus},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                setState(() {
                  _attendanceStatus[staff.staff.id] = selection.first;
                });
              }
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(StaffWithRole staff) {
    if (staff.staff.photo != null && staff.staff.photo!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: MemoryImage(staff.staff.photo!),
      );
    }

    return CircleAvatar(
      radius: 20,
      child: Text(
        staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'S',
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final current = ref.read(staffAttendanceDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(staffAttendanceDateProvider.notifier).state = picked;
      _attendanceStatus.clear();
    }
  }

  Future<void> _handleQuickAction(String action) async {
    final records = await ref.read(staffAttendanceForDateProvider.future);

    setState(() {
      for (final record in records) {
        switch (action) {
          case 'mark_all_present':
            _attendanceStatus[record.staff.staff.id] = 'present';
            break;
          case 'mark_all_absent':
            _attendanceStatus[record.staff.staff.id] = 'absent';
            break;
        }
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_attendanceStatus.isEmpty) return;

    setState(() => _isSaving = true);

    final service = ref.read(staffAttendanceServiceProvider);
    final date = ref.read(staffAttendanceDateProvider);

    final attendanceData = _attendanceStatus.entries.map((e) {
      return StaffAttendanceMarkData(staffId: e.key, status: e.value);
    }).toList();

    try {
      final result = await service.markBulkAttendance(
        attendanceData: attendanceData,
        date: date,
        markedBy: 1, // Current user ID
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance saved: ${result.successful} successful, ${result.failed} failed',
            ),
            backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
          ),
        );

        ref.invalidate(staffAttendanceForDateProvider);
        ref.invalidate(staffDailySummaryProvider);
        _attendanceStatus.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
