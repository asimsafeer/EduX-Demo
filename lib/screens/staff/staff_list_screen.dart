/// EduX School Management System
/// Staff List Screen - Main staff management view
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/staff_provider.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import 'widgets/staff_data_table.dart';
import 'widgets/staff_filters_panel.dart';
import 'widgets/staff_search_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Main screen for staff management
class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePaginationCount();
    });
  }

  Future<void> _updatePaginationCount() async {
    final count = await ref.read(staffCountProvider.future);
    ref.read(staffPaginationProvider.notifier).setTotalItems(count);
  }

  void _onRefresh() {
    ref.invalidate(staffListProvider);
    ref.invalidate(staffCountProvider);
    _updatePaginationCount();
  }

  void _onAddStaff() {
    context.go('/staff/new');
  }

  void _onViewStaff(int id) {
    context.go('/staff/$id');
  }

  void _onEditStaff(int id) {
    context.go('/staff/$id/edit');
  }

  Future<void> _onDeleteStaff(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: const Text(
          'Are you sure you want to delete this staff member? '
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
          .read(staffOperationProvider.notifier)
          .deleteStaff(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _onRefresh();
      }
    }
  }

  Future<void> _onExportStaff(WidgetRef ref) async {
    try {
      final staffList = await ref.read(staffListProvider.future);
      if (staffList.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No staff data to export')),
        );
        return;
      }

      final exportService = ref.read(staffExportServiceProvider);
      final excelBytes = await exportService.exportStaffListExcel(staffList);

      if (!mounted) return;

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Staff List',
        fileName: 'staff_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(excelBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to $result'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final pagination = ref.watch(staffPaginationProvider);
    final operationState = ref.watch(staffOperationProvider);

    ref.listen<StaffOperationState>(staffOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(staffOperationProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          const StaffFiltersPanel(),
          Expanded(
            child: staffAsync.when(
              data: (staffList) {
                if (staffList.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No Staff Found',
                    description: ref.read(staffFiltersProvider).hasFilters
                        ? 'Try adjusting your filters or search query.'
                        : 'Add your first staff member to get started.',
                    actionText: ref.read(staffFiltersProvider).hasFilters
                        ? 'Clear Filters'
                        : 'Add Staff',
                    onAction: ref.read(staffFiltersProvider).hasFilters
                        ? () => ref
                              .read(staffFiltersProvider.notifier)
                              .clearAllFilters()
                        : _onAddStaff,
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: StaffDataTable(
                        staffList: staffList,
                        onView: _onViewStaff,
                        onEdit: _onEditStaff,
                        onDelete: _onDeleteStaff,
                        selectedIds: ref.watch(selectedStaffProvider),
                        onSelect: (id) {
                          final selected = ref.read(selectedStaffProvider);
                          if (selected.contains(id)) {
                            ref.read(selectedStaffProvider.notifier).state = {
                              ...selected,
                            }..remove(id);
                          } else {
                            ref.read(selectedStaffProvider.notifier).state = {
                              ...selected,
                            }..add(id);
                          }
                        },
                        onSelectAll: (value) {
                          if (value == true) {
                            final ids = staffList
                                .map((s) => s.staff.id)
                                .toSet();
                            ref.read(selectedStaffProvider.notifier).state =
                                ids;
                          } else {
                            ref.read(selectedStaffProvider.notifier).state = {};
                          }
                        },
                      ),
                    ),
                    _buildPaginationBar(pagination),
                  ],
                );
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, stack) => AppErrorState(
                message: 'Failed to load staff: ${error.toString()}',
                onRetry: _onRefresh,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: operationState.isLoading ? null : _onAddStaff,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, child) {
                    final countAsync = ref.watch(staffCountProvider);
                    return countAsync.when(
                      data: (count) => Text(
                        '$count staff members',
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
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: const StaffSearchBar(),
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
                      final selectedIds = ref.watch(selectedStaffProvider);
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
                                  title: const Text('Delete Staff'),
                                  content: Text(
                                    'Are you sure you want to delete ${selectedIds.length} staff members? '
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
                                    .read(staffOperationProvider.notifier)
                                    .deleteStaffMembers(selectedIds.toList());

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selected staff members deleted',
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
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Import Staff',
                    onPressed: () => context.go('/staff/import'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Export Staff',
                    onPressed: () => _onExportStaff(ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.assignment_ind),
                    tooltip: 'Teaching Assignments',
                    onPressed: () => context.go('/staff/assignments'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _onRefresh,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'More Options',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'attendance':
                          context.go('/staff/attendance');
                          break;
                        case 'leave':
                          context.go('/staff/leave');
                          break;
                        case 'payroll':
                          context.go('/staff/payroll');
                          break;
                        case 'assignments':
                          context.go('/staff/assignments');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'attendance',
                        child: ListTile(
                          leading: Icon(Icons.fact_check),
                          title: Text('Staff Attendance'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'leave',
                        child: ListTile(
                          leading: Icon(Icons.event_busy),
                          title: Text('Leave Management'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'payroll',
                        child: ListTile(
                          leading: Icon(Icons.payments),
                          title: Text('Payroll'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'assignments',
                        child: ListTile(
                          leading: Icon(Icons.assignment),
                          title: Text('Teaching Assignments'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(StaffPaginationState pagination) {
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
                          .read(staffPaginationProvider.notifier)
                          .setPageSize(value);
                    }
                  },
                ),
                Text(' per page', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            'Page ${pagination.page} of ${pagination.totalPages}',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: pagination.page > 1
                    ? () =>
                          ref.read(staffPaginationProvider.notifier).setPage(1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pagination.hasPreviousPage
                    ? () => ref
                          .read(staffPaginationProvider.notifier)
                          .previousPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pagination.hasNextPage
                    ? () =>
                          ref.read(staffPaginationProvider.notifier).nextPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: pagination.page < pagination.totalPages
                    ? () => ref
                          .read(staffPaginationProvider.notifier)
                          .setPage(pagination.totalPages)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
