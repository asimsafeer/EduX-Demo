/// EduX School Management System
/// Class Subject Repository - Data access layer for class-subject assignments
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for class subject with full details
class ClassSubjectWithDetails {
  final ClassSubject classSubject;
  final Subject subject;
  final String? teacherName;
  final int? teacherId;

  ClassSubjectWithDetails({
    required this.classSubject,
    required this.subject,
    this.teacherName,
    this.teacherId,
  });

  String get displayName => '${subject.code} - ${subject.name}';
}

/// Data class for subject assignment info
class SubjectAssignmentInfo {
  final int classId;
  final String className;
  final String? teacherName;
  final int periodsPerWeek;

  SubjectAssignmentInfo({
    required this.classId,
    required this.className,
    this.teacherName,
    required this.periodsPerWeek,
  });
}

/// Abstract class subject repository interface
abstract class ClassSubjectRepository {
  /// Get all class-subject assignments
  Future<List<ClassSubject>> getAll();

  /// Get subjects assigned to a class for an academic year
  Future<List<ClassSubjectWithDetails>> getByClass(
    int classId,
    String academicYear,
  );

  /// Get classes that have a subject assigned
  Future<List<SubjectAssignmentInfo>> getBySubject(
    int subjectId,
    String academicYear,
  );

  /// Get a specific assignment by ID
  Future<ClassSubject?> getById(int id);

  /// Check if subject is already assigned to class
  Future<bool> isAssigned(int classId, int subjectId, String academicYear);

  /// Assign a subject to a class
  Future<int> assign(ClassSubjectsCompanion assignment);

  /// Remove a subject from a class
  Future<bool> unassign(int id);

  /// Assign a teacher to a class-subject
  Future<bool> assignTeacher(int id, int? teacherId);

  /// Update periods per week
  Future<bool> updatePeriodsPerWeek(int id, int periods);

  /// Bulk assign subjects to a class
  Future<void> bulkAssign(
    int classId,
    List<int> subjectIds,
    String academicYear,
  );

  /// Get unassigned subjects for a class
  Future<List<Subject>> getUnassignedSubjects(int classId, String academicYear);
}

/// Implementation of ClassSubjectRepository using Drift database
class ClassSubjectRepositoryImpl implements ClassSubjectRepository {
  final AppDatabase _db;

  ClassSubjectRepositoryImpl(this._db);

  @override
  Future<List<ClassSubject>> getAll() async {
    return await _db.select(_db.classSubjects).get();
  }

  @override
  Future<List<ClassSubjectWithDetails>> getByClass(
    int classId,
    String academicYear,
  ) async {
    final query =
        _db.select(_db.classSubjects).join([
            innerJoin(
              _db.subjects,
              _db.subjects.id.equalsExp(_db.classSubjects.subjectId),
            ),
          ])
          ..where(
            _db.classSubjects.classId.equals(classId) &
                _db.classSubjects.academicYear.equals(academicYear),
          )
          ..orderBy([OrderingTerm.asc(_db.subjects.name)]);

    final results = await query.get();
    final List<ClassSubjectWithDetails> detailedList = [];

    for (final row in results) {
      final classSubject = row.readTable(_db.classSubjects);
      final subject = row.readTable(_db.subjects);
      final teacherName = await _getTeacherName(classSubject.teacherId);

      detailedList.add(
        ClassSubjectWithDetails(
          classSubject: classSubject,
          subject: subject,
          teacherName: teacherName,
          teacherId: classSubject.teacherId,
        ),
      );
    }

    return detailedList;
  }

  @override
  Future<List<SubjectAssignmentInfo>> getBySubject(
    int subjectId,
    String academicYear,
  ) async {
    final query =
        _db.select(_db.classSubjects).join([
            innerJoin(
              _db.classes,
              _db.classes.id.equalsExp(_db.classSubjects.classId),
            ),
          ])
          ..where(
            _db.classSubjects.subjectId.equals(subjectId) &
                _db.classSubjects.academicYear.equals(academicYear),
          )
          ..orderBy([OrderingTerm.asc(_db.classes.displayOrder)]);

    final results = await query.get();
    final List<SubjectAssignmentInfo> infoList = [];

    for (final row in results) {
      final classSubject = row.readTable(_db.classSubjects);
      final schoolClass = row.readTable(_db.classes);
      final teacherName = await _getTeacherName(classSubject.teacherId);

      infoList.add(
        SubjectAssignmentInfo(
          classId: schoolClass.id,
          className: schoolClass.name,
          teacherName: teacherName,
          periodsPerWeek: classSubject.periodsPerWeek,
        ),
      );
    }

    return infoList;
  }

  Future<String?> _getTeacherName(int? staffId) async {
    if (staffId == null) return null;

    final staff = await (_db.select(
      _db.staff,
    )..where((t) => t.id.equals(staffId))).getSingleOrNull();

    if (staff == null) return null;
    return '${staff.firstName} ${staff.lastName}';
  }

  @override
  Future<ClassSubject?> getById(int id) async {
    return await (_db.select(
      _db.classSubjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<bool> isAssigned(
    int classId,
    int subjectId,
    String academicYear,
  ) async {
    final existing =
        await (_db.select(_db.classSubjects)..where(
              (t) =>
                  t.classId.equals(classId) &
                  t.subjectId.equals(subjectId) &
                  t.academicYear.equals(academicYear),
            ))
            .getSingleOrNull();
    return existing != null;
  }

  @override
  Future<int> assign(ClassSubjectsCompanion assignment) async {
    return await _db.into(_db.classSubjects).insert(assignment);
  }

  @override
  Future<bool> unassign(int id) async {
    final deleted = await (_db.delete(
      _db.classSubjects,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  @override
  Future<bool> assignTeacher(int id, int? teacherId) async {
    final updated =
        await (_db.update(_db.classSubjects)..where((t) => t.id.equals(id)))
            .write(ClassSubjectsCompanion(teacherId: Value(teacherId)));
    return updated > 0;
  }

  @override
  Future<bool> updatePeriodsPerWeek(int id, int periods) async {
    final updated =
        await (_db.update(_db.classSubjects)..where((t) => t.id.equals(id)))
            .write(ClassSubjectsCompanion(periodsPerWeek: Value(periods)));
    return updated > 0;
  }

  @override
  Future<void> bulkAssign(
    int classId,
    List<int> subjectIds,
    String academicYear,
  ) async {
    await _db.batch((batch) {
      for (final subjectId in subjectIds) {
        batch.insert(
          _db.classSubjects,
          ClassSubjectsCompanion.insert(
            classId: classId,
            subjectId: subjectId,
            academicYear: academicYear,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<List<Subject>> getUnassignedSubjects(
    int classId,
    String academicYear,
  ) async {
    // Get all active subjects
    final allSubjects =
        await (_db.select(_db.subjects)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();

    // Get already assigned subject IDs
    final assigned =
        await (_db.select(_db.classSubjects)..where(
              (t) =>
                  t.classId.equals(classId) &
                  t.academicYear.equals(academicYear),
            ))
            .get();

    final assignedIds = assigned.map((a) => a.subjectId).toSet();

    // Return unassigned subjects
    return allSubjects.where((s) => !assignedIds.contains(s.id)).toList();
  }
}
