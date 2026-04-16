/// EduX School Management System
/// Staff Provider - Riverpod state management for staff module
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'student_provider.dart';
import '../repositories/staff_repository.dart';
import '../repositories/leave_repository.dart';
import '../repositories/staff_attendance_repository.dart';
import '../repositories/payroll_repository.dart';
import '../repositories/staff_assignment_repository.dart';
import 'dashboard_provider.dart';
import '../services/staff_service.dart';
import '../services/staff_attendance_service.dart';
import '../services/leave_service.dart';
import '../services/payroll_service.dart';
import '../services/staff_import_service.dart';
import '../services/staff_export_service.dart';

// ============================================
// REPOSITORIES
// ============================================

/// Staff repository provider
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StaffRepositoryImpl(db);
});

/// Leave repository provider
final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LeaveRepositoryImpl(db);
});

/// Staff attendance repository provider
final staffAttendanceRepositoryProvider = Provider<StaffAttendanceRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return StaffAttendanceRepositoryImpl(db);
});

/// Payroll repository provider
final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PayrollRepositoryImpl(db);
});

/// Staff assignment repository provider
final staffAssignmentRepositoryProvider = Provider<StaffAssignmentRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return StaffAssignmentRepositoryImpl(db);
});

// ============================================
// SERVICES
// ============================================

/// Staff service provider
final staffServiceProvider = Provider<StaffService>((ref) {
  final db = ref.watch(databaseProvider);
  return StaffService(db);
});

/// Staff import service provider
final staffImportServiceProvider = Provider<StaffImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return StaffImportService(db);
});

/// Staff export service provider
final staffExportServiceProvider = Provider<StaffExportService>((ref) {
  return StaffExportService();
});

/// Staff attendance service provider
final staffAttendanceServiceProvider = Provider<StaffAttendanceService>((ref) {
  final db = ref.watch(databaseProvider);
  return StaffAttendanceService(db);
});

/// Leave service provider
final leaveServiceProvider = Provider<LeaveService>((ref) {
  final db = ref.watch(databaseProvider);
  return LeaveService(db);
});

/// Payroll service provider
final payrollServiceProvider = Provider<PayrollService>((ref) {
  final db = ref.watch(databaseProvider);
  return PayrollService(db);
});

// ============================================
// FILTERS & PAGINATION
// ============================================

/// Staff filters state
class StaffFiltersNotifier extends StateNotifier<StaffFilters> {
  StaffFiltersNotifier() : super(const StaffFilters());

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
  }

  void setRoleId(int? roleId) {
    state = state.copyWith(roleId: roleId, clearRoleId: roleId == null);
  }

  void setDepartment(String? department) {
    state = state.copyWith(
      department: department,
      clearDepartment: department == null || department.isEmpty,
    );
  }

  void setDesignation(String? designation) {
    state = state.copyWith(
      designation: designation,
      clearDesignation: designation == null,
    );
  }

  void setStatus(String? status) {
    state = state.copyWith(
      status: status,
      clearStatus: status == null || status.isEmpty,
    );
  }

  void setSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending);
  }

  void clearAllFilters() {
    state = state.clearAll();
  }
}

final staffFiltersProvider =
    StateNotifierProvider<StaffFiltersNotifier, StaffFilters>((ref) {
      return StaffFiltersNotifier();
    });

/// Staff pagination state
class StaffPaginationState {
  final int page;
  final int pageSize;
  final int totalItems;

  const StaffPaginationState({
    this.page = 1,
    this.pageSize = 25,
    this.totalItems = 0,
  });

  int get totalPages => (totalItems / pageSize).ceil().clamp(1, 9999);
  int get offset => (page - 1) * pageSize;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  StaffPaginationState copyWith({int? page, int? pageSize, int? totalItems}) {
    return StaffPaginationState(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

class StaffPaginationNotifier extends StateNotifier<StaffPaginationState> {
  StaffPaginationNotifier() : super(const StaffPaginationState());

  void setPage(int page) {
    state = state.copyWith(page: page);
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

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, page: 1);
  }

  void setTotalItems(int total) {
    state = state.copyWith(totalItems: total);
  }
}

final staffPaginationProvider =
    StateNotifierProvider<StaffPaginationNotifier, StaffPaginationState>((ref) {
      return StaffPaginationNotifier();
    });

// ============================================
// DATA PROVIDERS
// ============================================

/// Staff list provider with filters and pagination
final staffListProvider = FutureProvider.autoDispose<List<StaffWithRole>>((
  ref,
) async {
  final repository = ref.watch(staffRepositoryProvider);
  final filters = ref.watch(staffFiltersProvider);
  final pagination = ref.watch(staffPaginationProvider);

  final filtersWithPagination = StaffFilters(
    searchQuery: filters.searchQuery,
    roleId: filters.roleId,
    department: filters.department,
    designation: filters.designation,
    status: filters.status,
    sortBy: filters.sortBy,
    ascending: filters.ascending,
    limit: pagination.pageSize,
    offset: pagination.offset,
  );

  return await repository.search(filtersWithPagination);
});

/// Staff count provider
final staffCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  final filters = ref.watch(staffFiltersProvider);

  return await repository.count(
    roleId: filters.roleId,
    department: filters.department,
    status: filters.status,
  );
});

/// Single staff provider by ID
final staffByIdProvider = FutureProvider.autoDispose
    .family<StaffWithRole?, int>((ref, id) async {
      final repository = ref.watch(staffRepositoryProvider);
      return await repository.getById(id);
    });

/// All staff roles
final staffRolesProvider = FutureProvider<List<StaffRole>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return await repository.getAllRoles();
});

/// Teachers only (staff with canTeach role)
final teachersProvider = FutureProvider<List<StaffWithRole>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return await repository.getTeachers();
});

/// Unassigned staff (staff without user account)
final unassignedStaffProvider = FutureProvider.autoDispose<List<StaffWithRole>>(
  (ref) async {
    final repository = ref.watch(staffRepositoryProvider);
    return await repository.getUnassignedStaff();
  },
);

/// Distinct departments
final staffDepartmentsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return await repository.getDistinctDepartments();
});

/// Distinct designations
final staffDesignationsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  return await repository.getDistinctDesignations();
});

// ============================================
// OPERATION STATE
// ============================================

/// Staff operation state for CRUD operations
class StaffOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const StaffOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  StaffOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StaffOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class StaffOperationNotifier extends StateNotifier<StaffOperationState> {
  final StaffService _service;
  final Ref _ref;

  StaffOperationNotifier(this._service, this._ref)
    : super(const StaffOperationState());

  Future<int?> createStaff(StaffFormData data) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final id = await _service.createStaff(data);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Staff member created successfully',
      );
      _invalidateStaffProviders();
      return id;
    } on StaffValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.errors.values.join(', '),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create staff: $e',
      );
      return null;
    }
  }

  Future<bool> updateStaff(int staffId, StaffFormData data) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final success = await _service.updateStaff(staffId, data);
      state = state.copyWith(
        isLoading: false,
        successMessage: success ? 'Staff member updated successfully' : null,
        error: success ? null : 'Failed to update staff',
      );
      if (success) _invalidateStaffProviders();
      return success;
    } on StaffValidationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.errors.values.join(', '),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update staff: $e',
      );
      return false;
    }
  }

  Future<bool> deleteStaff(int staffId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final success = await _service.deleteStaff(staffId);
      state = state.copyWith(
        isLoading: false,
        successMessage: success ? 'Staff member deleted successfully' : null,
        error: success ? null : 'Failed to delete staff',
      );
      if (success) _invalidateStaffProviders();
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete staff: $e',
      );
      return false;
    }
  }

  Future<bool> updateStatus(int staffId, String status) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final success = await _service.updateStatus(staffId, status);
      state = state.copyWith(
        isLoading: false,
        successMessage: success ? 'Status updated successfully' : null,
      );
      if (success) _invalidateStaffProviders();
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update status: $e',
      );
      return false;
    }
  }

  Future<bool> deleteStaffMembers(List<int> ids) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final count = await _service.bulkDelete(ids);
      final success = count > 0;

      if (success) {
        _invalidateStaffProviders();
        _ref.read(selectedStaffProvider.notifier).state = {};
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: success
            ? '$count staff members deleted successfully'
            : null,
        error: success ? null : 'Failed to delete staff members',
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete staff members: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateStaffProviders() {
    _ref.invalidate(staffListProvider);
    _ref.invalidate(staffCountProvider);
    _ref.invalidate(teachersProvider);
    _ref.invalidate(staffDepartmentsProvider);
    _ref.invalidate(staffDesignationsProvider);
    _ref.invalidate(dashboardProvider);
  }
}

final staffOperationProvider =
    StateNotifierProvider<StaffOperationNotifier, StaffOperationState>((ref) {
      final service = ref.watch(staffServiceProvider);
      return StaffOperationNotifier(service, ref);
    });

/// Selected staff provider (for bulk operations)
final selectedStaffProvider = StateProvider<Set<int>>((ref) => {});

// ============================================
// LEAVE PROVIDERS
// ============================================

/// Leave types
final leaveTypesProvider = FutureProvider<List<LeaveType>>((ref) async {
  final service = ref.watch(leaveServiceProvider);
  return await service.getAllLeaveTypes();
});

/// Leave filter state
class LeaveFilterState {
  final String? status;
  final int? staffId;

  const LeaveFilterState({this.status, this.staffId});

  LeaveFilterState copyWith({
    String? status,
    int? staffId,
    bool clearStatus = false,
    bool clearStaffId = false,
  }) {
    return LeaveFilterState(
      status: clearStatus ? null : (status ?? this.status),
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
    );
  }
}

final leaveFilterProvider = StateProvider<LeaveFilterState>(
  (ref) => const LeaveFilterState(),
);

/// Leave requests with filters
final leaveRequestsProvider =
    FutureProvider.autoDispose<List<LeaveRequestWithDetails>>((ref) async {
      final service = ref.watch(leaveServiceProvider);
      final filters = ref.watch(leaveFilterProvider);

      return await service.getRequests(
        status: filters.status,
        staffId: filters.staffId,
        limit: 100,
      );
    });

/// Pending leave requests
final pendingLeaveRequestsProvider =
    FutureProvider.autoDispose<List<LeaveRequestWithDetails>>((ref) async {
      final service = ref.watch(leaveServiceProvider);
      return await service.getPendingRequests();
    });

/// Leave balance for a staff
final leaveBalanceProvider = FutureProvider.autoDispose
    .family<List<LeaveBalance>, int>((ref, staffId) async {
      final repository = ref.watch(leaveRepositoryProvider);
      return await repository.getLeaveBalance(staffId);
    });

// ============================================
// ATTENDANCE PROVIDERS
// ============================================

/// Selected date for attendance
final staffAttendanceDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Staff attendance for selected date
final staffAttendanceForDateProvider =
    FutureProvider.autoDispose<List<StaffAttendanceRecord>>((ref) async {
      final service = ref.watch(staffAttendanceServiceProvider);
      final date = ref.watch(staffAttendanceDateProvider);

      return await service.getAttendanceForDate(date);
    });

/// Daily attendance summary
final staffDailySummaryProvider =
    FutureProvider.autoDispose<DailyStaffAttendanceSummary>((ref) async {
      final repository = ref.watch(staffAttendanceRepositoryProvider);
      final date = ref.watch(staffAttendanceDateProvider);

      return await repository.getDailySummary(date);
    });

/// Staff attendance stats
final staffAttendanceStatsProvider = FutureProvider.autoDispose
    .family<
      StaffAttendanceStats,
      ({int staffId, DateTime start, DateTime end})
    >((ref, params) async {
      final repository = ref.watch(staffAttendanceRepositoryProvider);
      return await repository.getStaffStats(
        params.staffId,
        startDate: params.start,
        endDate: params.end,
      );
    });

// ============================================
// PAYROLL PROVIDERS
// ============================================

/// Selected month for payroll
final payrollMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

/// Payroll for selected month
final payrollForMonthProvider =
    FutureProvider.autoDispose<List<PayrollWithStaff>>((ref) async {
      final repository = ref.watch(payrollRepositoryProvider);
      final month = ref.watch(payrollMonthProvider);

      return await repository.getByMonth(month);
    });

/// Pending payrolls
final pendingPayrollsProvider =
    FutureProvider.autoDispose<List<PayrollWithStaff>>((ref) async {
      final repository = ref.watch(payrollRepositoryProvider);
      final month = ref.watch(payrollMonthProvider);

      return await repository.getPending(month: month);
    });

/// Monthly payroll summary
final payrollSummaryProvider =
    FutureProvider.autoDispose<PayrollMonthlySummary>((ref) async {
      final repository = ref.watch(payrollRepositoryProvider);
      final month = ref.watch(payrollMonthProvider);

      return await repository.getMonthlySummary(month);
    });

/// Staff payroll history
final staffPayrollHistoryProvider = FutureProvider.autoDispose
    .family<List<PayrollWithStaff>, int>((ref, staffId) async {
      final repository = ref.watch(payrollRepositoryProvider);
      return await repository.getByStaff(staffId);
    });

// ============================================
// ASSIGNMENT PROVIDERS
// ============================================

/// Academic year for assignments
final assignmentAcademicYearProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return now.month >= 4
      ? '${now.year}-${now.year + 1}'
      : '${now.year - 1}-${now.year}';
});

/// All assignments for academic year
final staffAssignmentsProvider =
    FutureProvider.autoDispose<List<StaffAssignmentWithDetails>>((ref) async {
      final repository = ref.watch(staffAssignmentRepositoryProvider);
      final academicYear = ref.watch(assignmentAcademicYearProvider);

      return await repository.getAllForYear(academicYear);
    });

/// Assignments by staff
final assignmentsByStaffProvider = FutureProvider.autoDispose
    .family<List<StaffAssignmentWithDetails>, int>((ref, staffId) async {
      final repository = ref.watch(staffAssignmentRepositoryProvider);
      final academicYear = ref.watch(assignmentAcademicYearProvider);

      return await repository.getByStaff(staffId, academicYear: academicYear);
    });

/// Teacher workload
final teacherWorkloadProvider = FutureProvider.autoDispose
    .family<TeacherWorkload, int>((ref, staffId) async {
      final repository = ref.watch(staffAssignmentRepositoryProvider);
      final academicYear = ref.watch(assignmentAcademicYearProvider);

      return await repository.getTeacherWorkload(
        staffId,
        academicYear: academicYear,
      );
    });
