/// EduX School Management System
/// Empty state widget for displaying when no data is available
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/theme.dart';

/// A widget to display when a list or view has no data
class AppEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Description text
  final String? description;

  /// Action button text
  final String? actionText;

  /// Action callback
  final VoidCallback? onAction;

  /// Icon size
  final double iconSize;

  const AppEmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.iconSize = 64,
  });

  /// Empty state for students
  const AppEmptyState.students({
    super.key,
    this.actionText = 'Add Student',
    this.onAction,
  }) : icon = LucideIcons.users,
       title = 'No Students Found',
       description =
           'There are no students to display. Add a new student to get started.',
       iconSize = 64;

  /// Empty state for staff
  const AppEmptyState.staff({
    super.key,
    this.actionText = 'Add Staff',
    this.onAction,
  }) : icon = LucideIcons.userCog,
       title = 'No Staff Members Found',
       description =
           'There are no staff members to display. Add a new staff member to get started.',
       iconSize = 64;

  /// Empty state for classes
  const AppEmptyState.classes({
    super.key,
    this.actionText = 'Add Class',
    this.onAction,
  }) : icon = LucideIcons.school,
       title = 'No Classes Found',
       description =
           'There are no classes to display. Add a new class to get started.',
       iconSize = 64;

  /// Empty state for attendance
  const AppEmptyState.attendance({
    super.key,
    this.actionText = 'Mark Attendance',
    this.onAction,
  }) : icon = LucideIcons.calendarCheck,
       title = 'No Attendance Records',
       description = 'No attendance has been marked for this date.',
       iconSize = 64;

  /// Empty state for fees
  const AppEmptyState.fees({
    super.key,
    this.actionText = 'Generate Invoice',
    this.onAction,
  }) : icon = LucideIcons.receipt,
       title = 'No Fee Records Found',
       description = 'There are no fee records to display.',
       iconSize = 64;

  /// Empty state for exams
  const AppEmptyState.exams({
    super.key,
    this.actionText = 'Create Exam',
    this.onAction,
  }) : icon = LucideIcons.fileText,
       title = 'No Exams Found',
       description =
           'There are no exams to display. Create a new exam to get started.',
       iconSize = 64;

  /// Empty state for search results
  const AppEmptyState.searchResults({super.key})
    : icon = LucideIcons.search,
      title = 'No Results Found',
      description = 'Try adjusting your search terms or filters.',
      actionText = null,
      onAction = null,
      iconSize = 64;

  /// Empty state for notifications
  const AppEmptyState.notifications({super.key})
    : icon = LucideIcons.bell,
      title = 'No Notifications',
      description = 'You\'re all caught up! No new notifications.',
      actionText = null,
      onAction = null,
      iconSize = 64;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.emptyStateTitle,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTextStyles.emptyStateMessage,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
