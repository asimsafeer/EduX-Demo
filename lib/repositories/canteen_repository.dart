/// EduX School Management System
/// Canteen Repository - Data access layer for canteen management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for Canteen with its financial summary
class CanteenWithSummary {
  final Canteen canteen;
  final double totalIncome;
  final double totalInvestment;
  final double netProfit;

  CanteenWithSummary({
    required this.canteen,
    required this.totalIncome,
    required this.totalInvestment,
    required this.netProfit,
  });
}

/// Abstract canteen repository interface
abstract class CanteenRepository {
  /// Get all canteens
  Future<List<Canteen>> getAll();

  /// Get active canteens
  Future<List<Canteen>> getActive();

  /// Get canteen by ID
  Future<Canteen?> getById(int id);

  /// Get canteen with financial summary
  Future<CanteenWithSummary?> getWithSummary(int id);

  /// Create a new canteen
  Future<int> create(CanteensCompanion canteenData);

  /// Update an existing canteen
  Future<bool> update(int id, CanteensCompanion canteenData);

  /// Delete a canteen
  Future<bool> delete(int id);

  /// Get transactions for a canteen
  Future<List<CanteenTransaction>> getTransactions(int canteenId);

  /// Add a transaction
  Future<int> addTransaction(CanteenTransactionsCompanion transactionData);
}

/// Implementation of CanteenRepository using Drift database
class CanteenRepositoryImpl implements CanteenRepository {
  final AppDatabase _db;

  CanteenRepositoryImpl(this._db);

  @override
  Future<List<Canteen>> getAll() async {
    return await _db.select(_db.canteens).get();
  }

  @override
  Future<List<Canteen>> getActive() async {
    return await (_db.select(
      _db.canteens,
    )..where((t) => t.isActive.equals(true))).get();
  }

  @override
  Future<Canteen?> getById(int id) async {
    return await (_db.select(
      _db.canteens,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<CanteenWithSummary?> getWithSummary(int id) async {
    final canteen = await getById(id);
    if (canteen == null) return null;

    final transactions = await getTransactions(id);

    double totalIncome = 0;
    double totalInvestment = 0;

    for (final tx in transactions) {
      if (tx.type.startsWith('income')) {
        totalIncome += tx.amount;
      } else if (tx.type.startsWith('expense')) {
        totalInvestment += tx.amount;
      }
    }

    return CanteenWithSummary(
      canteen: canteen,
      totalIncome: totalIncome,
      totalInvestment: totalInvestment,
      netProfit: totalIncome - totalInvestment,
    );
  }

  @override
  Future<int> create(CanteensCompanion canteenData) async {
    return await _db.into(_db.canteens).insert(canteenData);
  }

  @override
  Future<bool> update(int id, CanteensCompanion canteenData) async {
    final updated =
        await (_db.update(_db.canteens)..where((t) => t.id.equals(id))).write(
          canteenData.copyWith(updatedAt: Value(DateTime.now())),
        );
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final updated =
        await (_db.update(_db.canteens)..where((t) => t.id.equals(id))).write(
          const CanteensCompanion(isActive: Value(false)),
        );
    return updated > 0;
  }

  @override
  Future<List<CanteenTransaction>> getTransactions(int canteenId) async {
    return await (_db.select(_db.canteenTransactions)
          ..where((t) => t.canteenId.equals(canteenId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  @override
  Future<int> addTransaction(
    CanteenTransactionsCompanion transactionData,
  ) async {
    return await _db.into(_db.canteenTransactions).insert(transactionData);
  }
}
