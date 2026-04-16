/// EduX School Management System
/// Class Repository - Data access layer for class management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for class with section count and student count
class ClassWithStats {
  final SchoolClass schoolClass;
  final int sectionCount;
  final int studentCount;

  ClassWithStats({
    required this.schoolClass,
    required this.sectionCount,
    required this.studentCount,
  });

  /// Full display name with student count
  String get displayName => '${schoolClass.name} ($studentCount students)';
}

/// Data class for class with its sections
class ClassWithSections {
  final SchoolClass schoolClass;
  final List<Section> sections;

  ClassWithSections({required this.schoolClass, required this.sections});
}

/// Abstract class repository interface
abstract class ClassRepository {
  /// Get all classes ordered by display order
  Future<List<SchoolClass>> getAll();

  /// Get all active classes
  Future<List<SchoolClass>> getAllActive();

  /// Get classes by level
  Future<List<SchoolClass>> getByLevel(String level);

  /// Get class by ID
  Future<SchoolClass?> getById(int id);

  /// Get class with all its sections
  Future<ClassWithSections?> getWithSections(int id);

  /// Get all classes with their stats (section count, student count)
  Future<List<ClassWithStats>> getAllWithStats();

  /// Get student count for a class
  Future<int> getStudentCount(int classId);

  /// Create a new class
  Future<int> create(ClassesCompanion classData);

  /// Update an existing class
  Future<bool> update(int id, ClassesCompanion classData);

  /// Soft delete a class (set isActive = false)
  Future<bool> delete(int id);

  /// Hard delete a class (actually remove from database)
  Future<bool> hardDelete(int id);

  /// Check if class name is unique within a level
  Future<bool> isNameUnique(String name, String level, {int? excludeId});

  /// Get class levels grouped
  Future<Map<String, List<SchoolClass>>> getGroupedByLevel();
}

/// Implementation of ClassRepository using Drift database
class ClassRepositoryImpl implements ClassRepository {
  final AppDatabase _db;

  ClassRepositoryImpl(this._db);

  @override
  Future<List<SchoolClass>> getAll() async {
    return await (_db.select(
      _db.classes,
    )..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();
  }

  @override
  Future<List<SchoolClass>> getAllActive() async {
    return await (_db.select(_db.classes)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm.asc(t.gradeLevel),
            (t) => OrderingTerm.asc(t.displayOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  @override
  Future<List<SchoolClass>> getByLevel(String level) async {
    return await (_db.select(_db.classes)
          ..where((t) => t.level.equals(level) & t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm.asc(t.gradeLevel),
            (t) => OrderingTerm.asc(t.displayOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  @override
  Future<SchoolClass?> getById(int id) async {
    return await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<ClassWithSections?> getWithSections(int id) async {
    final schoolClass = await getById(id);
    if (schoolClass == null) return null;

    final sections =
        await (_db.select(_db.sections)
              ..where((t) => t.classId.equals(id) & t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();

    return ClassWithSections(schoolClass: schoolClass, sections: sections);
  }

  @override
  Future<List<ClassWithStats>> getAllWithStats() async {
    final classes = await getAllActive();
    final List<ClassWithStats> result = [];

    for (final schoolClass in classes) {
      final sectionCount = await _getSectionCount(schoolClass.id);
      final studentCount = await getStudentCount(schoolClass.id);

      result.add(
        ClassWithStats(
          schoolClass: schoolClass,
          sectionCount: sectionCount,
          studentCount: studentCount,
        ),
      );
    }

    return result;
  }

  Future<int> _getSectionCount(int classId) async {
    final count =
        await (_db.selectOnly(_db.sections)
              ..addColumns([_db.sections.id.count()])
              ..where(
                _db.sections.classId.equals(classId) &
                    _db.sections.isActive.equals(true),
              ))
            .map((row) => row.read(_db.sections.id.count()))
            .getSingle();
    return count ?? 0;
  }

  @override
  Future<int> getStudentCount(int classId) async {
    // Count students with active enrollments in this class
    final count =
        await (_db.selectOnly(_db.enrollments)
              ..addColumns([_db.enrollments.id.count()])
              ..where(
                _db.enrollments.classId.equals(classId) &
                    _db.enrollments.isCurrent.equals(true) &
                    _db.enrollments.status.equals('active'),
              ))
            .map((row) => row.read(_db.enrollments.id.count()))
            .getSingle();
    return count ?? 0;
  }

  @override
  Future<int> create(ClassesCompanion classData) async {
    return await _db.into(_db.classes).insert(classData);
  }

  @override
  Future<bool> update(int id, ClassesCompanion classData) async {
    final updated =
        await (_db.update(_db.classes)..where((t) => t.id.equals(id))).write(
          classData.copyWith(updatedAt: Value(DateTime.now())),
        );
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    // Soft delete - just set isActive to false
    final updated =
        await (_db.update(_db.classes)..where((t) => t.id.equals(id))).write(
          const ClassesCompanion(isActive: Value(false)),
        );
    return updated > 0;
  }

  @override
  Future<bool> hardDelete(int id) async {
    final deleted = await (_db.delete(
      _db.classes,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<bool> isNameUnique(String name, String level, {int? excludeId}) async {
    var query = _db.select(_db.classes)
      ..where(
        (t) =>
            t.name.lower().equals(name.toLowerCase()) & t.level.equals(level),
      );

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }

  @override
  Future<Map<String, List<SchoolClass>>> getGroupedByLevel() async {
    final classes = await getAllActive();
    final Map<String, List<SchoolClass>> grouped = {
      'pre_primary': [],
      'primary': [],
      'middle': [],
      'secondary': [],
    };

    for (final schoolClass in classes) {
      final level = schoolClass.level;
      if (grouped.containsKey(level)) {
        grouped[level]!.add(schoolClass);
      }
    }

    return grouped;
  }
}
