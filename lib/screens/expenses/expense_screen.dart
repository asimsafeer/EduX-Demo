/// EduX School Management System
/// Expense Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/core.dart';
import '../../providers/providers.dart';
import '../../database/database.dart';
import '../../services/expense_pdf_service.dart';
import 'expense_form_dialog.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => ref.read(expenseProvider.notifier).loadData());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Reports'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.printer),
            onPressed: () => _generateAndPrintPdf(context, state),
            tooltip: 'Print Report',
          ),
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref
                .read(expenseProvider.notifier)
                .loadData(range: state.dateRange),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(context),
        label: const Text('Add Expense'),
        icon: const Icon(LucideIcons.plus),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(child: Text('Error: ${state.error}'))
          : Padding(
              padding: AppTheme.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Display
                  if (state.dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Period: ${DateFormat('MMM d, yyyy').format(state.dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(state.dateRange!.end)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                  // Summary Cards
                  _buildSummaryCards(state.stats),
                  const SizedBox(height: 24),

                  // Transactions List
                  Text(
                    'Expense Transactions',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildExpenseList(state.expenses)),
                ],
              ),
            ),
    );
  }

  Future<void> _generateAndPrintPdf(
    BuildContext context,
    ExpenseState state,
  ) async {
    if (state.expenses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No expenses to print')));
      return;
    }

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final db = AppDatabase.instance;
      final settings = await (db.select(
        db.schoolSettings,
      )..limit(1)).getSingleOrNull();

      if (settings == null) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Close loading

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School settings not found')),
        );
        return;
      }

      final bytes = await ExpensePdfService.generateExpensePdf(
        schoolSettings: settings,
        stats: state.stats,
        expenses: state.expenses,
        dateRange:
            state.dateRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (!context.mounted) return;
      await PdfHelper.previewPdf(
        context,
        bytes,
        'Expense_Report_${DateFormat('MMM_yyyy').format(DateTime.now())}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading if open

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
        }
      }
    }
  }

  Widget _buildSummaryCards(ExpenseStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive card width calculation
        // On wide screens (>= 1200): 4 cards per row
        // On desktop/tablet (>= 800): 2 cards per row
        // On mobile (< 800): 1 card per row (full width)

        double cardWidth;
        if (width >= 1200) {
          cardWidth = (width - 48) / 4; // 3 gaps of 16px
        } else if (width >= 800) {
          cardWidth = (width - 16) / 2; // 1 gap of 16px
        } else {
          cardWidth = width; // Full width
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Total Income',
                value: stats.totalFeeCollected,
                icon: LucideIcons.arrowDownCircle,
                color: AppColors.success,
                subtitle: 'Fees Collected',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Payroll Expense',
                value: stats.totalPayroll,
                icon: LucideIcons.users,
                color: AppColors.warning,
                subtitle: 'Staff Salaries',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Other Expenses',
                value: stats.totalExpenses,
                icon: LucideIcons.receipt,
                color: AppColors.error,
                subtitle: 'Operational Costs',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Net Income',
                value: stats.netIncome,
                icon: LucideIcons.wallet,
                color: stats.netIncome >= 0
                    ? AppColors.primary
                    : AppColors.error,
                subtitle: 'Income - (Payroll + Expenses)',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses recorded for this period'));
    }

    return Card(
      child: ListView.separated(
        itemCount: expenses.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              child: Icon(
                LucideIcons.receipt,
                color: AppColors.error,
                size: 20,
              ),
            ),
            title: Text(expense.title, style: AppTextStyles.bodyLarge),
            subtitle: Text(
              '${expense.category} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PKR ${NumberFormat('#,###').format(expense.amount)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(LucideIcons.moreVertical, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showExpenseDialog(context, expense: expense);
                    } else if (value == 'delete') {
                      _confirmDelete(context, expense);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialRange =
        ref.read(expenseProvider).dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      ref.read(expenseProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _showExpenseDialog(
    BuildContext context, {
    Expense? expense,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(expense: expense),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PKR ${NumberFormat('#,###').format(value)}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
