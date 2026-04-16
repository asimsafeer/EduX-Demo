/// EduX School Management System
/// Staff Assignment Repository - Data access layer for teaching assignments
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for staff assignment with details
class StaffAssignmentWithDetails {
  final StaffSubjectAssignment assignment;
  final StaffData staff;
  final SchoolClass schoolClass;
  final Section? section;
  final Subject subject;

  const StaffAssignmentWithDetails({
    required this.assignment,
    required this.staff,
    required this.schoolClass,
    this.section,
    required this.subject,
  });

  String get staffName => '${staff.firstName} ${staff.lastName}'.trim();
  String get classSection => section != null
      ? '${schoolClass.name} - ${section!.name}'
      : schoolClass.name;
}

/// Teacher workload summary
class TeacherWorkload {
  final int staffId;
  final String staffName;
  final int totalClasses;
  final int totalSections;
  final int uniqueSubjects;
  final List<StaffAssignmentWithDetails> assignments;

  const TeacherWorkload({
    required this.staffId,
    required this.staffName,
    required this.totalClasses,
    required this.totalSections,
    required this.uniqueSubjects,
    required this.assignments,
  });
}

/// Abstract staff assignment repository interface
abstract class StaffAssignmentRepository {
  Future<StaffSubjectAssignment?> getById(int id);
  Future<StaffAssignmentWithDetails?> getByIdWithDetails(int id);

  Future<int> create(StaffSubjectAssignmentsCompanion assignment);
  Future<bool> update(int id, StaffSubjectAssignmentsCompanion assignment);
  Future<bool> delete(int id);

  Future<List<StaffAssignmentWithDetails>> getByStaff(
    int staffId, {
    String? academicYear,
  });
  Future<List<StaffAssignmentWithDetails>> getByClass(
    int classId, {
    int? sectionId,
    String? academicYear,
  });
  Future<List<StaffAssignmentWithDetails>> getBySubject(
    int subjectId, {
    String? academicYear,
  });

  Future<TeacherWorkload> getTeacherWorkload(
    int staffId, {
    required String academicYear,
  });

  Future<StaffData?> getClassTeacher(
    int classId,
    int sectionId, {
    required String academicYear,
  });

  Future<bool> assignmentExists(
    int staffId,
    int classId,
    int? sectionId,
    int subjectId,
    String academicYear,
  );

  Future<List<StaffAssignmentWithDetails>> getAllForYear(String academicYear);
}

/// Implementation of StaffAssignmentRepository using Drift database
class StaffAssignmentRepositoryImpl implements StaffAssignmentRepository {
  final AppDatabase _db;

  StaffAssignmentRepositoryImpl(this._db);

  @override
  Future<StaffSubjectAssignment?> getById(int id) async {
    return await (_db.select(
      _db.staffSubjectAssignments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<StaffAssignmentWithDetails?> getByIdWithDetails(int id) async {
    final query = _db.select(_db.staffSubjectAssignments).join([
      innerJoin(
        _db.staff,
        _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
      ),
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
      ),
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
      ),
    ])..where(_db.staffSubjectAssignments.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return StaffAssignmentWithDetails(
      assignment: result.readTable(_db.staffSubjectAssignments),
      staff: result.readTable(_db.staff),
      schoolClass: result.readTable(_db.classes),
      section: result.readTableOrNull(_db.sections),
      subject: result.readTable(_db.subjects),
    );
  }

  @override
  Future<int> create(StaffSubjectAssignmentsCompanion assignment) async {
    return await _db.into(_db.staffSubjectAssignments).insert(assignment);
  }

  @override
  Future<bool> update(
    int id,
    StaffSubjectAssignmentsCompanion assignment,
  ) async {
    final rowsAffected = await (_db.update(
      _db.staffSubjectAssignments,
    )..where((t) => t.id.equals(id))).write(assignment);
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_db.delete(
      _db.staffSubjectAssignments,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  @override
  Future<List<StaffAssignmentWithDetails>> getByStaff(
    int staffId, {
    String? academicYear,
  }) async {
    final query = _db.select(_db.staffSubjectAssignments).join([
      innerJoin(
        _db.staff,
        _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
      ),
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
      ),
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
      ),
    ])..where(_db.staffSubjectAssignments.staffId.equals(staffId));

    if (academicYear != null) {
      query.where(
        _db.staffSubjectAssignments.academicYear.equals(academicYear),
      );
    }

    query.orderBy([
      OrderingTerm.asc(_db.classes.displayOrder),
      OrderingTerm.asc(_db.sections.name),
      OrderingTerm.asc(_db.subjects.name),
    ]);

    final results = await query.get();
    return results.map((row) {
      return StaffAssignmentWithDetails(
        assignment: row.readTable(_db.staffSubjectAssignments),
        staff: row.readTable(_db.staff),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        subject: row.readTable(_db.subjects),
      );
    }).toList();
  }

  @override
  Future<List<StaffAssignmentWithDetails>> getByClass(
    int classId, {
    int? sectionId,
    String? academicYear,
  }) async {
    final query = _db.select(_db.staffSubjectAssignments).join([
      innerJoin(
        _db.staff,
        _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
      ),
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
      ),
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
      ),
    ])..where(_db.staffSubjectAssignments.classId.equals(classId));

    if (sectionId != null) {
      query.where(_db.staffSubjectAssignments.sectionId.equals(sectionId));
    }

    if (academicYear != null) {
      query.where(
        _db.staffSubjectAssignments.academicYear.equals(academicYear),
      );
    }

    query.orderBy([OrderingTerm.asc(_db.subjects.name)]);

    final results = await query.get();
    return results.map((row) {
      return StaffAssignmentWithDetails(
        assignment: row.readTable(_db.staffSubjectAssignments),
        staff: row.readTable(_db.staff),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        subject: row.readTable(_db.subjects),
      );
    }).toList();
  }

  @override
  Future<List<StaffAssignmentWithDetails>> getBySubject(
    int subjectId, {
    String? academicYear,
  }) async {
    final query = _db.select(_db.staffSubjectAssignments).join([
      innerJoin(
        _db.staff,
        _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
      ),
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
      ),
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
      ),
    ])..where(_db.staffSubjectAssignments.subjectId.equals(subjectId));

    if (academicYear != null) {
      query.where(
        _db.staffSubjectAssignments.academicYear.equals(academicYear),
      );
    }

    final results = await query.get();
    return results.map((row) {
      return StaffAssignmentWithDetails(
        assignment: row.readTable(_db.staffSubjectAssignments),
        staff: row.readTable(_db.staff),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        subject: row.readTable(_db.subjects),
      );
    }).toList();
  }

  @override
  Future<TeacherWorkload> getTeacherWorkload(
    int staffId, {
    required String academicYear,
  }) async {
    final assignments = await getByStaff(staffId, academicYear: academicYear);

    final staff = await (_db.select(
      _db.staff,
    )..where((t) => t.id.equals(staffId))).getSingleOrNull();

    final classIds = <int>{};
    final sectionIds = <int>{};
    final subjectIds = <int>{};

    for (final a in assignments) {
      classIds.add(a.schoolClass.id);
      if (a.section != null) sectionIds.add(a.section!.id);
      subjectIds.add(a.subject.id);
    }

    return TeacherWorkload(
      staffId: staffId,
      staffName: staff != null
          ? '${staff.firstName} ${staff.lastName}'.trim()
          : 'Unknown',
      totalClasses: classIds.length,
      totalSections: sectionIds.length,
      uniqueSubjects: subjectIds.length,
      assignments: assignments,
    );
  }

  @override
  Future<StaffData?> getClassTeacher(
    int classId,
    int sectionId, {
    required String academicYear,
  }) async {
    final query =
        _db.select(_db.staffSubjectAssignments).join([
          innerJoin(
            _db.staff,
            _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
          ),
        ])..where(
          _db.staffSubjectAssignments.classId.equals(classId) &
              _db.staffSubjectAssignments.sectionId.equals(sectionId) &
              _db.staffSubjectAssignments.academicYear.equals(academicYear) &
              _db.staffSubjectAssignments.isClassTeacher.equals(true),
        );

    final result = await query.getSingleOrNull();
    return result?.readTable(_db.staff);
  }

  @override
  Future<bool> assignmentExists(
    int staffId,
    int classId,
    int? sectionId,
    int subjectId,
    String academicYear,
  ) async {
    var query = _db.select(_db.staffSubjectAssignments)
      ..where(
        (t) =>
            t.staffId.equals(staffId) &
            t.classId.equals(classId) &
            t.subjectId.equals(subjectId) &
            t.academicYear.equals(academicYear),
      );

    if (sectionId != null) {
      query = query..where((t) => t.sectionId.equals(sectionId));
    } else {
      query = query..where((t) => t.sectionId.isNull());
    }

    final results = await query.get();
    return results.isNotEmpty;
  }

  @override
  Future<List<StaffAssignmentWithDetails>> getAllForYear(
    String academicYear,
  ) async {
    final query =
        _db.select(_db.staffSubjectAssignments).join([
            innerJoin(
              _db.staff,
              _db.staff.id.equalsExp(_db.staffSubjectAssignments.staffId),
            ),
            innerJoin(
              _db.classes,
              _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
            ),
            leftOuterJoin(
              _db.sections,
              _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
            ),
            innerJoin(
              _db.subjects,
              _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
            ),
          ])
          ..where(_db.staffSubjectAssignments.academicYear.equals(academicYear))
          ..orderBy([
            OrderingTerm.asc(_db.staff.firstName),
            OrderingTerm.asc(_db.classes.displayOrder),
          ]);

    final results = await query.get();
    return results.map((row) {
      return StaffAssignmentWithDetails(
        assignment: row.readTable(_db.staffSubjectAssignments),
        staff: row.readTable(_db.staff),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
        subject: row.readTable(_db.subjects),
      );
    }).toList();
  }
}
