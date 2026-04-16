/// EduX School Management System
/// Quick Action Buttons Widget
library;

import 'package:flutter/material.dart';

/// Quick action buttons for bulk attendance operations
class AttendanceQuickActions extends StatelessWidget {
  final VoidCallback? onMarkAllPresent;
  final VoidCallback? onMarkAllAbsent;
  final VoidCallback? onClearAll;
  final bool isLoading;
  final bool hasChanges;

  const AttendanceQuickActions({
    super.key,
    this.onMarkAllPresent,
    this.onMarkAllAbsent,
    this.onClearAll,
    this.isLoading = false,
    this.hasChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Quick Actions:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            context,
            label: 'Mark All Present',
            icon: Icons.check_circle_outline,
            color: Colors.green.shade600,
            onPressed: isLoading ? null : onMarkAllPresent,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context,
            label: 'Mark All Absent',
            icon: Icons.cancel_outlined,
            color: Colors.red.shade600,
            onPressed: isLoading ? null : onMarkAllAbsent,
          ),
          if (onClearAll != null && hasChanges) ...[
            const SizedBox(width: 12),
            _buildActionButton(
              context,
              label: 'Clear All',
              icon: Icons.refresh,
              color: theme.colorScheme.outline,
              onPressed: isLoading ? null : onClearAll,
              outline: true,
            ),
          ],
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool outline = false,
  }) {
    if (outline) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
