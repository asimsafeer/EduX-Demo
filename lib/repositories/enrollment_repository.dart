/// EduX School Management System
/// Enrollment Repository - Data access layer for enrollment management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for enrollment with class and section info
class EnrollmentWithDetails {
  final Enrollment enrollment;
  final SchoolClass schoolClass;
  final Section section;

  EnrollmentWithDetails({
    required this.enrollment,
    required this.schoolClass,
    required this.section,
  });

  String get classSection => '${schoolClass.name} - ${section.name}';
}

/// Abstract enrollment repository interface
abstract class EnrollmentRepository {
  // Core operations
  Future<Enrollment?> getCurrentEnrollment(int studentId);
  Future<List<EnrollmentWithDetails>> getEnrollmentHistory(int studentId);
  Future<int> create(EnrollmentsCompanion enrollment);
  Future<bool> update(int id, EnrollmentsCompanion enrollment);

  // Status change operations
  Future<bool> promoteStudent(
    int studentId,
    int newClassId,
    int newSectionId,
    String newAcademicYear, {
    String? rollNumber,
  });
  Future<bool> transferStudent(int studentId, {required String reason});
  Future<bool> withdrawStudent(
    int studentId, {
    required String reason,
    DateTime? leavingDate,
  });
  Future<bool> activateStudent(
    int studentId,
    int classId,
    int sectionId,
    String academicYear,
  );

  // Query operations
  Future<int> getEnrollmentCount(int classId, int sectionId);
  Future<List<Enrollment>> getByAcademicYear(String academicYear);
  Future<String> generateNextRollNumber(int classId, int sectionId);
  Future<int> reassignRollNumbers(int classId, int sectionId);
}

/// Implementation of EnrollmentRepository using Drift database
class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final AppDatabase _db;

  EnrollmentRepositoryImpl(this._db);

  @override
  Future<Enrollment?> getCurrentEnrollment(int studentId) async {
    return await (_db.select(_db.enrollments)..where(
          (t) => t.studentId.equals(studentId) & t.isCurrent.equals(true),
        ))
        .getSingleOrNull();
  }

  @override
  Future<List<EnrollmentWithDetails>> getEnrollmentHistory(
    int studentId,
  ) async {
    final query =
        _db.select(_db.enrollments).join([
            innerJoin(
              _db.classes,
              _db.classes.id.equalsExp(_db.enrollments.classId),
            ),
            innerJoin(
              _db.sections,
              _db.sections.id.equalsExp(_db.enrollments.sectionId),
            ),
          ])
          ..where(_db.enrollments.studentId.equals(studentId))
          ..orderBy([OrderingTerm.desc(_db.enrollments.enrollmentDate)]);

    final results = await query.get();

    return results.map((row) {
      return EnrollmentWithDetails(
        enrollment: row.readTable(_db.enrollments),
        schoolClass: row.readTable(_db.classes),
        section: row.readTable(_db.sections),
      );
    }).toList();
  }

  @override
  Future<int> create(EnrollmentsCompanion enrollment) async {
    return await _db.into(_db.enrollments).insert(enrollment);
  }

  @override
  Future<bool> update(int id, EnrollmentsCompanion enrollment) async {
    final updated = enrollment.copyWith(updatedAt: Value(DateTime.now()));

    final rowsAffected = await (_db.update(
      _db.enrollments,
    )..where((t) => t.id.equals(id))).write(updated);

    return rowsAffected > 0;
  }

  @override
  Future<bool> promoteStudent(
    int studentId,
    int newClassId,
    int newSectionId,
    String newAcademicYear, {
    String? rollNumber,
  }) async {
    return await _db.transaction(() async {
      // Get current enrollment
      final currentEnrollment = await getCurrentEnrollment(studentId);

      if (currentEnrollment != null) {
        // End current enrollment
        await (_db.update(
          _db.enrollments,
        )..where((t) => t.id.equals(currentEnrollment.id))).write(
          EnrollmentsCompanion(
            isCurrent: const Value(false),
            status: const Value('promoted'),
            endDate: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // Create new enrollment
      final rollNo = rollNumber ?? await generateNextRollNumber(newClassId, newSectionId);

      await _db
          .into(_db.enrollments)
          .insert(
            EnrollmentsCompanion.insert(
              studentId: studentId,
              classId: newClassId,
              sectionId: newSectionId,
              academicYear: newAcademicYear,
              enrollmentDate: DateTime.now(),
              rollNumber: Value(rollNo),
              status: const Value('active'),
              isCurrent: const Value(true),
            ),
          );

      return true;
    });
  }

  @override
  Future<bool> transferStudent(int studentId, {required String reason}) async {
    return await _db.transaction(() async {
      // Get current enrollment
      final currentEnrollment = await getCurrentEnrollment(studentId);

      if (currentEnrollment != null) {
        // End current enrollment
        await (_db.update(
          _db.enrollments,
        )..where((t) => t.id.equals(currentEnrollment.id))).write(
          EnrollmentsCompanion(
            isCurrent: const Value(false),
            status: const Value('transferred'),
            endDate: Value(DateTime.now()),
            notes: Value(reason),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // Update student status
      await (_db.update(
        _db.students,
      )..where((t) => t.id.equals(studentId))).write(
        StudentsCompanion(
          status: const Value('transferred'),
          leavingDate: Value(DateTime.now()),
          leavingReason: Value(reason),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  @override
  Future<bool> withdrawStudent(
    int studentId, {
    required String reason,
    DateTime? leavingDate,
  }) async {
    final leaveDate = leavingDate ?? DateTime.now();

    return await _db.transaction(() async {
      // Get current enrollment
      final currentEnrollment = await getCurrentEnrollment(studentId);

      if (currentEnrollment != null) {
        // End current enrollment
        await (_db.update(
          _db.enrollments,
        )..where((t) => t.id.equals(currentEnrollment.id))).write(
          EnrollmentsCompanion(
            isCurrent: const Value(false),
            status: const Value('withdrawn'),
            endDate: Value(leaveDate),
            notes: Value(reason),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // Update student status
      await (_db.update(
        _db.students,
      )..where((t) => t.id.equals(studentId))).write(
        StudentsCompanion(
          status: const Value('withdrawn'),
          leavingDate: Value(leaveDate),
          leavingReason: Value(reason),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  @override
  Future<bool> activateStudent(
    int studentId,
    int classId,
    int sectionId,
    String academicYear,
  ) async {
    return await _db.transaction(() async {
      // Create new enrollment
      await _db
          .into(_db.enrollments)
          .insert(
            EnrollmentsCompanion.insert(
              studentId: studentId,
              classId: classId,
              sectionId: sectionId,
              academicYear: academicYear,
              enrollmentDate: DateTime.now(),
              status: const Value('active'),
              isCurrent: const Value(true),
            ),
          );

      // Update student status to active
      await (_db.update(
        _db.students,
      )..where((t) => t.id.equals(studentId))).write(
        StudentsCompanion(
          status: const Value('active'),
          leavingDate: const Value(null),
          leavingReason: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  @override
  Future<int> getEnrollmentCount(int classId, int sectionId) async {
    final result =
        await (_db.selectOnly(_db.enrollments)
              ..addColumns([_db.enrollments.id.count()])
              ..where(
                _db.enrollments.classId.equals(classId) &
                    _db.enrollments.sectionId.equals(sectionId) &
                    _db.enrollments.isCurrent.equals(true),
              ))
            .getSingle();

    return result.read(_db.enrollments.id.count()) ?? 0;
  }

  @override
  Future<List<Enrollment>> getByAcademicYear(String academicYear) async {
    return await (_db.select(_db.enrollments)..where(
          (t) => t.academicYear.equals(academicYear) & t.isCurrent.equals(true),
        ))
        .get();
  }

  @override
  Future<String> generateNextRollNumber(int classId, int sectionId) async {
    final query = _db.select(_db.enrollments)
      ..where((t) => t.classId.equals(classId) & t.sectionId.equals(sectionId))
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.rollNumber.cast<int>(),
              mode: OrderingMode.desc,
            ),
        (t) => OrderingTerm(
              expression: t.rollNumber,
              mode: OrderingMode.desc,
            ),
      ]);

    query.limit(1);
    final latestEnrollment = await query.getSingleOrNull();

    if (latestEnrollment == null || latestEnrollment.rollNumber == null) {
      return "1";
    }

    try {
      final lastNum = int.parse(latestEnrollment.rollNumber!);
      return (lastNum + 1).toString();
    } catch (_) {
      // If not numeric, just count total students and add 1
      final count = await getEnrollmentCount(classId, sectionId);
      return (count + 1).toString();
    }
  }

  @override
  Future<int> reassignRollNumbers(int classId, int sectionId) async {
    return await _db.transaction(() async {
      // Get all active enrollments for this class and section
      final query = _db.select(_db.enrollments).join([
        innerJoin(
          _db.students,
          _db.students.id.equalsExp(_db.enrollments.studentId),
        ),
      ]);

      query.where(
        _db.enrollments.classId.equals(classId) &
            _db.enrollments.sectionId.equals(sectionId) &
            _db.enrollments.isCurrent.equals(true),
      );

      // Order by student name primarily
      query.orderBy([OrderingTerm.asc(_db.students.studentName)]);

      final rows = await query.get();
      int count = 0;

      for (int i = 0; i < rows.length; i++) {
        final enrollment = rows[i].readTable(_db.enrollments);
        final newRollNumber = (i + 1).toString();

        // Only update if it changed
        if (enrollment.rollNumber != newRollNumber) {
          await (_db.update(_db.enrollments)..where((t) => t.id.equals(enrollment.id)))
              .write(EnrollmentsCompanion(rollNumber: Value(newRollNumber)));
          count++;
        }
      }

      return count;
    });
  }
}
