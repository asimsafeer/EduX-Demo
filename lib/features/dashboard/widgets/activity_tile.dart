/// EduX School Management System
/// Activity Tile Widget for Recent Activity Feed
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';

/// Activity tile widget for recent activity feed
class ActivityTile extends StatelessWidget {
  final ActivityLog activity;

  const ActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getActionStyle(activity.action);
    final timeAgo = _getTimeAgo(activity.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAction(activity.action),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeAgo,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    return switch (action) {
      'login' => 'User logged in',
      'logout' => 'User logged out',
      'create' => 'Created new record',
      'update' => 'Updated record',
      'delete' => 'Deleted record',
      'backup' => 'Database backed up',
      'restore' => 'Database restored',
      'export' => 'Data exported',
      'import' => 'Data imported',
      'student_create' => 'New student added',
      'student_update' => 'Student updated',
      'staff_create' => 'New staff added',
      'staff_update' => 'Staff updated',
      'fee_collect' => 'Fee collected',
      'attendance_mark' => 'Attendance marked',
      'marks_entry' => 'Marks entered',
      _ =>
        action
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) {
              if (w.isEmpty) return w;
              return '${w[0].toUpperCase()}${w.substring(1)}';
            })
            .join(' '),
    };
  }

  (IconData, Color) _getActionStyle(String action) {
    if (action.contains('login')) {
      return (LucideIcons.logIn, AppColors.info);
    }
    if (action.contains('logout')) {
      return (LucideIcons.logOut, AppColors.textSecondary);
    }
    if (action.contains('create') || action.contains('add')) {
      return (LucideIcons.plus, AppColors.success);
    }
    if (action.contains('update') || action.contains('edit')) {
      return (LucideIcons.pencil, AppColors.primary);
    }
    if (action.contains('delete') || action.contains('remove')) {
      return (LucideIcons.trash2, AppColors.error);
    }
    if (action.contains('backup')) {
      return (LucideIcons.download, AppColors.info);
    }
    if (action.contains('restore')) {
      return (LucideIcons.uploadCloud, AppColors.warning);
    }
    if (action.contains('fee') || action.contains('payment')) {
      return (LucideIcons.banknote, AppColors.success);
    }
    if (action.contains('attendance')) {
      return (LucideIcons.calendarCheck, AppColors.primary);
    }
    if (action.contains('marks') || action.contains('exam')) {
      return (LucideIcons.fileText, AppColors.info);
    }
    return (LucideIcons.activity, AppColors.textSecondary);
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(dateTime);
  }
}

/// Section widget for activity feed
class ActivityFeed extends StatelessWidget {
  final List<ActivityLog> activities;

  const ActivityFeed({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.activity,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'No recent activity',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          ActivityTile(activity: activities[index]),
    );
  }
}
