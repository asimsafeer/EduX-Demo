/// EduX School Management System
/// Attendance Calendar Widget
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../repositories/attendance_repository.dart';

/// Calendar widget for displaying attendance indicators
class AttendanceCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final List<CalendarDayIndicator> indicators;
  final ValueChanged<DateTime>? onDayTap;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isLoading;

  const AttendanceCalendar({
    super.key,
    required this.selectedMonth,
    required this.indicators,
    required this.onMonthChanged,
    this.selectedDate,
    this.onDayTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Create indicator map for quick lookup
    final indicatorMap = <int, CalendarDayIndicator>{};
    for (final indicator in indicators) {
      indicatorMap[indicator.date.day] = indicator;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Month header with navigation
          _buildMonthHeader(context, theme),

          // Weekday headers
          _buildWeekdayHeaders(theme),

          // Calendar grid
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            _buildCalendarGrid(
              context,
              theme,
              now,
              firstWeekday,
              daysInMonth,
              indicatorMap,
            ),

          // Legend
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, ThemeData theme) {
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
            ),
            tooltip: 'Previous month',
          ),
          Text(
            monthFormat.format(selectedMonth),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
            ),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(ThemeData theme) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: weekdays.map((day) {
          final isWeekend = day == 'Sat' || day == 'Sun';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? theme.colorScheme.error.withValues(alpha: 0.7)
                      : theme.colorScheme.outline,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    ThemeData theme,
    DateTime now,
    int firstWeekday,
    int daysInMonth,
    Map<int, CalendarDayIndicator> indicatorMap,
  ) {
    final weeks = <Widget>[];
    var currentDay = 1;
    // Monday = 1, so if firstWeekday is 1, we start at position 0
    var dayOffset = firstWeekday - 1;

    while (currentDay <= daysInMonth) {
      final weekRow = <Widget>[];

      for (var i = 0; i < 7; i++) {
        if ((weeks.isEmpty && i < dayOffset) || currentDay > daysInMonth) {
          // Empty cell
          weekRow.add(const Expanded(child: SizedBox(height: 48)));
        } else {
          final day = currentDay;
          final date = DateTime(selectedMonth.year, selectedMonth.month, day);
          final indicator = indicatorMap[day];
          final isToday = _isSameDay(date, now);
          final isSelected =
              selectedDate != null && _isSameDay(date, selectedDate!);
          final isFuture = date.isAfter(now);

          weekRow.add(
            Expanded(
              child: _buildDayCell(
                context,
                theme,
                day,
                indicator,
                isToday,
                isSelected,
                isFuture,
                () => onDayTap?.call(date),
              ),
            ),
          );
          currentDay++;
        }
      }

      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(children: weekRow),
        ),
      );
    }

    return Column(children: weeks);
  }

  Widget _buildDayCell(
    BuildContext context,
    ThemeData theme,
    int day,
    CalendarDayIndicator? indicator,
    bool isToday,
    bool isSelected,
    bool isFuture,
    VoidCallback? onTap,
  ) {
    final status = indicator?.status ?? CalendarDayStatus.notMarked;
    final indicatorColor = _getStatusColor(status);
    final canTap = !isFuture && status != CalendarDayStatus.holiday;

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isFuture
                    ? theme.colorScheme.outline.withValues(alpha: 0.4)
                    : (status == CalendarDayStatus.holiday
                          ? theme.colorScheme.error.withValues(alpha: 0.7)
                          : null),
              ),
            ),
            if (!isFuture && status != CalendarDayStatus.notMarked) ...[
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('All Present', Colors.green.shade600),
          const SizedBox(width: 16),
          _buildLegendItem('Partial', Colors.yellow.shade700),
          const SizedBox(width: 16),
          _buildLegendItem('High Absence', Colors.red.shade600),
          const SizedBox(width: 16),
          _buildLegendItem('Holiday', Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(CalendarDayStatus status) {
    switch (status) {
      case CalendarDayStatus.allPresent:
        return Colors.green.shade600;
      case CalendarDayStatus.partial:
        return Colors.yellow.shade700;
      case CalendarDayStatus.highAbsence:
        return Colors.red.shade600;
      case CalendarDayStatus.holiday:
        return Colors.grey.shade400;
      case CalendarDayStatus.notMarked:
        return Colors.transparent;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
