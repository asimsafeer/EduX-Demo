/// EduX School Management System
/// Attendance Provider - Riverpod state management for attendance module
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/attendance_repository.dart';
import '../services/attendance_service.dart';
import '../services/attendance_pdf_service.dart';
import '../providers/academics_provider.dart';
import '../providers/dashboard_provider.dart';

// ============================================
// REPOSITORY & SERVICE PROVIDERS
// ============================================

/// Attendance repository provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AttendanceRepositoryImpl(db);
});

/// Attendance service provider
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final db = ref.watch(databaseProvider);
  return AttendanceService(repository, db);
});

/// Attendance PDF service provider
final attendancePdfServiceProvider = Provider<AttendancePdfService>((ref) {
  return AttendancePdfService();
});

// ============================================
// SELECTED STATE PROVIDERS
// ============================================

/// Selected date for attendance (defaults to today)
final attendanceSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Selected class ID for attendance
final attendanceSelectedClassProvider = StateProvider<int?>((ref) => null);

/// Selected section ID for attendance
final attendanceSelectedSectionProvider = StateProvider<int?>((ref) => null);

/// Selected month/year for calendar view
final attendanceCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// ============================================
// ATTENDANCE DATA PROVIDERS
// ============================================

/// Query parameters for class attendance
class AttendanceQuery {
  final int classId;
  final int sectionId;
  final DateTime date;
  final String academicYear;

  const AttendanceQuery({
    required this.classId,
    required this.sectionId,
    required this.date,
    required this.academicYear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceQuery &&
          runtimeType == other.runtimeType &&
          classId == other.classId &&
          sectionId == other.sectionId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          academicYear == other.academicYear;

  @override
  int get hashCode =>
      classId.hashCode ^
      sectionId.hashCode ^
      date.year.hashCode ^
      date.month.hashCode ^
      date.day.hashCode ^
      academicYear.hashCode;
}

/// Class attendance for a specific date provider
final classAttendanceProvider = FutureProvider.autoDispose
    .family<List<StudentAttendanceEntry>, AttendanceQuery>((ref, query) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getClassAttendance(
        classId: query.classId,
        sectionId: query.sectionId,
        date: query.date,
        academicYear: query.academicYear,
      );
    });

/// Daily attendance summary provider
final dailySummaryProvider = FutureProvider.autoDispose
    .family<
      DailyAttendanceSummary,
      ({int classId, int sectionId, DateTime date})
    >((ref, params) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getDailySummary(
        classId: params.classId,
        sectionId: params.sectionId,
        date: params.date,
      );
    });

/// Student attendance stats provider
final studentAttendanceStatsProvider = FutureProvider.autoDispose
    .family<
      AttendanceStats,
      ({int studentId, DateTime startDate, DateTime endDate})
    >((ref, params) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getStudentStats(
        studentId: params.studentId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

/// Class attendance stats provider
final classAttendanceStatsProvider = FutureProvider.autoDispose
    .family<
      AttendanceStats,
      ({int classId, int sectionId, DateTime startDate, DateTime endDate})
    >((ref, params) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getClassStats(
        classId: params.classId,
        sectionId: params.sectionId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

/// Student attendance history provider
final studentAttendanceHistoryProvider = FutureProvider.autoDispose
    .family<
      List<StudentAttendanceData>,
      ({int studentId, DateTime? startDate, DateTime? endDate})
    >((ref, params) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getStudentHistory(
        studentId: params.studentId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

/// Calendar indicators provider
final calendarIndicatorsProvider = FutureProvider.autoDispose
    .family<
      List<CalendarDayIndicator>,
      ({int classId, int sectionId, int year, int month})
    >((ref, params) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getCalendarData(
        classId: params.classId,
        sectionId: params.sectionId,
        year: params.year,
        month: params.month,
      );
    });

/// Low attendance alerts provider
final lowAttendanceAlertsProvider = FutureProvider.autoDispose
    .family<List<LowAttendanceAlert>, ({double threshold, int? classId})>((
      ref,
      params,
    ) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getLowAttendanceAlerts(
        threshold: params.threshold,
        classId: params.classId,
      );
    });

/// Today's unmarked classes provider
final todayUnmarkedClassesProvider =
    FutureProvider.autoDispose<
      List<({int classId, int sectionId, String className, String sectionName})>
    >((ref) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.getTodayUnmarkedClasses();
    });

/// Check if attendance is marked for a date
final isAttendanceMarkedProvider = FutureProvider.autoDispose
    .family<bool, ({int classId, int sectionId, DateTime date})>((
      ref,
      params,
    ) async {
      final service = ref.watch(attendanceServiceProvider);
      return service.isAttendanceMarked(
        classId: params.classId,
        sectionId: params.sectionId,
        date: params.date,
      );
    });

/// Daily attendance lock status provider
final dailyAttendanceStatusProvider = FutureProvider.autoDispose
    .family<
      DailyAttendanceStatusData?,
      ({int classId, int sectionId, DateTime date})
    >((ref, params) async {
      final repository = ref.watch(attendanceRepositoryProvider);
      return repository.getDailyStatus(
        params.classId,
        params.sectionId,
        params.date,
      );
    });

// ============================================
// LOCAL ATTENDANCE STATE (FOR MARKING)
// ============================================

/// Local attendance state for editing before save
class LocalAttendanceState {
  final Map<int, String> statuses; // studentId -> status
  final Map<int, String?> remarks; // studentId -> remarks
  final bool hasChanges;

  const LocalAttendanceState({
    this.statuses = const {},
    this.remarks = const {},
    this.hasChanges = false,
  });

  LocalAttendanceState copyWith({
    Map<int, String>? statuses,
    Map<int, String?>? remarks,
    bool? hasChanges,
  }) {
    return LocalAttendanceState(
      statuses: statuses ?? this.statuses,
      remarks: remarks ?? this.remarks,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  LocalAttendanceState setStatus(int studentId, String status) {
    final newStatuses = Map<int, String>.from(statuses);
    newStatuses[studentId] = status;
    return copyWith(statuses: newStatuses, hasChanges: true);
  }

  LocalAttendanceState setRemarks(int studentId, String? remarksText) {
    final newRemarks = Map<int, String?>.from(remarks);
    newRemarks[studentId] = remarksText;
    return copyWith(remarks: newRemarks, hasChanges: true);
  }

  LocalAttendanceState setAllStatus(List<int> studentIds, String status) {
    final newStatuses = Map<int, String>.from(statuses);
    for (final id in studentIds) {
      newStatuses[id] = status;
    }
    return copyWith(statuses: newStatuses, hasChanges: true);
  }

  LocalAttendanceState loadFromEntries(List<StudentAttendanceEntry> entries) {
    final newStatuses = <int, String>{};
    final newRemarks = <int, String?>{};

    for (final entry in entries) {
      if (entry.attendance != null) {
        newStatuses[entry.student.id] = entry.attendance!.status;
        newRemarks[entry.student.id] = entry.attendance!.remarks;
      } else {
        // Default to present for new entries
        newStatuses[entry.student.id] = 'present';
      }
    }

    return LocalAttendanceState(
      statuses: newStatuses,
      remarks: newRemarks,
      hasChanges: false,
    );
  }

  List<AttendanceMarkData> toMarkDataList() {
    return statuses.entries
        .map(
          (e) => AttendanceMarkData(
            studentId: e.key,
            status: e.value,
            remarks: remarks[e.key],
          ),
        )
        .toList();
  }
}

/// Local attendance state notifier
class LocalAttendanceNotifier extends StateNotifier<LocalAttendanceState> {
  LocalAttendanceNotifier() : super(const LocalAttendanceState());

  void setStatus(int studentId, String status) {
    state = state.setStatus(studentId, status);
  }

  void setRemarks(int studentId, String? remarks) {
    state = state.setRemarks(studentId, remarks);
  }

  void setAllStatus(List<int> studentIds, String status) {
    state = state.setAllStatus(studentIds, status);
  }

  void loadFromEntries(List<StudentAttendanceEntry> entries) {
    state = state.loadFromEntries(entries);
  }

  void reset() {
    state = const LocalAttendanceState();
  }

  void markSaved() {
    state = state.copyWith(hasChanges: false);
  }
}

/// Local attendance state provider
final localAttendanceProvider =
    StateNotifierProvider.autoDispose<
      LocalAttendanceNotifier,
      LocalAttendanceState
    >((ref) {
      return LocalAttendanceNotifier();
    });

// ============================================
// OPERATION STATE
// ============================================

/// Attendance operation state
class AttendanceOperationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final bool isSaving;

  const AttendanceOperationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.isSaving = false,
  });

  AttendanceOperationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? isSaving,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AttendanceOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Attendance operation notifier
class AttendanceOperationNotifier
    extends StateNotifier<AttendanceOperationState> {
  final AttendanceService _service;
  final Ref _ref;

  AttendanceOperationNotifier(this._service, this._ref)
    : super(const AttendanceOperationState());

  /// Save attendance for a class
  Future<bool> saveAttendance({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
    required List<AttendanceMarkData> attendanceData,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _service.markBulkAttendance(
        attendanceData: attendanceData,
        classId: classId,
        sectionId: sectionId,
        date: date,
        academicYear: academicYear,
        markedBy: markedBy,
      );

      if (result.failCount > 0) {
        state = state.copyWith(
          isSaving: false,
          error: 'Some records failed: ${result.errors.join(", ")}',
        );
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        successMessage:
            'Attendance saved successfully for ${result.successCount} students',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Mark all students present
  Future<bool> markAllPresent({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _service.markAllPresent(
        classId: classId,
        sectionId: sectionId,
        date: date,
        academicYear: academicYear,
        markedBy: markedBy,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Marked ${result.successCount} students as present',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Mark all students absent
  Future<bool> markAllAbsent({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await _service.markAllAbsent(
        classId: classId,
        sectionId: sectionId,
        date: date,
        academicYear: academicYear,
        markedBy: markedBy,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Marked ${result.successCount} students as absent',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Update single attendance
  Future<bool> updateAttendance({
    required int attendanceId,
    required String status,
    required int updatedBy,
    String? remarks,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get attendance record first to know which providers to invalidate
      final attendance = await _service.getAttendanceById(attendanceId);

      await _service.updateAttendance(
        attendanceId: attendanceId,
        status: status,
        updatedBy: updatedBy,
        remarks: remarks,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Attendance updated successfully',
      );

      if (attendance != null) {
        _invalidateProviders(
          attendance.classId,
          attendance.sectionId,
          attendance.date,
        );
      } else {
        // Fallback: invalidate dashboard at least
        _ref.invalidate(dashboardProvider);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete attendance for a date
  Future<bool> deleteAttendanceForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
    required int deletedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final count = await _service.deleteAttendanceForDate(
        classId: classId,
        sectionId: sectionId,
        date: date,
        deletedBy: deletedBy,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deleted $count attendance records',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Lock attendance for a date
  Future<bool> lockAttendance({
    required int classId,
    required int sectionId,
    required DateTime date,
    required int lockedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.repository.lockAttendance(
        classId,
        sectionId,
        date,
        lockedBy,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Attendance locked successfully',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Unlock attendance for a date
  Future<bool> unlockAttendance({
    required int classId,
    required int sectionId,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.repository.unlockAttendance(classId, sectionId, date);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Attendance unlocked successfully',
      );

      _invalidateProviders(classId, sectionId, date);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _invalidateProviders(int classId, int sectionId, DateTime date) {
    final academicYear =
        _ref.read(currentAcademicYearProvider).valueOrNull ?? '';

    _ref.invalidate(
      classAttendanceProvider(
        AttendanceQuery(
          classId: classId,
          sectionId: sectionId,
          date: date,
          academicYear: academicYear,
        ),
      ),
    );
    _ref.invalidate(
      dailySummaryProvider((
        classId: classId,
        sectionId: sectionId,
        date: date,
      )),
    );
    _ref.invalidate(
      calendarIndicatorsProvider((
        classId: classId,
        sectionId: sectionId,
        year: date.year,
        month: date.month,
      )),
    );
    _ref.invalidate(todayUnmarkedClassesProvider);
    _ref.invalidate(
      isAttendanceMarkedProvider((
        classId: classId,
        sectionId: sectionId,
        date: date,
      )),
    );
    _ref.invalidate(
      dailyAttendanceStatusProvider((
        classId: classId,
        sectionId: sectionId,
        date: date,
      )),
    );
    _ref.invalidate(dashboardProvider);
  }
}

/// Attendance operation provider
final attendanceOperationProvider =
    StateNotifierProvider<
      AttendanceOperationNotifier,
      AttendanceOperationState
    >((ref) {
      final service = ref.watch(attendanceServiceProvider);
      return AttendanceOperationNotifier(service, ref);
    });

// ============================================
// REPORT GENERATION STATE
// ============================================

/// Report generation state
class ReportGenerationState {
  final bool isGenerating;
  final String? error;
  final String reportType;

  const ReportGenerationState({
    this.isGenerating = false,
    this.error,
    this.reportType = '',
  });

  ReportGenerationState copyWith({
    bool? isGenerating,
    String? error,
    String? reportType,
    bool clearError = false,
  }) {
    return ReportGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      reportType: reportType ?? this.reportType,
    );
  }
}

/// Report generation notifier
class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  ReportGenerationNotifier() : super(const ReportGenerationState());

  void startGenerating(String reportType) {
    state = state.copyWith(
      isGenerating: true,
      reportType: reportType,
      clearError: true,
    );
  }

  void finishGenerating() {
    state = state.copyWith(isGenerating: false);
  }

  void setError(String error) {
    state = state.copyWith(isGenerating: false, error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Report generation provider
final reportGenerationProvider =
    StateNotifierProvider<ReportGenerationNotifier, ReportGenerationState>((
      ref,
    ) {
      return ReportGenerationNotifier();
    });

// ============================================
// HELPER PROVIDERS
// ============================================

/// Current academic year value provider (simplified access)
final attendanceAcademicYearProvider = FutureProvider<String>((ref) async {
  final result = await ref.watch(currentAcademicYearProvider.future);
  return result;
});

/// Combined selected class and section valid check
final isAttendanceSelectionValidProvider = Provider<bool>((ref) {
  final classId = ref.watch(attendanceSelectedClassProvider);
  final sectionId = ref.watch(attendanceSelectedSectionProvider);
  return classId != null && sectionId != null;
});

/// Date range for current academic year (for stats)
final academicYearDateRangeProvider =
    FutureProvider<({DateTime start, DateTime end})>((ref) async {
      final db = ref.watch(databaseProvider);
      final academicYear = await db.getCurrentAcademicYear();

      if (academicYear != null) {
        return (start: academicYear.startDate, end: academicYear.endDate);
      }

      // Default to current school year (April to March)
      final now = DateTime.now();
      final startYear = now.month >= 4 ? now.year : now.year - 1;
      return (
        start: DateTime(startYear, 4, 1),
        end: DateTime(startYear + 1, 3, 31),
      );
    });
