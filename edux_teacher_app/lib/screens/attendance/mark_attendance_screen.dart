/// EduX Teacher App - Mark Attendance Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance_record.dart';
import '../../models/class_section.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/sync_provider.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final ClassSection classSection;

  const MarkAttendanceScreen({
    super.key,
    required this.classSection,
  });

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load attendance for this class
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  Future<void> _loadAttendance() async {
    await ref.read(attendanceProvider.notifier).loadStudents(
          widget.classSection.classId,
          widget.classSection.sectionId,
          selectedDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final stats = attendanceState.stats;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.classSection.displayName),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          // Save button
          if (attendanceState.isComplete)
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          _buildStatsCard(stats),

          // Quick Actions
          _buildQuickActions(),

          // Students List
          Expanded(
            child: attendanceState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceState.students.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsList(attendanceState),
          ),

          // Bottom Bar
          _buildBottomBar(stats),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AttendanceStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Present',
                  value: stats.present,
                  color: AttendanceStatus.getColor('present'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Absent',
                  value: stats.absent,
                  color: AttendanceStatus.getColor('absent'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Late',
                  value: stats.late,
                  color: AttendanceStatus.getColor('late'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Leave',
                  value: stats.leave,
                  color: AttendanceStatus.getColor('leave'),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${stats.marked}/${stats.total}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stats.percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: stats.isComplete ? AppTheme.success : AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              label: 'All Present',
              icon: Icons.check_circle,
              color: AttendanceStatus.getColor('present'),
              onTap: () => _markAll('present'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              label: 'All Absent',
              icon: Icons.cancel,
              color: AttendanceStatus.getColor('absent'),
              onTap: () => _markAll('absent'),
            ),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            label: 'Reset',
            icon: Icons.refresh,
            color: AppTheme.textTertiary,
            onTap: _clearAll,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(dynamic attendanceState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceState.students.length,
      itemBuilder: (context, index) {
        final student = attendanceState.students[index];
        final status = attendanceState.getStatus(student.studentId);
        final remarks = attendanceState.getRemarks(student.studentId);

        return _StudentAttendanceCard(
          student: student,
          status: status,
          remarks: remarks,
          onStatusChanged: (newStatus) => _markAttendance(student.studentId, newStatus),
          onAddRemark: () => _showRemarkDialog(student.studentId, remarks),
        )
            .animate()
            .fadeIn(delay: (index * 30).ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildEmptyState() {
    final attendanceState = ref.watch(attendanceProvider);
    final hasError = attendanceState.error != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.people_outline,
            size: 64,
            color: hasError 
                ? AppTheme.error.withValues(alpha: 0.5)
                : AppTheme.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasError ? 'Failed to Load Students' : 'No Students Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: hasError ? AppTheme.error : AppTheme.textSecondary,
                ),
          ),
          if (attendanceState.error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                attendanceState.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.error.withValues(alpha: 0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Tap refresh to load students from server',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: attendanceState.isLoading
                ? null
                : () {
                    ref.read(attendanceProvider.notifier).fetchStudentsFromServer(
                          widget.classSection.classId,
                          widget.classSection.sectionId,
                        );
                  },
            icon: attendanceState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(attendanceState.isLoading ? 'Loading...' : 'Load Students'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AttendanceStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.marked} of ${stats.total} marked',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (stats.remaining > 0)
                    Text(
                      '${stats.remaining} remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warning,
                          ),
                    ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: stats.isComplete ? () => Navigator.pop(context) : null,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendance(int studentId, String status) async {
    await ref.read(attendanceProvider.notifier).markAttendance(
          studentId,
          widget.classSection.classId,
          widget.classSection.sectionId,
          selectedDate,
          status,
        );

    // Refresh pending count
    ref.read(syncProvider.notifier).refreshPendingCount();
  }

  Future<void> _markAll(String status) async {
    await ref.read(attendanceProvider.notifier).markAll(
          widget.classSection.classId,
          widget.classSection.sectionId,
          selectedDate,
          status,
        );

    // Refresh pending count
    ref.read(syncProvider.notifier).refreshPendingCount();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will remove all attendance marks for this class.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(attendanceProvider.notifier).clearAll(
            widget.classSection.classId,
            widget.classSection.sectionId,
            selectedDate,
          );

      // Refresh pending count
      ref.read(syncProvider.notifier).refreshPendingCount();
    }
  }

  Future<void> _showRemarkDialog(int studentId, String? currentRemark) async {
    final controller = TextEditingController(text: currentRemark ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Remark'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter remark (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(attendanceProvider.notifier).addRemark(
            studentId,
            widget.classSection.classId,
            widget.classSection.sectionId,
            selectedDate,
            result,
          );
    }

    controller.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 12,
          horizontal: compact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: color .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 16 : 20, color: color),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final dynamic student;
  final String? status;
  final String? remarks;
  final Function(String) onStatusChanged;
  final VoidCallback onAddRemark;

  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.remarks,
    required this.onStatusChanged,
    required this.onAddRemark,
  });

  @override
  Widget build(BuildContext context) {
    final hasRemarks = remarks != null && remarks!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (student.rollNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Roll: ${student.rollNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Remark Button
                IconButton(
                  onPressed: onAddRemark,
                  icon: Icon(
                    hasRemarks ? Icons.note : Icons.note_add_outlined,
                    color: hasRemarks ? AppTheme.primary : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),

            // Remarks text
            if (hasRemarks) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remarks!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Status Buttons
            Row(
              children: [
                _StatusButton(
                  status: 'present',
                  isSelected: status == 'present',
                  onTap: () => onStatusChanged('present'),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  status: 'absent',
                  isSelected: status == 'absent',
                  onTap: () => onStatusChanged('absent'),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  status: 'late',
                  isSelected: status == 'late',
                  onTap: () => onStatusChanged('late'),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  status: 'leave',
                  isSelected: status == 'leave',
                  onTap: () => onStatusChanged('leave'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AttendanceStatus.getColor(status);
    final bgColor = AttendanceStatus.getBackgroundColor(status);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            AttendanceStatus.getShortCode(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
