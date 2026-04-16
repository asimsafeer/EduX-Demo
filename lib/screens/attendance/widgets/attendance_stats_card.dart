/// EduX School Management System
/// Attendance Stats Card Widget
library;

import 'package:flutter/material.dart';
import '../../../repositories/attendance_repository.dart';

/// Card widget displaying attendance statistics summary
class AttendanceStatsCard extends StatelessWidget {
  final DailyAttendanceSummary? summary;
  final AttendanceStats? stats;
  final bool isCompact;
  final bool showPercentageBar;

  const AttendanceStatsCard({
    super.key,
    this.summary,
    this.stats,
    this.isCompact = false,
    this.showPercentageBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get values from either summary or stats
    final total = summary?.totalStudents ?? stats?.totalDays ?? 0;
    final present = summary?.presentCount ?? stats?.presentDays ?? 0;
    final absent = summary?.absentCount ?? stats?.absentDays ?? 0;
    final late = summary?.lateCount ?? stats?.lateDays ?? 0;
    final leave = summary?.leaveCount ?? stats?.leaveDays ?? 0;
    final percentage =
        summary?.attendancePercentage ?? stats?.attendancePercentage ?? 0.0;

    if (isCompact) {
      return _buildCompactView(
        theme,
        total,
        present,
        absent,
        late,
        leave,
        percentage,
      );
    }

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (summary != null)
                  _buildStatusChip(
                    context,
                    summary!.isMarked ? 'Marked' : 'Not Marked',
                    summary!.isMarked ? Colors.green : Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  context,
                  'Total',
                  total.toString(),
                  theme.colorScheme.outline,
                ),
                _buildDivider(),
                _buildStatItem(
                  context,
                  'Present',
                  present.toString(),
                  Colors.green.shade600,
                ),
                _buildDivider(),
                _buildStatItem(
                  context,
                  'Absent',
                  absent.toString(),
                  Colors.red.shade600,
                ),
                _buildDivider(),
                _buildStatItem(
                  context,
                  'Late',
                  late.toString(),
                  Colors.orange.shade600,
                ),
                _buildDivider(),
                _buildStatItem(
                  context,
                  'Leave',
                  leave.toString(),
                  Colors.blue.shade600,
                ),
              ],
            ),

            // Percentage bar
            if (showPercentageBar) ...[
              const SizedBox(height: 16),
              _buildPercentageBar(context, percentage, total > 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(
    ThemeData theme,
    int total,
    int present,
    int absent,
    int late,
    int leave,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip('P', present.toString(), Colors.green.shade600),
          _buildStatChip('A', absent.toString(), Colors.red.shade600),
          _buildStatChip('L', late.toString(), Colors.orange.shade600),
          _buildStatChip('LV', leave.toString(), Colors.blue.shade600),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPercentageColor(percentage),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPercentageBar(
    BuildContext context,
    double percentage,
    bool hasData,
  ) {
    final theme = Theme.of(context);
    final color = _getPercentageColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance Rate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              hasData ? '${percentage.toStringAsFixed(1)}%' : 'N/A',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasData ? color : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hasData ? percentage / 100 : 0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green.shade600;
    if (percentage >= 75) return Colors.lightGreen.shade600;
    if (percentage >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
