/// EduX School Management System
/// Student Repository - Data access layer for student management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for student with current enrollment information
class StudentWithEnrollment {
  final Student student;
  final Enrollment? currentEnrollment;
  final SchoolClass? schoolClass;
  final Section? section;

  StudentWithEnrollment({
    required this.student,
    this.currentEnrollment,
    this.schoolClass,
    this.section,
  });

  String get fullName => '${student.studentName} ${student.fatherName ?? ''}';

  String get classSection {
    if (schoolClass == null) return 'Not Enrolled';
    if (section == null) return schoolClass!.name;
    return '${schoolClass!.name} - ${section!.name}';
  }
}

/// Student filter parameters
class StudentFilters {
  final String? searchQuery;
  final int? classId;
  final int? sectionId;
  final String? gender;
  final String? status;
  final DateTime? admissionFrom;
  final DateTime? admissionTo;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final String sortBy;
  final bool ascending;
  final int limit;
  final int offset;

  const StudentFilters({
    this.searchQuery,
    this.classId,
    this.sectionId,
    this.gender,
    this.status,
    this.admissionFrom,
    this.admissionTo,
    this.createdFrom,
    this.createdTo,
    this.sortBy = 'studentName',
    this.ascending = true,
    this.limit = 25,
    this.offset = 0,
  });

  StudentFilters copyWith({
    String? searchQuery,
    int? classId,
    int? sectionId,
    String? gender,
    String? status,
    DateTime? admissionFrom,
    DateTime? admissionTo,
    DateTime? createdFrom,
    DateTime? createdTo,
    String? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
    bool clearSearch = false,
    bool clearClassId = false,
    bool clearSectionId = false,
    bool clearGender = false,
    bool clearStatus = false,
    bool clearAdmissionDate = false,
    bool clearCreatedDate = false,
  }) {
    return StudentFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      classId: clearClassId ? null : (classId ?? this.classId),
      sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
      gender: clearGender ? null : (gender ?? this.gender),
      status: clearStatus ? null : (status ?? this.status),
      admissionFrom: clearAdmissionDate ? null : (admissionFrom ?? this.admissionFrom),
      admissionTo: clearAdmissionDate ? null : (admissionTo ?? this.admissionTo),
      createdFrom: clearCreatedDate ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearCreatedDate ? null : (createdTo ?? this.createdTo),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  StudentFilters clearAll() {
    return StudentFilters(
      sortBy: sortBy,
      ascending: ascending,
      limit: limit,
      offset: 0,
    );
  }

  bool get hasFilters =>
      searchQuery != null ||
      classId != null ||
      sectionId != null ||
      gender != null ||
      status != null ||
      admissionFrom != null ||
      admissionTo != null ||
      createdFrom != null ||
      createdTo != null;
}

/// Abstract student repository interface
abstract class StudentRepository {
  // Core CRUD operations
  Future<List<Student>> getAll({int? limit, int? offset});
  Future<Student?> getById(int id);
  Future<Student?> getByUuid(String uuid);
  Future<Student?> getByAdmissionNumber(String admissionNumber);
  Future<int> create(StudentsCompanion student);
  Future<bool> update(int id, StudentsCompanion student);
  Future<bool> delete(int id);
  Future<int> deleteMultiple(List<int> ids);
  Future<int> bulkUpdateStatus(List<int> ids, String status);

  // Search and filter operations
  Future<List<StudentWithEnrollment>> search(StudentFilters filters);

  // Counting operations
  Future<int> count({
    int? classId,
    int? sectionId,
    String? status,
    DateTime? admissionFrom,
    DateTime? admissionTo,
  });

  // Enrollment-related queries
  Future<StudentWithEnrollment?> getWithCurrentEnrollment(int studentId);
  Future<List<StudentWithEnrollment>> getByClassSection(
    int classId,
    int sectionId,
  );

  // Admission number
  Future<String> generateAdmissionNumber();
  Future<bool> isAdmissionNumberUnique(
    String admissionNumber, {
    int? excludeId,
  });
}

/// Implementation of StudentRepository using Drift database
class StudentRepositoryImpl implements StudentRepository {
  final AppDatabase _db;

  StudentRepositoryImpl(this._db);

  @override
  Future<List<Student>> getAll({int? limit, int? offset}) async {
    var query = _db.select(_db.students)
      ..orderBy([(t) => OrderingTerm.asc(t.studentName)]);

    if (limit != null) {
      query = query..limit(limit, offset: offset);
    }

    return await query.get();
  }

  @override
  Future<Student?> getById(int id) async {
    return await (_db.select(
      _db.students,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Student?> getByUuid(String uuid) async {
    return await (_db.select(
      _db.students,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  @override
  Future<Student?> getByAdmissionNumber(String admissionNumber) async {
    return await (_db.select(_db.students)
          ..where((t) => t.admissionNumber.equals(admissionNumber)))
        .getSingleOrNull();
  }

  @override
  Future<int> create(StudentsCompanion student) async {
    return await _db.into(_db.students).insert(student);
  }

  @override
  Future<bool> update(int id, StudentsCompanion student) async {
    final updatedStudent = student.copyWith(updatedAt: Value(DateTime.now()));

    final rowsAffected = await (_db.update(
      _db.students,
    )..where((t) => t.id.equals(id))).write(updatedStudent);

    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_db.delete(
      _db.students,
    )..where((t) => t.id.equals(id))).go();

    return rowsAffected > 0;
  }

  @override
  Future<int> deleteMultiple(List<int> ids) async {
    return await (_db.delete(_db.students)..where((t) => t.id.isIn(ids))).go();
  }

  @override
  Future<int> bulkUpdateStatus(List<int> ids, String status) async {
    return await (_db.update(_db.students)..where((t) => t.id.isIn(ids))).write(
      StudentsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<StudentWithEnrollment>> search(StudentFilters filters) async {
    final query = _db.select(_db.students, distinct: true).join([
      leftOuterJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      leftOuterJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.enrollments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
    ]);

    // Build WHERE conditions
    Expression<bool>? whereCondition;

    // Search query - match name or admission number
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final searchTerm = '%${filters.searchQuery!.toLowerCase()}%';
      final searchCondition =
          _db.students.studentName.lower().like(searchTerm) |
          _db.students.fatherName.lower().like(searchTerm) |
          _db.students.admissionNumber.lower().like(searchTerm);

      whereCondition = searchCondition;
    }

    // Class filter
    if (filters.classId != null) {
      final classCondition = _db.enrollments.classId.equals(filters.classId!);
      whereCondition = whereCondition == null
          ? classCondition
          : whereCondition & classCondition;
    }

    // Section filter
    if (filters.sectionId != null) {
      final sectionCondition = _db.enrollments.sectionId.equals(
        filters.sectionId!,
      );
      whereCondition = whereCondition == null
          ? sectionCondition
          : whereCondition & sectionCondition;
    }

    // Gender filter
    if (filters.gender != null && filters.gender!.isNotEmpty) {
      final genderCondition = _db.students.gender.equals(filters.gender!);
      whereCondition = whereCondition == null
          ? genderCondition
          : whereCondition & genderCondition;
    }

    // Status filter
    if (filters.status != null && filters.status!.isNotEmpty) {
      final statusCondition = _db.students.status.equals(filters.status!);
      whereCondition = whereCondition == null
          ? statusCondition
          : whereCondition & statusCondition;
    }

    // Admission date range filter
    if (filters.admissionFrom != null) {
      final fromCondition = _db.students.admissionDate.isBiggerOrEqualValue(
        filters.admissionFrom!,
      );
      whereCondition = whereCondition == null
          ? fromCondition
          : whereCondition & fromCondition;
    }

    if (filters.admissionTo != null) {
      // Set to end of day for inclusive filtering
      final toDate = DateTime(
        filters.admissionTo!.year,
        filters.admissionTo!.month,
        filters.admissionTo!.day,
        23, 59, 59,
      );
      final toCondition = _db.students.admissionDate.isSmallerOrEqualValue(toDate);
      whereCondition = whereCondition == null
          ? toCondition
          : whereCondition & toCondition;
    }

    // Created date range filter
    if (filters.createdFrom != null) {
      final fromCondition = _db.students.createdAt.isBiggerOrEqualValue(
        filters.createdFrom!,
      );
      whereCondition = whereCondition == null
          ? fromCondition
          : whereCondition & fromCondition;
    }

    if (filters.createdTo != null) {
      final toDate = DateTime(
        filters.createdTo!.year,
        filters.createdTo!.month,
        filters.createdTo!.day,
        23, 59, 59,
      );
      final toCondition = _db.students.createdAt.isSmallerOrEqualValue(toDate);
      whereCondition = whereCondition == null
          ? toCondition
          : whereCondition & toCondition;
    }

    if (whereCondition != null) {
      query.where(whereCondition);
    }

    // Apply sorting
    final sortColumn = _getSortColumn(filters.sortBy);
    query.orderBy([
      if (filters.ascending)
        OrderingTerm.asc(sortColumn)
      else
        OrderingTerm.desc(sortColumn),
    ]);

    // Apply pagination (use 0 or negative limit for no limit)
    if (filters.limit > 0) {
      query.limit(filters.limit, offset: filters.offset);
    }

    // Execute query and map results
    final results = await query.get();

    return results.map((row) {
      return StudentWithEnrollment(
        student: row.readTable(_db.students),
        currentEnrollment: row.readTableOrNull(_db.enrollments),
        schoolClass: row.readTableOrNull(_db.classes),
        section: row.readTableOrNull(_db.sections),
      );
    }).toList();
  }

  GeneratedColumn _getSortColumn(String sortBy) {
    switch (sortBy) {
      case 'admissionNumber':
        return _db.students.admissionNumber;
      case 'fatherName':
        return _db.students.fatherName;
      case 'admissionDate':
        return _db.students.admissionDate;
      case 'createdAt':
        return _db.students.createdAt;
      case 'status':
        return _db.students.status;
      case 'rollNumber':
        return _db.enrollments.rollNumber;
      case 'studentName':
      default:
        return _db.students.studentName;
    }
  }

  @override
  Future<int> count({
    int? classId,
    int? sectionId,
    String? status,
    DateTime? admissionFrom,
    DateTime? admissionTo,
  }) async {
    final countExp = _db.students.id.count(distinct: true);

    // Simple count without class/section filter
    if (classId == null && sectionId == null) {
      final query = _db.selectOnly(_db.students)..addColumns([countExp]);

      if (status != null) {
        query.where(_db.students.status.equals(status));
      }
      if (admissionFrom != null) {
        query.where(
          _db.students.admissionDate.isBiggerOrEqualValue(admissionFrom),
        );
      }
      if (admissionTo != null) {
        query.where(
          _db.students.admissionDate.isSmallerOrEqualValue(admissionTo),
        );
      }

      final row = await query.getSingle();
      return row.read(countExp) ?? 0;
    }

    // Count with class/section filter - need to join
    final query = _db.selectOnly(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
    ]);
    query.addColumns([countExp]);

    Expression<bool>? whereCondition;

    if (classId != null) {
      whereCondition = _db.enrollments.classId.equals(classId);
    }

    if (sectionId != null) {
      final sectionCondition = _db.enrollments.sectionId.equals(sectionId);
      whereCondition = whereCondition == null
          ? sectionCondition
          : whereCondition & sectionCondition;
    }

    if (status != null) {
      final statusCondition = _db.students.status.equals(status);
      whereCondition = whereCondition == null
          ? statusCondition
          : whereCondition & statusCondition;
    }

    if (admissionFrom != null) {
      final fromCondition = _db.students.admissionDate.isBiggerOrEqualValue(
        admissionFrom,
      );
      whereCondition = whereCondition == null
          ? fromCondition
          : whereCondition & fromCondition;
    }

    if (admissionTo != null) {
      final toCondition = _db.students.admissionDate.isSmallerOrEqualValue(
        admissionTo,
      );
      whereCondition = whereCondition == null
          ? toCondition
          : whereCondition & toCondition;
    }

    if (whereCondition != null) {
      query.where(whereCondition);
    }

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<StudentWithEnrollment?> getWithCurrentEnrollment(int studentId) async {
    final query = _db.select(_db.students).join([
      leftOuterJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      leftOuterJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.enrollments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
    ])..where(_db.students.id.equals(studentId));

    final result = await query.getSingleOrNull();

    if (result == null) return null;

    return StudentWithEnrollment(
      student: result.readTable(_db.students),
      currentEnrollment: result.readTableOrNull(_db.enrollments),
      schoolClass: result.readTableOrNull(_db.classes),
      section: result.readTableOrNull(_db.sections),
    );
  }

  @override
  Future<List<StudentWithEnrollment>> getByClassSection(
    int classId,
    int sectionId,
  ) async {
    final query =
        _db.select(_db.students).join([
            innerJoin(
              _db.enrollments,
              _db.enrollments.studentId.equalsExp(_db.students.id) &
                  _db.enrollments.isCurrent.equals(true),
            ),
            innerJoin(
              _db.classes,
              _db.classes.id.equalsExp(_db.enrollments.classId),
            ),
            innerJoin(
              _db.sections,
              _db.sections.id.equalsExp(_db.enrollments.sectionId),
            ),
          ])
          ..where(
            _db.enrollments.classId.equals(classId) &
                _db.enrollments.sectionId.equals(sectionId) &
                _db.students.status.equals('active'),
          )
          ..orderBy([OrderingTerm.asc(_db.students.studentName)]);

    final results = await query.get();

    return results.map((row) {
      return StudentWithEnrollment(
        student: row.readTable(_db.students),
        currentEnrollment: row.readTable(_db.enrollments),
        schoolClass: row.readTable(_db.classes),
        section: row.readTable(_db.sections),
      );
    }).toList();
  }

  @override
  Future<String> generateAdmissionNumber() async {
    // Get sequence from number_sequences table
    final sequence = await (_db.select(
      _db.numberSequences,
    )..where((t) => t.name.equals('admission'))).getSingleOrNull();

    if (sequence == null) {
      // Create sequence if not exists
      await _db
          .into(_db.numberSequences)
          .insert(
            NumberSequencesCompanion.insert(
              name: 'admission',
              prefix: const Value('ADM-'),
              currentNumber: const Value(1),
              minDigits: const Value(5),
            ),
          );
      return 'ADM-00001';
    }

    // Increment and get new number
    final nextNumber = sequence.currentNumber + 1;
    final paddedNumber = nextNumber.toString().padLeft(sequence.minDigits, '0');

    // Update sequence
    await (_db.update(_db.numberSequences)
          ..where((t) => t.name.equals('admission')))
        .write(NumberSequencesCompanion(currentNumber: Value(nextNumber)));

    return '${sequence.prefix}$paddedNumber';
  }

  @override
  Future<bool> isAdmissionNumberUnique(
    String admissionNumber, {
    int? excludeId,
  }) async {
    var query = _db.select(_db.students)
      ..where((t) => t.admissionNumber.equals(admissionNumber));

    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }

    final existing = await query.getSingleOrNull();
    return existing == null;
  }
}
