/// EduX School Management System
/// Class List Screen - Display and manage school classes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../database/app_database.dart';
import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rbac_service.dart';
import 'widgets/class_form_dialog.dart';
import 'widgets/class_card.dart';

/// Screen displaying all school classes grouped by level
class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  static const _levelLabels = {
    'pre_primary': 'Pre-Primary',
    'primary': 'Primary',
    'middle': 'Middle School',
    'secondary': 'Secondary',
  };

  static const _levelIcons = {
    'pre_primary': LucideIcons.baby,
    'primary': LucideIcons.bookOpen,
    'middle': LucideIcons.graduationCap,
    'secondary': LucideIcons.school,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesGroupedByLevelProvider);
    final operationState = ref.watch(classOperationProvider);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    // Listen for operation messages
    ref.listen<OperationState>(classOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(classOperationProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(classOperationProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: classesAsync.when(
        data: (groupedClasses) {
          // Check if any classes exist
          final hasClasses = groupedClasses.values.any(
            (list) => list.isNotEmpty,
          );

          if (!hasClasses) {
            return AppEmptyState(
              icon: LucideIcons.graduationCap,
              title: 'No Classes Configured',
              description:
                  'Start by adding your school classes to organize students.',
              actionText: canManage ? 'Add First Class' : null,
              onAction: canManage
                  ? () => _showAddClassDialog(context, ref)
                  : null,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Level sections
                for (final level in _levelLabels.keys)
                  if (groupedClasses[level]?.isNotEmpty ?? false) ...[
                    _buildLevelSection(
                      context,
                      ref,
                      level,
                      groupedClasses[level]!,
                    ),
                    const SizedBox(height: 24),
                  ],
              ],
            ),
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stack) => AppErrorState(
          message: 'Failed to load classes: ${error.toString()}',
          onRetry: () => ref.invalidate(classesGroupedByLevelProvider),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: operationState.isLoading
                  ? null
                  : () => _showAddClassDialog(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Class'),
            )
          : null,
    );
  }

  Widget _buildLevelSection(
    BuildContext context,
    WidgetRef ref,
    String level,
    List<SchoolClass> classes,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level header
        Row(
          children: [
            Icon(
              _levelIcons[level] ?? LucideIcons.book,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _levelLabels[level] ?? level.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${classes.length} ${classes.length == 1 ? 'class' : 'classes'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Class cards grid
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: classes.map((schoolClass) {
            return ClassCard(
              schoolClass: schoolClass,
              onEdit: () => _showEditClassDialog(context, ref, schoolClass),
              onDelete: () => _confirmDeleteClass(context, ref, schoolClass),
              onViewSections: () {
                ref.read(selectedClassIdProvider.notifier).state =
                    schoolClass.id;
                ref.read(academicsActiveTabProvider.notifier).state =
                    1; // Sections tab
              },
              onAssignSubjects: () {
                context.pushNamed(
                  'subject-assignment',
                  pathParameters: {'classId': schoolClass.id.toString()},
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const ClassFormDialog());
  }

  void _showEditClassDialog(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(schoolClass: schoolClass),
    );
  }

  Future<void> _confirmDeleteClass(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "${schoolClass.name}"? '
          'This will also deactivate all sections in this class.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(classOperationProvider.notifier)
          .deleteClass(schoolClass.id);
    }
  }
}
