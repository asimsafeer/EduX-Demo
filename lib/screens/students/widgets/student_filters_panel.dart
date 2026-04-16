/// EduX School Management System
/// Student Filters Panel - Class, section, gender, status filters
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/student_provider.dart';
import '../../../providers/assigned_classes_provider.dart';

/// Collapsible filters panel for student list
class StudentFiltersPanel extends ConsumerWidget {
  const StudentFiltersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(studentFiltersProvider);
    final classesAsync = ref.watch(classesProvider);
    final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Header (Static)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (filters.hasFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (filters.hasFilters)
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(studentFiltersProvider.notifier)
                          .clearAllFilters();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Filters content - Always Visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class filter
                SizedBox(
                  width: 200,
                  child: classesAsync.when(
                    data: (classes) {
                      // Filter classes for restricted users
                      final filtered = assignedClassIds != null
                          ? classes
                                .where((c) => assignedClassIds.contains(c.id))
                                .toList()
                          : classes;
                      return DropdownButtonFormField<int?>(
                        initialValue: filters.classId,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Classes'),
                          ),
                          ...filtered.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          ref
                              .read(studentFiltersProvider.notifier)
                              .setClassId(value);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Section filter (dependent on class)
                if (filters.classId != null)
                  SizedBox(
                    width: 200,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final sectionsAsync = ref.watch(
                          sectionsByClassProvider(filters.classId!),
                        );

                        return sectionsAsync.when(
                          data: (sections) => DropdownButtonFormField<int?>(
                            initialValue: filters.sectionId,
                            decoration: const InputDecoration(
                              labelText: 'Section',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Sections'),
                              ),
                              ...sections.map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(studentFiltersProvider.notifier)
                                  .setSectionId(value);
                            },
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),

                // Gender filter
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      ref
                          .read(studentFiltersProvider.notifier)
                          .setGender(value);
                    },
                  ),
                ),

                // Status filter
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'withdrawn',
                        child: Text('Withdrawn'),
                      ),
                      DropdownMenuItem(
                        value: 'transferred',
                        child: Text('Transferred'),
                      ),
                      DropdownMenuItem(
                        value: 'graduated',
                        child: Text('Graduated'),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(studentFiltersProvider.notifier)
                          .setStatus(value);
                    },
                  ),
                ),

                // Group by Class
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: filters.groupByClass,
                      onChanged: (value) {
                        ref
                            .read(studentFiltersProvider.notifier)
                            .toggleGroupByClass(value);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Group by Class'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
