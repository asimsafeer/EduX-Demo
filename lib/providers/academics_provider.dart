/// EduX School Management System
/// Academics Provider - Riverpod state management for academic module
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/class_repository.dart';
import '../repositories/section_repository.dart';
import '../repositories/subject_repository.dart';
import '../repositories/class_subject_repository.dart';
import '../repositories/timetable_repository.dart';
import '../repositories/period_definition_repository.dart';
import '../services/working_days_service.dart';
import 'dashboard_provider.dart';
// Added for SectionOperationNotifier
import '../providers/student_provider.dart'; // Added as per instruction
import 'assigned_classes_provider.dart';

// ============================================
// DATABASE PROVIDER
// ============================================

/// Database provider (using singleton)
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// ============================================
// REPOSITORY PROVIDERS
// ============================================

/// Class repository provider
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ClassRepositoryImpl(db);
});

/// Section repository provider
final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SectionRepositoryImpl(db);
});

/// Subject repository provider
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SubjectRepositoryImpl(db);
});

/// Class subject repository provider
final classSubjectRepositoryProvider = Provider<ClassSubjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ClassSubjectRepositoryImpl(db);
});

/// Timetable repository provider
final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TimetableRepositoryImpl(db);
});

/// Period definition repository provider
final periodDefinitionRepositoryProvider = Provider<PeriodDefinitionRepository>(
  (ref) {
    final db = ref.watch(databaseProvider);
    return PeriodDefinitionRepositoryImpl(db);
  },
);

// ============================================
// CURRENT ACADEMIC YEAR PROVIDER
// ============================================

/// Current academic year provider
final currentAcademicYearProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(databaseProvider);
  final academicYear = await db.getCurrentAcademicYear();

  if (academicYear != null) {
    return academicYear.name;
  }

  // Default to current calendar year if not set
  final now = DateTime.now();
  return '${now.year}-${now.year + 1}';
});

// ============================================
// CLASSES DATA PROVIDERS
// ============================================

/// All active classes provider
final classesProvider = FutureProvider<List<SchoolClass>>((ref) async {
  final repo = ref.watch(classRepositoryProvider);
  final allClasses = await repo.getAllActive();

  // Apply filtering for restricted users (e.g., teachers)
  final assignedClassIds = await ref.watch(assignedClassIdsProvider.future);
  if (assignedClassIds != null) {
    return allClasses.where((c) => assignedClassIds.contains(c.id)).toList();
  }

  return allClasses;
});

/// Classes with stats provider
final classesWithStatsProvider = FutureProvider<List<ClassWithStats>>((
  ref,
) async {
  final repo = ref.watch(classRepositoryProvider);
  return await repo.getAllWithStats();
});

/// Classes grouped by level provider
final classesGroupedByLevelProvider =
    FutureProvider<Map<String, List<SchoolClass>>>((ref) async {
      final repo = ref.watch(classRepositoryProvider);
      return await repo.getGroupedByLevel();
    });

/// Single class with sections provider
final classWithSectionsProvider =
    FutureProvider.family<ClassWithSections?, int>((ref, classId) async {
      final repo = ref.watch(classRepositoryProvider);
      return await repo.getWithSections(classId);
    });

/// Class student count provider
final classStudentCountProvider = FutureProvider.family<int, int>((
  ref,
  classId,
) async {
  final repo = ref.watch(classRepositoryProvider);
  return await repo.getStudentCount(classId);
});

// ============================================
// SECTIONS DATA PROVIDERS
// ============================================

/// Sections by class provider
final sectionsByClassProvider = FutureProvider.family<List<Section>, int>((
  ref,
  classId,
) async {
  final repo = ref.watch(sectionRepositoryProvider);

  // Security check: If restricted, user must only access sections of assigned classes
  final assignedClassIds = await ref.watch(assignedClassIdsProvider.future);
  if (assignedClassIds != null && !assignedClassIds.contains(classId)) {
    return []; // Return empty if looking up sections for an unassigned class
  }

  return await repo.getActiveByClass(classId);
});

/// Sections with stats by class provider
final sectionsWithStatsByClassProvider =
    FutureProvider.family<List<SectionWithStats>, int>((ref, classId) async {
      final repo = ref.watch(sectionRepositoryProvider);
      return await repo.getWithStatsByClass(classId);
    });

/// Single section with stats provider
final sectionWithStatsProvider = FutureProvider.family<SectionWithStats?, int>((
  ref,
  sectionId,
) async {
  final repo = ref.watch(sectionRepositoryProvider);
  return await repo.getWithStats(sectionId);
});

/// All class-section combinations for dropdowns
final classSectionPairsProvider = FutureProvider<List<ClassSectionPair>>((
  ref,
) async {
  final repo = ref.watch(sectionRepositoryProvider);
  return await repo.getClassSectionCombinations();
});

// ============================================
// SUBJECTS DATA PROVIDERS
// ============================================

/// Subject filters state
class SubjectFiltersNotifier extends StateNotifier<SubjectFilters> {
  SubjectFiltersNotifier() : super(const SubjectFilters());

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void setType(String? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setIsActive(bool? isActive) {
    state = state.copyWith(isActive: isActive, clearIsActive: isActive == null);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSortOrder() {
    state = state.copyWith(ascending: !state.ascending);
  }

  void clearAllFilters() {
    state = state.clearAll();
  }
}

/// Subject filters provider
final subjectFiltersProvider =
    StateNotifierProvider<SubjectFiltersNotifier, SubjectFilters>((ref) {
      return SubjectFiltersNotifier();
    });

/// All active subjects provider
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repo = ref.watch(subjectRepositoryProvider);
  return await repo.getAllActive();
});

/// Subjects with filters provider
final filteredSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repo = ref.watch(subjectRepositoryProvider);
  final filters = ref.watch(subjectFiltersProvider);
  return await repo.search(filters);
});

/// Subjects with usage count provider
final subjectsWithUsageProvider = FutureProvider<List<SubjectWithUsage>>((
  ref,
) async {
  final repo = ref.watch(subjectRepositoryProvider);
  return await repo.getAllWithUsage();
});

// ============================================
// CLASS SUBJECTS DATA PROVIDERS
// ============================================

/// Class subjects provider (subjects assigned to a class)
final classSubjectsProvider =
    FutureProvider.family<
      List<ClassSubjectWithDetails>,
      ({int classId, String academicYear})
    >((ref, params) async {
      final repo = ref.watch(classSubjectRepositoryProvider);
      return await repo.getByClass(params.classId, params.academicYear);
    });

/// Unassigned subjects for a class provider
final unassignedSubjectsProvider =
    FutureProvider.family<List<Subject>, ({int classId, String academicYear})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(classSubjectRepositoryProvider);
      return await repo.getUnassignedSubjects(
        params.classId,
        params.academicYear,
      );
    });

// ============================================
// TIMETABLE DATA PROVIDERS
// ============================================

/// Timetable slots provider
final timetableSlotsProvider =
    FutureProvider.family<List<TimetableSlotWithDetails>, TimetableQuery>((
      ref,
      query,
    ) async {
      final repo = ref.watch(timetableRepositoryProvider);
      return await repo.getByClassSection(query);
    });

/// Weekly timetable provider
final weeklyTimetableProvider =
    FutureProvider.family<
      Map<String, Map<int, TimetableSlotWithDetails?>>,
      TimetableQuery
    >((ref, query) async {
      final repo = ref.watch(timetableRepositoryProvider);
      return await repo.getWeeklyTimetable(
        query.classId,
        query.sectionId,
        query.academicYear,
      );
    });

/// Teacher timetable provider (for conflict checking)
final teacherTimetableProvider =
    FutureProvider.family<
      List<TimetableSlot>,
      ({int teacherId, String day, String academicYear})
    >((ref, params) async {
      final repo = ref.watch(timetableRepositoryProvider);
      return await repo.getByTeacher(
        params.teacherId,
        params.day,
        params.academicYear,
      );
    });

// ============================================
// PERIOD DEFINITIONS PROVIDERS
// ============================================

/// Period definitions provider
final periodDefinitionsProvider =
    FutureProvider.family<List<PeriodDefinition>, String>((
      ref,
      academicYear,
    ) async {
      final repo = ref.watch(periodDefinitionRepositoryProvider);
      return await repo.getAll(academicYear);
    });

/// Period count provider
final periodCountProvider = FutureProvider.family<int, String>((
  ref,
  academicYear,
) async {
  final repo = ref.watch(periodDefinitionRepositoryProvider);
  return await repo.getPeriodCount(academicYear);
});

// ============================================
// SELECTED STATE PROVIDERS
// ============================================

/// Active tab in academics screen
final academicsActiveTabProvider = StateProvider<int>((ref) => 0);

/// Selected class ID
final selectedClassIdProvider = StateProvider<int?>((ref) => null);

/// Selected section ID
final selectedSectionIdProvider = StateProvider<int?>((ref) => null);

/// Selected subject ID
final selectedSubjectIdProvider = StateProvider<int?>((ref) => null);

// ============================================
// OPERATION STATE
// ============================================

/// Generic operation state
class OperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const OperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  OperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OperationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// ============================================
// CLASS OPERATION NOTIFIER
// ============================================

/// Class operation notifier for async operations
class ClassOperationNotifier extends StateNotifier<OperationState> {
  final ClassRepository _repository;
  final Ref _ref;

  ClassOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createClass({
    required String name,
    required String level,
    required int gradeLevel,
    required int displayOrder,
    String? description,
    double monthlyFee = 0,
  }) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Check uniqueness
      final isUnique = await _repository.isNameUnique(name, level);
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A class with this name already exists in this level',
        );
        return false;
      }

      await _repository.create(
        ClassesCompanion.insert(
          name: name,
          level: level,
          gradeLevel: gradeLevel,
          displayOrder: displayOrder,
          description: Value(description),
          monthlyFee: Value(monthlyFee),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Class created successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateClass({
    required int id,
    required String name,
    required String level,
    required int gradeLevel,
    required int displayOrder,
    String? description,
    double monthlyFee = 0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isUnique = await _repository.isNameUnique(
        name,
        level,
        excludeId: id,
      );
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A class with this name already exists in this level',
        );
        return false;
      }

      await _repository.update(
        id,
        ClassesCompanion(
          name: Value(name),
          level: Value(level),
          gradeLevel: Value(gradeLevel),
          displayOrder: Value(displayOrder),
          description: Value(description),
          monthlyFee: Value(monthlyFee),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Class updated successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteClass(int id) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.delete(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Class deleted successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders() {
    _ref.invalidate(classesProvider);
    _ref.invalidate(classesWithStatsProvider);
    _ref.invalidate(classesGroupedByLevelProvider);
    _ref.invalidate(classSectionPairsProvider);
    _ref.invalidate(dashboardProvider);
  }
}

/// Class operation provider
final classOperationProvider =
    StateNotifierProvider<ClassOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(classRepositoryProvider);
      return ClassOperationNotifier(repo, ref);
    });

// ============================================
// SECTION OPERATION NOTIFIER
// ============================================

/// Section operation notifier
class SectionOperationNotifier extends StateNotifier<OperationState> {
  final SectionRepository _repository;
  final Ref _ref;

  SectionOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createSection({
    required int classId,
    required String name,
    int? capacity,
    String? roomNumber,
    int? classTeacherId,
  }) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isUnique = await _repository.isNameUnique(name, classId);
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A section with this name already exists in this class',
        );
        return false;
      }

      await _repository.create(
        SectionsCompanion.insert(
          classId: classId,
          name: name,
          capacity: Value(capacity),
          roomNumber: Value(roomNumber),
          classTeacherId: Value(classTeacherId),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Section created successfully',
      );
      _invalidateProviders(classId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSection({
    required int id,
    required int classId,
    required String name,
    int? capacity,
    String? roomNumber,
    int? classTeacherId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isUnique = await _repository.isNameUnique(
        name,
        classId,
        excludeId: id,
      );
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A section with this name already exists in this class',
        );
        return false;
      }

      await _repository.update(
        id,
        SectionsCompanion(
          name: Value(name),
          capacity: Value(capacity),
          roomNumber: Value(roomNumber),
          classTeacherId: Value(classTeacherId),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Section updated successfully',
      );
      _invalidateProviders(classId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSection(int id, int classId) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.delete(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Section deleted successfully',
      );
      _invalidateProviders(classId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reassignRollNumbers(int classId, int sectionId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final enrollmentRepo = _ref.read(enrollmentRepositoryProvider);
      final count = await enrollmentRepo.reassignRollNumbers(
        classId,
        sectionId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage:
            'Successfully re-assigned roll numbers for $count students',
      );
      _invalidateProviders(classId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders(int classId) {
    _ref.invalidate(sectionsByClassProvider(classId));
    _ref.invalidate(sectionsWithStatsByClassProvider(classId));
    _ref.invalidate(classSectionPairsProvider);
    _ref.invalidate(classWithSectionsProvider(classId));
    _ref.invalidate(dashboardProvider);
  }
}

/// Section operation provider
final sectionOperationProvider =
    StateNotifierProvider<SectionOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(sectionRepositoryProvider);
      return SectionOperationNotifier(repo, ref);
    });

// ============================================
// SUBJECT OPERATION NOTIFIER
// ============================================

/// Subject operation notifier
class SubjectOperationNotifier extends StateNotifier<OperationState> {
  final SubjectRepository _repository;
  final Ref _ref;

  SubjectOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createSubject({
    required String code,
    required String name,
    String type = 'core',
    int? creditHours,
    String? description,
  }) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isUnique = await _repository.isCodeUnique(code);
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A subject with this code already exists',
        );
        return false;
      }

      await _repository.create(
        SubjectsCompanion.insert(
          code: code.toUpperCase(),
          name: name,
          type: Value(type),
          creditHours: Value(creditHours),
          description: Value(description),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subject created successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSubject({
    required int id,
    required String code,
    required String name,
    String type = 'core',
    int? creditHours,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isUnique = await _repository.isCodeUnique(code, excludeId: id);
      if (!isUnique) {
        state = state.copyWith(
          isLoading: false,
          error: 'A subject with this code already exists',
        );
        return false;
      }

      await _repository.update(
        id,
        SubjectsCompanion(
          code: Value(code.toUpperCase()),
          name: Value(name),
          type: Value(type),
          creditHours: Value(creditHours),
          description: Value(description),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subject updated successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSubject(int id) async {
    if (DemoConfig.isDemo) {
      state = state.copyWith(isLoading: false, error: DemoConfig.restrictionMessage);
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.delete(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subject deleted successfully',
      );
      _invalidateProviders();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders() {
    _ref.invalidate(subjectsProvider);
    _ref.invalidate(filteredSubjectsProvider);
    _ref.invalidate(subjectsWithUsageProvider);
    _ref.invalidate(dashboardProvider);
  }
}

/// Subject operation provider
final subjectOperationProvider =
    StateNotifierProvider<SubjectOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(subjectRepositoryProvider);
      return SubjectOperationNotifier(repo, ref);
    });

// ============================================
// TIMETABLE OPERATION NOTIFIER
// ============================================

/// Timetable operation notifier
class TimetableOperationNotifier extends StateNotifier<OperationState> {
  final TimetableRepository _repository;
  final Ref _ref;

  TimetableOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createSlot({
    required int classId,
    required int sectionId,
    required int subjectId,
    required String dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required String academicYear,
    int? teacherId,
    bool isBreak = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Check for conflicts
      final conflict = await _repository.checkConflict(
        null,
        teacherId,
        dayOfWeek,
        periodNumber,
        academicYear,
      );

      if (conflict != null) {
        state = state.copyWith(isLoading: false, error: conflict.message);
        return false;
      }

      await _repository.create(
        TimetableSlotsCompanion.insert(
          classId: classId,
          sectionId: sectionId,
          subjectId: subjectId,
          dayOfWeek: dayOfWeek,
          periodNumber: periodNumber,
          startTime: startTime,
          endTime: endTime,
          academicYear: academicYear,
          teacherId: Value(teacherId),
          isBreak: Value(isBreak),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Timetable slot created successfully',
      );
      _invalidateProviders(classId, sectionId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSlot({
    required int id,
    required int classId,
    required int sectionId,
    required int subjectId,
    required String dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required String academicYear,
    int? teacherId,
    bool isBreak = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conflict = await _repository.checkConflict(
        id,
        teacherId,
        dayOfWeek,
        periodNumber,
        academicYear,
      );

      if (conflict != null) {
        state = state.copyWith(isLoading: false, error: conflict.message);
        return false;
      }

      await _repository.update(
        id,
        TimetableSlotsCompanion(
          subjectId: Value(subjectId),
          teacherId: Value(teacherId),
          isBreak: Value(isBreak),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Timetable slot updated successfully',
      );
      _invalidateProviders(classId, sectionId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSlot(
    int id,
    int classId,
    int sectionId,
    String academicYear,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.delete(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Timetable slot deleted successfully',
      );
      _invalidateProviders(classId, sectionId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> copyTimetable({
    required int fromClassId,
    required int fromSectionId,
    required int toClassId,
    required int toSectionId,
    required String academicYear,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.copyTimetable(
        fromClassId,
        fromSectionId,
        toClassId,
        toSectionId,
        academicYear,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Timetable copied successfully',
      );
      _invalidateProviders(toClassId, toSectionId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders(int classId, int sectionId, String academicYear) {
    _ref.invalidate(
      timetableSlotsProvider(
        TimetableQuery(
          classId: classId,
          sectionId: sectionId,
          academicYear: academicYear,
        ),
      ),
    );
    _ref.invalidate(
      weeklyTimetableProvider(
        TimetableQuery(
          classId: classId,
          sectionId: sectionId,
          academicYear: academicYear,
        ),
      ),
    );
  }
}

/// Timetable operation provider
final timetableOperationProvider =
    StateNotifierProvider<TimetableOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(timetableRepositoryProvider);
      return TimetableOperationNotifier(repo, ref);
    });

// ============================================
// CLASS SUBJECT OPERATION NOTIFIER
// ============================================

/// Class subject operation notifier
class ClassSubjectOperationNotifier extends StateNotifier<OperationState> {
  final ClassSubjectRepository _repository;
  final Ref _ref;

  ClassSubjectOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> assignSubject({
    required int classId,
    required int subjectId,
    required String academicYear,
    int? teacherId,
    int periodsPerWeek = 0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final isAssigned = await _repository.isAssigned(
        classId,
        subjectId,
        academicYear,
      );
      if (isAssigned) {
        state = state.copyWith(
          isLoading: false,
          error: 'This subject is already assigned to this class',
        );
        return false;
      }

      await _repository.assign(
        ClassSubjectsCompanion.insert(
          classId: classId,
          subjectId: subjectId,
          academicYear: academicYear,
          teacherId: Value(teacherId),
          periodsPerWeek: Value(periodsPerWeek),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subject assigned successfully',
      );
      _invalidateProviders(classId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> unassignSubject(int id, int classId, String academicYear) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.unassign(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subject removed successfully',
      );
      _invalidateProviders(classId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignTeacher(
    int id,
    int classId,
    String academicYear,
    int? teacherId,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.assignTeacher(id, teacherId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Teacher assigned successfully',
      );
      _invalidateProviders(classId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> bulkAssignSubjects({
    required int classId,
    required List<int> subjectIds,
    required String academicYear,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.bulkAssign(classId, subjectIds, academicYear);
      state = state.copyWith(
        isLoading: false,
        successMessage: '${subjectIds.length} subjects assigned successfully',
      );
      _invalidateProviders(classId, academicYear);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders(int classId, String academicYear) {
    _ref.invalidate(
      classSubjectsProvider((classId: classId, academicYear: academicYear)),
    );
    _ref.invalidate(
      unassignedSubjectsProvider((
        classId: classId,
        academicYear: academicYear,
      )),
    );
  }
}

/// Class subject operation provider
final classSubjectOperationProvider =
    StateNotifierProvider<ClassSubjectOperationNotifier, OperationState>((ref) {
      final repo = ref.watch(classSubjectRepositoryProvider);
      return ClassSubjectOperationNotifier(repo, ref);
    });

// ============================================
// PERIOD DEFINITION OPERATION NOTIFIER
// ============================================

/// Period definition operation notifier
class PeriodDefinitionOperationNotifier extends StateNotifier<OperationState> {
  final PeriodDefinitionRepository _repository;
  final Ref _ref;

  PeriodDefinitionOperationNotifier(this._repository, this._ref)
    : super(const OperationState());

  Future<bool> createPeriod({
    required int periodNumber,
    required String name,
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required int displayOrder,
    required String academicYear,
    bool isBreak = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.create(
        PeriodDefinitionsCompanion.insert(
          periodNumber: periodNumber,
          name: name,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: durationMinutes,
          displayOrder: displayOrder,
          academicYear: academicYear,
          isBreak: Value(isBreak),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Period created successfully',
      );
      _ref.invalidate(periodDefinitionsProvider(academicYear));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> reorderPeriods(
    List<int> ids,
    List<int> newOrders,
    String academicYear,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.reorder(ids, newOrders);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Periods reordered successfully',
      );
      _ref.invalidate(periodDefinitionsProvider(academicYear));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePeriod({
    required int id,
    required String academicYear,
    int? periodNumber,
    String? name,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    int? displayOrder,
    bool? isBreak,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.update(
        id,
        PeriodDefinitionsCompanion(
          periodNumber: periodNumber != null
              ? Value(periodNumber)
              : const Value.absent(),
          name: name != null ? Value(name) : const Value.absent(),
          startTime: startTime != null
              ? Value(startTime)
              : const Value.absent(),
          endTime: endTime != null ? Value(endTime) : const Value.absent(),
          durationMinutes: durationMinutes != null
              ? Value(durationMinutes)
              : const Value.absent(),
          displayOrder: displayOrder != null
              ? Value(displayOrder)
              : const Value.absent(),
          isBreak: isBreak != null ? Value(isBreak) : const Value.absent(),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Period updated successfully',
      );
      _ref.invalidate(periodDefinitionsProvider(academicYear));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePeriod(int id, String academicYear) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.delete(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Period deleted successfully',
      );
      _ref.invalidate(periodDefinitionsProvider(academicYear));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> seedDefaults(String academicYear) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.seedDefaults(academicYear);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Default periods created successfully',
      );
      _ref.invalidate(periodDefinitionsProvider(academicYear));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

/// Period definition operation provider
final periodDefinitionOperationProvider =
    StateNotifierProvider<PeriodDefinitionOperationNotifier, OperationState>((
      ref,
    ) {
      final repo = ref.watch(periodDefinitionRepositoryProvider);
      return PeriodDefinitionOperationNotifier(repo, ref);
    });

// ============================================
// WORKING DAYS PROVIDER
// ============================================

/// Working days provider - gets configured working days from school settings
final workingDaysProvider = FutureProvider<List<String>>((ref) async {
  final service = WorkingDaysService.instance();
  return await service.getWorkingDays();
});

/// Class-specific working days provider
final classWorkingDaysProvider =
    FutureProvider.family<List<String>, ({int classId, String academicYear})>((
      ref,
      params,
    ) async {
      final service = WorkingDaysService.instance();
      return await service.getClassWorkingDays(
        params.classId,
        params.academicYear,
      );
    });
