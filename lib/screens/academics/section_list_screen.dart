/// EduX School Management System
/// Section List Screen - Display and manage sections
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';

import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/section_repository.dart';
import '../../services/rbac_service.dart';
import 'widgets/section_form_dialog.dart';
import 'widgets/section_card.dart';

/// Screen displaying all sections grouped by class
class SectionListScreen extends ConsumerWidget {
  const SectionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesWithStatsProvider);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    // operationState removed

    // Listen for operation messages
    ref.listen<OperationState>(sectionOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(sectionOperationProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(sectionOperationProvider.notifier).clearMessages();
      }
    });

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return AppEmptyState(
            icon: LucideIcons.layoutGrid,
            title: 'No Classes Available',
            description: 'Add classes first before managing sections.',
            actionText: 'Go to Classes',
            onAction: () {
              ref.read(academicsActiveTabProvider.notifier).state = 0;
            },
          );
        }

        return Row(
          children: [
            // Left panel - Class list
            SizedBox(
              width: 280,
              child: _buildClassList(context, ref, classes, selectedClassId),
            ),
            const VerticalDivider(width: 1),
            // Right panel - Sections for selected class
            Expanded(
              child: selectedClassId == null
                  ? _buildNoSelectionState(context)
                  : _buildSectionsList(context, ref, selectedClassId),
            ),
          ],
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (error, stack) => AppErrorState(
        message: 'Failed to load classes: ${error.toString()}',
        onRetry: () => ref.invalidate(classesWithStatsProvider),
      ),
    );
  }

  Widget _buildClassList(
    BuildContext context,
    WidgetRef ref,
    List<ClassWithStats> classes,
    int? selectedClassId,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.graduationCap,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Class',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Class list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classWithStats = classes[index];
              final isSelected =
                  classWithStats.schoolClass.id == selectedClassId;

              return ListTile(
                selected: isSelected,
                selectedTileColor: theme.colorScheme.primary,
                selectedColor: theme.colorScheme.onPrimary,
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    classWithStats.schoolClass.name.isNotEmpty
                        ? classWithStats.schoolClass.name[0]
                        : '?',
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  classWithStats.schoolClass.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${classWithStats.sectionCount} sections · ${classWithStats.studentCount} students',
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  ref.read(selectedClassIdProvider.notifier).state =
                      classWithStats.schoolClass.id;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoSelectionState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mousePointer, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Select a class to view its sections',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList(BuildContext context, WidgetRef ref, int classId) {
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(sectionsWithStatsByClassProvider(classId));
    final classAsync = ref.watch(classWithSectionsProvider(classId));
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with class name and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.layoutGrid,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: classAsync.when(
                  data: (data) => Text(
                    'Sections in ${data?.schoolClass.name ?? "Class"}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Sections'),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () => _showAddSectionDialog(context, ref, classId),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Section'),
                ),
            ],
          ),
        ),
        // Sections grid
        Expanded(
          child: sectionsAsync.when(
            data: (sections) {
              if (sections.isEmpty) {
                return AppEmptyState(
                  icon: LucideIcons.layoutGrid,
                  title: 'No Sections',
                  description:
                      'Add sections to organize students in this class.',
                  actionText: canManage ? 'Add Section' : null,
                  onAction: canManage
                      ? () => _showAddSectionDialog(context, ref, classId)
                      : null,
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: sections.map((sectionWithStats) {
                    return SectionCard(
                      sectionWithStats: sectionWithStats,
                      onEdit: () => _showEditSectionDialog(
                        context,
                        ref,
                        sectionWithStats,
                      ),
                      onDelete: () =>
                          _confirmDeleteSection(context, ref, sectionWithStats),
                      onReassignRollNumbers: () => ref
                          .read(sectionOperationProvider.notifier)
                          .reassignRollNumbers(
                            sectionWithStats.section.classId,
                            sectionWithStats.section.id,
                          ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (error, stack) => AppErrorState(
              message: 'Failed to load sections: ${error.toString()}',
              onRetry: () =>
                  ref.invalidate(sectionsWithStatsByClassProvider(classId)),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSectionDialog(BuildContext context, WidgetRef ref, int classId) {
    showDialog(
      context: context,
      builder: (context) => SectionFormDialog(classId: classId),
    );
  }

  void _showEditSectionDialog(
    BuildContext context,
    WidgetRef ref,
    SectionWithStats sectionWithStats,
  ) {
    showDialog(
      context: context,
      builder: (context) => SectionFormDialog(
        classId: sectionWithStats.section.classId,
        section: sectionWithStats.section,
      ),
    );
  }

  Future<void> _confirmDeleteSection(
    BuildContext context,
    WidgetRef ref,
    SectionWithStats sectionWithStats,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Are you sure you want to delete section "${sectionWithStats.section.name}"? '
          'This will affect ${sectionWithStats.studentCount} students.',
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
          .read(sectionOperationProvider.notifier)
          .deleteSection(
            sectionWithStats.section.id,
            sectionWithStats.section.classId,
          );
    }
  }
}
