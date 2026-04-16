/// EduX School Management System
/// Expense Provider
library;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import 'dashboard_provider.dart';
import '../repositories/repositories.dart';

/// Expense statistics
class ExpenseStats {
  final double totalExpenses;
  final double totalPayroll;
  final double totalFeeCollected;
  final double netIncome;

  const ExpenseStats({
    this.totalExpenses = 0,
    this.totalPayroll = 0,
    this.totalFeeCollected = 0,
    this.netIncome = 0,
  });

  double get totalOutflow => totalExpenses + totalPayroll;
}

/// Expense State
class ExpenseState {
  final List<Expense> expenses;
  final ExpenseStats stats;
  final DateTimeRange? dateRange;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    this.expenses = const [],
    this.stats = const ExpenseStats(),
    this.dateRange,
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    ExpenseStats? stats,
    DateTimeRange? dateRange,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      stats: stats ?? this.stats,
      dateRange:
          dateRange, // Nullable update logic requires care, here assuming explicit set
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Expense Notifier
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _repository;
  final AppDatabase _db;
  final PaymentRepository _paymentRepo;
  final Ref _ref;

  ExpenseNotifier(this._repository, this._db, this._paymentRepo, this._ref)
    : super(const ExpenseState(isLoading: true)) {
    loadData();
  }

  Future<void> loadData({DateTimeRange? range}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Default to current month if no range
    final now = DateTime.now();
    final start = range?.start ?? DateTime(now.year, now.month, 1);
    final end = range?.end ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      // 1. Load Expenses
      final expenses = await _repository.getExpensesByDateRange(start, end);
      final expenseTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

      // 2. Load Payroll
      // Assuming payroll date corresponds to 'createdAt' or 'paymentDate'
      // Ideally pass period to query. Payroll has 'month' string (YYYY-MM).
      // Converting range to months is tricky if range is arbitrary days.
      // For simplicity, we'll sum up payrolls created/paid within the date range.
      // But payroll table usually has `month` field.
      // Let's us `month` field to filter.
      final startMonth = DateFormat('yyyy-MM').format(start);
      final endMonth = DateFormat('yyyy-MM').format(end);

      final payrolls =
          await (_db.select(_db.payroll)
                ..where((t) => t.month.isBetweenValues(startMonth, endMonth))
                ..where((t) => t.status.equals('paid')))
              .get();

      final payrollTotal = payrolls.fold(0.0, (sum, p) => sum + p.netSalary);

      // 3. Load Fee Collection
      final feeCollected = await _paymentRepo.getTotalCollectionForPeriod(
        from: start,
        to: end,
      );

      state = state.copyWith(
        expenses: expenses,
        stats: ExpenseStats(
          totalExpenses: expenseTotal,
          totalPayroll: payrollTotal,
          totalFeeCollected: feeCollected,
          netIncome: feeCollected - (expenseTotal + payrollTotal),
        ),
        dateRange: range ?? DateTimeRange(start: start, end: end),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    await loadData(
      range: DateTimeRange(start: start, end: end),
    );
  }

  Future<void> clearDateRange() async {
    await loadData();
  }

  Future<bool> createExpense(ExpensesCompanion expense) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.createExpense(expense);
      await loadData(range: state.dateRange); // Reload to update stats
      _ref.invalidate(dashboardProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateExpense(ExpensesCompanion expense) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.updateExpense(expense);
      await loadData(range: state.dateRange);
      _ref.invalidate(dashboardProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deleteExpense(id);
      await loadData(range: state.dateRange);
      _ref.invalidate(dashboardProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Providers
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((
  ref,
) {
  final db = AppDatabase.instance;
  return ExpenseNotifier(
    DriftExpenseRepository(db),
    db,
    DriftPaymentRepository(db),
    ref,
  );
});
