/// EduX School Management System
/// Student List Screen - Main student management view
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/student_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import 'widgets/student_data_table.dart';
import 'widgets/student_filters_panel.dart';
import 'widgets/student_grouped_list.dart';
import 'widgets/student_search_bar.dart';

/// Main screen for student management
class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  bool _isLoading = false;

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Initialize pagination count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updatePaginationCount();
      }
    });

    // Auto-refresh every 15 seconds to keep data in sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  Future<void> _updatePaginationCount() async {
    if (!mounted) return;
    try {
      final count = await ref.read(studentCountProvider.future);
      if (mounted) {
        ref.read(studentPaginationProvider.notifier).setTotalItems(count);
      }
    } catch (e) {
      // Silently ignore errors if widget is disposed
      debugPrint('Error updating pagination count: $e');
    }
  }

  void _onRefresh() {
    if (!mounted) return;
    ref.invalidate(studentsProvider);
    ref.invalidate(studentCountProvider);
    ref.invalidate(allStudentsProvider); // Invalidate export cache
    // Don't call _updatePaginationCount here to avoid double async operations
  }

  void _onAddStudent() {
    context.go('/students/new');
  }

  void _onViewStudent(int id) {
    context.go('/students/$id');
  }

  void _onEditStudent(int id) {
    context.go('/students/$id/edit');
  }

  Future<void> _onDeleteStudent(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student? '
          'This action cannot be undone.',
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
      final success = await ref
          .read(studentOperationProvider.notifier)
          .deleteStudent(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _onRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(studentFiltersProvider);
    final isGrouped = filters.groupByClass;

    // When grouped by class, fetch ALL students so every class shows its full roster.
    // Otherwise, use the paginated provider.
    final studentsAsync = isGrouped
        ? ref.watch(allStudentsProvider)
        : ref.watch(studentsProvider);
    final pagination = ref.watch(studentPaginationProvider);
    final operationState = ref.watch(studentOperationProvider);

    // Show error snackbar if operation failed
    ref.listen<StudentOperationState>(studentOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(studentOperationProvider.notifier).clearMessages();
      }
    });

    // Reset pagination when filters change to avoid "No Students Found" errors
    // caused by stale offsets exceeding the new result count.
    ref.listen<StudentListFilters>(studentFiltersProvider, (prev, next) {
      if (prev != next) {
        ref.read(studentPaginationProvider.notifier).setPage(1);
        _updatePaginationCount();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          // Header section
          _buildHeader(context),

          // Filters panel
          const StudentFiltersPanel(),

          // Content area
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.school_outlined,
                    title: 'No Students Found',
                    description: ref.read(studentFiltersProvider).hasFilters
                        ? 'Try adjusting your filters or search query.'
                        : 'Add your first student to get started.',
                    actionText: ref.read(studentFiltersProvider).hasFilters
                        ? 'Clear Filters'
                        : 'Add Student',
                    onAction: ref.read(studentFiltersProvider).hasFilters
                        ? () => ref
                              .read(studentFiltersProvider.notifier)
                              .clearAllFilters()
                        : _onAddStudent,
                  );
                }

                if (isGrouped) {
                  return StudentGroupedList(
                    students: students,
                    onView: _onViewStudent,
                    onEdit: _onEditStudent,
                    onDelete: _onDeleteStudent,
                  );
                }

                return StudentDataTable(
                  students: students,
                  startIndex: pagination.offset,
                  onView: _onViewStudent,
                  onEdit: _onEditStudent,
                  onDelete: _onDeleteStudent,
                  selectedIds: ref.watch(selectedStudentsProvider),
                  onSelect: (id) {
                    final selected = ref.read(selectedStudentsProvider);
                    if (selected.contains(id)) {
                      ref.read(selectedStudentsProvider.notifier).state = {
                        ...selected,
                      }..remove(id);
                    } else {
                      ref.read(selectedStudentsProvider.notifier).state = {
                        ...selected,
                      }..add(id);
                    }
                  },
                  onSelectAll: (value) {
                    if (value == true) {
                      final ids = students.map((s) => s.student.id).toSet();
                      ref.read(selectedStudentsProvider.notifier).state = ids;
                    } else {
                      ref.read(selectedStudentsProvider.notifier).state = {};
                    }
                  },
                );
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, stack) => AppErrorState(
                message: 'Failed to load students: ${error.toString()}',
                onRetry: _onRefresh,
              ),
            ),
          ),
          // Pagination bar — hidden in grouped mode since all students are shown
          if (!isGrouped) _buildPaginationBar(pagination),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: operationState.isLoading ? null : _onAddStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, child) {
                    final countAsync = ref.watch(studentCountProvider);
                    return countAsync.when(
                      data: (count) => Text(
                        '$count students total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => const SizedBox(height: 16),
                      error: (_, __) => const SizedBox(height: 16),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: const StudentSearchBar(),
            ),
          ),

          const SizedBox(width: 16),

          // Actions
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedIds = ref.watch(selectedStudentsProvider);
                      if (selectedIds.isEmpty) return const SizedBox.shrink();

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${selectedIds.length} selected',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          // Bulk Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Selected',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Students'),
                                  content: Text(
                                    'Are you sure you want to delete ${selectedIds.length} students? '
                                    'This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final success = await ref
                                    .read(studentOperationProvider.notifier)
                                    .deleteStudents(selectedIds.toList());

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selected students deleted',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          const VerticalDivider(width: 1),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _onRefresh,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Export Options',
                    icon: const Icon(Icons.download),
                    onSelected: (value) => _exportData(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf),
                          title: Text('Export as PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'excel',
                        child: ListTile(
                          leading: Icon(Icons.table_chart),
                          title: Text('Export as Excel'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.upload),
                    tooltip: 'Import Students',
                    onPressed: () {
                      context.go('/students/import');
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.school),
                    tooltip: 'Promote / Change Status',
                    onPressed: () {
                      context.go('/students/promotion');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(PaginationState pagination) {
    final theme = Theme.of(context);

    if (pagination.totalItems == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Page size selector
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Show: ', style: theme.textTheme.bodySmall),
                DropdownButton<int>(
                  value: pagination.pageSize,
                  underline: const SizedBox.shrink(),
                  items: [10, 25, 50, 100].map((size) {
                    return DropdownMenuItem(value: size, child: Text('$size'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(studentPaginationProvider.notifier)
                          .setPageSize(value);
                    }
                  },
                ),
                Text(' per page', style: theme.textTheme.bodySmall),
              ],
            ),
          ),

          // Pagination controls (Page info + Navigation)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page info
              Text(
                'Page ${pagination.page} of ${pagination.totalPages}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              // Navigation buttons
              IconButton(
                icon: const Icon(Icons.first_page),
                tooltip: 'First Page',
                onPressed: pagination.page > 1
                    ? () => ref
                          .read(studentPaginationProvider.notifier)
                          .setPage(1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
                onPressed: pagination.hasPreviousPage
                    ? () => ref
                          .read(studentPaginationProvider.notifier)
                          .previousPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
                onPressed: pagination.hasNextPage
                    ? () => ref
                          .read(studentPaginationProvider.notifier)
                          .nextPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'Last Page',
                onPressed: pagination.page < pagination.totalPages
                    ? () => ref
                          .read(studentPaginationProvider.notifier)
                          .setPage(pagination.totalPages)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String type) async {
    setState(() => _isLoading = true);
    try {
      final exportService = ref.read(studentExportServiceProvider);
      // Get all students without pagination for export
      final students = await ref.read(allStudentsProvider.future);

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students to export')),
          );
        }
        return;
      }

      final schoolSettings = await ref.read(
        schoolSettingsForExportProvider.future,
      );

      if (schoolSettings == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'School settings not found. Please configure school settings.',
              ),
            ),
          );
        }
        return;
      }
      final settings = schoolSettings;

      final List<int> bytes;
      final String extension;
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      if (type == 'pdf') {
        bytes = await exportService.generateStudentListPdf(
          students: students,
          school: settings,
          title: 'Student List',
        );
        extension = 'pdf';
      } else {
        bytes = await exportService.exportStudentListExcel(students);
        extension = 'xlsx';
      }

      final fileName = 'students_list_$dateStr.$extension';

      // Request location to save file
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Student List',
        fileName: fileName,
        allowedExtensions: [extension],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export saved to $outputFile'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
