/// EduX School Management System
/// Student Provider - Riverpod state management for student module
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/student_repository.dart';
import '../repositories/enrollment_repository.dart';
import '../services/student_service.dart';
import '../services/student_export_service.dart';
import '../services/student_import_service.dart';
import 'academics_provider.dart' as academics;
import 'assigned_classes_provider.dart';
import 'refresh_service.dart';

/// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Student repository provider
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StudentRepositoryImpl(db);
});

/// Enrollment repository provider
final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EnrollmentRepositoryImpl(db);
});

/// Student service provider
final studentServiceProvider = Provider<StudentService>((ref) {
  final db = ref.watch(databaseProvider);
  return StudentService(db);
});

/// Student export service provider
final studentExportServiceProvider = Provider<StudentExportService>((ref) {
  return StudentExportService();
});

/// Student import service provider
final studentImportServiceProvider = Provider<StudentImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return StudentImportService(db);
});

/// Pagination state
class PaginationState {
  final int page;
  final int pageSize;
  final int totalItems;

  const PaginationState({
    this.page = 1,
    this.pageSize = 25,
    this.totalItems = 0,
  });

  int get offset => (page - 1) * pageSize;
  int get totalPages => (totalItems / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  PaginationState copyWith({int? page, int? pageSize, int? totalItems}) {
    return PaginationState(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

/// Pagination notifier
class PaginationNotifier extends StateNotifier<PaginationState> {
  PaginationNotifier() : super(const PaginationState());

  void setPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(page: page);
    }
  }

  void nextPage() {
    if (state.hasNextPage) {
      state = state.copyWith(page: state.page + 1);
    }
  }

  void previousPage() {
    if (state.hasPreviousPage) {
      state = state.copyWith(page: state.page - 1);
    }
  }

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, page: 1);
  }

  void setTotalItems(int totalItems) {
    state = state.copyWith(totalItems: totalItems);
  }

  void reset() {
    state = const PaginationState();
  }
}

/// Pagination provider
final studentPaginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState>((ref) {
      return PaginationNotifier();
    });

/// Student filters model for UI
class StudentListFilters {
  final String? searchQuery;
  final int? classId;
  final int? sectionId;
  final String? gender;
  final String? status;
  final String sortBy;
  final bool ascending;
  final int limit;
  final int offset;
  final bool groupByClass;

  const StudentListFilters({
    this.searchQuery,
    this.classId,
    this.sectionId,
    this.gender,
    this.status,
    this.sortBy = 'admissionNumber',
    this.ascending = true,
    this.limit = 25,
    this.offset = 0,
    this.groupByClass = false,
  });

  bool get hasFilters =>
      searchQuery != null ||
      classId != null ||
      sectionId != null ||
      gender != null ||
      status != null ||
      groupByClass;

  StudentListFilters copyWith({
    String? searchQuery,
    bool clearSearch = false,
    int? classId,
    bool clearClassId = false,
    int? sectionId,
    bool clearSectionId = false,
    String? gender,
    bool clearGender = false,
    String? status,
    bool clearStatus = false,
    String? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
    bool? groupByClass,
  }) {
    return StudentListFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      classId: clearClassId ? null : (classId ?? this.classId),
      sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
      gender: clearGender ? null : (gender ?? this.gender),
      status: clearStatus ? null : (status ?? this.status),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      groupByClass: groupByClass ?? this.groupByClass,
    );
  }

  StudentListFilters clearAll() {
    return const StudentListFilters();
  }
}

/// Student filters notifier
class StudentFiltersNotifier extends StateNotifier<StudentListFilters> {
  StudentFiltersNotifier() : super(const StudentListFilters());

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
  }

  void setClassId(int? classId) {
    state = state.copyWith(
      classId: classId,
      clearClassId: classId == null,
      clearSectionId: true, // Reset section when class changes
    );
  }

  void setSectionId(int? sectionId) {
    state = state.copyWith(
      sectionId: sectionId,
      clearSectionId: sectionId == null,
    );
  }

  void setGender(String? gender) {
    state = state.copyWith(
      gender: gender,
      clearGender: gender == null || gender.isEmpty,
    );
  }

  void setStatus(String? status) {
    state = state.copyWith(
      status: status,
      clearStatus: status == null || status.isEmpty,
    );
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

  void updatePagination(int limit, int offset) {
    state = state.copyWith(limit: limit, offset: offset);
  }

  void toggleGroupByClass(bool value) {
    state = state.copyWith(groupByClass: value);
  }
}

/// Student filters provider
final studentFiltersProvider =
    StateNotifierProvider<StudentFiltersNotifier, StudentListFilters>((ref) {
      return StudentFiltersNotifier();
    });

/// Student count provider
final studentCountProvider = FutureProvider<int>((ref) async {
  final filters = ref.watch(studentFiltersProvider);
  final repo = ref.watch(studentRepositoryProvider);
  final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

  // If user has class restrictions and no explicit class filter is set,
  // sum counts across assigned classes.
  if (assignedClassIds != null && filters.classId == null) {
    if (assignedClassIds.isEmpty) return 0;
    int total = 0;
    for (final cid in assignedClassIds) {
      total += await repo.count(
        classId: cid,
        sectionId: filters.sectionId,
        status: filters.status,
      );
    }
    return total;
  }

  return await repo.count(
    classId: filters.classId,
    sectionId: filters.sectionId,
    status: filters.status,
  );
});

/// Students list provider with filters and pagination
final studentsProvider = FutureProvider.autoDispose<List<StudentWithEnrollment>>((
  ref,
) async {
  final filters = ref.watch(studentFiltersProvider);
  final pagination = ref.watch(studentPaginationProvider);
  final repo = ref.watch(studentRepositoryProvider);
  final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

  // If restricted user with no explicit class filter, query per assigned class
  if (assignedClassIds != null && filters.classId == null) {
    if (assignedClassIds.isEmpty) return [];
    final List<StudentWithEnrollment> allResults = [];
    for (final cid in assignedClassIds) {
      final searchFilters = StudentFilters(
        searchQuery: filters.searchQuery,
        classId: cid,
        sectionId: filters.sectionId,
        gender: filters.gender,
        status: filters.status,
        sortBy: filters.sortBy,
        ascending: filters.ascending,
        limit: 0, // No limit
        offset: 0,
      );
      allResults.addAll(await repo.search(searchFilters));
    }
    // Apply manual pagination
    allResults.sort(
      (a, b) => a.student.admissionNumber.compareTo(b.student.admissionNumber),
    );
    final start = pagination.offset.clamp(0, allResults.length);
    final end = (start + pagination.pageSize).clamp(0, allResults.length);
    return allResults.sublist(start, end);
  }

  // Update filters with pagination
  final searchFilters = StudentFilters(
    searchQuery: filters.searchQuery,
    classId: filters.classId,
    sectionId: filters.sectionId,
    gender: filters.gender,
    status: filters.status,
    sortBy: filters.sortBy,
    ascending: filters.ascending,
    limit: pagination.pageSize,
    offset: pagination.offset,
  );

  return await repo.search(searchFilters);
});

/// All students provider (no pagination, for exports and grouped view)
final allStudentsProvider =
    FutureProvider.autoDispose<List<StudentWithEnrollment>>((ref) async {
      final filters = ref.watch(studentFiltersProvider);
      final repo = ref.watch(studentRepositoryProvider);
      final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

      // If restricted user with no explicit class filter, query per assigned class
      if (assignedClassIds != null && filters.classId == null) {
        if (assignedClassIds.isEmpty) return [];
        final List<StudentWithEnrollment> allResults = [];
        for (final cid in assignedClassIds) {
          final searchFilters = StudentFilters(
            searchQuery: filters.searchQuery,
            classId: cid,
            sectionId: filters.sectionId,
            gender: filters.gender,
            status: filters.status,
            sortBy: filters.sortBy,
            ascending: filters.ascending,
            limit: 0, // No limit
            offset: 0,
          );
          allResults.addAll(await repo.search(searchFilters));
        }
        return allResults;
      }

      // Get all matching students without pagination
      final searchFilters = StudentFilters(
        searchQuery: filters.searchQuery,
        classId: filters.classId,
        sectionId: filters.sectionId,
        gender: filters.gender,
        status: filters.status,
        sortBy: filters.sortBy,
        ascending: filters.ascending,
        limit: 0, // No limit
        offset: 0,
      );

      return await repo.search(searchFilters);
    });

/// All active students provider for selection dialogs (no pagination)
final allActiveStudentsProvider =
    FutureProvider.autoDispose<List<StudentWithEnrollment>>((ref) async {
      final repo = ref.watch(studentRepositoryProvider);
      final assignedClassIds = ref.watch(assignedClassIdsProvider).valueOrNull;

      // If restricted user, query per assigned class
      if (assignedClassIds != null) {
        if (assignedClassIds.isEmpty) return [];
        final List<StudentWithEnrollment> allResults = [];
        for (final cid in assignedClassIds) {
          final searchFilters = StudentFilters(
            classId: cid,
            status: 'active',
            sortBy: 'studentName',
            ascending: true,
            limit: 0, // No limit
            offset: 0,
          );
          allResults.addAll(await repo.search(searchFilters));
        }
        // Sort combined results
        allResults.sort((a, b) => a.student.studentName.compareTo(b.student.studentName));
        return allResults;
      }

      // Get all active students without pagination
      final searchFilters = StudentFilters(
        status: 'active',
        sortBy: 'studentName',
        ascending: true,
        limit: 0, // No limit
        offset: 0,
      );

      return await repo.search(searchFilters);
    });

/// Student by ID provider
final studentByIdProvider = FutureProvider.autoDispose
    .family<StudentWithEnrollment?, int>((ref, id) async {
      final repo = ref.watch(studentRepositoryProvider);
      return await repo.getWithCurrentEnrollment(id);
    });

/// Classes provider
final classesProvider = academics.classesProvider;

/// Sections by class provider
final sectionsByClassProvider = academics.sectionsByClassProvider;

/// School settings provider (for exports)
final schoolSettingsForExportProvider = FutureProvider<SchoolSetting?>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  return await db.getSchoolSettings();
});

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

/// Loading state for student operations
class StudentOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const StudentOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  StudentOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StudentOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Student operation notifier for CRUD operations
class StudentOperationNotifier extends StateNotifier<StudentOperationState> {
  final Ref _ref;

  StudentOperationNotifier(this._ref) : super(const StudentOperationState());

  Future<int?> createStudent(StudentFormData data) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      final id = await service.createStudent(data);

      // Refresh student data and cross-module providers
      RefreshService.refreshStudentData(_ref.invalidate);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Student created successfully',
      );
      return id;
    } on ValidationException catch (e) {
      state = state.copyWith(isLoading: false, error: e.errors.values.first);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create student: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> updateStudent(int id, StudentFormData data) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      await service.updateStudent(id, data);

      // Refresh student data and cross-module providers
      RefreshService.refreshStudentData(_ref.invalidate);
      _ref.invalidate(studentByIdProvider(id));

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Student updated successfully',
      );
      return true;
    } on ValidationException catch (e) {
      state = state.copyWith(isLoading: false, error: e.errors.values.first);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update student: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteStudent(int id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      await service.deleteStudent(id);

      // Refresh student data and cross-module providers
      RefreshService.refreshStudentData(_ref.invalidate);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Student deleted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete student: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteStudents(List<int> ids) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      final count = await service.bulkDelete(ids);

      // Refresh student data and cross-module providers
      RefreshService.refreshStudentData(_ref.invalidate);
      _ref.read(selectedStudentsProvider.notifier).state = {};

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deleted $count students successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete students: ${e.toString()}',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Bulk update status for multiple students (by class)
  Future<int> bulkUpdateStatus(List<int> studentIds, String newStatus) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      final count = await service.bulkUpdateStatus(studentIds, newStatus);

      RefreshService.refreshStudentData(_ref.invalidate);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Updated $count students to $newStatus',
      );
      return count;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: ${e.toString()}',
      );
      return 0;
    }
  }

  /// Bulk promote students to a new class or graduate them
  Future<int> bulkPromoteStudents({
    required List<int> studentIds,
    int? targetClassId,
    int? targetSectionId,
    required String academicYear,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = _ref.read(studentServiceProvider);
      final count = await service.bulkPromoteStudents(
        studentIds: studentIds,
        targetClassId: targetClassId,
        targetSectionId: targetSectionId,
        academicYear: academicYear,
      );

      RefreshService.refreshStudentData(_ref.invalidate);
      _ref.read(selectedStudentsProvider.notifier).state = {};

      final action = targetClassId == null ? 'Graduated' : 'Promoted';
      state = state.copyWith(
        isLoading: false,
        successMessage: '$action $count students successfully',
      );
      return count;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to promote students: ${e.toString()}',
      );
      return 0;
    }
  }
}

/// Student operation provider
final studentOperationProvider =
    StateNotifierProvider<StudentOperationNotifier, StudentOperationState>((
      ref,
    ) {
      return StudentOperationNotifier(ref);
    });

/// Selected students provider (for bulk operations)
final selectedStudentsProvider = StateProvider<Set<int>>((ref) => {});
