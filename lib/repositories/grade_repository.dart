/// EduX School Management System
/// Grade Repository - Data access layer for grade settings management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Abstract grade repository interface
abstract class GradeRepository {
  // CRUD operations
  Future<GradeSetting?> getById(int id);
  Future<int> create(GradeSettingsCompanion grade);
  Future<bool> update(int id, GradeSettingsCompanion grade);
  Future<bool> delete(int id);

  // Query operations
  Future<List<GradeSetting>> getAllGrades();
  Future<GradeSetting?> getGradeForPercentage(double percentage);
  Future<GradeSetting?> getGradeByName(String gradeName);

  // Reordering
  Future<void> reorderGrades(List<int> gradeIds);

  // Validation
  Future<bool> isGradeNameUnique(String name, {int? excludeId});
  Future<bool> hasOverlappingRange(
    double minPercentage,
    double maxPercentage, {
    int? excludeId,
  });
}

/// Drift implementation of grade repository
class DriftGradeRepository implements GradeRepository {
  final AppDatabase _db;

  DriftGradeRepository(this._db);

  @override
  Future<GradeSetting?> getById(int id) async {
    return await (_db.select(
      _db.gradeSettings,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> create(GradeSettingsCompanion grade) async {
    return await _db.into(_db.gradeSettings).insert(grade);
  }

  @override
  Future<bool> update(int id, GradeSettingsCompanion grade) async {
    return await (_db.update(
          _db.gradeSettings,
        )..where((t) => t.id.equals(id))).write(grade) >
        0;
  }

  @override
  Future<bool> delete(int id) async {
    return await (_db.delete(
          _db.gradeSettings,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<List<GradeSetting>> getAllGrades() async {
    return await (_db.select(
      _db.gradeSettings,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();
  }

  @override
  Future<GradeSetting?> getGradeForPercentage(double percentage) async {
    return await (_db.select(_db.gradeSettings)
          ..where(
            (t) =>
                t.minPercentage.isSmallerOrEqualValue(percentage) &
                t.maxPercentage.isBiggerOrEqualValue(percentage),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.minPercentage)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<GradeSetting?> getGradeByName(String gradeName) async {
    return await (_db.select(
      _db.gradeSettings,
    )..where((t) => t.grade.equals(gradeName))).getSingleOrNull();
  }

  @override
  Future<void> reorderGrades(List<int> gradeIds) async {
    await _db.batch((batch) {
      for (int i = 0; i < gradeIds.length; i++) {
        batch.update(
          _db.gradeSettings,
          GradeSettingsCompanion(
            displayOrder: Value(i + 1),
            updatedAt: Value(DateTime.now()),
          ),
          where: (t) => t.id.equals(gradeIds[i]),
        );
      }
    });
  }

  @override
  Future<bool> isGradeNameUnique(String name, {int? excludeId}) async {
    final query = _db.select(_db.gradeSettings)
      ..where((t) => t.grade.equals(name));

    if (excludeId != null) {
      query.where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }

  @override
  Future<bool> hasOverlappingRange(
    double minPercentage,
    double maxPercentage, {
    int? excludeId,
  }) async {
    // Check if any existing grade has an overlapping range
    // Overlap occurs if: existing.min <= new.max AND existing.max >= new.min
    final allGrades = await getAllGrades();

    for (final grade in allGrades) {
      // Skip if we're excluding this grade (during edit)
      if (excludeId != null && grade.id == excludeId) continue;

      // Check for overlap
      if (grade.minPercentage <= maxPercentage &&
          grade.maxPercentage >= minPercentage) {
        return true;
      }
    }

    return false;
  }
}

/// Grade calculation utility
class GradeCalculator {
  final List<GradeSetting> _grades;

  GradeCalculator(this._grades) {
    // Sort by min percentage descending for proper lookup
    _grades.sort((a, b) => b.minPercentage.compareTo(a.minPercentage));
  }

  /// Get grade for a percentage
  GradeSetting? getGrade(double percentage) {
    for (final grade in _grades) {
      if (percentage >= grade.minPercentage &&
          percentage <= grade.maxPercentage) {
        return grade;
      }
    }
    return null;
  }

  /// Calculate GPA from percentage
  double getGpa(double percentage) {
    final grade = getGrade(percentage);
    return grade?.gpa ?? 0.0;
  }

  /// Get grade name from percentage
  String getGradeName(double percentage) {
    final grade = getGrade(percentage);
    return grade?.grade ?? 'N/A';
  }

  /// Check if passing grade
  bool isPassing(double percentage) {
    final grade = getGrade(percentage);
    return grade?.isPassing ?? false;
  }

  /// Get remarks for percentage
  String? getRemarks(double percentage) {
    final grade = getGrade(percentage);
    return grade?.remarks;
  }

  /// Calculate overall GPA from multiple subject percentages
  double calculateOverallGpa(List<double> percentages) {
    if (percentages.isEmpty) return 0.0;
    double totalGpa = 0;
    for (final pct in percentages) {
      totalGpa += getGpa(pct);
    }
    return totalGpa / percentages.length;
  }

  /// Calculate weighted GPA
  double calculateWeightedGpa(
    List<({double percentage, double weight})> items,
  ) {
    if (items.isEmpty) return 0.0;
    double totalWeightedGpa = 0;
    double totalWeight = 0;
    for (final item in items) {
      totalWeightedGpa += getGpa(item.percentage) * item.weight;
      totalWeight += item.weight;
    }
    return totalWeight > 0 ? totalWeightedGpa / totalWeight : 0.0;
  }
}
