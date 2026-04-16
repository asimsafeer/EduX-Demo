/// EduX School Management System
/// Staff Filters Panel Widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/staff_provider.dart';

/// Filter panel for staff list
class StaffFiltersPanel extends ConsumerWidget {
  const StaffFiltersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(staffFiltersProvider);
    final rolesAsync = ref.watch(staffRolesProvider);
    final departmentsAsync = ref.watch(staffDepartmentsProvider);

    if (!filters.hasFilters &&
        rolesAsync is! AsyncData &&
        departmentsAsync is! AsyncData) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Role filter
          rolesAsync.when(
            data: (roles) => _FilterDropdown(
              label: 'Role',
              value: filters.roleId?.toString(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Roles')),
                ...roles.map(
                  (role) => DropdownMenuItem(
                    value: role.id.toString(),
                    child: Text(role.name),
                  ),
                ),
              ],
              onChanged: (value) {
                ref
                    .read(staffFiltersProvider.notifier)
                    .setRoleId(value != null ? int.parse(value) : null);
              },
            ),
            loading: () => const SizedBox(width: 150),
            error: (_, __) => const SizedBox(width: 150),
          ),
          const SizedBox(width: 12),

          // Department filter
          departmentsAsync.when(
            data: (departments) {
              if (departments.isEmpty) return const SizedBox.shrink();
              return _FilterDropdown(
                label: 'Department',
                value: filters.department,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...departments.map(
                    (dept) => DropdownMenuItem(value: dept, child: Text(dept)),
                  ),
                ],
                onChanged: (value) {
                  ref.read(staffFiltersProvider.notifier).setDepartment(value);
                },
              );
            },
            loading: () => const SizedBox(width: 150),
            error: (_, __) => const SizedBox(width: 150),
          ),
          const SizedBox(width: 12),

          // Status filter
          _FilterDropdown(
            label: 'Status',
            value: filters.status,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
              DropdownMenuItem(value: 'resigned', child: Text('Resigned')),
              DropdownMenuItem(value: 'terminated', child: Text('Terminated')),
            ],
            onChanged: (value) {
              ref.read(staffFiltersProvider.notifier).setStatus(value);
            },
          ),

          const Spacer(),

          // Clear filters
          if (filters.hasFilters)
            TextButton.icon(
              onPressed: () {
                ref.read(staffFiltersProvider.notifier).clearAllFilters();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final void Function(String?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(label, style: theme.textTheme.bodySmall),
          style: theme.textTheme.bodySmall,
          items: items,
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }
}
