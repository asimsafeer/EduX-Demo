/// EduX School Management System
/// Subject List Screen - Display and manage subjects
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../database/app_database.dart';
import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/subject_repository.dart';
import '../../services/rbac_service.dart';
import 'widgets/subject_form_dialog.dart';

/// Screen displaying all subjects with filters
class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key});

  static const _typeLabels = {
    'core': 'Core',
    'elective': 'Elective',
    'optional': 'Optional',
  };

  static const _typeColors = {
    'core': Colors.blue,
    'elective': Colors.purple,
    'optional': Colors.orange,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(filteredSubjectsProvider);
    final filters = ref.watch(subjectFiltersProvider);
    final operationState = ref.watch(subjectOperationProvider);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    // Listen for operation messages
    ref.listen<OperationState>(subjectOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(subjectOperationProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(subjectOperationProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters bar
          _buildFiltersBar(context, ref, filters),
          // Content
          Expanded(
            child: subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  if (filters.hasFilters) {
                    return AppEmptyState(
                      icon: LucideIcons.search,
                      title: 'No Subjects Found',
                      description: 'Try adjusting your filters.',
                      actionText: 'Clear Filters',
                      onAction: () => ref
                          .read(subjectFiltersProvider.notifier)
                          .clearAllFilters(),
                    );
                  }
                  return AppEmptyState(
                    icon: LucideIcons.book,
                    title: 'No Subjects Configured',
                    description: 'Add subjects to assign them to classes.',
                    actionText: canManage ? 'Add First Subject' : null,
                    onAction: canManage
                        ? () => _showAddSubjectDialog(context, ref)
                        : null,
                  );
                }

                return _buildSubjectTable(context, ref, subjects);
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, stack) => AppErrorState(
                message: 'Failed to load subjects: ${error.toString()}',
                onRetry: () => ref.invalidate(filteredSubjectsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: operationState.isLoading
                  ? null
                  : () => _showAddSubjectDialog(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Subject'),
            )
          : null,
    );
  }

  Widget _buildFiltersBar(
    BuildContext context,
    WidgetRef ref,
    SubjectFilters filters,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Search field
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onChanged: (value) {
                ref
                    .read(subjectFiltersProvider.notifier)
                    .setSearchQuery(value.isEmpty ? null : value);
              },
            ),
          ),
          const SizedBox(width: 16),
          // Type filter
          DropdownButton<String?>(
            value: filters.type,
            hint: const Text('All Types'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Types'),
              ),
              ..._typeLabels.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (value) {
              ref.read(subjectFiltersProvider.notifier).setType(value);
            },
          ),
          const SizedBox(width: 16),
          // Status filter
          DropdownButton<bool?>(
            value: filters.isActive,
            hint: const Text('All Status'),
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
              DropdownMenuItem(value: true, child: Text('Active')),
              DropdownMenuItem(value: false, child: Text('Inactive')),
            ],
            onChanged: (value) {
              ref.read(subjectFiltersProvider.notifier).setIsActive(value);
            },
          ),
          const Spacer(),
          // Clear filters
          if (filters.hasFilters)
            TextButton.icon(
              onPressed: () =>
                  ref.read(subjectFiltersProvider.notifier).clearAllFilters(),
              icon: const Icon(LucideIcons.x),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectTable(
    BuildContext context,
    WidgetRef ref,
    List<Subject> subjects,
  ) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerLow,
            ),
            columns: const [
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Credit Hours')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: subjects.map((subject) {
              return DataRow(
                cells: [
                  // Code
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subject.code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  // Name
                  DataCell(
                    Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Type
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (_typeColors[subject.type] ?? Colors.grey)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabels[subject.type] ?? subject.type,
                        style: TextStyle(
                          color: _typeColors[subject.type] ?? Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Credit Hours
                  DataCell(
                    Text(
                      subject.creditHours?.toString() ?? '-',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Status
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: subject.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subject.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: subject.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Actions
                  DataCell(
                    canManage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.edit2, size: 18),
                                tooltip: 'Edit',
                                onPressed: () => _showEditSubjectDialog(
                                  context,
                                  ref,
                                  subject,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteSubject(
                                  context,
                                  ref,
                                  subject,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const SubjectFormDialog(),
    );
  }

  void _showEditSubjectDialog(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) {
    showDialog(
      context: context,
      builder: (context) => SubjectFormDialog(subject: subject),
    );
  }

  Future<void> _confirmDeleteSubject(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}" (${subject.code})? '
          'This will remove it from all class assignments.',
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
          .read(subjectOperationProvider.notifier)
          .deleteSubject(subject.id);
    }
  }
}
