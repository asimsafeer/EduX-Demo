/// EduX School Management System
/// Staff Leave Screen - Leave requests management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/staff_provider.dart';
import '../../repositories/leave_repository.dart';
import '../../services/leave_service.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

/// Leave management screen
class StaffLeaveScreen extends ConsumerStatefulWidget {
  const StaffLeaveScreen({super.key});

  @override
  ConsumerState<StaffLeaveScreen> createState() => _StaffLeaveScreenState();
}

class _StaffLeaveScreenState extends ConsumerState<StaffLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
        title: const Text('Leave Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'All Requests'),
            Tab(text: 'Leave Types'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_PendingRequestsTab(), _AllRequestsTab(), _LeaveTypesTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Future<void> _showNewRequestDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _LeaveRequestDialog(),
    );
    ref.invalidate(pendingLeaveRequestsProvider);
    ref.invalidate(leaveRequestsProvider);
  }
}

class _PendingRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingLeaveRequestsProvider);

    return pendingAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No pending leave requests'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _LeaveRequestCard(request: request, showActions: true);
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Failed to load requests: $e',
        onRetry: () => ref.invalidate(pendingLeaveRequestsProvider),
      ),
    );
  }
}

class _AllRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(leaveRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No leave requests'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _LeaveRequestCard(request: request, showActions: false);
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Failed to load requests: $e',
        onRetry: () => ref.invalidate(leaveRequestsProvider),
      ),
    );
  }
}

class _LeaveTypesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);

    return typesAsync.when(
      data: (types) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: type.isPaid
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  child: Icon(
                    type.isPaid ? Icons.paid : Icons.money_off,
                    color: type.isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(type.name),
                subtitle: Text(type.description ?? 'No description'),
                trailing: Chip(label: Text('${type.maxDays} days/year')),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Failed to load leave types: $e',
        onRetry: () => ref.invalidate(leaveTypesProvider),
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final LeaveRequestWithDetails request;
  final bool showActions;

  const _LeaveRequestCard({required this.request, this.showActions = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;

    switch (request.request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.staffName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.leaveType.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(statusIcon, size: 16, color: statusColor),
                  label: Text(
                    request.request.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  side: BorderSide.none,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(request.request.startDate)} - '
                  '${DateFormat('dd MMM yyyy').format(request.request.endDate)}',
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timelapse, size: 16),
                const SizedBox(width: 8),
                Text('${request.request.totalDays} days'),
                if (request.request.isHalfDay) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Half Day', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${request.request.reason}',
              style: theme.textTheme.bodySmall,
            ),
            if (request.request.remarks != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Remarks: ${request.request.remarks}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            if (showActions && request.isPending) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _approveRequest(context, ref),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, WidgetRef ref) async {
    final service = ref.read(leaveServiceProvider);

    try {
      await service.approveLeave(
        requestId: request.request.id,
        approvedBy: 1, // Current user ID
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(pendingLeaveRequestsProvider);
        ref.invalidate(leaveRequestsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      final service = ref.read(leaveServiceProvider);

      try {
        await service.rejectLeave(
          requestId: request.request.id,
          rejectedBy: 1,
          reason: reasonController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.invalidate(pendingLeaveRequestsProvider);
          ref.invalidate(leaveRequestsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

class _LeaveRequestDialog extends ConsumerStatefulWidget {
  const _LeaveRequestDialog();

  @override
  ConsumerState<_LeaveRequestDialog> createState() =>
      _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends ConsumerState<_LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedStaffId;
  int? _selectedLeaveTypeId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isHalfDay = false;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final leaveTypesAsync = ref.watch(leaveTypesProvider);

    return AlertDialog(
      title: const Text('New Leave Request'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Staff selection
              staffAsync.when(
                data: (staffList) => DropdownButtonFormField<int>(
                  initialValue: _selectedStaffId,
                  decoration: const InputDecoration(
                    labelText: 'Staff Member *',
                    border: OutlineInputBorder(),
                  ),
                  items: staffList
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.staff.id,
                          child: Text(s.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStaffId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load staff'),
              ),
              const SizedBox(height: 16),

              // Leave type
              leaveTypesAsync.when(
                data: (types) => DropdownButtonFormField<int>(
                  initialValue: _selectedLeaveTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Leave Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: types
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLeaveTypeId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load leave types'),
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            if (_endDate.isBefore(_startDate)) {
                              _endDate = _startDate;
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Half day toggle
              CheckboxListTile(
                title: const Text('Half Day'),
                value: _isHalfDay,
                onChanged: (v) => setState(() => _isHalfDay = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 10) return 'Provide more details';
                  return null;
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
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final service = ref.read(leaveServiceProvider);

    try {
      await service.submitLeaveRequest(
        LeaveRequestFormData(
          staffId: _selectedStaffId!,
          leaveTypeId: _selectedLeaveTypeId!,
          startDate: _startDate,
          endDate: _endDate,
          isHalfDay: _isHalfDay,
          reason: _reasonController.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on LeaveValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.errors.values.join(', ')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
