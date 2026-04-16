/// EduX School Management System
/// Date Picker Button Widget
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/working_days_service.dart';

/// Button widget for date selection with picker
class DatePickerButton extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowFutureDates;
  final bool showWeekday;
  final bool isCompact;

  const DatePickerButton({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
    this.allowFutureDates = false,
    this.showWeekday = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _isSameDay(selectedDate, today);

    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final compactFormat = DateFormat('dd MMM yyyy');

    return FutureBuilder<bool>(
      future: _isWorkingDay(selectedDate),
      builder: (context, snapshot) {
        final isWorkingDay = snapshot.data ?? true;
        final isNonWorkingDay = !isWorkingDay;

        return InkWell(
          onTap: () => _showDatePicker(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isNonWorkingDay
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNonWorkingDay
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isCompact ? 16 : 20,
                  color: isNonWorkingDay
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                SizedBox(width: isCompact ? 8 : 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCompact
                              ? compactFormat.format(selectedDate)
                              : dateFormat.format(selectedDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isNonWorkingDay ? theme.colorScheme.error : null,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Today',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isNonWorkingDay && !isCompact) ...[
                      const SizedBox(height: 2),
                      Text(
                        'School Closed - Non Working Day',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(width: isCompact ? 4 : 8),
                Icon(Icons.arrow_drop_down, color: theme.colorScheme.outline),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isWorkingDay(DateTime date) async {
    final workingDaysService = WorkingDaysService.instance();
    return await workingDaysService.isWorkingDate(date);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final first = firstDate ?? DateTime(now.year - 1, 1, 1);
    final last =
        lastDate ?? (allowFutureDates ? DateTime(now.year + 1, 12, 31) : today);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(last) ? last : selectedDate,
      firstDate: first,
      lastDate: last,
      helpText: 'Select Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Date range picker button
class DateRangePickerButton extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateRangePickerButton({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onRangeChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM');
    final yearFormat = DateFormat('yyyy');

    final sameYear = startDate.year == endDate.year;
    final startStr = sameYear
        ? dateFormat.format(startDate)
        : '${dateFormat.format(startDate)} ${yearFormat.format(startDate)}';
    final endStr =
        '${dateFormat.format(endDate)} ${yearFormat.format(endDate)}';

    return InkWell(
      onTap: () => _showDateRangePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '$startStr - $endStr',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 2, 1, 1);
    final last = lastDate ?? DateTime(now.year, 12, 31);

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      firstDate: first,
      lastDate: last,
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      saveText: 'Apply',
    );

    if (picked != null) {
      onRangeChanged(picked);
    }
  }
}
