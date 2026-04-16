/// EduX School Management System
/// Class Card Widget - Display individual class info
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/rbac_service.dart';

/// Card widget displaying class information with actions
class ClassCard extends ConsumerWidget {
  final SchoolClass schoolClass;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewSections;
  final VoidCallback? onAssignSubjects;

  const ClassCard({
    super.key,
    required this.schoolClass,
    this.onEdit,
    this.onDelete,
    this.onViewSections,
    this.onAssignSubjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentCountAsync = ref.watch(
      classStudentCountProvider(schoolClass.id),
    );
    final sectionsAsync = ref.watch(classWithSectionsProvider(schoolClass.id));

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
      child: InkWell(
        onTap: onViewSections,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                children: [
                  // Class icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        schoolClass.name.isNotEmpty
                            ? schoolClass.name[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Class name and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolClass.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Grade ${schoolClass.gradeLevel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  if (!schoolClass.isActive)
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
              // Stats row
              Row(
                children: [
                  // Sections count
                  sectionsAsync.when(
                    data: (data) => _buildStatChip(
                      context,
                      LucideIcons.layoutGrid,
                      '${data?.sections.length ?? 0} sections',
                    ),
                    loading: () => _buildStatChip(
                      context,
                      LucideIcons.layoutGrid,
                      '... sections',
                    ),
                    error: (_, __) => _buildStatChip(
                      context,
                      LucideIcons.layoutGrid,
                      '0 sections',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Students count
                  studentCountAsync.when(
                    data: (count) => _buildStatChip(
                      context,
                      LucideIcons.users,
                      '$count students',
                    ),
                    loading: () => _buildStatChip(
                      context,
                      LucideIcons.users,
                      '... students',
                    ),
                    error: (_, __) => _buildStatChip(
                      context,
                      LucideIcons.users,
                      '0 students',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Monthly fee
              if (schoolClass.monthlyFee > 0)
                Row(
                  children: [
                    Icon(
                      LucideIcons.wallet,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fee: Rs. ${schoolClass.monthlyFee.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Actions row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  if (canManage)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(LucideIcons.edit2, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onViewSections,
                    icon: const Icon(LucideIcons.layoutGrid, size: 16),
                    label: const Text('Sections'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  if (canManage)
                    TextButton.icon(
                      onPressed: onAssignSubjects,
                      icon: const Icon(LucideIcons.bookOpen, size: 16),
                      label: const Text('Subjects'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  if (canManage)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
