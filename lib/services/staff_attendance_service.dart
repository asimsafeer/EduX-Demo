/// EduX School Management System
/// Staff Attendance Service - Business logic for staff attendance
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/staff_attendance_repository.dart';
import '../repositories/staff_repository.dart';
import '../repositories/leave_repository.dart';

/// Result of attendance validation
class StaffAttendanceValidationResult {
  final bool isValid;
  final String? error;

  const StaffAttendanceValidationResult({required this.isValid, this.error});
}

/// Data for marking attendance
class StaffAttendanceMarkData {
  final int staffId;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? remarks;

  const StaffAttendanceMarkData({
    required this.staffId,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.remarks,
  });
}

/// Batch attendance result
class StaffBatchAttendanceResult {
  final int successful;
  final int failed;
  final List<String> errors;

  const StaffBatchAttendanceResult({
    required this.successful,
    required this.failed,
    required this.errors,
  });

  bool get hasErrors => failed > 0;
}

/// Staff attendance service for business logic
class StaffAttendanceService {
  final AppDatabase _db;
  final StaffAttendanceRepository _attendanceRepository;
  final StaffRepository _staffRepository;
  final LeaveRepository _leaveRepository;

  StaffAttendanceService(this._db)
    : _attendanceRepository = StaffAttendanceRepositoryImpl(_db),
      _staffRepository = StaffRepositoryImpl(_db),
      _leaveRepository = LeaveRepositoryImpl(_db);

  /// Valid attendance statuses
  static const validStatuses = [
    'present',
    'absent',
    'late',
    'half_day',
    'leave',
  ];

  /// Validate if attendance can be marked for a date
  StaffAttendanceValidationResult validateMarkableDate(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    // Cannot mark for future dates
    if (dateOnly.isAfter(today)) {
      return const StaffAttendanceValidationResult(
        isValid: false,
        error: 'Cannot mark attendance for future dates',
      );
    }

    // Cannot mark for dates more than 7 days old
    final maxPastDate = today.subtract(const Duration(days: 7));
    if (dateOnly.isBefore(maxPastDate)) {
      return const StaffAttendanceValidationResult(
        isValid: false,
        error: 'Cannot mark attendance for dates older than 7 days',
      );
    }

    return const StaffAttendanceValidationResult(isValid: true);
  }

  /// Validate attendance status
  StaffAttendanceValidationResult validateStatus(String status) {
    if (!validStatuses.contains(status)) {
      return StaffAttendanceValidationResult(
        isValid: false,
        error: 'Invalid status. Valid statuses: ${validStatuses.join(", ")}',
      );
    }
    return const StaffAttendanceValidationResult(isValid: true);
  }

  /// Mark attendance for a single staff member
  Future<int> markAttendance({
    required int staffId,
    required DateTime date,
    required String status,
    required int markedBy,
    String? checkIn,
    String? checkOut,
    String? remarks,
  }) async {
    // Validate date
    final dateValidation = validateMarkableDate(date);
    if (!dateValidation.isValid) {
      throw AttendanceValidationException(dateValidation.error!);
    }

    // Validate status
    final statusValidation = validateStatus(status);
    if (!statusValidation.isValid) {
      throw AttendanceValidationException(statusValidation.error!);
    }

    // Validate staff exists
    final staff = await _staffRepository.getById(staffId);
    if (staff == null) {
      throw AttendanceValidationException('Staff member not found');
    }

    // Check for approved leave on this date
    if (status != 'leave') {
      final hasApprovedLeave = await _checkApprovedLeave(staffId, date);
      if (hasApprovedLeave) {
        // Auto-set to leave status
        return await _markAttendanceRecord(
          staffId: staffId,
          date: date,
          status: 'leave',
          checkIn: null,
          checkOut: null,
          remarks: 'On approved leave',
        );
      }
    }

    return await _markAttendanceRecord(
      staffId: staffId,
      date: date,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
      remarks: remarks,
    );
  }

  Future<int> _markAttendanceRecord({
    required int staffId,
    required DateTime date,
    required String status,
    String? checkIn,
    String? checkOut,
    String? remarks,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final companion = StaffAttendanceCompanion.insert(
      staffId: staffId,
      date: dateOnly,
      status: status,
      checkIn: Value(checkIn),
      checkOut: Value(checkOut),
      remarks: Value(remarks),
      markedBy: 1, // System/admin user
    );

    return await _attendanceRepository.markAttendance(companion);
  }

  /// Mark attendance for multiple staff at once
  Future<StaffBatchAttendanceResult> markBulkAttendance({
    required List<StaffAttendanceMarkData> attendanceData,
    required DateTime date,
    required int markedBy,
  }) async {
    // Validate date
    final dateValidation = validateMarkableDate(date);
    if (!dateValidation.isValid) {
      throw AttendanceValidationException(dateValidation.error!);
    }

    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final data in attendanceData) {
      try {
        await markAttendance(
          staffId: data.staffId,
          date: date,
          status: data.status,
          markedBy: markedBy,
          checkIn: data.checkIn,
          checkOut: data.checkOut,
          remarks: data.remarks,
        );
        successful++;
      } catch (e) {
        failed++;
        errors.add('Staff ${data.staffId}: ${e.toString()}');
      }
    }

    // Log activity
    await _logActivity(
      action: 'mark_attendance',
      module: 'staff_attendance',
      details:
          'Marked attendance for $successful staff members on ${_formatDate(date)}',
    );

    return StaffBatchAttendanceResult(
      successful: successful,
      failed: failed,
      errors: errors,
    );
  }

  /// Mark all active staff as present
  Future<StaffBatchAttendanceResult> markAllPresent({
    required DateTime date,
    required int markedBy,
  }) async {
    return await _markAllWithStatus(
      date: date,
      markedBy: markedBy,
      status: 'present',
    );
  }

  /// Mark all active staff as absent
  Future<StaffBatchAttendanceResult> markAllAbsent({
    required DateTime date,
    required int markedBy,
  }) async {
    return await _markAllWithStatus(
      date: date,
      markedBy: markedBy,
      status: 'absent',
    );
  }

  Future<StaffBatchAttendanceResult> _markAllWithStatus({
    required DateTime date,
    required int markedBy,
    required String status,
  }) async {
    // Get all active staff
    final allStaff = await _staffRepository.search(
      const StaffFilters(status: 'active', limit: 0), // No limit - fetch all staff
    );

    final attendanceData = allStaff.map((s) {
      return StaffAttendanceMarkData(staffId: s.staff.id, status: status);
    }).toList();

    return await markBulkAttendance(
      attendanceData: attendanceData,
      date: date,
      markedBy: markedBy,
    );
  }

  /// Get attendance for a date with all active staff
  Future<List<StaffAttendanceRecord>> getAttendanceForDate(
    DateTime date,
  ) async {
    // Get all active staff
    final allStaff = await _staffRepository.search(
      const StaffFilters(status: 'active', limit: 0), // No limit - fetch all staff
    );

    // Get existing attendance records
    final existingRecords = await _attendanceRepository.getAttendanceForDate(
      date,
    );
    final recordMap = {for (var r in existingRecords) r.staff.id: r};

    // Build complete list
    final result = <StaffAttendanceRecord>[];
    for (final staff in allStaff) {
      final existing = recordMap[staff.staff.id];
      result.add(
        StaffAttendanceRecord(
          staff: staff,
          attendance: existing?.attendance,
          hasAttendance: existing != null,
        ),
      );
    }

    return result;
  }

  /// Get staff attendance history
  Future<List<StaffAttendanceData>> getStaffHistory({
    required int staffId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _attendanceRepository.getStaffAttendanceHistory(
      staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get staff attendance statistics
  Future<StaffAttendanceStats> getStaffStats({
    required int staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _attendanceRepository.getStaffStats(
      staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get daily summary
  Future<DailyStaffAttendanceSummary> getDailySummary(DateTime date) async {
    return await _attendanceRepository.getDailySummary(date);
  }

  /// Get monthly calendar
  Future<Map<DateTime, DailyStaffAttendanceSummary>> getMonthlyCalendar(
    int year,
    int month,
  ) async {
    return await _attendanceRepository.getMonthlyCalendar(year, month);
  }

  /// Check if attendance is marked for a date
  Future<bool> isAttendanceMarked(DateTime date) async {
    return await _attendanceRepository.isAttendanceMarked(date);
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<bool> _checkApprovedLeave(int staffId, DateTime date) async {
    final requests = await _leaveRepository.getAllRequests(
      staffId: staffId,
      status: 'approved',
    );

    for (final request in requests) {
      final startDate = request.request.startDate;
      final endDate = request.request.endDate;
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (!dateOnly.isBefore(startDate) && !dateOnly.isAfter(endDate)) {
        return true;
      }
    }

    return false;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _logActivity({
    required String action,
    required String module,
    required String details,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            action: action,
            module: module,
            description: details,
            userId: const Value(null),
          ),
        );
  }
}

/// Staff attendance record with optional attendance data
class StaffAttendanceRecord {
  final StaffWithRole staff;
  final StaffAttendanceData? attendance;
  final bool hasAttendance;

  const StaffAttendanceRecord({
    required this.staff,
    this.attendance,
    required this.hasAttendance,
  });

  String get status => attendance?.status ?? 'unmarked';
}

/// Exception for attendance validation errors
class AttendanceValidationException implements Exception {
  final String message;

  AttendanceValidationException(this.message);

  @override
  String toString() => 'AttendanceValidationException: $message';
}
