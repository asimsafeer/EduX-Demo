/// EduX School Management System
/// Exam Providers - Riverpod state management for examination module
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../providers/student_provider.dart' show databaseProvider;
import '../repositories/exam_repository.dart';
import '../repositories/marks_repository.dart';
import '../repositories/grade_repository.dart';
import '../services/exam_service.dart';
import '../services/report_card_service.dart';
import 'dashboard_provider.dart';
import 'assigned_classes_provider.dart';

// ============================================
// REPOSITORY PROVIDERS
// ============================================

/// Exam repository provider
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftExamRepository(db);
});

/// Marks repository provider
final marksRepositoryProvider = Provider<MarksRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftMarksRepository(db);
});

/// Grade repository provider
final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftGradeRepository(db);
});

// ============================================
// SERVICE PROVIDERS
// ============================================

/// Exam service provider
final examServiceProvider = Provider<ExamService>((ref) {
  final db = ref.watch(databaseProvider);
  final examRepo = ref.watch(examRepositoryProvider);
  final marksRepo = ref.watch(marksRepositoryProvider);
  final gradeRepo = ref.watch(gradeRepositoryProvider);
  return ExamService(db, examRepo, marksRepo, gradeRepo);
});

/// Report card service provider
final reportCardServiceProvider = Provider<ReportCardService>((ref) {
  final db = ref.watch(databaseProvider);
  final examRepo = ref.watch(examRepositoryProvider);
  final marksRepo = ref.watch(marksRepositoryProvider);
  return ReportCardService(db, examRepo, marksRepo);
});

// ============================================
// EXAM FILTER STATE
// ============================================

/// Current exam filters state
final examFiltersProvider =
    StateNotifierProvider<ExamFiltersNotifier, ExamFilters>((ref) {
      return ExamFiltersNotifier();
    });

class ExamFiltersNotifier extends StateNotifier<ExamFilters> {
  ExamFiltersNotifier() : super(const ExamFilters());

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId, clearClassId: classId == null);
  }

  void setType(String? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setAcademicYear(String? year) {
    state = state.copyWith(academicYear: year);
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(startDateFrom: from, startDateTo: to);
  }

  void resetFilters() {
    state = const ExamFilters();
  }

  void loadMore() {
    state = state.copyWith(offset: state.offset + state.limit);
  }

  void resetPagination() {
    state = state.copyWith(offset: 0);
  }
}

// ============================================
// EXAM LIST PROVIDERS
// ============================================

/// Helper to build filters with allowed classes
Future<ExamFilters> _buildFiltersWithAllowedClasses(
  Ref ref,
  ExamFilters baseFilters,
) async {
  final assignedClassIds = await ref.watch(assignedClassIdsProvider.future);
  if (assignedClassIds != null) {
    return baseFilters.copyWith(
      allowedClassIds: (assignedClassIds as List<dynamic>).cast<int>(),
    );
  }
  return baseFilters;
}

/// Exams list with current filters
final examsListProvider = FutureProvider<List<ExamWithDetails>>((ref) async {
  final service = ref.watch(examServiceProvider);
  final baseFilters = ref.watch(examFiltersProvider);
  final filters = await _buildFiltersWithAllowedClasses(ref, baseFilters);
  return await service.getExams(filters);
});

/// Exams count by status
final examCountByStatusProvider = FutureProvider.family<int, String>((
  ref,
  status,
) async {
  final repo = ref.watch(examRepositoryProvider);
  return await repo.countExamsByStatus(status);
});

/// Draft exams
final draftExamsProvider = FutureProvider<List<ExamWithDetails>>((ref) async {
  final service = ref.watch(examServiceProvider);
  final filters = await _buildFiltersWithAllowedClasses(
    ref,
    const ExamFilters(status: 'draft'),
  );
  return await service.getExams(filters);
});

/// Active exams
final activeExamsProvider = FutureProvider<List<ExamWithDetails>>((ref) async {
  final service = ref.watch(examServiceProvider);
  final filters = await _buildFiltersWithAllowedClasses(
    ref,
    const ExamFilters(status: 'active'),
  );
  return await service.getExams(filters);
});

/// Completed exams
final completedExamsProvider = FutureProvider<List<ExamWithDetails>>((
  ref,
) async {
  final service = ref.watch(examServiceProvider);
  final filters = await _buildFiltersWithAllowedClasses(
    ref,
    const ExamFilters(status: 'completed'),
  );
  return await service.getExams(filters);
});

// ============================================
// SINGLE EXAM PROVIDERS
// ============================================

/// Current selected exam ID
final selectedExamIdProvider = StateProvider<int?>((ref) => null);

/// Current exam details
final currentExamProvider = FutureProvider<ExamWithDetails?>((ref) async {
  final examId = ref.watch(selectedExamIdProvider);
  if (examId == null) return null;

  final service = ref.watch(examServiceProvider);
  return await service.getExamDetails(examId);
});

/// Exam subjects for current exam
final examSubjectsProvider = FutureProvider<List<ExamSubjectWithDetails>>((
  ref,
) async {
  final examId = ref.watch(selectedExamIdProvider);
  if (examId == null) return [];

  final service = ref.watch(examServiceProvider);
  return await service.getExamSubjects(examId);
});

/// Exam by ID (for specific lookup)
final examByIdProvider = FutureProvider.family<ExamWithDetails?, int>((
  ref,
  examId,
) async {
  final service = ref.watch(examServiceProvider);
  return await service.getExamDetails(examId);
});

// ============================================
// MARKS ENTRY PROVIDERS
// ============================================

/// Current exam subject ID for marks entry
final selectedExamSubjectIdProvider = StateProvider<int?>((ref) => null);

/// Student marks for current exam subject
final studentMarksProvider = FutureProvider<List<StudentMarkEntry>>((
  ref,
) async {
  final examId = ref.watch(selectedExamIdProvider);
  final examSubjectId = ref.watch(selectedExamSubjectIdProvider);

  if (examId == null || examSubjectId == null) return [];

  final currentExam = await ref.watch(currentExamProvider.future);
  if (currentExam == null) return [];

  final marksRepo = ref.watch(marksRepositoryProvider);
  return await marksRepo.getMarksForExamSubject(
    examId: examId,
    examSubjectId: examSubjectId,
    classId: currentExam.exam.classId,
  );
});

/// Marks entry state notifier
final marksEntryProvider =
    StateNotifierProvider.autoDispose<MarksEntryNotifier, MarksEntryState>((
      ref,
    ) {
      return MarksEntryNotifier(ref);
    });

class MarksEntryState {
  final Map<int, double?> marks;
  final Map<int, bool> absent;
  final Map<int, String?> remarks;
  final Map<int, String?> validationErrors;
  final bool isSaving;
  final String? error;
  final int savedCount;

  const MarksEntryState({
    this.marks = const {},
    this.absent = const {},
    this.remarks = const {},
    this.validationErrors = const {},
    this.isSaving = false,
    this.error,
    this.savedCount = 0,
  });

  MarksEntryState copyWith({
    Map<int, double?>? marks,
    Map<int, bool>? absent,
    Map<int, String?>? remarks,
    Map<int, String?>? validationErrors,
    bool? isSaving,
    String? error,
    int? savedCount,
    bool clearError = false,
  }) {
    return MarksEntryState(
      marks: marks ?? this.marks,
      absent: absent ?? this.absent,
      remarks: remarks ?? this.remarks,
      validationErrors: validationErrors ?? this.validationErrors,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      savedCount: savedCount ?? this.savedCount,
    );
  }
}

class MarksEntryNotifier extends StateNotifier<MarksEntryState> {
  final Ref _ref;

  MarksEntryNotifier(this._ref) : super(const MarksEntryState());

  /// Initialize with existing marks
  void initializeFromEntries(List<StudentMarkEntry> entries) {
    final marks = <int, double?>{};
    final absent = <int, bool>{};
    final remarks = <int, String?>{};

    for (final entry in entries) {
      marks[entry.student.id] = entry.marksObtained;
      absent[entry.student.id] = entry.isAbsent;
      remarks[entry.student.id] = entry.remarks;
    }

    state = state.copyWith(
      marks: marks,
      absent: absent,
      remarks: remarks,
      validationErrors: {},
      clearError: true,
    );
  }

  /// Set marks for a student
  void setMarks(int studentId, double? marks, double maxMarks) {
    final newMarks = Map<int, double?>.from(state.marks);
    final newValidationErrors = Map<int, String?>.from(state.validationErrors);
    final newRemarks = Map<int, String?>.from(state.remarks);

    // Validation
    if (marks != null) {
      if (marks < 0) {
        newValidationErrors[studentId] = 'Marks cannot be negative';
      } else if (marks > maxMarks) {
        newValidationErrors[studentId] = 'Marks cannot exceed $maxMarks';
      } else {
        newValidationErrors.remove(studentId);
      }
    } else {
      newValidationErrors.remove(studentId);
    }

    newMarks[studentId] = marks;

    // If marks are set, student is not absent
    if (marks != null) {
      final newAbsent = Map<int, bool>.from(state.absent);
      newAbsent[studentId] = false;

      // Auto-calculate remarks
      if (marks <= maxMarks && marks >= 0 && maxMarks > 0) {
        final gradeCalc = _ref.read(gradeCalculatorProvider).valueOrNull;
        if (gradeCalc != null) {
          final percentage = (marks / maxMarks) * 100;
          final calcRemarks = gradeCalc.getRemarks(percentage);
          if (calcRemarks != null && calcRemarks.isNotEmpty) {
            newRemarks[studentId] = calcRemarks;
          }
        }
      }

      state = state.copyWith(
        marks: newMarks,
        absent: newAbsent,
        remarks: newRemarks,
        validationErrors: newValidationErrors,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        marks: newMarks,
        remarks: newRemarks,
        validationErrors: newValidationErrors,
        clearError: true,
      );
    }
  }

  /// Set absent status for a student
  void setAbsent(int studentId, bool isAbsent) {
    final newAbsent = Map<int, bool>.from(state.absent);
    newAbsent[studentId] = isAbsent;

    // If absent, clear marks and validation errors
    if (isAbsent) {
      final newMarks = Map<int, double?>.from(state.marks);
      final newValidationErrors = Map<int, String?>.from(
        state.validationErrors,
      );

      newMarks[studentId] = null;
      newValidationErrors.remove(studentId);

      state = state.copyWith(
        marks: newMarks,
        absent: newAbsent,
        validationErrors: newValidationErrors,
        clearError: true,
      );
    } else {
      state = state.copyWith(absent: newAbsent, clearError: true);
    }
  }

  /// Set remarks for a student
  void setRemarks(int studentId, String? remarks) {
    final newRemarks = Map<int, String?>.from(state.remarks);
    newRemarks[studentId] = remarks;
    state = state.copyWith(remarks: newRemarks);
  }

  /// Save all marks
  Future<bool> saveMarks({
    required int examId,
    required int examSubjectId,
    required int enteredBy,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final service = _ref.read(examServiceProvider);
      final studentIds = {...state.marks.keys, ...state.absent.keys};

      final entries = <MarkEntryData>[];
      for (final studentId in studentIds) {
        final isAbsent = state.absent[studentId] ?? false;
        final marks = state.marks[studentId];
        final remarks = state.remarks[studentId];

        // Skip if no data entered
        if (!isAbsent && marks == null) continue;

        entries.add(
          MarkEntryData(
            studentId: studentId,
            marksObtained: marks,
            isAbsent: isAbsent,
            remarks: remarks,
          ),
        );
      }

      if (entries.isEmpty) {
        state = state.copyWith(isSaving: false, error: 'No marks to save');
        return false;
      }

      final result = await service.enterBulkMarks(
        examId: examId,
        examSubjectId: examSubjectId,
        entries: entries,
        enteredBy: enteredBy,
      );

      state = state.copyWith(
        isSaving: false,
        savedCount: result.successCount,
        error: result.errors.isNotEmpty ? result.errors.join('\n') : null,
      );

      // Invalidate providers to refresh data
      _ref.invalidate(studentMarksProvider);
      _ref.invalidate(examSubjectsProvider);
      _ref.invalidate(currentExamProvider);
      _ref.invalidate(examsListProvider);
      _ref.invalidate(examCountByStatusProvider);
      _ref.invalidate(dashboardProvider);

      return result.isComplete;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const MarksEntryState();
  }
}

// ============================================
// EXAM RESULTS PROVIDERS
// ============================================

/// Exam results for current exam
final examResultsProvider = FutureProvider<List<StudentExamResult>>((
  ref,
) async {
  final examId = ref.watch(selectedExamIdProvider);
  if (examId == null) return [];

  final marksRepo = ref.watch(marksRepositoryProvider);
  return await marksRepo.getExamResults(examId);
});

/// Class rankings for current exam
final classRankingsProvider = FutureProvider<List<StudentExamResult>>((
  ref,
) async {
  final examId = ref.watch(selectedExamIdProvider);
  if (examId == null) return [];

  final service = ref.watch(examServiceProvider);
  return await service.getClassRankings(examId);
});

/// Exam statistics for current exam
final examStatsProvider = FutureProvider<ExamOverallStats?>((ref) async {
  final examId = ref.watch(selectedExamIdProvider);
  if (examId == null) return null;

  final service = ref.watch(examServiceProvider);
  return await service.getExamStats(examId);
});

/// Single student result
final studentExamResultProvider =
    FutureProvider.family<StudentExamResult?, ({int examId, int studentId})>((
      ref,
      params,
    ) async {
      final service = ref.watch(examServiceProvider);
      return await service.getStudentResult(
        examId: params.examId,
        studentId: params.studentId,
      );
    });

// ============================================
// GRADE SETTINGS PROVIDERS
// ============================================

/// All grade settings
final gradeSettingsProvider = FutureProvider<List<GradeSetting>>((ref) async {
  final repo = ref.watch(gradeRepositoryProvider);
  return await repo.getAllGrades();
});

/// Grade calculator
final gradeCalculatorProvider = FutureProvider<GradeCalculator>((ref) async {
  final grades = await ref.watch(gradeSettingsProvider.future);
  return GradeCalculator(grades);
});

/// Grade settings notifier for CRUD operations
final gradeSettingsNotifierProvider =
    StateNotifierProvider<
      GradeSettingsNotifier,
      AsyncValue<List<GradeSetting>>
    >((ref) {
      return GradeSettingsNotifier(ref);
    });

class GradeSettingsNotifier
    extends StateNotifier<AsyncValue<List<GradeSetting>>> {
  final Ref _ref;

  GradeSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(gradeRepositoryProvider);
      final grades = await repo.getAllGrades();
      state = AsyncValue.data(grades);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadGrades();
    _ref.invalidate(gradeSettingsProvider);
    _ref.invalidate(gradeCalculatorProvider);
  }

  Future<bool> addGrade({
    required String gradeName,
    required double minPercentage,
    required double maxPercentage,
    required double gpa,
    bool isPassing = true,
    String? remarks,
  }) async {
    try {
      final repo = _ref.read(gradeRepositoryProvider);

      // Check if name is unique
      final isUnique = await repo.isGradeNameUnique(gradeName);
      if (!isUnique) {
        throw Exception('Grade name already exists');
      }

      // Check for overlapping range
      final hasOverlap = await repo.hasOverlappingRange(
        minPercentage,
        maxPercentage,
      );
      if (hasOverlap) {
        throw Exception('Percentage range overlaps with existing grade');
      }

      // Get next display order
      final currentGrades = state.value ?? [];
      final displayOrder = currentGrades.isEmpty
          ? 1
          : currentGrades
                    .map((g) => g.displayOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;

      await repo.create(
        GradeSettingsCompanion.insert(
          grade: gradeName,
          minPercentage: minPercentage,
          maxPercentage: maxPercentage,
          gpa: gpa,
          remarks: Value(remarks),
          displayOrder: displayOrder,
          isPassing: Value(isPassing),
        ),
      );

      await refresh();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateGrade({
    required int id,
    required String gradeName,
    required double minPercentage,
    required double maxPercentage,
    required double gpa,
    bool isPassing = true,
    String? remarks,
  }) async {
    try {
      final repo = _ref.read(gradeRepositoryProvider);

      // Check if name is unique (excluding current)
      final isUnique = await repo.isGradeNameUnique(gradeName, excludeId: id);
      if (!isUnique) {
        throw Exception('Grade name already exists');
      }

      // Check for overlapping range (excluding current)
      final hasOverlap = await repo.hasOverlappingRange(
        minPercentage,
        maxPercentage,
        excludeId: id,
      );
      if (hasOverlap) {
        throw Exception('Percentage range overlaps with existing grade');
      }

      await repo.update(
        id,
        GradeSettingsCompanion(
          grade: Value(gradeName),
          minPercentage: Value(minPercentage),
          maxPercentage: Value(maxPercentage),
          gpa: Value(gpa),
          remarks: Value(remarks),
          isPassing: Value(isPassing),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await refresh();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteGrade(int id) async {
    try {
      final repo = _ref.read(gradeRepositoryProvider);
      await repo.delete(id);
      await refresh();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorderGrades(List<GradeSetting> newOrder) async {
    try {
      final repo = _ref.read(gradeRepositoryProvider);
      await repo.reorderGrades(newOrder.map((g) => g.id).toList());
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

// ============================================
// REPORT CARD PROVIDERS
// ============================================

/// Report card data for a student
final reportCardDataProvider =
    FutureProvider.family<ReportCardData?, ({int examId, int studentId})>((
      ref,
      params,
    ) async {
      final service = ref.watch(reportCardServiceProvider);
      return await service.getReportCardData(
        examId: params.examId,
        studentId: params.studentId,
      );
    });

/// Bulk report card data for an exam
final bulkReportCardDataProvider =
    FutureProvider.family<List<ReportCardData>, int>((ref, examId) async {
      final service = ref.watch(reportCardServiceProvider);
      return await service.getBulkReportCardData(examId);
    });

// ============================================
// EXAM FORM STATE
// ============================================

/// Exam form state for create/edit
final examFormProvider =
    StateNotifierProvider.autoDispose<ExamFormNotifier, ExamFormState>((ref) {
      return ExamFormNotifier(ref);
    });

class ExamFormState {
  final String name;
  final String? type;
  final int? classId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final List<ExamSubjectData> subjects;
  final bool isSaving;
  final String? error;
  final int currentStep;

  const ExamFormState({
    this.name = '',
    this.type,
    this.classId,
    this.startDate,
    this.endDate,
    this.description,
    this.subjects = const [],
    this.isSaving = false,
    this.error,
    this.currentStep = 0,
  });

  ExamFormState copyWith({
    String? name,
    String? type,
    int? classId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<ExamSubjectData>? subjects,
    bool? isSaving,
    String? error,
    int? currentStep,
    bool clearType = false,
    bool clearClassId = false,
    bool clearError = false,
  }) {
    return ExamFormState(
      name: name ?? this.name,
      type: clearType ? null : (type ?? this.type),
      classId: clearClassId ? null : (classId ?? this.classId),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get isValid =>
      name.isNotEmpty &&
      type != null &&
      classId != null &&
      startDate != null &&
      subjects.isNotEmpty;
}

class ExamFormNotifier extends StateNotifier<ExamFormState> {
  final Ref _ref;

  ExamFormNotifier(this._ref) : super(const ExamFormState());

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setType(String? type) {
    state = state.copyWith(
      type: type,
      clearType: type == null,
      clearError: true,
    );
  }

  void setClassId(int? classId) {
    state = state.copyWith(
      classId: classId,
      clearClassId: classId == null,
      clearError: true,
    );
  }

  void setStartDate(DateTime? date) {
    state = state.copyWith(startDate: date, clearError: true);
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date, clearError: true);
  }

  void setDescription(String? description) {
    state = state.copyWith(description: description);
  }

  void addSubject(ExamSubjectData subject) {
    final subjects = [...state.subjects, subject];
    state = state.copyWith(subjects: subjects, clearError: true);
  }

  void updateSubject(int index, ExamSubjectData subject) {
    final subjects = [...state.subjects];
    subjects[index] = subject;
    state = state.copyWith(subjects: subjects);
  }

  void removeSubject(int index) {
    final subjects = [...state.subjects];
    subjects.removeAt(index);
    state = state.copyWith(subjects: subjects);
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Load existing exam for editing
  Future<void> loadExam(int examId) async {
    try {
      final examRepo = _ref.read(examRepositoryProvider);
      final exam = await examRepo.getById(examId);
      if (exam == null) return;

      final examSubjects = await examRepo.getExamSubjects(examId);

      final subjects = examSubjects.map((es) {
        return ExamSubjectData(
          subjectId: es.examSubject.subjectId,
          maxMarks: es.examSubject.maxMarks,
          passingMarks: es.examSubject.passingMarks,
          examDate: es.examSubject.examDate,
          examTime: es.examSubject.examTime,
          durationMinutes: es.examSubject.durationMinutes,
        );
      }).toList();

      state = ExamFormState(
        name: exam.name,
        type: exam.type,
        classId: exam.classId,
        startDate: exam.startDate,
        endDate: exam.endDate,
        description: exam.description,
        subjects: subjects,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Create new exam
  Future<int?> createExam({
    required String academicYear,
    required int createdBy,
    String status = 'active',
  }) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill all required fields');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final service = _ref.read(examServiceProvider);

      final data = ExamCreationData(
        name: state.name,
        type: state.type!,
        classId: state.classId!,
        academicYear: academicYear,
        startDate: state.startDate!,
        endDate: state.endDate,
        description: state.description,
        subjects: state.subjects,
        status: status,
      );

      final examId = await service.createExam(data: data, createdBy: createdBy);

      state = state.copyWith(isSaving: false);

      // Invalidate exam lists
      _ref.invalidate(examsListProvider);
      _ref.invalidate(draftExamsProvider);
      _ref.invalidate(dashboardProvider);

      return examId;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  /// Update existing exam
  Future<bool> updateExam({
    required int examId,
    required String academicYear,
    required int updatedBy,
  }) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill all required fields');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final service = _ref.read(examServiceProvider);

      final data = ExamCreationData(
        name: state.name,
        type: state.type!,
        classId: state.classId!,
        academicYear: academicYear,
        startDate: state.startDate!,
        endDate: state.endDate,
        description: state.description,
        subjects: state.subjects,
      );

      await service.updateExam(
        examId: examId,
        data: data,
        updatedBy: updatedBy,
      );

      state = state.copyWith(isSaving: false);

      // Invalidate exam lists
      _ref.invalidate(examsListProvider);
      _ref.invalidate(examByIdProvider(examId));
      _ref.invalidate(dashboardProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ExamFormState();
  }
}
