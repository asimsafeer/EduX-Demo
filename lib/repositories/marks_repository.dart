/// EduX School Management System
/// Marks Repository - Data access layer for student marks management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Student mark entry with full details
class StudentMarkEntry {
  final StudentMark? mark;
  final Student student;
  final Enrollment enrollment;
  final double maxMarks;
  final double passingMarks;

  const StudentMarkEntry({
    this.mark,
    required this.student,
    required this.enrollment,
    required this.maxMarks,
    required this.passingMarks,
  });

  /// Whether marks have been entered
  bool get isMarked => mark != null;

  /// Whether student is marked absent
  bool get isAbsent => mark?.isAbsent ?? false;

  /// Marks obtained (null if not marked or absent)
  double? get marksObtained => mark?.marksObtained;

  /// Percentage (null if not marked or absent)
  double? get percentage {
    if (marksObtained == null || maxMarks == 0) return null;
    return (marksObtained! / maxMarks) * 100;
  }

  /// Whether student passed
  bool? get isPassed {
    if (marksObtained == null) return null;
    return marksObtained! >= passingMarks;
  }

  /// Grade (from mark record)
  String? get grade => mark?.grade;

  /// Remarks
  String? get remarks => mark?.remarks;
}

/// Exam result for a student
class StudentExamResult {
  final Student student;
  final Enrollment enrollment;
  final List<SubjectResult> subjectResults;
  final double totalMarksObtained;
  final double totalMaxMarks;
  final double percentage;
  final String overallGrade;
  final double gpa;
  final int classRank;
  final bool isPassed;
  final String? teacherRemarks;
  final String? principalRemarks;

  const StudentExamResult({
    required this.student,
    required this.enrollment,
    required this.subjectResults,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
    required this.percentage,
    required this.overallGrade,
    required this.gpa,
    required this.classRank,
    required this.isPassed,
    this.teacherRemarks,
    this.principalRemarks,
  });
}

/// Result for a single subject
class SubjectResult {
  final Subject subject;
  final double maxMarks;
  final double passingMarks;
  final double? marksObtained;
  final bool isAbsent;
  final String? grade;
  final String? remarks;

  const SubjectResult({
    required this.subject,
    required this.maxMarks,
    required this.passingMarks,
    this.marksObtained,
    this.isAbsent = false,
    this.grade,
    this.remarks,
  });

  bool get isPassed {
    if (marksObtained == null || isAbsent) return false;
    return marksObtained! >= passingMarks;
  }

  double? get percentage {
    if (marksObtained == null || maxMarks == 0) return null;
    return (marksObtained! / maxMarks) * 100;
  }
}

/// Subject statistics for an exam
class ExamSubjectStats {
  final int examSubjectId;
  final Subject subject;
  final double maxMarks;
  final double passingMarks;
  final int totalStudents;
  final int markedStudents;
  final int absentStudents;
  final int passedStudents;
  final int failedStudents;
  final double? averageMarks;
  final double? highestMarks;
  final double? lowestMarks;

  const ExamSubjectStats({
    required this.examSubjectId,
    required this.subject,
    required this.maxMarks,
    required this.passingMarks,
    required this.totalStudents,
    required this.markedStudents,
    required this.absentStudents,
    required this.passedStudents,
    required this.failedStudents,
    this.averageMarks,
    this.highestMarks,
    this.lowestMarks,
  });

  double get passPercentage {
    if (markedStudents - absentStudents == 0) return 0;
    return (passedStudents / (markedStudents - absentStudents)) * 100;
  }

  double get markedPercentage {
    if (totalStudents == 0) return 0;
    return (markedStudents / totalStudents) * 100;
  }
}

/// Overall exam statistics
class ExamOverallStats {
  final int examId;
  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final int absentStudents;
  final double averagePercentage;
  final double highestPercentage;
  final double lowestPercentage;
  final Map<String, int> gradeDistribution;
  final List<ExamSubjectStats> subjectStats;

  const ExamOverallStats({
    required this.examId,
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.absentStudents,
    required this.averagePercentage,
    required this.highestPercentage,
    required this.lowestPercentage,
    required this.gradeDistribution,
    required this.subjectStats,
  });

  double get passPercentage {
    final appeared = totalStudents - absentStudents;
    if (appeared == 0) return 0;
    return (passedStudents / appeared) * 100;
  }
}

/// Abstract marks repository interface
abstract class MarksRepository {
  // CRUD operations
  Future<StudentMark?> getById(int id);
  Future<StudentMark?> getByStudentAndSubject(int studentId, int examSubjectId);
  Future<int> create(StudentMarksCompanion mark);
  Future<bool> update(int id, StudentMarksCompanion mark);
  Future<bool> delete(int id);

  // Upsert operations
  Future<int> upsert(StudentMarksCompanion mark);
  Future<void> upsertBatch(List<StudentMarksCompanion> marks);

  // Query operations
  Future<List<StudentMarkEntry>> getMarksForExamSubject({
    required int examId,
    required int examSubjectId,
    required int classId,
  });
  Future<List<StudentMark>> getMarksByStudent(int studentId);
  Future<List<StudentMark>> getMarksByExam(int examId);

  // Results operations
  Future<StudentExamResult?> getStudentExamResult({
    required int examId,
    required int studentId,
  });
  Future<List<StudentExamResult>> getExamResults(int examId);
  Future<List<StudentExamResult>> getClassRankings(int examId);

  // Statistics
  Future<ExamSubjectStats> getExamSubjectStats(int examSubjectId);
  Future<ExamOverallStats> getExamOverallStats(int examId);

  // Cached results
  Future<int> saveExamResult(ExamResultsCompanion result);
  Future<void> saveExamResults(List<ExamResultsCompanion> results);
  Future<ExamResult?> getCachedResult(int examId, int studentId);
  Future<void> clearCachedResults(int examId);
}

/// Drift implementation of marks repository
class DriftMarksRepository implements MarksRepository {
  final AppDatabase _db;

  DriftMarksRepository(this._db);

  @override
  Future<StudentMark?> getById(int id) async {
    return await (_db.select(
      _db.studentMarks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<StudentMark?> getByStudentAndSubject(
    int studentId,
    int examSubjectId,
  ) async {
    return await (_db.select(_db.studentMarks)..where(
          (t) =>
              t.studentId.equals(studentId) &
              t.examSubjectId.equals(examSubjectId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<int> create(StudentMarksCompanion mark) async {
    return await _db.into(_db.studentMarks).insert(mark);
  }

  @override
  Future<bool> update(int id, StudentMarksCompanion mark) async {
    return await (_db.update(
          _db.studentMarks,
        )..where((t) => t.id.equals(id))).write(mark) >
        0;
  }

  @override
  Future<bool> delete(int id) async {
    return await (_db.delete(
          _db.studentMarks,
        )..where((t) => t.id.equals(id))).go() >
        0;
  }

  @override
  Future<int> upsert(StudentMarksCompanion mark) async {
    return await _db.into(_db.studentMarks).insertOnConflictUpdate(mark);
  }

  @override
  Future<void> upsertBatch(List<StudentMarksCompanion> marks) async {
    await _db.batch((batch) {
      for (final mark in marks) {
        batch.insert(
          _db.studentMarks,
          mark,
          onConflict: DoUpdate(
            (old) => mark,
            target: [
              _db.studentMarks.examSubjectId,
              _db.studentMarks.studentId,
            ],
          ),
        );
      }
    });
  }

  @override
  Future<List<StudentMarkEntry>> getMarksForExamSubject({
    required int examId,
    required int examSubjectId,
    required int classId,
  }) async {
    // Get exam subject details
    final examSubject = await (_db.select(
      _db.examSubjects,
    )..where((t) => t.id.equals(examSubjectId))).getSingleOrNull();
    if (examSubject == null) return [];

    // Get all enrolled students for the class
    final enrollmentQuery = _db.select(_db.enrollments).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.enrollments.studentId),
      ),
    ]);
    enrollmentQuery.where(
      _db.enrollments.classId.equals(classId) &
          _db.enrollments.status.equals('active'),
    );
    enrollmentQuery.orderBy([OrderingTerm.asc(_db.students.admissionNumber)]);

    final enrollmentRows = await enrollmentQuery.get();

    // Get existing marks for this exam subject
    final existingMarks = await (_db.select(
      _db.studentMarks,
    )..where((t) => t.examSubjectId.equals(examSubjectId))).get();
    final marksByStudent = {for (var m in existingMarks) m.studentId: m};

    // Build entries
    final entries = <StudentMarkEntry>[];
    for (final row in enrollmentRows) {
      final student = row.readTable(_db.students);
      final enrollment = row.readTable(_db.enrollments);

      entries.add(
        StudentMarkEntry(
          mark: marksByStudent[student.id],
          student: student,
          enrollment: enrollment,
          maxMarks: examSubject.maxMarks,
          passingMarks: examSubject.passingMarks,
        ),
      );
    }

    return entries;
  }

  @override
  Future<List<StudentMark>> getMarksByStudent(int studentId) async {
    return await (_db.select(_db.studentMarks)
          ..where((t) => t.studentId.equals(studentId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  @override
  Future<List<StudentMark>> getMarksByExam(int examId) async {
    return await (_db.select(
      _db.studentMarks,
    )..where((t) => t.examId.equals(examId))).get();
  }

  @override
  Future<StudentExamResult?> getStudentExamResult({
    required int examId,
    required int studentId,
  }) async {
    // Get student info
    final studentQuery = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id),
      ),
    ]);
    studentQuery.where(_db.students.id.equals(studentId));
    final studentRow = await studentQuery.getSingleOrNull();
    if (studentRow == null) return null;

    final student = studentRow.readTable(_db.students);
    final enrollment = studentRow.readTable(_db.enrollments);

    // Get exam subjects with marks
    final subjectResults = await _getStudentSubjectResults(examId, studentId);
    if (subjectResults.isEmpty) return null;

    // Calculate totals
    double totalObtained = 0;
    double totalMax = 0;
    int passedSubjects = 0;
    bool hasAbsent = false;

    for (final result in subjectResults) {
      totalMax += result.maxMarks;
      if (result.isAbsent) {
        hasAbsent = true;
      } else if (result.marksObtained != null) {
        totalObtained += result.marksObtained!;
        if (result.isPassed) passedSubjects++;
      }
    }

    // Calculate percentage
    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

    // Get grade for percentage
    final gradeInfo = await _getGradeForPercentage(percentage);

    // Determine pass/fail (must pass all subjects)
    final isPassed = passedSubjects == subjectResults.length && !hasAbsent;

    // Get class rank
    final rank = await _getStudentRank(examId, studentId);

    // Get cached result for remarks if available
    final cachedResult = await getCachedResult(examId, studentId);

    return StudentExamResult(
      student: student,
      enrollment: enrollment,
      subjectResults: subjectResults,
      totalMarksObtained: totalObtained,
      totalMaxMarks: totalMax,
      percentage: percentage,
      overallGrade: gradeInfo?.grade ?? 'N/A',
      gpa: gradeInfo?.gpa ?? 0.0,
      classRank: rank,
      isPassed: isPassed,
      teacherRemarks: cachedResult?.teacherRemarks,
      principalRemarks: cachedResult?.principalRemarks,
    );
  }

  @override
  Future<List<StudentExamResult>> getExamResults(int examId) async {
    // Get exam subjects to know max marks
    final subjects = await (_db.select(_db.examSubjects).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.examSubjects.subjectId),
      ),
    ])..where(_db.examSubjects.examId.equals(examId))).get();

    // Get all marks for this exam
    final allMarks = await (_db.select(_db.studentMarks)
          ..where((t) => t.examId.equals(examId)))
        .get();

    // Group marks by student
    final marksByStudent = <int, List<StudentMark>>{};
    for (final mark in allMarks) {
      marksByStudent.putIfAbsent(mark.studentId, () => []).add(mark);
    }

    // Get all enrolled students for this class
    final exam = await (_db.select(_db.exams)
          ..where((t) => t.id.equals(examId)))
        .getSingleOrNull();
    if (exam == null) return [];

    final enrollmentQuery = _db.select(_db.enrollments).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.enrollments.studentId),
      ),
    ]);
    enrollmentQuery.where(
      _db.enrollments.classId.equals(exam.classId) &
          _db.enrollments.status.equals('active'),
    );
    final enrollmentRows = await enrollmentQuery.get();

    // Get all grades for calculations
    final grades = await (_db.select(_db.gradeSettings)
          ..orderBy([(t) => OrderingTerm.desc(t.minPercentage)]))
        .get();

    final results = <StudentExamResult>[];
    for (final row in enrollmentRows) {
      final student = row.readTable(_db.students);
      final enrollment = row.readTable(_db.enrollments);
      final studentMarks = marksByStudent[student.id] ?? [];
      final marksMap = {for (var m in studentMarks) m.examSubjectId: m};

      // Calculate subject results
      final subjectResults = <SubjectResult>[];
      double totalObtained = 0;
      double totalMax = 0;
      int passedSubjects = 0;
      bool hasAbsent = false;

      for (final sRow in subjects) {
        final es = sRow.readTable(_db.examSubjects);
        final sub = sRow.readTable(_db.subjects);
        final mark = marksMap[es.id];

        totalMax += es.maxMarks;
        if (mark?.isAbsent ?? false) {
          hasAbsent = true;
          subjectResults.add(
            SubjectResult(
              subject: sub,
              maxMarks: es.maxMarks,
              passingMarks: es.passingMarks,
              isAbsent: true,
            ),
          );
        } else {
          final obtained = mark?.marksObtained;
          if (obtained != null) {
            totalObtained += obtained;
            if (obtained >= es.passingMarks) passedSubjects++;
          }
          subjectResults.add(
            SubjectResult(
              subject: sub,
              maxMarks: es.maxMarks,
              passingMarks: es.passingMarks,
              marksObtained: obtained,
              grade: mark?.grade,
              remarks: mark?.remarks,
            ),
          );
        }
      }

      final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      final grade = grades.where(
        (g) => percentage >= g.minPercentage && percentage <= g.maxPercentage,
      ).firstOrNull;

      // determine if passed (must pass all subjects if subjects were entered)
      final isPassed = subjectResults.isNotEmpty && 
                       passedSubjects == subjectResults.length && 
                       !hasAbsent;

      // Get cached result for remarks if available
      final cachedResult = await getCachedResult(examId, student.id);

      results.add(
        StudentExamResult(
          student: student,
          enrollment: enrollment,
          subjectResults: subjectResults,
          totalMarksObtained: totalObtained,
          totalMaxMarks: totalMax,
          percentage: percentage,
          overallGrade: grade?.grade ?? 'N/A',
          gpa: grade?.gpa ?? 0.0,
          classRank: 0, // Will be set after sorting
          isPassed: isPassed,
          teacherRemarks: cachedResult?.teacherRemarks,
          principalRemarks: cachedResult?.principalRemarks,
        ),
      );
    }

    // Sort by percentage descending and assign ranks
    results.sort((a, b) => b.percentage.compareTo(a.percentage));
    for (int i = 0; i < results.length; i++) {
      final old = results[i];
      results[i] = StudentExamResult(
        student: old.student,
        enrollment: old.enrollment,
        subjectResults: old.subjectResults,
        totalMarksObtained: old.totalMarksObtained,
        totalMaxMarks: old.totalMaxMarks,
        percentage: old.percentage,
        overallGrade: old.overallGrade,
        gpa: old.gpa,
        classRank: i + 1,
        isPassed: old.isPassed,
        teacherRemarks: old.teacherRemarks,
        principalRemarks: old.principalRemarks,
      );
    }

    return results;
  }

  @override
  Future<List<StudentExamResult>> getClassRankings(int examId) async {
    final results = await getExamResults(examId);
    // Sort by admission number numerically for consistent display/printing
    results.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.student.admissionNumber);
      final bMatch = RegExp(r'\d+').firstMatch(b.student.admissionNumber);

      if (aMatch != null && bMatch != null) {
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        return aNum.compareTo(bNum);
      } else if (aMatch != null) {
        return -1;
      } else if (bMatch != null) {
        return 1;
      } else {
        return a.student.admissionNumber.compareTo(b.student.admissionNumber);
      }
    });
    return results;
  }

  @override
  Future<ExamSubjectStats> getExamSubjectStats(int examSubjectId) async {
    // Get exam subject with subject info
    final esQuery = _db.select(_db.examSubjects).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.examSubjects.subjectId),
      ),
    ]);
    esQuery.where(_db.examSubjects.id.equals(examSubjectId));
    final esRow = await esQuery.getSingle();

    final examSubject = esRow.readTable(_db.examSubjects);
    final subject = esRow.readTable(_db.subjects);

    // Get exam for class info
    final exam = await (_db.select(
      _db.exams,
    )..where((t) => t.id.equals(examSubject.examId))).getSingle();

    // Get total enrolled students
    final totalStudents = await _getEnrolledStudentCount(exam.classId);

    // Get marks for this subject
    final marks = await (_db.select(
      _db.studentMarks,
    )..where((t) => t.examSubjectId.equals(examSubjectId))).get();

    int markedStudents = marks.length;
    int absentStudents = marks.where((m) => m.isAbsent).length;
    int passedStudents = 0;
    int failedStudents = 0;
    double totalMarks = 0;
    double? highest;
    double? lowest;

    for (final mark in marks) {
      if (!mark.isAbsent && mark.marksObtained != null) {
        totalMarks += mark.marksObtained!;
        if (mark.marksObtained! >= examSubject.passingMarks) {
          passedStudents++;
        } else {
          failedStudents++;
        }
        if (highest == null || mark.marksObtained! > highest) {
          highest = mark.marksObtained;
        }
        if (lowest == null || mark.marksObtained! < lowest) {
          lowest = mark.marksObtained;
        }
      }
    }

    final appearedStudents = markedStudents - absentStudents;
    final average = appearedStudents > 0 ? totalMarks / appearedStudents : null;

    return ExamSubjectStats(
      examSubjectId: examSubjectId,
      subject: subject,
      maxMarks: examSubject.maxMarks,
      passingMarks: examSubject.passingMarks,
      totalStudents: totalStudents,
      markedStudents: markedStudents,
      absentStudents: absentStudents,
      passedStudents: passedStudents,
      failedStudents: failedStudents,
      averageMarks: average,
      highestMarks: highest,
      lowestMarks: lowest,
    );
  }

  @override
  Future<ExamOverallStats> getExamOverallStats(int examId) async {
    // Get exam subjects stats
    final examSubjects = await (_db.select(
      _db.examSubjects,
    )..where((t) => t.examId.equals(examId))).get();

    final subjectStats = <ExamSubjectStats>[];
    for (final es in examSubjects) {
      subjectStats.add(await getExamSubjectStats(es.id));
    }

    // Get exam results for overall stats
    final results = await getExamResults(examId);

    int passedStudents = 0;
    int failedStudents = 0;
    int absentStudents = 0;
    double totalPercentage = 0;
    double? highest;
    double? lowest;
    final gradeDistribution = <String, int>{};

    for (final result in results) {
      if (result.isPassed) {
        passedStudents++;
      } else {
        failedStudents++;
      }

      // Check if student was absent for all subjects
      if (result.subjectResults.every((s) => s.isAbsent)) {
        absentStudents++;
      } else {
        totalPercentage += result.percentage;
        if (highest == null || result.percentage > highest) {
          highest = result.percentage;
        }
        if (lowest == null || result.percentage < lowest) {
          lowest = result.percentage;
        }
      }

      // Count grades
      gradeDistribution[result.overallGrade] =
          (gradeDistribution[result.overallGrade] ?? 0) + 1;
    }

    final appearedStudents = results.length - absentStudents;
    final avgPercentage = appearedStudents > 0
        ? totalPercentage / appearedStudents
        : 0.0;

    return ExamOverallStats(
      examId: examId,
      totalStudents: results.length,
      passedStudents: passedStudents,
      failedStudents: failedStudents,
      absentStudents: absentStudents,
      averagePercentage: avgPercentage,
      highestPercentage: highest ?? 0,
      lowestPercentage: lowest ?? 0,
      gradeDistribution: gradeDistribution,
      subjectStats: subjectStats,
    );
  }

  @override
  Future<int> saveExamResult(ExamResultsCompanion result) async {
    return await _db.into(_db.examResults).insertOnConflictUpdate(result);
  }

  @override
  Future<void> saveExamResults(List<ExamResultsCompanion> results) async {
    await _db.batch((batch) {
      for (final result in results) {
        batch.insert(
          _db.examResults,
          result,
          onConflict: DoUpdate(
            (old) => result,
            target: [_db.examResults.examId, _db.examResults.studentId],
          ),
        );
      }
    });
  }

  @override
  Future<ExamResult?> getCachedResult(int examId, int studentId) async {
    return await (_db.select(_db.examResults)..where(
          (t) => t.examId.equals(examId) & t.studentId.equals(studentId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<void> clearCachedResults(int examId) async {
    await (_db.delete(
      _db.examResults,
    )..where((t) => t.examId.equals(examId))).go();
  }

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  Future<List<SubjectResult>> _getStudentSubjectResults(
    int examId,
    int studentId,
  ) async {
    // Get exam subjects with subject info
    final esQuery = _db.select(_db.examSubjects).join([
      innerJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.examSubjects.subjectId),
      ),
    ]);
    esQuery.where(_db.examSubjects.examId.equals(examId));
    esQuery.orderBy([OrderingTerm.asc(_db.subjects.name)]);

    final esRows = await esQuery.get();

    final results = <SubjectResult>[];
    for (final row in esRows) {
      final examSubject = row.readTable(_db.examSubjects);
      final subject = row.readTable(_db.subjects);

      // Get mark for this student and subject
      final mark = await getByStudentAndSubject(studentId, examSubject.id);

      results.add(
        SubjectResult(
          subject: subject,
          maxMarks: examSubject.maxMarks,
          passingMarks: examSubject.passingMarks,
          marksObtained: mark?.marksObtained,
          isAbsent: mark?.isAbsent ?? false,
          grade: mark?.grade,
          remarks: mark?.remarks,
        ),
      );
    }

    return results;
  }

  Future<GradeSetting?> _getGradeForPercentage(double percentage) async {
    return await (_db.select(_db.gradeSettings)
          ..where(
            (t) =>
                t.minPercentage.isSmallerOrEqualValue(percentage) &
                t.maxPercentage.isBiggerOrEqualValue(percentage),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> _getStudentRank(int examId, int studentId) async {
    // Get all results sorted by percentage
    final results = await getClassRankings(examId);

    // Find student's position
    for (int i = 0; i < results.length; i++) {
      if (results[i].student.id == studentId) {
        return i + 1;
      }
    }
    return 0;
  }

  Future<int> _getEnrolledStudentCount(int classId) async {
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
}
