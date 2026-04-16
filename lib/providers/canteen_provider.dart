/// EduX School Management System
/// Canteen Provider - Riverpod state management for canteen module
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/canteen_repository.dart';
import 'academics_provider.dart'; // For OperationState and databaseProvider

/// Canteen repository provider
final canteenRepositoryProvider = Provider<CanteenRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CanteenRepositoryImpl(db);
});

// ============================================
// CANTEEN DATA PROVIDERS
// ============================================

/// All canteens provider
final allCanteensProvider = FutureProvider<List<Canteen>>((ref) async {
  final repo = ref.watch(canteenRepositoryProvider);
  return await repo.getAll();
});

/// Active canteens provider
final activeCanteensProvider = FutureProvider<List<Canteen>>((ref) async {
  final repo = ref.watch(canteenRepositoryProvider);
  return await repo.getActive();
});

/// Canteen with summary provider
final canteenSummaryProvider = FutureProvider.family<CanteenWithSummary?, int>((
  ref,
  id,
) async {
  final repo = ref.watch(canteenRepositoryProvider);
  return await repo.getWithSummary(id);
});

/// Canteen transactions provider
final canteenTransactionsProvider =
    FutureProvider.family<List<CanteenTransaction>, int>((ref, id) async {
      final repo = ref.watch(canteenRepositoryProvider);
      return await repo.getTransactions(id);
    });

// ============================================
// OPERATION NOTIFIER
// ============================================

/// Canteen operation notifier
class CanteenOperationNotifier extends StateNotifier<OperationState> {
  final CanteenRepository _repository;
  final Ref _ref;

  CanteenOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createCanteen({
    required String name,
    required String operatorName,
    String? operatorPhone,
    String businessModel = 'rent',
    double monthlyRent = 0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.create(
        CanteensCompanion.insert(
          name: name,
          operatorName: operatorName,
          operatorPhone: Value(operatorPhone),
          businessModel: Value(businessModel),
          monthlyRent: Value(monthlyRent),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Canteen added successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCanteen(int id, CanteensCompanion data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.update(id, data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Canteen updated successfully',
      );
      _invalidateProviders();
      _ref.invalidate(canteenSummaryProvider(id));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addTransaction({
    required int canteenId,
    required String type,
    required double amount,
    DateTime? date,
    String? description,
    int? recordedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.addTransaction(
        CanteenTransactionsCompanion.insert(
          canteenId: canteenId,
          type: type,
          amount: amount,
          date: Value(date ?? DateTime.now()),
          description: Value(description),
          recordedBy: Value(recordedBy),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Transaction recorded successfully',
      );
      _ref.invalidate(canteenTransactionsProvider(canteenId));
      _ref.invalidate(canteenSummaryProvider(canteenId));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(allCanteensProvider);
    _ref.invalidate(activeCanteensProvider);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

/// Canteen operation provider
final canteenOperationProvider =
    StateNotifierProvider<CanteenOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(canteenRepositoryProvider);
      return CanteenOperationNotifier(repo, ref);
    });
