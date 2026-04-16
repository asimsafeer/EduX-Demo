/// EduX School Management System
/// Section Card Widget - Display individual section info
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../repositories/section_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/rbac_service.dart';

/// Card widget displaying section information with actions
class SectionCard extends ConsumerWidget {
  final SectionWithStats sectionWithStats;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReassignRollNumbers;

  const SectionCard({
    super.key,
    required this.sectionWithStats,
    this.onEdit,
    this.onDelete,
    this.onReassignRollNumbers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final section = sectionWithStats.section;

    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                // Section icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      section.name.isNotEmpty
                          ? section.name[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Section name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${section.name}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (section.roomNumber != null)
                        Text(
                          'Room: ${section.roomNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                if (!section.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Capacity indicator
            if (section.capacity != null) ...[
              _buildCapacityIndicator(context),
              const SizedBox(height: 12),
            ],

            // Stats row
            Row(
              children: [
                _buildStatChip(
                  context,
                  LucideIcons.users,
                  sectionWithStats.capacityStatus,
                  sectionWithStats.isAtCapacity ? Colors.orange.shade800 : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Class teacher
            if (sectionWithStats.classTeacherName != null) ...[
              Row(
                children: [
                  Icon(
                    LucideIcons.userCheck,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sectionWithStats.classTeacherName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions row
            if (canManage)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: onReassignRollNumbers,
                    icon: const Icon(LucideIcons.listOrdered, size: 18),
                    label: const Text('Roll Nos'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.edit2, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            // Actions row empty if not manager, but we want the spacing to match or be empty
            if (!canManage)
              const SizedBox(
                height: 36,
              ), // approximate height of the buttons to keep cards aligned
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final section = sectionWithStats.section;
    final capacity = section.capacity ?? 0;
    final studentCount = sectionWithStats.studentCount;
    final progress = capacity > 0 ? studentCount / capacity : 0.0;

    Color progressColor;
    if (progress >= 1.0) {
      progressColor = theme.colorScheme.error;
    } else if (progress >= 0.8) {
      progressColor = Colors.orange.shade800;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Capacity',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label, [
    Color? color,
  ]) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.1) ??
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
