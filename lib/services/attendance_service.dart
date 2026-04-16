/// EduX School Management System
/// Attendance Service - Business logic for attendance operations
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/attendance_repository.dart';
import '../core/constants/app_constants.dart';
import 'working_days_service.dart';

/// Result of attendance validation
class AttendanceValidationResult {
  final bool isValid;
  final List<String> errors;

  const AttendanceValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory AttendanceValidationResult.valid() =>
      const AttendanceValidationResult(isValid: true);

  factory AttendanceValidationResult.invalid(List<String> errors) =>
      AttendanceValidationResult(isValid: false, errors: errors);
}

/// Data for marking attendance
class AttendanceMarkData {
  final int studentId;
  final String status;
  final String? remarks;

  const AttendanceMarkData({
    required this.studentId,
    required this.status,
    this.remarks,
  });
}

/// Batch attendance result
class BatchAttendanceResult {
  final int successCount;
  final int failCount;
  final List<String> errors;

  const BatchAttendanceResult({
    required this.successCount,
    required this.failCount,
    this.errors = const [],
  });
}

/// Attendance service for business logic
class AttendanceService {
  final AttendanceRepository _repository;
  final AppDatabase _db;

  AttendanceService(this._repository, this._db);

  AttendanceRepository get repository => _repository;

  /// Validate if attendance can be marked for a date
  Future<AttendanceValidationResult> validateMarkableDate(DateTime date) async {
    final errors = <String>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Cannot mark future attendance
    if (dateOnly.isAfter(today)) {
      errors.add('Cannot mark attendance for future dates');
    }

    // Check if it's a working day using school settings
    final workingDaysService = WorkingDaysService(_db);
    final isWorkingDay = await workingDaysService.isWorkingDate(date);
    if (!isWorkingDay) {
      errors.add('Cannot mark attendance on non-working days');
    }

    // Limit how far back attendance can be marked (30 days)
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    if (dateOnly.isBefore(thirtyDaysAgo)) {
      errors.add('Cannot mark attendance for dates older than 30 days');
    }

    return errors.isEmpty
        ? AttendanceValidationResult.valid()
        : AttendanceValidationResult.invalid(errors);
  }

  /// Validate attendance status
  AttendanceValidationResult validateStatus(String status) {
    if (!AttendanceStatus.studentStatuses.contains(status)) {
      return AttendanceValidationResult.invalid([
        'Invalid attendance status: $status',
      ]);
    }
    return AttendanceValidationResult.valid();
  }

  /// Mark attendance for a single student
  Future<int> markAttendance({
    required int studentId,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
    required String academicYear,
    required int markedBy,
    String? remarks,
  }) async {
    // Validate date
    final dateValidation = await validateMarkableDate(date);
    if (!dateValidation.isValid) {
      throw AttendanceException(dateValidation.errors.join(', '));
    }

    // Validate status
    final statusValidation = validateStatus(status);
    if (!statusValidation.isValid) {
      throw AttendanceException(statusValidation.errors.join(', '));
    }

    // Check if student exists and is active
    final studentQuery = _db.select(_db.students)
      ..where((t) => t.id.equals(studentId) & t.status.equals('active'));
    final student = await studentQuery.getSingleOrNull();

    if (student == null) {
      throw AttendanceException('Student not found or inactive');
    }

    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();

    // Upsert attendance record
    final result = await _repository.upsert(
      StudentAttendanceCompanion.insert(
        studentId: studentId,
        classId: classId,
        sectionId: sectionId,
        date: dateOnly,
        status: status,
        remarks: Value(remarks),
        academicYear: academicYear,
        markedBy: markedBy,
        updatedAt: Value(now),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'attendance_marked',
      module: 'attendance',
      details:
          'Marked $status for student ID $studentId on ${_formatDate(dateOnly)}',
      userId: markedBy,
    );

    return result;
  }

  /// Mark attendance for multiple students at once
  Future<BatchAttendanceResult> markBulkAttendance({
    required List<AttendanceMarkData> attendanceData,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
  }) async {
    // Validate date first
    final dateValidation = await validateMarkableDate(date);
    if (!dateValidation.isValid) {
      throw AttendanceException(dateValidation.errors.join(', '));
    }

    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final companions = <StudentAttendanceCompanion>[];
    final errors = <String>[];
    int failCount = 0;

    for (final data in attendanceData) {
      // Validate status
      final statusValidation = validateStatus(data.status);
      if (!statusValidation.isValid) {
        errors.add(
          'Student ${data.studentId}: ${statusValidation.errors.join(', ')}',
        );
        failCount++;
        continue;
      }

      companions.add(
        StudentAttendanceCompanion.insert(
          studentId: data.studentId,
          classId: classId,
          sectionId: sectionId,
          date: dateOnly,
          status: data.status,
          remarks: Value(data.remarks),
          academicYear: academicYear,
          markedBy: markedBy,
          updatedAt: Value(now),
        ),
      );
    }

    if (companions.isNotEmpty) {
      await _repository.upsertBatch(companions);
    }

    final successCount = companions.length;

    // Log activity
    await _logActivity(
      action: 'bulk_attendance_marked',
      module: 'attendance',
      details:
          'Marked attendance for $successCount students on ${_formatDate(dateOnly)}',
      userId: markedBy,
    );

    return BatchAttendanceResult(
      successCount: successCount,
      failCount: failCount,
      errors: errors,
    );
  }

  /// Mark all students as present for a class
  Future<BatchAttendanceResult> markAllPresent({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
  }) async {
    return _markAllWithStatus(
      classId: classId,
      sectionId: sectionId,
      date: date,
      academicYear: academicYear,
      markedBy: markedBy,
      status: AttendanceStatus.present,
    );
  }

  /// Mark all students as absent for a class
  Future<BatchAttendanceResult> markAllAbsent({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
  }) async {
    return _markAllWithStatus(
      classId: classId,
      sectionId: sectionId,
      date: date,
      academicYear: academicYear,
      markedBy: markedBy,
      status: AttendanceStatus.absent,
    );
  }

  Future<BatchAttendanceResult> _markAllWithStatus({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
    required int markedBy,
    required String status,
  }) async {
    // Validate date
    final dateValidation = await validateMarkableDate(date);
    if (!dateValidation.isValid) {
      throw AttendanceException(dateValidation.errors.join(', '));
    }

    // Get all enrolled students
    final entries = await _repository.getClassAttendanceForDate(
      classId: classId,
      sectionId: sectionId,
      date: date,
      academicYear: academicYear,
    );

    final attendanceData = entries
        .map((e) => AttendanceMarkData(studentId: e.student.id, status: status))
        .toList();

    return markBulkAttendance(
      attendanceData: attendanceData,
      classId: classId,
      sectionId: sectionId,
      date: date,
      academicYear: academicYear,
      markedBy: markedBy,
    );
  }

  /// Update existing attendance record
  Future<bool> updateAttendance({
    required int attendanceId,
    required String status,
    required int updatedBy,
    String? remarks,
  }) async {
    // Validate status
    final statusValidation = validateStatus(status);
    if (!statusValidation.isValid) {
      throw AttendanceException(statusValidation.errors.join(', '));
    }

    final existing = await _repository.getById(attendanceId);
    if (existing == null) {
      throw AttendanceException('Attendance record not found');
    }

    // Validate date is within editable range
    final dateValidation = await validateMarkableDate(existing.date);
    if (!dateValidation.isValid) {
      throw AttendanceException(dateValidation.errors.join(', '));
    }

    final result = await _repository.update(
      attendanceId,
      StudentAttendanceCompanion(
        status: Value(status),
        remarks: Value(remarks),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'attendance_updated',
      module: 'attendance',
      details: 'Updated attendance ID $attendanceId to $status',
      userId: updatedBy,
    );

    return result;
  }

  /// Get attendance by ID
  Future<StudentAttendanceData?> getAttendanceById(int id) async {
    return _repository.getById(id);
  }

  /// Get class attendance for a specific date with student details
  Future<List<StudentAttendanceEntry>> getClassAttendance({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
  }) async {
    return _repository.getClassAttendanceForDate(
      classId: classId,
      sectionId: sectionId,
      date: date,
      academicYear: academicYear,
    );
  }

  /// Get student attendance history
  Future<List<StudentAttendanceData>> getStudentHistory({
    required int studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _repository.getStudentHistory(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculate attendance statistics for a student
  Future<AttendanceStats> getStudentStats({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _repository.getStudentStats(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculate attendance statistics for a class
  Future<AttendanceStats> getClassStats({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _repository.getClassStats(
      classId: classId,
      sectionId: sectionId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get daily attendance summary
  Future<DailyAttendanceSummary> getDailySummary({
    required int classId,
    required int sectionId,
    required DateTime date,
  }) async {
    return _repository.getDailySummary(
      classId: classId,
      sectionId: sectionId,
      date: date,
    );
  }

  /// Get calendar indicators for a month
  Future<List<CalendarDayIndicator>> getCalendarData({
    required int classId,
    required int sectionId,
    required int year,
    required int month,
  }) async {
    return _repository.getCalendarIndicators(
      classId: classId,
      sectionId: sectionId,
      year: year,
      month: month,
    );
  }

  /// Get unmarked dates for a class
  Future<List<DateTime>> getUnmarkedDates({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _repository.getUnmarkedDates(
      classId: classId,
      sectionId: sectionId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get students with low attendance (below threshold)
  Future<List<LowAttendanceAlert>> getLowAttendanceAlerts({
    double threshold = 75.0,
    DateTime? startDate,
    DateTime? endDate,
    int? classId,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 1, 1);
    final end = endDate ?? now;

    return _repository.getLowAttendanceAlerts(
      threshold: threshold,
      startDate: start,
      endDate: end,
      classId: classId,
    );
  }

  /// Check if attendance is marked for a class on a date
  Future<bool> isAttendanceMarked({
    required int classId,
    required int sectionId,
    required DateTime date,
  }) async {
    final count = await _repository.countMarkedForDate(
      classId: classId,
      sectionId: sectionId,
      date: date,
    );
    return count > 0;
  }

  /// Get attendance percentage for a student
  Future<double> getStudentAttendancePercentage({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final stats = await getStudentStats(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
    return stats.attendancePercentage;
  }

  /// Delete attendance for a date
  Future<int> deleteAttendanceForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
    required int deletedBy,
  }) async {
    final count = await _repository.deleteByDate(date, classId, sectionId);

    // Log activity
    await _logActivity(
      action: 'attendance_deleted',
      module: 'attendance',
      details: 'Deleted $count attendance records for ${_formatDate(date)}',
      userId: deletedBy,
    );

    return count;
  }

  /// Get today's unmarked classes
  Future<
    List<({int classId, int sectionId, String className, String sectionName})>
  >
  getTodayUnmarkedClasses() async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    // Skip non-working days based on school settings
    final workingDaysService = WorkingDaysService(_db);
    final isWorkingDay = await workingDaysService.isWorkingDate(today);
    if (!isWorkingDay) {
      return [];
    }

    // Get all active class-section pairs
    final classesQuery =
        _db.select(_db.sections).join([
          innerJoin(
            _db.classes,
            _db.classes.id.equalsExp(_db.sections.classId),
          ),
        ])..where(
          _db.sections.isActive.equals(true) &
              _db.classes.isActive.equals(true),
        );

    final classSections = await classesQuery.get();

    // Get all marked sections for today to avoid N+1 queries
    final markedQuery = _db.selectOnly(_db.studentAttendance)
      ..addColumns([
        _db.studentAttendance.classId,
        _db.studentAttendance.sectionId,
      ])
      ..where(_db.studentAttendance.date.equals(dateOnly));

    final markedRows = await markedQuery.get();
    final markedKeys = markedRows.map((row) {
      final cId = row.read(_db.studentAttendance.classId);
      final sId = row.read(_db.studentAttendance.sectionId);
      return '${cId}_$sId';
    }).toSet();

    final unmarked =
        <
          ({int classId, int sectionId, String className, String sectionName})
        >[];

    for (final row in classSections) {
      final classData = row.readTable(_db.classes);
      final sectionData = row.readTable(_db.sections);
      final key = '${classData.id}_${sectionData.id}';

      if (!markedKeys.contains(key)) {
        unmarked.add((
          classId: classData.id,
          sectionId: sectionData.id,
          className: classData.name,
          sectionName: sectionData.name,
        ));
      }
    }

    return unmarked;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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
            action: action,
            module: module,
            description: details,
            details: Value(details),
            userId: Value(userId),
          ),
        );
  }
}

/// Exception for attendance operations
class AttendanceException implements Exception {
  final String message;

  AttendanceException(this.message);

  @override
  String toString() => 'AttendanceException: $message';
}
