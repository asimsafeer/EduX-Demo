/// EduX School Management System
/// Staff Profile Screen - View staff details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/staff_provider.dart';
import '../../repositories/staff_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../repositories/staff_task_repository.dart';
import 'package:drift/drift.dart' hide Column; // Added for Value

/// Staff profile screen with tabbed sections
class StaffProfileScreen extends ConsumerStatefulWidget {
  final int staffId;

  const StaffProfileScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Increased length
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return Scaffold(
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) {
            return AppErrorState(
              message: 'Staff member not found',
              onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
            );
          }
          return _buildContent(context, staff);
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, _) => AppErrorState(
          message: 'Failed to load staff: $error',
          onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StaffWithRole staffWithRole) {
    final theme = Theme.of(context);
    final staff = staffWithRole.staff;
    final role = staffWithRole.role;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/staff'),
              ),
              const SizedBox(width: 16),
              // Photo
              _buildAvatar(staffWithRole, 50),
              const SizedBox(width: 20),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          staffWithRole.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusChip(staff.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff.designation} • ${staff.employeeId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRoleChip(role),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/staff/${staff.id}/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.phone),
                    tooltip: 'Call ${staff.phone}',
                    onPressed: () {},
                  ),
                  if (staff.email != null)
                    IconButton(
                      icon: const Icon(Icons.email),
                      tooltip: 'Email ${staff.email}',
                      onPressed: () {},
                    ),
                ],
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
              Tab(text: 'Attendance', icon: Icon(Icons.fact_check_outlined)),
              Tab(text: 'Leave', icon: Icon(Icons.event_busy_outlined)),
              Tab(text: 'Assignments', icon: Icon(Icons.assignment_outlined)),
              Tab(text: 'Tasks', icon: Icon(Icons.task_alt)), // Added
              Tab(text: 'Payroll', icon: Icon(Icons.payments_outlined)),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(staffWithRole),
              _buildAttendanceTab(),
              _buildLeaveTab(),
              _buildAssignmentsTab(),
              _buildTasksTab(), // Added
              _buildPayrollTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(StaffWithRole staff, double radius) {
    if (staff.staff.photo != null && staff.staff.photo!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(staff.staff.photo!),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(
        staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'S',
        style: TextStyle(fontSize: radius * 0.8),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRoleChip(StaffRole role) {
    return Chip(
      avatar: Icon(
        role.canTeach ? Icons.school : Icons.admin_panel_settings,
        size: 16,
      ),
      label: Text(role.name, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildOverviewTab(StaffWithRole staffWithRole) {
    final staff = staffWithRole.staff;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildInfoCard(
                  title: 'Personal Information',
                  icon: Icons.person,
                  items: [
                    _InfoItem('Full Name', staffWithRole.fullName),
                    if (staff.dateOfBirth != null)
                      _InfoItem(
                        'Date of Birth',
                        DateFormat('dd MMM yyyy').format(staff.dateOfBirth!),
                      ),
                    _InfoItem(
                      'Gender',
                      staff.gender == 'male' ? 'Male' : 'Female',
                    ),
                    if (staff.cnic != null) _InfoItem('CNIC', staff.cnic!),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone,
                  items: [
                    _InfoItem('Phone', staff.phone),
                    if (staff.alternatePhone != null)
                      _InfoItem('Alternate Phone', staff.alternatePhone!),
                    if (staff.email != null) _InfoItem('Email', staff.email!),
                    if (staff.address != null)
                      _InfoItem('Address', staff.address!),
                    if (staff.city != null) _InfoItem('City', staff.city!),
                  ],
                ),
                const SizedBox(height: 16),
                if (staff.emergencyContactName != null)
                  _buildInfoCard(
                    title: 'Emergency Contact',
                    icon: Icons.emergency,
                    items: [
                      _InfoItem('Name', staff.emergencyContactName!),
                      if (staff.emergencyContactPhone != null)
                        _InfoItem('Phone', staff.emergencyContactPhone!),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildInfoCard(
                  title: 'Professional Information',
                  icon: Icons.work,
                  items: [
                    _InfoItem('Designation', staff.designation),
                    if (staff.department != null)
                      _InfoItem('Department', staff.department!),
                    if (staff.qualification != null)
                      _InfoItem('Qualification', staff.qualification!),
                    if (staff.specialization != null)
                      _InfoItem('Specialization', staff.specialization!),
                    if (staff.experienceYears != null)
                      _InfoItem('Experience', '${staff.experienceYears} years'),
                    if (staff.previousEmployer != null)
                      _InfoItem('Previous Employer', staff.previousEmployer!),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Employment Details',
                  icon: Icons.assignment_ind,
                  items: [
                    _InfoItem('Employee ID', staff.employeeId),
                    _InfoItem(
                      'Joining Date',
                      DateFormat('dd MMM yyyy').format(staff.joiningDate),
                    ),
                    _InfoItem(
                      'Basic Salary',
                      'PKR ${NumberFormat('#,##0').format(staff.basicSalary)}',
                    ),
                    _InfoItem('Status', _formatStatus(staff.status)),
                    if (staff.endDate != null)
                      _InfoItem(
                        'End Date',
                        DateFormat('dd MMM yyyy').format(staff.endDate!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (staff.bankName != null || staff.accountNumber != null)
                  _buildInfoCard(
                    title: 'Bank Details',
                    icon: Icons.account_balance,
                    items: [
                      if (staff.bankName != null)
                        _InfoItem('Bank', staff.bankName!),
                      if (staff.accountNumber != null)
                        _InfoItem('Account', staff.accountNumber!),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'on_leave':
        return 'On Leave';
      case 'resigned':
        return 'Resigned';
      case 'terminated':
        return 'Terminated';
      default:
        return status;
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final statsAsync = ref.watch(
      staffAttendanceStatsProvider((
        staffId: widget.staffId,
        start: startOfMonth,
        end: endOfMonth,
      )),
    );

    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Summary - ${DateFormat('MMMM yyyy').format(now)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total Days', '${stats.totalDays}', Colors.blue),
                _buildStatCard('Present', '${stats.present}', Colors.green),
                _buildStatCard('Absent', '${stats.absent}', Colors.red),
                _buildStatCard('Late', '${stats.late}', Colors.orange),
                _buildStatCard('Leave', '${stats.onLeave}', Colors.purple),
                _buildStatCard(
                  'Attendance',
                  '${stats.presentPercentage.toStringAsFixed(1)}%',
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTab() {
    final balanceAsync = ref.watch(leaveBalanceProvider(widget.staffId));

    return balanceAsync.when(
      data: (balances) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: balances.map((balance) {
                return SizedBox(
                  width: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balance.leaveTypeName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Allocated',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${balance.allocated}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Used',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${balance.used}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${balance.remaining}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAssignmentsTab() {
    final assignmentsAsync = ref.watch(
      assignmentsByStaffProvider(widget.staffId),
    );

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Center(child: Text('No teaching assignments'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(a.subject.name[0])),
                title: Text(a.subject.name),
                subtitle: Text(a.classSection),
                trailing: a.assignment.isClassTeacher
                    ? const Chip(
                        label: Text('Class Teacher'),
                        backgroundColor: Colors.blue,
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPayrollTab() {
    final payrollAsync = ref.watch(staffPayrollHistoryProvider(widget.staffId));

    return payrollAsync.when(
      data: (payrolls) {
        if (payrolls.isEmpty) {
          return const Center(child: Text('No payroll records'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: payrolls.length,
          itemBuilder: (context, index) {
            final p = payrolls[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.payroll.status == FeeConstants.invoiceStatusPaid
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  child: Icon(
                    p.payroll.status == FeeConstants.invoiceStatusPaid ? Icons.check : Icons.pending,
                    color: p.payroll.status == FeeConstants.invoiceStatusPaid
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                title: Text(_formatMonth(p.payroll.month)),
                subtitle: Text(
                  'Net: PKR ${NumberFormat('#,##0').format(p.payroll.netSalary)}',
                ),
                trailing: Chip(
                  label: Text(p.payroll.status == FeeConstants.invoiceStatusPaid ? 'Paid' : 'Pending'),
                  backgroundColor: p.payroll.status == FeeConstants.invoiceStatusPaid
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
  }

  Widget _buildTasksTab() {
    final tasksAsync = ref.watch(staffTasksProvider(widget.staffId));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No tasks assigned'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showTaskDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showTaskDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.status == 'completed',
                    onChanged: (v) async {
                      final newStatus = v == true ? 'completed' : 'pending';
                      await ref
                          .read(staffTaskRepositoryProvider)
                          .updateStatus(task.id, newStatus);
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.status == 'completed'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null) Text(task.description!),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildPriorityChip(task.priority),
                          const SizedBox(width: 8),
                          if (task.dueDate != null)
                            Text(
                              'Due: ${DateFormat('MMM d').format(task.dueDate!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showTaskDialog(task: task);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(staffTaskRepositoryProvider)
                              .deleteTask(task.id);
                        }
                      }
                    },
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showTaskDialog({StaffTask? task}) async {
    await showDialog(
      context: context,
      builder: (context) =>
          _StaffTaskDialog(staffId: widget.staffId, task: task),
    );
  }
}

class _StaffTaskDialog extends ConsumerStatefulWidget {
  final int staffId;
  final StaffTask? task;

  const _StaffTaskDialog({required this.staffId, this.task});

  @override
  ConsumerState<_StaffTaskDialog> createState() => _StaffTaskDialogState();
}

class _StaffTaskDialogState extends ConsumerState<_StaffTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _priority;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _priority = widget.task?.priority ?? 'medium';
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'medium', 'high']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(
                  _dueDate == null
                      ? 'Select date'
                      : DateFormat('MMM d, yyyy').format(_dueDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(staffTaskRepositoryProvider);

      final companion = StaffTasksCompanion(
        staffId: Value(widget.staffId),
        title: Value(_titleController.text),
        description: Value(
          _descController.text.isEmpty ? null : _descController.text,
        ),
        priority: Value(_priority),
        dueDate: Value(_dueDate),
      );

      if (widget.task == null) {
        await repository.createTask(companion);
      } else {
        await repository.updateTask(
          companion.copyWith(id: Value(widget.task!.id)),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
