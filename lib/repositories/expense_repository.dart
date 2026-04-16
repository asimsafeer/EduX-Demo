/// EduX School Management System
/// Expense Repository
library;

import 'package:drift/drift.dart';
import '../database/database.dart';

/// Repository interface for expense management
abstract class ExpenseRepository {
  /// Get all expenses
  Future<List<Expense>> getAllExpenses();

  /// Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);

  /// Create a new expense
  Future<int> createExpense(ExpensesCompanion expense);

  /// Update an existing expense
  Future<bool> updateExpense(ExpensesCompanion expense);

  /// Delete an expense
  Future<int> deleteExpense(int id);

  /// Calculate total expenses for a period (including optional payroll)
  Future<double> getTotalExpenses(DateTime start, DateTime end);
}

/// Drift implementation of ExpenseRepository
class DriftExpenseRepository implements ExpenseRepository {
  final AppDatabase _db;

  DriftExpenseRepository(this._db);

  @override
  Future<List<Expense>> getAllExpenses() {
    return (_db.select(_db.expenses)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.expenses)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  @override
  Future<int> createExpense(ExpensesCompanion expense) {
    return _db.into(_db.expenses).insert(expense);
  }

  @override
  Future<bool> updateExpense(ExpensesCompanion expense) async {
    return await (_db.update(_db.expenses)..where((t) => t.id.equals(expense.id.value)))
            .write(expense) >
        0;
  }

  @override
  Future<int> deleteExpense(int id) {
    return (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    // Sum of expenses
    final expenses = await getExpensesByDateRange(start, end);
    final expenseTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return expenseTotal;
  }
}
