/// EduX School Management System
/// Staff Payroll Screen - Payroll management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart' show currentUserProvider;
import '../../repositories/payroll_repository.dart';
import '../../services/payroll_service.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

/// Payroll management screen
class StaffPayrollScreen extends ConsumerStatefulWidget {
  const StaffPayrollScreen({super.key});

  @override
  ConsumerState<StaffPayrollScreen> createState() => _StaffPayrollScreenState();
}

class _StaffPayrollScreenState extends ConsumerState<StaffPayrollScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMonth = ref.watch(payrollMonthProvider);
    final payrollAsync = ref.watch(payrollForMonthProvider);
    final summaryAsync = ref.watch(payrollSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
        title: const Text('Payroll Management'),
        actions: [
          // Month selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  _formatMonth(selectedMonth),
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Generate payroll button
          FilledButton.icon(
            onPressed: () => _showGeneratePayrollDialog(context),
            icon: const Icon(Icons.calculate),
            label: const Text('Generate Payroll'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          summaryAsync.when(
            data: (summary) => _buildSummaryBar(theme, summary),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Payroll list
          Expanded(
            child: payrollAsync.when(
              data: (payrolls) {
                if (payrolls.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payroll generated for ${_formatMonth(selectedMonth)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _showGeneratePayrollDialog(context),
                          child: const Text('Generate Payroll'),
                        ),
                      ],
                    ),
                  );
                }
                return _buildPayrollList(payrolls);
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, _) => AppErrorState(
                message: 'Failed to load payroll: $error',
                onRetry: () => ref.invalidate(payrollForMonthProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme, PayrollMonthlySummary summary) {
    final formatter = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _buildSummaryCard(
            theme,
            'Total Staff',
            '${summary.totalStaff}',
            Icons.people,
            Colors.blue,
          ),
          _buildSummaryCard(
            theme,
            'Total Basic',
            'PKR ${formatter.format(summary.totalBasicSalary)}',
            Icons.account_balance_wallet,
            Colors.green,
          ),
          _buildSummaryCard(
            theme,
            'Total Allowances',
            'PKR ${formatter.format(summary.totalAllowances)}',
            Icons.add_circle,
            Colors.teal,
          ),
          _buildSummaryCard(
            theme,
            'Total Deductions',
            'PKR ${formatter.format(summary.totalDeductions)}',
            Icons.remove_circle,
            Colors.red,
          ),
          _buildSummaryCard(
            theme,
            'Total Net Salary',
            'PKR ${formatter.format(summary.totalNetSalary)}',
            Icons.payments,
            Colors.purple,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text('Paid: ${summary.paid}'),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text('Pending: ${summary.pending}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollList(List<PayrollWithStaff> payrolls) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Designation')),
          DataColumn(label: Text('Basic'), numeric: true),
          DataColumn(label: Text('Allowances'), numeric: true),
          DataColumn(label: Text('Deductions'), numeric: true),
          DataColumn(label: Text('Net Salary'), numeric: true),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: payrolls.map((p) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(radius: 16, child: Text(p.staffName[0])),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.staffName),
                        Text(
                          p.staff.employeeId,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(p.staff.designation)),
              DataCell(Text(formatter.format(p.payroll.basicSalary))),
              DataCell(Text(formatter.format(p.payroll.allowances))),
              DataCell(Text(formatter.format(p.payroll.deductions))),
              DataCell(
                Text(
                  formatter.format(p.payroll.netSalary),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(_buildStatusChip(p.payroll.status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.payroll.status != 'paid') ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Adjustments',
                        onPressed: () => _editAdjustments(p.payroll.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.payment, size: 20),
                        tooltip: 'Mark as Paid',
                        onPressed: () => _markAsPaid(p.payroll.id),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.print, size: 20),
                      tooltip: 'Print Salary Slip',
                      onPressed: () => _printSalarySlip(p.payroll.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isPaid = status == FeeConstants.invoiceStatusPaid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isPaid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'Paid' : 'Pending',
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    final current = ref.read(payrollMonthProvider);
    final parts = current.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
    final newMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    ref.read(payrollMonthProvider.notifier).state = newMonth;
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

  Future<void> _showGeneratePayrollDialog(BuildContext context) async {
    final month = ref.read(payrollMonthProvider);
    final workingDaysController = TextEditingController(text: '26');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Payroll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate payroll for ${_formatMonth(month)}?'),
            const SizedBox(height: 16),
            TextField(
              controller: workingDaysController,
              decoration: const InputDecoration(
                labelText: 'Working Days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(payrollServiceProvider);

      try {
        final currentUser = ref.read(currentUserProvider);
        await service.generateMonthlyPayroll(
          month: month,
          workingDays: int.parse(workingDaysController.text),
          generatedBy: currentUser?.id ?? 1,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payroll generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(payrollForMonthProvider);
          ref.invalidate(payrollSummaryProvider);
        }
      } on PayrollValidationException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    workingDaysController.dispose();
  }

  Future<void> _markAsPaid(int payrollId) async {
    // Show dialog with bonuses/deductions before marking as paid
    final result = await _showPaymentWithAdjustmentsDialog(context, payrollId);

    if (result == null) return; // User cancelled

    final service = ref.read(payrollServiceProvider);

    try {
      // First update payroll with any adjustments
      if (result.hasAdjustments) {
        await service.updatePayroll(
          payrollId,
          PayrollUpdateData(
            allowances: result.allowances,
            deductions: result.deductions,
            remarks: result.remarks,
          ),
        );
      }

      // Then mark as paid
      await service.markAsPaid(
        payrollId: payrollId,
        paymentMode: result.paymentMode,
        referenceNumber: result.referenceNumber,
        processedBy: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salary marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(payrollForMonthProvider);
        ref.invalidate(payrollSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Edit payroll adjustments without marking as paid
  Future<void> _editAdjustments(int payrollId) async {
    final service = ref.read(payrollServiceProvider);

    // Get current payroll data
    final payroll = await service.getPayrollWithDetails(payrollId);
    if (payroll == null) return;

    if (!mounted) return;

    // Pre-populate with existing adjustments
    final existingAllowances = payroll.allowancesMap.entries
        .map((e) => PayrollAdjustment(name: e.key, amount: e.value))
        .toList();
    final existingDeductions = payroll.deductionsMap.entries
        .map((e) => PayrollAdjustment(name: e.key, amount: e.value))
        .toList();

    // Show adjustment dialog
    final result = await _showAdjustmentDialog(
      context,
      payroll,
      existingAllowances,
      existingDeductions,
    );

    if (result == null) return; // User cancelled
    if (!mounted) return;

    try {
      await service.updatePayroll(
        payrollId,
        PayrollUpdateData(
          allowances: result.allowances,
          deductions: result.deductions,
          remarks: result.remarks,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adjustments updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      ref.invalidate(payrollForMonthProvider);
      ref.invalidate(payrollSummaryProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Show dialog for editing adjustments only
  Future<PaymentWithAdjustmentsResult?> _showAdjustmentDialog(
    BuildContext context,
    PayrollWithStaff payroll,
    List<PayrollAdjustment> initialAllowances,
    List<PayrollAdjustment> initialDeductions,
  ) async {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0');

    final allowanceNameController = TextEditingController();
    final allowanceAmountController = TextEditingController();
    final deductionNameController = TextEditingController();
    final deductionAmountController = TextEditingController();
    final remarksController = TextEditingController(text: payroll.payroll.remarks);

    final allowances = List<PayrollAdjustment>.from(initialAllowances);
    final deductions = List<PayrollAdjustment>.from(initialDeductions);

    return showDialog<PaymentWithAdjustmentsResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final totalAllowances = allowances.fold<double>(
            0,
            (sum, a) => sum + a.amount,
          );
          final totalDeductions = deductions.fold<double>(
            0,
            (sum, d) => sum + d.amount,
          );
          final adjustedNetSalary =
              payroll.payroll.basicSalary + totalAllowances - totalDeductions;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Edit Payroll Adjustments'),
                      Text(payroll.staffName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current salary info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Basic Salary',
                          'PKR ${formatter.format(payroll.payroll.basicSalary)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Current Net',
                          'PKR ${formatter.format(payroll.payroll.netSalary)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Allowances Section
                  _buildSectionHeader(
                    'Allowances (Bonuses)',
                    Icons.add_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),

                  ...allowances.asMap().entries.map((entry) {
                    final index = entry.key;
                    final allowance = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(allowance.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PKR ${formatter.format(allowance.amount)}'),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => allowances.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: allowanceNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: allowanceAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixText: 'PKR ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          final name = allowanceNameController.text.trim();
                          final amount =
                              double.tryParse(allowanceAmountController.text) ??
                              0;
                          if (name.isNotEmpty && amount > 0) {
                            setState(() {
                              allowances.add(
                                PayrollAdjustment(name: name, amount: amount),
                              );
                              allowanceNameController.clear();
                              allowanceAmountController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Deductions Section
                  _buildSectionHeader(
                    'Deductions',
                    Icons.remove_circle,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),

                  ...deductions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final deduction = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(deduction.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PKR ${formatter.format(deduction.amount)}'),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => deductions.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: deductionNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: deductionAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixText: 'PKR ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.red),
                        onPressed: () {
                          final name = deductionNameController.text.trim();
                          final amount =
                              double.tryParse(deductionAmountController.text) ??
                              0;
                          if (name.isNotEmpty && amount > 0) {
                            setState(() {
                              deductions.add(
                                PayrollAdjustment(name: name, amount: amount),
                              );
                              deductionNameController.clear();
                              deductionAmountController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Remarks
                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Final calculation summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Basic Salary',
                          'PKR ${formatter.format(payroll.payroll.basicSalary)}',
                        ),
                        if (totalAllowances > 0)
                          _buildInfoRow(
                            '+ Allowances',
                            'PKR ${formatter.format(totalAllowances)}',
                            color: Colors.green,
                          ),
                        if (totalDeductions > 0)
                          _buildInfoRow(
                            '- Deductions',
                            'PKR ${formatter.format(totalDeductions)}',
                            color: Colors.red,
                          ),
                        const Divider(),
                        _buildInfoRow(
                          'NEW NET SALARY',
                          'PKR ${formatter.format(adjustedNetSalary)}',
                          isBold: true,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  PaymentWithAdjustmentsResult(
                    paymentMode: 'bank_transfer',
                    allowances: allowances,
                    deductions: deductions,
                    remarks: remarksController.text.isEmpty
                        ? null
                        : remarksController.text,
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save Adjustments'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show dialog for payment with bonuses/deductions
  Future<PaymentWithAdjustmentsResult?> _showPaymentWithAdjustmentsDialog(
    BuildContext context,
    int payrollId,
  ) async {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##0');

    // Get current payroll data
    final payroll = await ref
        .read(payrollServiceProvider)
        .getPayrollWithDetails(payrollId);
    if (payroll == null) return null;

    if (!context.mounted) return null;

    final paymentModeController = ValueNotifier<String>('bank_transfer');
    final referenceController = TextEditingController();
    final remarksController = TextEditingController();
    final allowanceNameController = TextEditingController();
    final allowanceAmountController = TextEditingController();
    final deductionNameController = TextEditingController();
    final deductionAmountController = TextEditingController();

    final allowances = <PayrollAdjustment>[];
    final deductions = <PayrollAdjustment>[];

    return showDialog<PaymentWithAdjustmentsResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate totals
          final totalAllowances = allowances.fold<double>(
            0,
            (sum, a) => sum + a.amount,
          );
          final totalDeductions = deductions.fold<double>(
            0,
            (sum, d) => sum + d.amount,
          );
          final adjustedNetSalary =
              payroll.payroll.netSalary + totalAllowances - totalDeductions;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.payment, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Process Salary Payment'),
                      Text(payroll.staffName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current salary info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Basic Salary',
                          'PKR ${formatter.format(payroll.payroll.basicSalary)}',
                        ),
                        _buildInfoRow(
                          'Current Allowances',
                          'PKR ${formatter.format(payroll.payroll.allowances)}',
                        ),
                        _buildInfoRow(
                          'Current Deductions',
                          'PKR ${formatter.format(payroll.payroll.deductions)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Current Net',
                          'PKR ${formatter.format(payroll.payroll.netSalary)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment mode selection
                  ValueListenableBuilder<String>(
                    valueListenable: paymentModeController,
                    builder: (context, mode, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Mode',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'cash', label: Text('Cash')),
                              ButtonSegment(
                                value: 'bank_transfer',
                                label: Text('Bank'),
                              ),
                              ButtonSegment(
                                value: 'cheque',
                                label: Text('Cheque'),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (selected) {
                              paymentModeController.value = selected.first;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reference number
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Allowances Section
                  _buildSectionHeader(
                    'Additional Allowances (Bonuses)',
                    Icons.add_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),

                  // Existing allowances
                  ...allowances.asMap().entries.map((entry) {
                    final index = entry.key;
                    final allowance = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(allowance.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PKR ${formatter.format(allowance.amount)}'),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => allowances.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add allowance input
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: allowanceNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: allowanceAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixText: 'PKR ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          final name = allowanceNameController.text.trim();
                          final amount =
                              double.tryParse(allowanceAmountController.text) ??
                              0;
                          if (name.isNotEmpty && amount > 0) {
                            setState(() {
                              allowances.add(
                                PayrollAdjustment(name: name, amount: amount),
                              );
                              allowanceNameController.clear();
                              allowanceAmountController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add Deductions Section
                  _buildSectionHeader(
                    'Additional Deductions',
                    Icons.remove_circle,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),

                  // Existing deductions
                  ...deductions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final deduction = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(deduction.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('PKR ${formatter.format(deduction.amount)}'),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => deductions.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add deduction input
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: deductionNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: deductionAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixText: 'PKR ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.red),
                        onPressed: () {
                          final name = deductionNameController.text.trim();
                          final amount =
                              double.tryParse(deductionAmountController.text) ??
                              0;
                          if (name.isNotEmpty && amount > 0) {
                            setState(() {
                              deductions.add(
                                PayrollAdjustment(name: name, amount: amount),
                              );
                              deductionNameController.clear();
                              deductionAmountController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Remarks
                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Final calculation summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Original Net Salary',
                          'PKR ${formatter.format(payroll.payroll.netSalary)}',
                        ),
                        if (totalAllowances > 0)
                          _buildInfoRow(
                            '+ Additional Allowances',
                            'PKR ${formatter.format(totalAllowances)}',
                            color: Colors.green,
                          ),
                        if (totalDeductions > 0)
                          _buildInfoRow(
                            '- Additional Deductions',
                            'PKR ${formatter.format(totalDeductions)}',
                            color: Colors.red,
                          ),
                        const Divider(),
                        _buildInfoRow(
                          'FINAL PAYMENT',
                          'PKR ${formatter.format(adjustedNetSalary)}',
                          isBold: true,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  PaymentWithAdjustmentsResult(
                    paymentMode: paymentModeController.value,
                    referenceNumber: referenceController.text.isEmpty
                        ? null
                        : referenceController.text,
                    allowances: allowances,
                    deductions: deductions,
                    remarks: remarksController.text.isEmpty
                        ? null
                        : remarksController.text,
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printSalarySlip(int payrollId) async {
    final service = ref.read(payrollServiceProvider);

    try {
      await service.printSalarySlip(context, payrollId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Result class for payment with adjustments dialog
class PaymentWithAdjustmentsResult {
  final String paymentMode;
  final String? referenceNumber;
  final List<PayrollAdjustment> allowances;
  final List<PayrollAdjustment> deductions;
  final String? remarks;

  PaymentWithAdjustmentsResult({
    required this.paymentMode,
    this.referenceNumber,
    this.allowances = const [],
    this.deductions = const [],
    this.remarks,
  });

  bool get hasAdjustments => allowances.isNotEmpty || deductions.isNotEmpty;
}
