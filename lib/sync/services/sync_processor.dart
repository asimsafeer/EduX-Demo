/// EduX School Management System
/// Sync processor - processes attendance sync data from teacher apps
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../database/database.dart';
import '../models/models.dart';

/// Result of processing a single attendance record
enum AttendanceProcessResult { created, updated, conflict, skipped, error }

/// Processes attendance sync data from teacher apps
class SyncProcessor {
  final AppDatabase _db;

  SyncProcessor(this._db);

  /// Factory constructor using singleton database
  factory SyncProcessor.instance() => SyncProcessor(AppDatabase.instance);

  // ============================================
  // MAIN SYNC PROCESSING
  // ============================================

  /// Process a sync request from teacher app
  /// Uses database transactions for data consistency during concurrent syncs
  Future<SyncResponse> processSync(
    SyncRequest request,
    String ipAddress, {
    int? serverUserId, // User ID to use for marking attendance (server-side)
  }) async {
    final serverTimestamp = DateTime.now();
    final errors = <String>[];
    int created = 0;
    int updated = 0;
    int conflicts = 0;

    // Process each attendance record within a transaction for consistency
    for (final record in request.attendanceRecords) {
      try {
        // Use transaction to ensure atomicity and prevent race conditions
        // when multiple teachers sync the same student attendance
        final result = await _db.transaction(() async {
          return await _processAttendanceRecord(
            record: record,
            teacherId: request.teacherId,
            serverUserId: serverUserId,
          );
        });

        switch (result) {
          case AttendanceProcessResult.created:
            created++;
            break;
          case AttendanceProcessResult.updated:
            updated++;
            break;
          case AttendanceProcessResult.conflict:
            conflicts++;
            break;
          case AttendanceProcessResult.skipped:
            // Record was already in sync, no action needed
            break;
          case AttendanceProcessResult.error:
            errors.add('Student ${record.studentId}: Processing error');
            break;
        }
      } on DriftWrappedException catch (e) {
        // Database constraint violation (e.g., unique constraint)
        errors.add(
          'Student ${record.studentId}: Database constraint error - ${e.message}',
        );
      } catch (e) {
        errors.add('Student ${record.studentId}: ${e.toString()}');
      }
    }

    // Build response
    final success = errors.isEmpty;
    final response = SyncResponse(
      success: success,
      processed: request.attendanceRecords.length,
      created: created,
      updated: updated,
      conflicts: conflicts,
      errors: errors,
      serverTimestamp: serverTimestamp,
    );

    return response;
  }

  /// Process a single attendance record with retry logic for concurrent access
  Future<AttendanceProcessResult> _processAttendanceRecord({
    required SyncAttendanceRecord record,
    required int teacherId,
    int? serverUserId,
  }) async {
    // Retry configuration for handling transient concurrency issues
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 100);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _processAttendanceRecordInternal(
          record: record,
          teacherId: teacherId,
          serverUserId: serverUserId,
        );
      } on DriftWrappedException catch (e) {
        // Database constraint violation - might be concurrent insert
        if (attempt < maxRetries - 1) {
          // Wait before retry
          await Future.delayed(retryDelay * (attempt + 1));
          continue;
        }
        // Max retries reached
        throw Exception(
          'Database error after $maxRetries attempts: ${e.message}',
        );
      }
    }

    // Should not reach here, but just in case
    throw Exception('Unexpected error processing attendance record');
  }

  /// Internal method to process a single attendance record
  Future<AttendanceProcessResult> _processAttendanceRecordInternal({
    required SyncAttendanceRecord record,
    required int teacherId,
    int? serverUserId,
  }) async {
    // Check if attendance is locked for this date/class/section
    final isLocked = await _isAttendanceLocked(
      record.classId,
      record.sectionId,
      record.date,
    );
    if (isLocked) {
      throw Exception('Attendance is locked for this date');
    }

    // Validate student exists and is active
    final student = await _db
        .select(_db.students)
        .get()
        .then(
          (list) => list.where((s) => s.id == record.studentId).firstOrNull,
        );

    if (student == null) {
      throw Exception('Student not found: ${record.studentId}');
    }

    if (student.status != 'active') {
      throw Exception('Student is not active: ${record.studentId}');
    }

    // Validate status
    if (!AttendanceStatus.studentStatuses.contains(record.status)) {
      throw Exception('Invalid attendance status: ${record.status}');
    }

    // Check for existing record
    final existing = await _getExistingAttendance(
      record.studentId,
      record.date,
    );

    // Get the user ID to mark attendance with
    // Use the teacher's linked user account if available, otherwise server user
    final int markedBy = serverUserId ?? await _getTeacherUserId(teacherId);

    if (existing == null) {
      // Create new record
      await _createAttendanceRecord(record: record, markedBy: markedBy);
      return AttendanceProcessResult.created;
    } else {
      // Check for conflict (different status)
      if (existing.status != record.status) {
        // Conflict detected - update with conflict flag
        await _updateAttendanceRecord(
          existingId: existing.id,
          record: record,
          updatedBy: markedBy,
        );
        return AttendanceProcessResult.conflict;
      } else {
        // Same status, just update remarks if changed
        if (existing.remarks != record.remarks) {
          await _updateAttendanceRecord(
            existingId: existing.id,
            record: record,
            updatedBy: markedBy,
          );
          return AttendanceProcessResult.updated;
        }
        return AttendanceProcessResult.skipped;
      }
    }
  }

  // ============================================
  // ATTENDANCE OPERATIONS
  // ============================================

  /// Create a new attendance record
  Future<void> _createAttendanceRecord({
    required SyncAttendanceRecord record,
    required int markedBy,
  }) async {
    final dateOnly = DateTime(
      record.date.year,
      record.date.month,
      record.date.day,
    );
    final now = DateTime.now();

    final currentYear = await _db.getCurrentAcademicYear();
    final academicYearStr = currentYear?.name ?? record.academicYear;

    await _db
        .into(_db.studentAttendance)
        .insert(
          StudentAttendanceCompanion.insert(
            studentId: record.studentId,
            classId: record.classId,
            sectionId: record.sectionId,
            date: dateOnly,
            status: record.status,
            remarks: Value(record.remarks),
            academicYear: academicYearStr,
            markedBy: markedBy,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Update an existing attendance record
  Future<void> _updateAttendanceRecord({
    required int existingId,
    required SyncAttendanceRecord record,
    required int updatedBy,
  }) async {
    await (_db.update(
      _db.studentAttendance,
    )..where((a) => a.id.equals(existingId))).write(
      StudentAttendanceCompanion(
        status: Value(record.status),
        remarks: Value(record.remarks),
        markedBy: Value(updatedBy),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get existing attendance record for student on date
  Future<StudentAttendanceData?> _getExistingAttendance(
    int studentId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    return await (_db.select(_db.studentAttendance)..where(
          (a) =>
              a.studentId.equals(studentId) &
              a.date.isBiggerOrEqualValue(dateOnly) &
              a.date.isSmallerThanValue(dateEnd),
        ))
        .getSingleOrNull();
  }

  /// Check if attendance is locked for date/class/section
  Future<bool> _isAttendanceLocked(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final status =
        await (_db.select(_db.dailyAttendanceStatus)..where(
              (s) =>
                  s.classId.equals(classId) &
                  s.sectionId.equals(sectionId) &
                  s.date.equals(dateOnly),
            ))
            .getSingleOrNull();

    return status?.isLocked ?? false;
  }

  /// Get the user ID associated with a teacher
  Future<int> _getTeacherUserId(int teacherId) async {
    final staff = await (_db.select(
      _db.staff,
    )..where((s) => s.id.equals(teacherId))).getSingleOrNull();

    if (staff?.userId != null) {
      return staff!.userId!;
    }

    // Fallback: Get admin user
    final admin = await _db.getAdminUser();
    if (admin != null) {
      return admin.id;
    }

    throw Exception('No valid user found for marking attendance');
  }

  // ============================================
  // CONFLICT DETECTION
  // ============================================

  /// Detect conflicts for a list of attendance records
  Future<List<SyncConflict>> detectConflicts(
    List<SyncAttendanceRecord> records,
  ) async {
    final conflicts = <SyncConflict>[];

    for (final record in records) {
      final existing = await _getExistingAttendance(
        record.studentId,
        record.date,
      );

      if (existing != null && existing.status != record.status) {
        // Get student name
        final student = await (_db.select(
          _db.students,
        )..where((s) => s.id.equals(record.studentId))).getSingleOrNull();

        conflicts.add(
          SyncConflict(
            studentId: record.studentId,
            studentName: student?.studentName ?? 'Unknown',
            date: record.date,
            teacherStatus: record.status,
            officeStatus: existing.status,
            existingRecordId: existing.id,
          ),
        );
      }
    }

    return conflicts;
  }

  /// Resolve a conflict by choosing which status to keep
  Future<void> resolveConflict({
    required int existingRecordId,
    required String chosenStatus,
    required int resolvedBy,
    String? remarks,
  }) async {
    await (_db.update(
      _db.studentAttendance,
    )..where((a) => a.id.equals(existingRecordId))).write(
      StudentAttendanceCompanion(
        status: Value(chosenStatus),
        remarks: Value(remarks),
        markedBy: Value(resolvedBy),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================
  // BATCH OPERATIONS
  // ============================================

  /// Process multiple sync requests in a batch
  Future<List<SyncResponse>> processBatchSync(
    List<SyncRequest> requests,
    String ipAddress, {
    int? serverUserId,
  }) async {
    final responses = <SyncResponse>[];

    for (final request in requests) {
      final response = await processSync(
        request,
        ipAddress,
        serverUserId: serverUserId,
      );
      responses.add(response);
    }

    return responses;
  }
}
