/// EduX School Management System
/// Exam Service - Business logic for examination operations
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../repositories/exam_repository.dart';
import '../repositories/marks_repository.dart';
import '../repositories/grade_repository.dart';
import '../core/constants/app_constants.dart';

/// Result of exam validation
class ExamValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  const ExamValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });

  factory ExamValidationResult.valid({List<String> warnings = const []}) {
    return ExamValidationResult(isValid: true, warnings: warnings);
  }

  factory ExamValidationResult.invalid(String errorMessage) {
    return ExamValidationResult(isValid: false, errorMessage: errorMessage);
  }
}

/// Result of marks validation
class MarksValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  const MarksValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });

  factory MarksValidationResult.valid({List<String> warnings = const []}) {
    return MarksValidationResult(isValid: true, warnings: warnings);
  }

  factory MarksValidationResult.invalid(String errorMessage) {
    return MarksValidationResult(isValid: false, errorMessage: errorMessage);
  }
}

/// Data for creating an exam
class ExamCreationData {
  final String name;
  final String type;
  final int classId;
  final String academicYear;
  final DateTime startDate;
  final DateTime? endDate;
  final String? description;
  final List<ExamSubjectData> subjects;
  final String status;

  const ExamCreationData({
    required this.name,
    required this.type,
    required this.classId,
    required this.academicYear,
    required this.startDate,
    this.endDate,
    this.description,
    required this.subjects,
    this.status = 'draft',
  });
}

/// Data for exam subject configuration
class ExamSubjectData {
  final int subjectId;
  final double maxMarks;
  final double passingMarks;
  final DateTime? examDate;
  final String? examTime;
  final int? durationMinutes;

  const ExamSubjectData({
    required this.subjectId,
    required this.maxMarks,
    required this.passingMarks,
    this.examDate,
    this.examTime,
    this.durationMinutes,
  });
}

/// Data for entering marks
class MarkEntryData {
  final int studentId;
  final double? marksObtained;
  final bool isAbsent;
  final String? remarks;

  const MarkEntryData({
    required this.studentId,
    this.marksObtained,
    this.isAbsent = false,
    this.remarks,
  });
}

/// Batch marks entry result
class BatchMarksResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const BatchMarksResult({
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
  });

  bool get isComplete => failureCount == 0;
}

/// Exam service for business logic
class ExamService {
  final AppDatabase _db;
  final ExamRepository _examRepo;
  final MarksRepository _marksRepo;
  final GradeRepository _gradeRepo;
  final Uuid _uuid = const Uuid();

  ExamService(this._db, this._examRepo, this._marksRepo, this._gradeRepo);

  // ============================================
  // EXAM VALIDATION
  // ============================================

  /// Validate exam creation data
  ExamValidationResult validateExamCreation(ExamCreationData data) {
    final warnings = <String>[];

    // Validate name
    if (data.name.trim().isEmpty) {
      return ExamValidationResult.invalid('Exam name is required');
    }
    if (data.name.length > 100) {
      return ExamValidationResult.invalid(
        'Exam name must be 100 characters or less',
      );
    }

    // Validate type
    if (!ExamConstants.types.contains(data.type)) {
      return ExamValidationResult.invalid('Invalid exam type');
    }

    // Validate dates
    if (data.endDate != null && data.endDate!.isBefore(data.startDate)) {
      return ExamValidationResult.invalid('End date must be after start date');
    }

    // Check if start date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (data.startDate.isBefore(today)) {
      warnings.add('Start date is in the past');
    }

    // Validate subjects
    if (data.subjects.isEmpty) {
      return ExamValidationResult.invalid('At least one subject is required');
    }

    for (final subject in data.subjects) {
      final subjectValidation = _validateSubjectData(subject);
      if (!subjectValidation.isValid) {
        return subjectValidation;
      }
    }

    // Check for duplicate subjects
    final subjectIds = data.subjects.map((s) => s.subjectId).toSet();
    if (subjectIds.length != data.subjects.length) {
      return ExamValidationResult.invalid('Duplicate subjects are not allowed');
    }

    return ExamValidationResult.valid(warnings: warnings);
  }

  ExamValidationResult _validateSubjectData(ExamSubjectData data) {
    if (data.maxMarks <= 0) {
      return ExamValidationResult.invalid(
        'Maximum marks must be greater than 0',
      );
    }
    if (data.passingMarks < 0) {
      return ExamValidationResult.invalid('Passing marks cannot be negative');
    }
    if (data.passingMarks > data.maxMarks) {
      return ExamValidationResult.invalid(
        'Passing marks cannot exceed maximum marks',
      );
    }
    if (data.durationMinutes != null && data.durationMinutes! <= 0) {
      return ExamValidationResult.invalid('Duration must be positive');
    }
    return ExamValidationResult.valid();
  }

  /// Validate marks entry
  MarksValidationResult validateMarksEntry({
    required double? marks,
    required bool isAbsent,
    required double maxMarks,
    required double passingMarks,
  }) {
    final warnings = <String>[];

    // Either marks or absent must be set
    if (!isAbsent && marks == null) {
      return MarksValidationResult.invalid(
        'Either marks or absent status must be set',
      );
    }

    if (isAbsent && marks != null) {
      return MarksValidationResult.invalid(
        'Cannot enter marks for absent student',
      );
    }

    if (marks != null) {
      if (marks < 0) {
        return MarksValidationResult.invalid('Marks cannot be negative');
      }
      if (marks > maxMarks) {
        return MarksValidationResult.invalid(
          'Marks cannot exceed maximum marks ($maxMarks)',
        );
      }

      // Warnings for unusual entries
      if (marks == 0) {
        warnings.add('Student scored 0 marks');
      }
      if (marks == maxMarks) {
        warnings.add('Student scored full marks');
      }
      if (marks < passingMarks) {
        warnings.add('Student has failed this subject');
      }
    }

    return MarksValidationResult.valid(warnings: warnings);
  }

  // ============================================
  // EXAM OPERATIONS
  // ============================================

  /// Create a new exam with subjects
  Future<int> createExam({
    required ExamCreationData data,
    required int createdBy,
  }) async {
    // Validate
    final validation = validateExamCreation(data);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    // Create exam
    final examId = await _examRepo.create(
      ExamsCompanion.insert(
        uuid: _uuid.v4(),
        name: data.name.trim(),
        type: data.type,
        academicYear: data.academicYear,
        classId: data.classId,
        startDate: data.startDate,
        endDate: Value(data.endDate),
        description: Value(data.description),
        status: Value(data.status),
        createdBy: createdBy,
      ),
    );

    // Add subjects
    final subjectCompanions = data.subjects.map((s) {
      return ExamSubjectsCompanion.insert(
        examId: examId,
        subjectId: s.subjectId,
        maxMarks: s.maxMarks,
        passingMarks: s.passingMarks,
        examDate: Value(s.examDate),
        examTime: Value(s.examTime),
        durationMinutes: Value(s.durationMinutes),
      );
    }).toList();

    await _examRepo.addExamSubjects(subjectCompanions);

    // Log activity
    await _logActivity(
      action: 'create',
      module: 'exams',
      details: 'Created exam: ${data.name}',
      userId: createdBy,
    );

    return examId;
  }

  /// Update an existing exam
  Future<bool> updateExam({
    required int examId,
    required ExamCreationData data,
    required int updatedBy,
  }) async {
    // Check if exam exists
    final exam = await _examRepo.getById(examId);
    if (exam == null) {
      throw Exception('Exam not found');
    }

    // Only draft exams can be edited
    if (exam.status != 'draft') {
      throw Exception('Only draft exams can be edited');
    }

    // Validate
    final validation = validateExamCreation(data);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    // Update exam
    await _examRepo.update(
      examId,
      ExamsCompanion(
        name: Value(data.name.trim()),
        type: Value(data.type),
        classId: Value(data.classId),
        academicYear: Value(data.academicYear),
        startDate: Value(data.startDate),
        endDate: Value(data.endDate),
        description: Value(data.description),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Replace subjects
    await _examRepo.deleteAllExamSubjects(examId);

    final subjectCompanions = data.subjects.map((s) {
      return ExamSubjectsCompanion.insert(
        examId: examId,
        subjectId: s.subjectId,
        maxMarks: s.maxMarks,
        passingMarks: s.passingMarks,
        examDate: Value(s.examDate),
        examTime: Value(s.examTime),
        durationMinutes: Value(s.durationMinutes),
      );
    }).toList();

    await _examRepo.addExamSubjects(subjectCompanions);

    // Log activity
    await _logActivity(
      action: 'update',
      module: 'exams',
      details: 'Updated exam: ${data.name}',
      userId: updatedBy,
    );

    return true;
  }

  /// Publish an exam (make it active)
  Future<bool> publishExam({
    required int examId,
    required int publishedBy,
  }) async {
    final exam = await _examRepo.getById(examId);
    if (exam == null) {
      throw Exception('Exam not found');
    }

    if (exam.status != 'draft') {
      throw Exception('Only draft exams can be published');
    }

    // Check if subjects are configured
    final subjects = await _examRepo.getExamSubjects(examId);
    if (subjects.isEmpty) {
      throw Exception(
        'At least one subject must be configured before publishing',
      );
    }

    await _examRepo.publishExam(examId);

    await _logActivity(
      action: 'publish',
      module: 'exams',
      details: 'Published exam: ${exam.name}',
      userId: publishedBy,
    );

    return true;
  }

  /// Complete an exam (mark as finished)
  Future<bool> completeExam({
    required int examId,
    required int completedBy,
  }) async {
    final exam = await _examRepo.getById(examId);
    if (exam == null) {
      throw Exception('Exam not found');
    }

    if (exam.status != 'active') {
      throw Exception('Only active exams can be completed');
    }

    // Calculate and cache results before completing
    await calculateAndCacheResults(examId);

    await _examRepo.completeExam(examId);

    await _logActivity(
      action: 'complete',
      module: 'exams',
      details: 'Completed exam: ${exam.name}',
      userId: completedBy,
    );

    return true;
  }

  /// Delete an exam
  Future<bool> deleteExam({required int examId, required int deletedBy}) async {
    final exam = await _examRepo.getById(examId);
    if (exam == null) {
      throw Exception('Exam not found');
    }

    // Only draft and active exams can be deleted
    if (exam.status != 'draft' && exam.status != 'active') {
      throw Exception('Only draft and active exams can be deleted');
    }

    await _examRepo.delete(examId);

    await _logActivity(
      action: 'delete',
      module: 'exams',
      details: 'Deleted exam: ${exam.name}',
      userId: deletedBy,
    );

    return true;
  }

  // ============================================
  // MARKS OPERATIONS
  // ============================================

  /// Enter marks for a student
  Future<int> enterMarks({
    required int examId,
    required int examSubjectId,
    required int studentId,
    required double? marksObtained,
    required bool isAbsent,
    required int enteredBy,
    String? remarks,
  }) async {
    // Get exam subject for validation
    final examSubject = await _examRepo.getExamSubjectById(examSubjectId);
    if (examSubject == null) {
      throw Exception('Exam subject not found');
    }

    // Validate
    final validation = validateMarksEntry(
      marks: marksObtained,
      isAbsent: isAbsent,
      maxMarks: examSubject.maxMarks,
      passingMarks: examSubject.passingMarks,
    );
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    // Calculate grade if marks provided
    String? grade;
    if (marksObtained != null && !isAbsent) {
      final percentage = (marksObtained / examSubject.maxMarks) * 100;
      final gradeInfo = await _gradeRepo.getGradeForPercentage(percentage);
      grade = gradeInfo?.grade;
    }

    // Upsert mark
    return await _marksRepo.upsert(
      StudentMarksCompanion.insert(
        examId: examId,
        examSubjectId: examSubjectId,
        studentId: studentId,
        marksObtained: Value(marksObtained),
        isAbsent: Value(isAbsent),
        grade: Value(grade),
        remarks: Value(remarks),
        enteredBy: enteredBy,
      ),
    );
  }

  /// Enter marks for multiple students at once
  Future<BatchMarksResult> enterBulkMarks({
    required int examId,
    required int examSubjectId,
    required List<MarkEntryData> entries,
    required int enteredBy,
  }) async {
    // Get exam subject for validation
    final examSubject = await _examRepo.getExamSubjectById(examSubjectId);
    if (examSubject == null) {
      throw Exception('Exam subject not found');
    }

    // Get all grades for grade calculation
    final grades = await _gradeRepo.getAllGrades();
    final gradeCalculator = GradeCalculator(grades);

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    final companions = <StudentMarksCompanion>[];

    for (final entry in entries) {
      // Validate
      final validation = validateMarksEntry(
        marks: entry.marksObtained,
        isAbsent: entry.isAbsent,
        maxMarks: examSubject.maxMarks,
        passingMarks: examSubject.passingMarks,
      );

      if (!validation.isValid) {
        failureCount++;
        errors.add('Student ${entry.studentId}: ${validation.errorMessage}');
        continue;
      }

      // Calculate grade
      String? grade;
      if (entry.marksObtained != null && !entry.isAbsent) {
        final percentage = (entry.marksObtained! / examSubject.maxMarks) * 100;
        grade = gradeCalculator.getGradeName(percentage);
      }

      companions.add(
        StudentMarksCompanion.insert(
          examId: examId,
          examSubjectId: examSubjectId,
          studentId: entry.studentId,
          marksObtained: Value(entry.marksObtained),
          isAbsent: Value(entry.isAbsent),
          grade: Value(grade),
          remarks: Value(entry.remarks),
          enteredBy: enteredBy,
        ),
      );
      successCount++;
    }

    // Batch upsert
    if (companions.isNotEmpty) {
      await _marksRepo.upsertBatch(companions);
    }

    // Log activity
    await _logActivity(
      action: 'enter_marks',
      module: 'exams',
      details: 'Entered marks for $successCount students',
      userId: enteredBy,
    );

    return BatchMarksResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  // ============================================
  // RESULTS CALCULATION
  // ============================================

  /// Calculate and cache exam results
  Future<void> calculateAndCacheResults(int examId) async {
    // Clear existing cached results
    await _marksRepo.clearCachedResults(examId);

    // Get all exam results
    final results = await _marksRepo.getExamResults(examId);

    // Calculate rankings
    final sortedResults = List<StudentExamResult>.from(results);
    sortedResults.sort((a, b) => b.percentage.compareTo(a.percentage));

    // Save to cache
    final companions = <ExamResultsCompanion>[];
    for (int i = 0; i < sortedResults.length; i++) {
      final result = sortedResults[i];
      companions.add(
        ExamResultsCompanion.insert(
          examId: examId,
          studentId: result.student.id,
          totalMarksObtained: result.totalMarksObtained,
          totalMaxMarks: result.totalMaxMarks,
          percentage: result.percentage,
          overallGrade: result.overallGrade,
          gpa: result.gpa,
          classRank: Value(i + 1),
          isPassed: result.isPassed,
          teacherRemarks: Value(result.teacherRemarks),
          principalRemarks: Value(result.principalRemarks),
        ),
      );
    }

    await _marksRepo.saveExamResults(companions);
  }

  /// Update teacher remarks for a student result
  Future<bool> updateTeacherRemarks({
    required int examId,
    required int studentId,
    required String remarks,
    required int updatedBy,
  }) async {
    final existing = await _marksRepo.getCachedResult(examId, studentId);
    if (existing == null) {
      // Calculate results first if not cached
      await calculateAndCacheResults(examId);
    }

    await _marksRepo.saveExamResult(
      ExamResultsCompanion(
        examId: Value(examId),
        studentId: Value(studentId),
        teacherRemarks: Value(remarks),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return true;
  }

  /// Update principal remarks for a student result
  Future<bool> updatePrincipalRemarks({
    required int examId,
    required int studentId,
    required String remarks,
    required int updatedBy,
  }) async {
    final existing = await _marksRepo.getCachedResult(examId, studentId);
    if (existing == null) {
      await calculateAndCacheResults(examId);
    }

    await _marksRepo.saveExamResult(
      ExamResultsCompanion(
        examId: Value(examId),
        studentId: Value(studentId),
        principalRemarks: Value(remarks),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return true;
  }

  // ============================================
  // QUERY OPERATIONS
  // ============================================

  /// Get exams with filtering
  Future<List<ExamWithDetails>> getExams(ExamFilters filters) async {
    return await _examRepo.getExams(filters);
  }

  /// Get exam with full details
  Future<ExamWithDetails?> getExamDetails(int examId) async {
    return await _examRepo.getExamWithDetails(examId);
  }

  /// Get exam subjects with progress
  Future<List<ExamSubjectWithDetails>> getExamSubjects(int examId) async {
    return await _examRepo.getExamSubjects(examId);
  }

  /// Get marks for a specific exam subject
  Future<List<StudentMarkEntry>> getMarksForSubject({
    required int examId,
    required int examSubjectId,
    required int classId,
  }) async {
    return await _marksRepo.getMarksForExamSubject(
      examId: examId,
      examSubjectId: examSubjectId,
      classId: classId,
    );
  }

  /// Get student exam result
  Future<StudentExamResult?> getStudentResult({
    required int examId,
    required int studentId,
  }) async {
    return await _marksRepo.getStudentExamResult(
      examId: examId,
      studentId: studentId,
    );
  }

  /// Get class rankings for an exam
  Future<List<StudentExamResult>> getClassRankings(int examId) async {
    return await _marksRepo.getClassRankings(examId);
  }

  /// Get exam statistics
  Future<ExamOverallStats> getExamStats(int examId) async {
    return await _marksRepo.getExamOverallStats(examId);
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<void> _logActivity({
    required String action,
    required String module,
    required String details,
    required int userId,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            userId: Value(userId),
            action: action,
            module: module,
            description: details,
          ),
        );
  }
}
