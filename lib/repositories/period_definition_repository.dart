/// EduX School Management System
/// Period Definition Repository - Data access layer for period configuration
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Abstract period definition repository interface
abstract class PeriodDefinitionRepository {
  /// Get all period definitions for an academic year
  Future<List<PeriodDefinition>> getAll(String academicYear);

  /// Get a specific period by ID
  Future<PeriodDefinition?> getById(int id);

  /// Get period by number for an academic year
  Future<PeriodDefinition?> getByNumber(int periodNumber, String academicYear);

  /// Create a new period definition
  Future<int> create(PeriodDefinitionsCompanion period);

  /// Update an existing period
  Future<bool> update(int id, PeriodDefinitionsCompanion period);

  /// Delete a period
  Future<bool> delete(int id);

  /// Reorder periods
  Future<void> reorder(List<int> ids, List<int> newOrders);

  /// Seed default periods for an academic year
  Future<void> seedDefaults(String academicYear);

  /// Get count of periods (excluding breaks)
  Future<int> getPeriodCount(String academicYear);

  /// Get total school hours
  Future<Duration> getTotalSchoolHours(String academicYear);
}

/// Implementation of PeriodDefinitionRepository using Drift database
class PeriodDefinitionRepositoryImpl implements PeriodDefinitionRepository {
  final AppDatabase _db;

  PeriodDefinitionRepositoryImpl(this._db);

  @override
  Future<List<PeriodDefinition>> getAll(String academicYear) async {
    return await (_db.select(_db.periodDefinitions)
          ..where((t) => t.academicYear.equals(academicYear))
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
        .get();
  }

  @override
  Future<PeriodDefinition?> getById(int id) async {
    return await (_db.select(
      _db.periodDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<PeriodDefinition?> getByNumber(
    int periodNumber,
    String academicYear,
  ) async {
    return await (_db.select(_db.periodDefinitions)..where(
          (t) =>
              t.periodNumber.equals(periodNumber) &
              t.academicYear.equals(academicYear),
        ))
        .getSingleOrNull();
  }

  @override
  Future<int> create(PeriodDefinitionsCompanion period) async {
    return await _db.into(_db.periodDefinitions).insert(period);
  }

  @override
  Future<bool> update(int id, PeriodDefinitionsCompanion period) async {
    final updated = await (_db.update(
      _db.periodDefinitions,
    )..where((t) => t.id.equals(id))).write(period);
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final deleted = await (_db.delete(
      _db.periodDefinitions,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<void> reorder(List<int> ids, List<int> newOrders) async {
    await _db.batch((batch) {
      for (var i = 0; i < ids.length; i++) {
        batch.update(
          _db.periodDefinitions,
          PeriodDefinitionsCompanion(displayOrder: Value(newOrders[i])),
          where: (t) => t.id.equals(ids[i]),
        );
      }
    });
  }

  @override
  Future<void> seedDefaults(String academicYear) async {
    // Check if periods already exist
    final existing = await getAll(academicYear);
    if (existing.isNotEmpty) return;

    // Default school schedule
    final defaultPeriods = [
      _createPeriod(1, 'Period 1', '08:00', '08:45', 45, false, 1),
      _createPeriod(2, 'Period 2', '08:45', '09:30', 45, false, 2),
      _createPeriod(3, 'Period 3', '09:30', '10:15', 45, false, 3),
      _createPeriod(0, 'Break', '10:15', '10:45', 30, true, 4),
      _createPeriod(4, 'Period 4', '10:45', '11:30', 45, false, 5),
      _createPeriod(5, 'Period 5', '11:30', '12:15', 45, false, 6),
      _createPeriod(6, 'Period 6', '12:15', '13:00', 45, false, 7),
      _createPeriod(0, 'Lunch Break', '13:00', '13:45', 45, true, 8),
      _createPeriod(7, 'Period 7', '13:45', '14:30', 45, false, 9),
      _createPeriod(8, 'Period 8', '14:30', '15:15', 45, false, 10),
    ];

    await _db.batch((batch) {
      for (final period in defaultPeriods) {
        batch.insert(
          _db.periodDefinitions,
          period.copyWith(academicYear: Value(academicYear)),
        );
      }
    });
  }

  PeriodDefinitionsCompanion _createPeriod(
    int periodNumber,
    String name,
    String startTime,
    String endTime,
    int durationMinutes,
    bool isBreak,
    int displayOrder,
  ) {
    return PeriodDefinitionsCompanion.insert(
      periodNumber: periodNumber,
      name: name,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      displayOrder: displayOrder,
      academicYear: '', // Will be set during insertion
      isBreak: Value(isBreak),
    );
  }

  @override
  Future<int> getPeriodCount(String academicYear) async {
    final count =
        await (_db.selectOnly(_db.periodDefinitions)
              ..addColumns([_db.periodDefinitions.id.count()])
              ..where(
                _db.periodDefinitions.academicYear.equals(academicYear) &
                    _db.periodDefinitions.isBreak.equals(false),
              ))
            .map((row) => row.read(_db.periodDefinitions.id.count()))
            .getSingle();
    return count ?? 0;
  }

  @override
  Future<Duration> getTotalSchoolHours(String academicYear) async {
    final periods = await getAll(academicYear);
    int totalMinutes = 0;

    for (final period in periods) {
      if (!period.isBreak) {
        totalMinutes += period.durationMinutes;
      }
    }

    return Duration(minutes: totalMinutes);
  }
}
