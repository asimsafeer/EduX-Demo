/// EduX School Management System
/// Staff Task Repository - Manages staff task assignments
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Provider for StaffTaskRepository
final staffTaskRepositoryProvider = Provider<StaffTaskRepository>((ref) {
  return StaffTaskRepository(AppDatabase.instance);
});

/// Provider to watch tasks for a specific staff member
final staffTasksProvider = StreamProvider.family<List<StaffTask>, int>((
  ref,
  staffId,
) {
  final repository = ref.watch(staffTaskRepositoryProvider);
  return repository.watchTasksByStaff(staffId);
});

/// Repository for managing staff tasks
class StaffTaskRepository {
  final AppDatabase _db;

  StaffTaskRepository(this._db);

  /// Get all tasks for a staff member (as stream)
  Stream<List<StaffTask>> watchTasksByStaff(int staffId) {
    return (_db.select(_db.staffTasks)
          ..where((t) => t.staffId.equals(staffId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.status, mode: OrderingMode.desc),
            // Custom ordering for priority could be complex in SQL,
            // simplifying to createdAt for now or just status grouping
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Create a new task
  Future<int> createTask(StaffTasksCompanion task) {
    return _db.into(_db.staffTasks).insert(task);
  }

  /// Update an existing task
  Future<bool> updateTask(StaffTasksCompanion task) {
    return _db.update(_db.staffTasks).replace(task);
  }

  /// Delete a task
  Future<int> deleteTask(int taskId) {
    return (_db.delete(_db.staffTasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// Update task status
  Future<int> updateStatus(int taskId, String status) {
    return (_db.update(_db.staffTasks)..where((t) => t.id.equals(taskId)))
        .write(StaffTasksCompanion(status: Value(status)));
  }
}
