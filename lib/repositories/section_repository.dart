/// EduX School Management System
/// Section Repository - Data access layer for section management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for section with additional info
class SectionWithStats {
  final Section section;
  final SchoolClass? schoolClass;
  final int studentCount;
  final String? classTeacherName;

  SectionWithStats({
    required this.section,
    this.schoolClass,
    required this.studentCount,
    this.classTeacherName,
  });

  /// Full display name (e.g., "Class 5 - A")
  String get fullName => '${schoolClass?.name ?? ''} - ${section.name}';

  /// Capacity status (e.g., "25/30 students")
  String get capacityStatus {
    if (section.capacity == null) return '$studentCount students';
    return '$studentCount/${section.capacity} students';
  }

  /// Is section at capacity
  bool get isAtCapacity {
    if (section.capacity == null) return false;
    return studentCount >= section.capacity!;
  }
}

/// Class-section combination for dropdowns
class ClassSectionPair {
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;

  ClassSectionPair({
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
  });

  /// Display name (e.g., "Class 5 - A")
  String get displayName => '$className - $sectionName';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassSectionPair &&
        other.classId == classId &&
        other.sectionId == sectionId;
  }

  @override
  int get hashCode => classId.hashCode ^ sectionId.hashCode;
}

/// Abstract section repository interface
abstract class SectionRepository {
  /// Get all sections
  Future<List<Section>> getAll();

  /// Get all active sections
  Future<List<Section>> getAllActive();

  /// Get sections by class ID
  Future<List<Section>> getByClass(int classId);

  /// Get active sections by class ID
  Future<List<Section>> getActiveByClass(int classId);

  /// Get section by ID
  Future<Section?> getById(int id);

  /// Get section with stats
  Future<SectionWithStats?> getWithStats(int id);

  /// Get all sections with stats
  Future<List<SectionWithStats>> getAllWithStats();

  /// Get sections with stats by class
  Future<List<SectionWithStats>> getWithStatsByClass(int classId);

  /// Get student count for a section
  Future<int> getStudentCount(int sectionId);

  /// Create a new section
  Future<int> create(SectionsCompanion sectionData);

  /// Update an existing section
  Future<bool> update(int id, SectionsCompanion sectionData);

  /// Soft delete a section (set isActive = false)
  Future<bool> delete(int id);

  /// Hard delete a section
  Future<bool> hardDelete(int id);

  /// Assign class teacher to section
  Future<bool> assignClassTeacher(int sectionId, int? staffId);

  /// Check if section name is unique within a class
  Future<bool> isNameUnique(String name, int classId, {int? excludeId});

  /// Get all class-section combinations for dropdowns
  Future<List<ClassSectionPair>> getClassSectionCombinations();
}

/// Implementation of SectionRepository using Drift database
class SectionRepositoryImpl implements SectionRepository {
  final AppDatabase _db;

  SectionRepositoryImpl(this._db);

  @override
  Future<List<Section>> getAll() async {
    return await (_db.select(
      _db.sections,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  @override
  Future<List<Section>> getAllActive() async {
    return await (_db.select(_db.sections)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<List<Section>> getByClass(int classId) async {
    return await (_db.select(_db.sections)
          ..where((t) => t.classId.equals(classId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<List<Section>> getActiveByClass(int classId) async {
    return await (_db.select(_db.sections)
          ..where((t) => t.classId.equals(classId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Future<Section?> getById(int id) async {
    return await (_db.select(
      _db.sections,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<SectionWithStats?> getWithStats(int id) async {
    final section = await getById(id);
    if (section == null) return null;

    final schoolClass = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(section.classId))).getSingleOrNull();

    final studentCount = await getStudentCount(id);
    final teacherName = await _getClassTeacherName(section.classTeacherId);

    return SectionWithStats(
      section: section,
      schoolClass: schoolClass,
      studentCount: studentCount,
      classTeacherName: teacherName,
    );
  }

  @override
  Future<List<SectionWithStats>> getAllWithStats() async {
    final sections = await getAllActive();
    final List<SectionWithStats> result = [];

    for (final section in sections) {
      final stats = await getWithStats(section.id);
      if (stats != null) {
        result.add(stats);
      }
    }

    return result;
  }

  @override
  Future<List<SectionWithStats>> getWithStatsByClass(int classId) async {
    final sections = await getActiveByClass(classId);
    final schoolClass = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(classId))).getSingleOrNull();

    final List<SectionWithStats> result = [];

    for (final section in sections) {
      final studentCount = await getStudentCount(section.id);
      final teacherName = await _getClassTeacherName(section.classTeacherId);

      result.add(
        SectionWithStats(
          section: section,
          schoolClass: schoolClass,
          studentCount: studentCount,
          classTeacherName: teacherName,
        ),
      );
    }

    return result;
  }

  Future<String?> _getClassTeacherName(int? staffId) async {
    if (staffId == null) return null;

    final staff = await (_db.select(
      _db.staff,
    )..where((t) => t.id.equals(staffId))).getSingleOrNull();

    if (staff == null) return null;
    return '${staff.firstName} ${staff.lastName}';
  }

  @override
  Future<int> getStudentCount(int sectionId) async {
    final count =
        await (_db.selectOnly(_db.enrollments)
              ..addColumns([_db.enrollments.id.count()])
              ..where(
                _db.enrollments.sectionId.equals(sectionId) &
                    _db.enrollments.isCurrent.equals(true) &
                    _db.enrollments.status.equals('active'),
              ))
            .map((row) => row.read(_db.enrollments.id.count()))
            .getSingle();
    return count ?? 0;
  }

  @override
  Future<int> create(SectionsCompanion sectionData) async {
    return await _db.into(_db.sections).insert(sectionData);
  }

  @override
  Future<bool> update(int id, SectionsCompanion sectionData) async {
    final updated =
        await (_db.update(_db.sections)..where((t) => t.id.equals(id))).write(
          sectionData.copyWith(updatedAt: Value(DateTime.now())),
        );
    return updated > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final updated =
        await (_db.update(_db.sections)..where((t) => t.id.equals(id))).write(
          const SectionsCompanion(isActive: Value(false)),
        );
    return updated > 0;
  }

  @override
  Future<bool> hardDelete(int id) async {
    final deleted = await (_db.delete(
      _db.sections,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<bool> assignClassTeacher(int sectionId, int? staffId) async {
    final updated =
        await (_db.update(
          _db.sections,
        )..where((t) => t.id.equals(sectionId))).write(
          SectionsCompanion(
            classTeacherId: Value(staffId),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return updated > 0;
  }

  @override
  Future<bool> isNameUnique(String name, int classId, {int? excludeId}) async {
    var query = _db.select(_db.sections)
      ..where(
        (t) =>
            t.name.lower().equals(name.toLowerCase()) &
            t.classId.equals(classId),
      );

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }

  @override
  Future<List<ClassSectionPair>> getClassSectionCombinations() async {
    // Get all active classes with their active sections
    final classes =
        await (_db.select(_db.classes)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
            .get();

    final List<ClassSectionPair> result = [];

    for (final schoolClass in classes) {
      final sections = await getActiveByClass(schoolClass.id);
      for (final section in sections) {
        result.add(
          ClassSectionPair(
            classId: schoolClass.id,
            sectionId: section.id,
            className: schoolClass.name,
            sectionName: section.name,
          ),
        );
      }
    }

    return result;
  }
}
