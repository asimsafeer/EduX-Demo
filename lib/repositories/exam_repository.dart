/// EduX School Management System
/// Exam Repository - Data access layer for examination management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Exam with class details
class ExamWithDetails {
  final Exam exam;
  final SchoolClass classInfo;
  final int subjectCount;
  final int markedStudents;
  final int totalStudents;

  const ExamWithDetails({
    required this.exam,
    required this.classInfo,
    required this.subjectCount,
    required this.markedStudents,
    required this.totalStudents,
  });

  /// Progress percentage for marks entry
  double get progressPercentage {
    if (totalStudents == 0 || subjectCount == 0) return 0;
    final total = totalStudents * subjectCount;
    return (markedStudents / total) * 100;
  }

  /// Whether all marks are entered
  bool get isComplete => markedStudents == (totalStudents * subjectCount);
}

/// Exam subject with subject details
class ExamSubjectWithDetails {
  final ExamSubject examSubject;
  final Subject subject;
  final int markedCount;
  final int totalStudents;

  const ExamSubjectWithDetails({
    required this.examSubject,
    required this.subject,
    required this.markedCount,
    required this.totalStudents,
  });

  /// Whether marks entry is complete for this subject
  bool get isComplete => markedCount == totalStudents;

  /// Progress percentage
  double get progressPercentage {
    if (totalStudents == 0) return 0;
    return (markedCount / totalStudents) * 100;
  }
}

class ExamFilters {
  final int? classId;
  final String? type;
  final String? status;
  final String? academicYear;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final int limit;
  final int offset;
  final List<int>? allowedClassIds;

  const ExamFilters({
    this.classId,
    this.type,
    this.status,
    this.academicYear,
    this.startDateFrom,
    this.startDateTo,
    this.limit = 50,
    this.offset = 0,
    this.allowedClassIds,
  });

  ExamFilters copyWith({
    int? classId,
    String? type,
    String? status,
    String? academicYear,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    int? limit,
    int? offset,
    List<int>? allowedClassIds,
    bool clearClassId = false,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return ExamFilters(
      classId: clearClassId ? null : (classId ?? this.classId),
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      academicYear: academicYear ?? this.academicYear,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      allowedClassIds: allowedClassIds ?? this.allowedClassIds,
    );
  }
}

/// Abstract exam repository interface
abstract class ExamRepository {
  // CRUD operations
  Future<Exam?> getById(int id);
  Future<Exam?> getByUuid(String uuid);
  Future<int> create(ExamsCompanion exam);
  Future<bool> update(int id, ExamsCompanion exam);
  Future<bool> delete(int id);

  // Query operations
  Future<List<ExamWithDetails>> getExams(ExamFilters filters);
  Future<ExamWithDetails?> getExamWithDetails(int examId);
  Future<List<Exam>> getExamsByClass(int classId, String academicYear);
  Future<List<Exam>> getExamsByStatus(String status);
  Future<List<Exam>> getActiveExams();

  // Status management
  Future<bool> updateStatus(int examId, String status);
  Future<bool> publishExam(int examId);
  Future<bool> completeExam(int examId);

  // Exam subjects
  Future<List<ExamSubjectWithDetails>> getExamSubjects(int examId);
  Future<ExamSubject?> getExamSubjectById(int id);
  Future<int> addExamSubject(ExamSubjectsCompanion subject);
  Future<void> addExamSubjects(List<ExamSubjectsCompanion> subjects);
  Future<bool> updateExamSubject(int id, ExamSubjectsCompanion subject);
  Future<bool> deleteExamSubject(int id);
  Future<void> deleteAllExamSubjects(int examId);

  // Statistics
  Future<int> countExamsByStatus(String status);
  Future<int> countExamsByClass(int classId, String academicYear);

  // Additional queries
  Future<List<Exam>> getAll();
  Future<List<ExamWithDetails>> getExamsNeedingMarksEntry();
}

/// Drift implementation of exam repository
class DriftExamRepository implements ExamRepository {
  final AppDatabase _db;

  DriftExamRepository(this._db);

  @override
  Future<Exam?> getById(int id) async {
    return await (_db.select(
      _db.exams,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Exam?> getByUuid(String uuid) async {
    return await (_db.select(
      _db.exams,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  @override
  Future<int> create(ExamsCompanion exam) async {
    return await _db.into(_db.exams).insert(exam);
  }

  @override
  Future<bool> update(int id, ExamsCompanion exam) async {
    return await (_db.update(
          _db.exams,
        )..where((t) => t.id.equals(id))).write(exam) >
        0;
  }

  @override
  Future<bool> delete(int id) async {
    return await (_db.delete(_db.exams)..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<List<ExamWithDetails>> getExams(ExamFilters filters) async {
    // Build the base query
    final query = _db.select(_db.exams).join([
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.exams.classId)),
    ]);

    // Apply allowed class restriction if provided
    if (filters.allowedClassIds != null) {
      if (filters.allowedClassIds!.isEmpty) {
        // Restricted to empty list -> return nothing
        return [];
      }
      query.where(_db.exams.classId.isIn(filters.allowedClassIds!));
    }

    // Apply filters
    if (filters.classId != null) {
      query.where(_db.exams.classId.equals(filters.classId!));
    }
    if (filters.type != null) {
      query.where(_db.exams.type.equals(filters.type!));
    }
    if (filters.status != null) {
      query.where(_db.exams.status.equals(filters.status!));
    }
    if (filters.academicYear != null) {
      query.where(_db.exams.academicYear.equals(filters.academicYear!));
    }
    if (filters.startDateFrom != null) {
      query.where(
        _db.exams.startDate.isBiggerOrEqualValue(filters.startDateFrom!),
      );
    }
    if (filters.startDateTo != null) {
      query.where(
        _db.exams.startDate.isSmallerOrEqualValue(filters.startDateTo!),
      );
    }

    // Order by date desc
    query.orderBy([OrderingTerm.desc(_db.exams.startDate)]);

    // Apply pagination
    query.limit(filters.limit, offset: filters.offset);

    final rows = await query.get();

    // Build result with additional info
    final results = <ExamWithDetails>[];
    for (final row in rows) {
      final exam = row.readTable(_db.exams);
      final classInfo = row.readTable(_db.classes);

      // Get subject count
      final subjectCount = await _getExamSubjectCount(exam.id);

      // Get marks progress
      final marksInfo = await _getMarksProgress(exam.id);

      results.add(
        ExamWithDetails(
          exam: exam,
          classInfo: classInfo,
          subjectCount: subjectCount,
          markedStudents: marksInfo.marked,
          totalStudents: marksInfo.total,
        ),
      );
    }

    return results;
  }

  @override
  Future<ExamWithDetails?> getExamWithDetails(int examId) async {
    final query = _db.select(_db.exams).join([
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.exams.classId)),
    ]);
    query.where(_db.exams.id.equals(examId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final exam = row.readTable(_db.exams);
    final classInfo = row.readTable(_db.classes);
    final subjectCount = await _getExamSubjectCount(exam.id);
    final marksInfo = await _getMarksProgress(exam.id);

    return ExamWithDetails(
      exam: exam,
      classInfo: classInfo,
      subjectCount: subjectCount,
      markedStudents: marksInfo.marked,
      totalStudents: marksInfo.total,
    );
  }

  @override
  Future<List<Exam>> getExamsByClass(int classId, String academicYear) async {
    return await (_db.select(_db.exams)
          ..where(
            (t) =>
                t.classId.equals(classId) & t.academicYear.equals(academicYear),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  @override
  Future<List<Exam>> getExamsByStatus(String status) async {
    return await (_db.select(_db.exams)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  @override
  Future<List<Exam>> getActiveExams() async {
    return await getExamsByStatus('active');
  }

  @override
  Future<bool> updateStatus(int examId, String status) async {
    return await (_db.update(
          _db.exams,
        )..where((t) => t.id.equals(examId))).write(
          ExamsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
          ),
        ) >
        0;
  }

  @override
  Future<bool> publishExam(int examId) async {
    return await updateStatus(examId, 'active');
  }

  @override
  Future<bool> completeExam(int examId) async {
    return await updateStatus(examId, 'completed');
  }

  @override
  Future<List<ExamSubjectWithDetails>> getExamSubjects(int examId) async {
    final query = _db.select(_db.examSubjects).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.examSubjects.subjectId),
      ),
    ]);
    query.where(_db.examSubjects.examId.equals(examId));
    query.orderBy([OrderingTerm.asc(_db.subjects.name)]);

    final rows = await query.get();

    // Get exam to find class for student count
    final exam = await getById(examId);
    if (exam == null) return [];

    // Get enrolled students count for the class
    final totalStudents = await _getEnrolledStudentCount(exam.classId);

    final results = <ExamSubjectWithDetails>[];
    for (final row in rows) {
      final examSubject = row.readTable(_db.examSubjects);
      final subject = row.readTable(_db.subjects);

      // Get marked count for this exam subject
      final markedCount = await _getMarkedCountForSubject(examSubject.id);

      results.add(
        ExamSubjectWithDetails(
          examSubject: examSubject,
          subject: subject,
          markedCount: markedCount,
          totalStudents: totalStudents,
        ),
      );
    }

    return results;
  }

  @override
  Future<ExamSubject?> getExamSubjectById(int id) async {
    return await (_db.select(
      _db.examSubjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<int> addExamSubject(ExamSubjectsCompanion subject) async {
    return await _db.into(_db.examSubjects).insert(subject);
  }

  @override
  Future<void> addExamSubjects(List<ExamSubjectsCompanion> subjects) async {
    await _db.batch((batch) {
      batch.insertAll(_db.examSubjects, subjects);
    });
  }

  @override
  Future<bool> updateExamSubject(int id, ExamSubjectsCompanion subject) async {
    return await (_db.update(
          _db.examSubjects,
        )..where((t) => t.id.equals(id))).write(subject) >
        0;
  }

  @override
  Future<bool> deleteExamSubject(int id) async {
    return await (_db.delete(
          _db.examSubjects,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<void> deleteAllExamSubjects(int examId) async {
    await (_db.delete(
      _db.examSubjects,
    )..where((t) => t.examId.equals(examId))).go();
  }

  @override
  Future<int> countExamsByStatus(String status) async {
    final count = _db.exams.id.count();
    final query = _db.selectOnly(_db.exams)
      ..addColumns([count])
      ..where(_db.exams.status.equals(status));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  @override
  Future<int> countExamsByClass(int classId, String academicYear) async {
    final count = _db.exams.id.count();
    final query = _db.selectOnly(_db.exams)
      ..addColumns([count])
      ..where(
        _db.exams.classId.equals(classId) &
            _db.exams.academicYear.equals(academicYear),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  Future<int> _getExamSubjectCount(int examId) async {
    final count = _db.examSubjects.id.count();
    final query = _db.selectOnly(_db.examSubjects)
      ..addColumns([count])
      ..where(_db.examSubjects.examId.equals(examId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<({int marked, int total})> _getMarksProgress(int examId) async {
    // Get total students * subjects
    final exam = await getById(examId);
    if (exam == null) return (marked: 0, total: 0);

    final totalStudents = await _getEnrolledStudentCount(exam.classId);
    final subjectCount = await _getExamSubjectCount(examId);
    final total = totalStudents * subjectCount;

    // Get marked count
    final markedCount = _db.studentMarks.id.count();
    final query = _db.selectOnly(_db.studentMarks)
      ..addColumns([markedCount])
      ..where(_db.studentMarks.examId.equals(examId));
    final result = await query.getSingle();
    final marked = result.read(markedCount) ?? 0;

    return (marked: marked, total: total);
  }

  Future<int> _getEnrolledStudentCount(int classId) async {
    // Get active enrollments for the class
    final count = _db.enrollments.id.count();
    final query = _db.selectOnly(_db.enrollments)
      ..addColumns([count])
      ..where(
        _db.enrollments.classId.equals(classId) &
            _db.enrollments.status.equals('active'),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> _getMarkedCountForSubject(int examSubjectId) async {
    final count = _db.studentMarks.id.count();
    final query = _db.selectOnly(_db.studentMarks)
      ..addColumns([count])
      ..where(_db.studentMarks.examSubjectId.equals(examSubjectId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  @override
  Future<List<Exam>> getAll() async {
    return await (_db.select(
      _db.exams,
    )..orderBy([(t) => OrderingTerm.desc(t.startDate)])).get();
  }

  @override
  Future<List<ExamWithDetails>> getExamsNeedingMarksEntry() async {
    // Get active or in_progress exams that have incomplete marks
    final filters = ExamFilters(status: 'active');
    final allActive = await getExams(filters);

    // Filter to those that are not complete
    return allActive.where((e) => !e.isComplete).toList();
  }
}
