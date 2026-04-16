/// EduX School Management System
/// Guardian Repository - Data access layer for guardian management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for guardian with student relationship info
class GuardianWithStudents {
  final Guardian guardian;
  final List<Student> students;
  final bool isPrimaryForAny;

  GuardianWithStudents({
    required this.guardian,
    this.students = const [],
    this.isPrimaryForAny = false,
  });

  String get fullName => '${guardian.firstName} ${guardian.lastName}';
}

/// Student-Guardian link info
class StudentGuardianLink {
  final Guardian guardian;
  final bool isPrimary;
  final bool canPickup;
  final bool isEmergencyContact;

  StudentGuardianLink({
    required this.guardian,
    this.isPrimary = false,
    this.canPickup = true,
    this.isEmergencyContact = false,
  });

  String get fullName => '${guardian.firstName} ${guardian.lastName}';
}

/// Abstract guardian repository interface
abstract class GuardianRepository {
  // Core CRUD operations
  Future<List<Guardian>> getAll();
  Future<Guardian?> getById(int id);
  Future<Guardian?> getByUuid(String uuid);
  Future<int> create(GuardiansCompanion guardian);
  Future<bool> update(int id, GuardiansCompanion guardian);
  Future<bool> delete(int id);

  // Student relationship operations
  Future<List<StudentGuardianLink>> getByStudentId(int studentId);
  Future<List<Student>> getStudentsByGuardianId(int guardianId);
  Future<void> linkToStudent(
    int studentId,
    int guardianId, {
    bool isPrimary = false,
    bool canPickup = true,
    bool isEmergencyContact = false,
  });
  Future<void> unlinkFromStudent(int studentId, int guardianId);
  Future<void> updateLink(
    int studentId,
    int guardianId, {
    bool? isPrimary,
    bool? canPickup,
    bool? isEmergencyContact,
  });

  // Search operations
  Future<List<Guardian>> search(String query);

  // Primary guardian operations
  Future<Guardian?> getPrimaryGuardian(int studentId);
  Future<void> setPrimaryGuardian(int studentId, int guardianId);
}

/// Implementation of GuardianRepository using Drift database
class GuardianRepositoryImpl implements GuardianRepository {
  final AppDatabase _db;

  GuardianRepositoryImpl(this._db);

  @override
  Future<List<Guardian>> getAll() async {
    return await (_db.select(
      _db.guardians,
    )..orderBy([(t) => OrderingTerm.asc(t.firstName)])).get();
  }

  @override
  Future<Guardian?> getById(int id) async {
    return await (_db.select(
      _db.guardians,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Guardian?> getByUuid(String uuid) async {
    return await (_db.select(
      _db.guardians,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  @override
  Future<int> create(GuardiansCompanion guardian) async {
    return await _db.into(_db.guardians).insert(guardian);
  }

  @override
  Future<bool> update(int id, GuardiansCompanion guardian) async {
    final updated = guardian.copyWith(updatedAt: Value(DateTime.now()));

    final rowsAffected = await (_db.update(
      _db.guardians,
    )..where((t) => t.id.equals(id))).write(updated);

    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    // First unlink from all students
    await (_db.delete(
      _db.studentGuardians,
    )..where((t) => t.guardianId.equals(id))).go();

    // Then delete the guardian
    final rowsAffected = await (_db.delete(
      _db.guardians,
    )..where((t) => t.id.equals(id))).go();

    return rowsAffected > 0;
  }

  @override
  Future<List<StudentGuardianLink>> getByStudentId(int studentId) async {
    final query =
        _db.select(_db.studentGuardians).join([
            innerJoin(
              _db.guardians,
              _db.guardians.id.equalsExp(_db.studentGuardians.guardianId),
            ),
          ])
          ..where(_db.studentGuardians.studentId.equals(studentId))
          ..orderBy([
            // Primary guardian first
            OrderingTerm.desc(_db.studentGuardians.isPrimary),
            OrderingTerm.asc(_db.guardians.firstName),
          ]);

    final results = await query.get();

    return results.map((row) {
      final link = row.readTable(_db.studentGuardians);
      final guardian = row.readTable(_db.guardians);

      return StudentGuardianLink(
        guardian: guardian,
        isPrimary: link.isPrimary,
        canPickup: link.canPickup,
        isEmergencyContact: link.isEmergencyContact,
      );
    }).toList();
  }

  @override
  Future<List<Student>> getStudentsByGuardianId(int guardianId) async {
    final query =
        _db.select(_db.studentGuardians).join([
            innerJoin(
              _db.students,
              _db.students.id.equalsExp(_db.studentGuardians.studentId),
            ),
          ])
          ..where(_db.studentGuardians.guardianId.equals(guardianId))
          ..orderBy([OrderingTerm.asc(_db.students.studentName)]);

    final results = await query.get();

    return results.map((row) => row.readTable(_db.students)).toList();
  }

  @override
  Future<void> linkToStudent(
    int studentId,
    int guardianId, {
    bool isPrimary = false,
    bool canPickup = true,
    bool isEmergencyContact = false,
  }) async {
    // If setting as primary, first unset other primaries for this student
    if (isPrimary) {
      await (_db.update(_db.studentGuardians)
            ..where((t) => t.studentId.equals(studentId)))
          .write(const StudentGuardiansCompanion(isPrimary: Value(false)));
    }

    // Insert or update the link
    await _db
        .into(_db.studentGuardians)
        .insertOnConflictUpdate(
          StudentGuardiansCompanion.insert(
            studentId: studentId,
            guardianId: guardianId,
            isPrimary: Value(isPrimary),
            canPickup: Value(canPickup),
            isEmergencyContact: Value(isEmergencyContact),
          ),
        );
  }

  @override
  Future<void> unlinkFromStudent(int studentId, int guardianId) async {
    await (_db.delete(_db.studentGuardians)..where(
          (t) =>
              t.studentId.equals(studentId) & t.guardianId.equals(guardianId),
        ))
        .go();
  }

  @override
  Future<void> updateLink(
    int studentId,
    int guardianId, {
    bool? isPrimary,
    bool? canPickup,
    bool? isEmergencyContact,
  }) async {
    // If setting as primary, first unset other primaries
    if (isPrimary == true) {
      await (_db.update(_db.studentGuardians)..where(
            (t) =>
                t.studentId.equals(studentId) &
                t.guardianId.equals(guardianId).not(),
          ))
          .write(const StudentGuardiansCompanion(isPrimary: Value(false)));
    }

    await (_db.update(_db.studentGuardians)..where(
          (t) =>
              t.studentId.equals(studentId) & t.guardianId.equals(guardianId),
        ))
        .write(
          StudentGuardiansCompanion(
            isPrimary: isPrimary != null
                ? Value(isPrimary)
                : const Value.absent(),
            canPickup: canPickup != null
                ? Value(canPickup)
                : const Value.absent(),
            isEmergencyContact: isEmergencyContact != null
                ? Value(isEmergencyContact)
                : const Value.absent(),
          ),
        );
  }

  @override
  Future<List<Guardian>> search(String query) async {
    if (query.isEmpty) return [];

    final searchTerm = '%${query.toLowerCase()}%';

    return await (_db.select(_db.guardians)
          ..where(
            (t) =>
                t.firstName.lower().like(searchTerm) |
                t.lastName.lower().like(searchTerm) |
                t.phone.lower().like(searchTerm) |
                t.cnic.lower().like(searchTerm),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.firstName)]))
        .get();
  }

  @override
  Future<Guardian?> getPrimaryGuardian(int studentId) async {
    final query =
        _db.select(_db.studentGuardians).join([
          innerJoin(
            _db.guardians,
            _db.guardians.id.equalsExp(_db.studentGuardians.guardianId),
          ),
        ])..where(
          _db.studentGuardians.studentId.equals(studentId) &
              _db.studentGuardians.isPrimary.equals(true),
        );

    final result = await query.getSingleOrNull();

    return result?.readTable(_db.guardians);
  }

  @override
  Future<void> setPrimaryGuardian(int studentId, int guardianId) async {
    // First unset all as primary for this student
    await (_db.update(_db.studentGuardians)
          ..where((t) => t.studentId.equals(studentId)))
        .write(const StudentGuardiansCompanion(isPrimary: Value(false)));

    // Then set the specified guardian as primary
    await (_db.update(_db.studentGuardians)..where(
          (t) =>
              t.studentId.equals(studentId) & t.guardianId.equals(guardianId),
        ))
        .write(const StudentGuardiansCompanion(isPrimary: Value(true)));
  }
}
