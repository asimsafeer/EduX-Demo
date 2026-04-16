/// EduX School Management System
/// Staff Data Table Widget
library;

import 'package:flutter/material.dart';

import '../../../database/app_database.dart';
import '../../../repositories/staff_repository.dart';

/// Sortable data table for staff listing
class StaffDataTable extends StatelessWidget {
  final List<StaffWithRole> staffList;
  final void Function(int id) onView;
  final void Function(int id) onEdit;
  final void Function(int id) onDelete;
  final Set<int> selectedIds;
  final ValueChanged<int> onSelect;
  final ValueChanged<bool?> onSelectAll;

  const StaffDataTable({
    super.key,
    required this.staffList,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.selectedIds = const {},
    required this.onSelect,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        columnSpacing: 20,
        horizontalMargin: 16,
        onSelectAll: onSelectAll,
        columns: const [
          DataColumn(label: Text('Employee ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Designation')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: staffList.map((staff) => _buildRow(context, staff)).toList(),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, StaffWithRole staffWithRole) {
    final staff = staffWithRole.staff;
    final role = staffWithRole.role;
    final theme = Theme.of(context);

    final isSelected = selectedIds.contains(staff.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (_) => onSelect(staff.id),
      cells: [
        DataCell(
          Text(
            staff.employeeId,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildAvatar(staffWithRole),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    staffWithRole.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (staff.email != null)
                    Text(
                      staff.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(_buildRoleChip(context, role)),
        DataCell(Text(staff.designation)),
        DataCell(Text(staff.phone)),
        DataCell(_buildStatusChip(context, staff.status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                tooltip: 'View Details',
                onPressed: () => onView(staff.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit',
                onPressed: () => onEdit(staff.id),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Delete',
                onPressed: () => onDelete(staff.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(StaffWithRole staff) {
    if (staff.staff.photo != null && staff.staff.photo!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: MemoryImage(staff.staff.photo!),
      );
    }

    return CircleAvatar(
      radius: 18,
      child: Text(
        staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'S',
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, StaffRole role) {
    Color chipColor;
    if (role.canTeach) {
      chipColor = Colors.blue;
    } else if (role.canAccessFees) {
      chipColor = Colors.green;
    } else {
      chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        role.name,
        style: TextStyle(
          fontSize: 11,
          color: chipColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
        ),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.2),
      side: BorderSide(color: chipColor.withValues(alpha: 0.5)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'on_leave':
        color = Colors.orange;
        label = 'On Leave';
        break;
      case 'resigned':
        color = Colors.red;
        label = 'Resigned';
        break;
      case 'terminated':
        color = Colors.red.shade900;
        label = 'Terminated';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
