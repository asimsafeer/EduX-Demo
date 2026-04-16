/// EduX School Management System
/// Timetable Grid Widget - Interactive weekly timetable display
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../repositories/timetable_repository.dart';

/// Interactive grid widget for displaying weekly timetable
class TimetableGrid extends StatelessWidget {
  final Map<String, Map<int, TimetableSlotWithDetails?>> timetable;
  final List<PeriodDefinition> periods;
  final int classId;
  final int sectionId;
  final String academicYear;
  final void Function(
    String day,
    int periodNum,
    TimetableSlotWithDetails? slot,
  )?
  onSlotTap;
  final List<String> workingDays;

  const TimetableGrid({
    super.key,
    required this.timetable,
    required this.periods,
    required this.classId,
    required this.sectionId,
    required this.academicYear,
    this.onSlotTap,
    this.workingDays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
  });

  static const _allDayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };
  
  Map<String, String> get _dayLabels {
    return Map.fromEntries(
      _allDayLabels.entries.where((e) => workingDays.contains(e.key)),
    );
  }

  static const _subjectColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
  ];

  Color _getSubjectColor(int? subjectId) {
    if (subjectId == null) return Colors.grey;
    return _subjectColors[subjectId % _subjectColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out break periods for headers

    // All periods sorted by display order
    final allPeriods = List<PeriodDefinition>.from(periods)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Legend
            _buildLegend(context),
            const SizedBox(height: 16),
            // Grid
            Table(
              border: TableBorder.all(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(100), // Period column
                for (int i = 0; i < _dayLabels.length; i++)
                  i + 1: const FlexColumnWidth(),
              },
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  children: [
                    _buildHeaderCell(context, 'Period'),
                    ..._dayLabels.values.map(
                      (day) => _buildHeaderCell(context, day),
                    ),
                  ],
                ),
                // Period rows
                for (final period in allPeriods)
                  TableRow(
                    decoration: period.isBreak
                        ? BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                          )
                        : null,
                    children: [
                      _buildPeriodCell(context, period),
                      ..._dayLabels.keys.map((day) {
                        final slot = timetable[day]?[period.periodNumber];
                        return _buildSlotCell(context, day, period, slot);
                      }),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _buildLegendItem(context, Colors.grey[700]!, 'Free Period'),
        const SizedBox(width: 16),
        _buildLegendItem(context, Colors.brown, 'Break'),
        const Spacer(),
        Icon(
          LucideIcons.info,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Click on a slot to add/edit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final theme = Theme.of(context);

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCell(BuildContext context, PeriodDefinition period) {
    final theme = Theme.of(context);

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              period.isBreak ? period.name : 'Period ${period.periodNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${period.startTime} - ${period.endTime}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCell(
    BuildContext context,
    String day,
    PeriodDefinition period,
    TimetableSlotWithDetails? slot,
  ) {
    final theme = Theme.of(context);

    // Break period
    if (period.isBreak) {
      return TableCell(
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.1)),
          child: Center(
            child: Icon(
              LucideIcons.coffee,
              color: Colors.brown.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ),
      );
    }

    // Empty slot
    if (slot == null) {
      return TableCell(
        child: InkWell(
          onTap: () => onSlotTap?.call(day, period.periodNumber, null),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Icon(
                LucideIcons.plus,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Slot with subject
    final subjectColor = _getSubjectColor(slot.slot.subjectId);

    return TableCell(
      child: InkWell(
        onTap: () => onSlotTap?.call(day, period.periodNumber, slot),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: subjectColor.withValues(alpha: 0.1),
            border: Border.all(color: subjectColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.shortCode,
                  style: TextStyle(
                    color: subjectColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (slot.teacherName != null)
                  Text(
                    slot.teacherName!.split(' ').first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
