/// EduX Teacher App - Attendance Provider
library;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

import '../database/app_database.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import 'classes_provider.dart';
import 'database_provider.dart';
import 'auth_provider.dart';

part 'attendance_provider.g.dart';

/// Attendance state
class AttendanceState {
  final List<Student> students;
  final Map<int, String> attendanceStatus; // studentId -> status
  final Map<int, String> remarks; // studentId -> remarks
  final bool isLoading;
  final String? error;
  final AttendanceStats stats;

  const AttendanceState({
    this.students = const [],
    this.attendanceStatus = const {},
    this.remarks = const {},
    this.isLoading = false,
    this.error,
    this.stats = const AttendanceStats(),
  });

  AttendanceState copyWith({
    List<Student>? students,
    Map<int, String>? attendanceStatus,
    Map<int, String>? remarks,
    bool? isLoading,
    String? error,
    AttendanceStats? stats,
  }) {
    return AttendanceState(
      students: students ?? this.students,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      remarks: remarks ?? this.remarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }

  /// Get status for a student
  String? getStatus(int studentId) => attendanceStatus[studentId];

  /// Get remarks for a student
  String? getRemarks(int studentId) => remarks[studentId];

  /// Check if all students have been marked
  bool get isComplete => stats.marked == stats.total && stats.total > 0;

  /// Get pending count
  int get pendingCount => stats.remaining;
}

/// Attendance provider
@Riverpod(keepAlive: true)
class Attendance extends _$Attendance {
  late AppDatabase _db;

  @override
  AttendanceState build() {
    _db = ref.read(databaseProvider);
    return const AttendanceState();
  }

  /// Load students for a class/section
  /// FIXED: Auto-fetches from server if cache is empty with better diagnostics
  Future<void> loadStudents(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get cached students
      var cachedStudents = await _db.getCachedStudents(classId, sectionId);

      // AUTO-FETCH: If cache is empty, try to fetch from server
      if (cachedStudents.isEmpty) {
        debugPrint('[Attendance] No cached students for class $classId-$sectionId, attempting auto-fetch...');
        
        final syncService = ref.read(syncServiceProvider);
        if (syncService.isInitialized) {
          try {
            final fetchResult = await syncService.fetchStudentsWithDiagnostics(classId, sectionId);
            
            // Check if server returned diagnostic info
            if (fetchResult['students'] != null) {
              final studentsList = fetchResult['students'] as List;
              debugPrint('[Attendance] Server returned ${studentsList.length} students');
              
              // Check for diagnostics
              if (studentsList.isEmpty && fetchResult['diagnostics'] != null) {
                final diagnostics = fetchResult['diagnostics'] as Map<String, dynamic>;
                debugPrint('[Attendance] Server diagnostics: $diagnostics');
                
                // Build helpful error message
                final errorMsg = _buildDiagnosticErrorMessage(diagnostics);
                state = AttendanceState(
                  students: const [],
                  attendanceStatus: const {},
                  remarks: const {},
                  stats: const AttendanceStats(),
                  error: errorMsg,
                );
                return;
              }
            }
            
            // Reload from cache after fetch
            cachedStudents = await _db.getCachedStudents(classId, sectionId);
            debugPrint('[Attendance] Auto-fetched ${cachedStudents.length} students for class $classId-$sectionId');
          } catch (e) {
            debugPrint('[Attendance] Auto-fetch failed for class $classId-$sectionId: $e');
            state = AttendanceState(
              students: const [],
              attendanceStatus: const {},
              remarks: const {},
              stats: const AttendanceStats(),
              error: 'Failed to fetch students: $e\n\nPlease check:\n1. Server is running\n2. Students are enrolled in this class\n3. Academic year is set correctly',
            );
            return;
          }
        } else {
          debugPrint('[Attendance] Sync service not initialized, cannot auto-fetch');
        }
      }

      // Get existing attendance for this date
      final existingAttendance = await _db.getAttendanceForClass(
        classId,
        sectionId,
        date,
      );

      // Build attendance status map
      final attendanceStatus = <int, String>{};
      final remarks = <int, String>{};

      for (final record in existingAttendance) {
        attendanceStatus[record.studentId] = record.status;
        if (record.remarks != null && record.remarks!.isNotEmpty) {
          remarks[record.studentId] = record.remarks!;
        }
      }

      final students = cachedStudents
          .map((s) => Student(
                studentId: s.studentId,
                name: s.name,
                rollNumber: s.rollNumber,
                gender: s.gender,
                photoUrl: s.photoUrl,
                classId: s.classId,
                sectionId: s.sectionId,
              ))
          .toList();

      // Calculate stats
      final stats = _calculateStats(students.length, attendanceStatus);

      // Check for data integrity issue (expected students but cache is empty)
      final classInfo = await _db.getCachedClass(classId, sectionId);
      final hasDataIntegrityIssue = cachedStudents.isEmpty && 
          (classInfo != null && classInfo.totalStudents > 0);

      state = AttendanceState(
        students: students,
        attendanceStatus: attendanceStatus,
        remarks: remarks,
        stats: stats,
        error: hasDataIntegrityIssue 
            ? 'Class shows ${classInfo!.totalStudents} students but none cached. Tap "Load Students" to fetch from server.'
            : cachedStudents.isEmpty 
                ? 'No students found for this class. Please verify students are enrolled in the main system.'
                : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[Attendance] Error loading students: $e');
      debugPrint(stackTrace.toString());
      state = AttendanceState(
        error: 'Error loading students: $e',
      );
    }
  }
  
  /// Build user-friendly error message from server diagnostics
  String _buildDiagnosticErrorMessage(Map<String, dynamic> diagnostics) {
    final buffer = StringBuffer();
    buffer.writeln('No students found. Server diagnostics:');
    buffer.writeln();
    
    final totalEnrollments = diagnostics['totalEnrollmentsAnyYear'] as int? ?? 0;
    final yearMatch = diagnostics['yearMatch'] as bool? ?? false;
    final activeStudents = diagnostics['activeStudents'] as int? ?? 0;
    final expectedYear = diagnostics['expectedAcademicYear'] as String? ?? 'unknown';
    final availableYears = diagnostics['availableAcademicYears'] as List<dynamic>? ?? [];
    
    if (totalEnrollments == 0) {
      buffer.writeln('• No enrollments exist for this class/section');
      buffer.writeln('  Please enroll students in the main system first.');
    } else if (!yearMatch) {
      buffer.writeln('• Enrollments exist for years: ${availableYears.join(", ")}');
      buffer.writeln('  But current year is: $expectedYear');
      buffer.writeln('  Please update academic year in main system settings.');
    } else if (activeStudents == 0) {
      buffer.writeln('• $totalEnrollments enrollments found but none are "active"');
      buffer.writeln('  Please check student status in the main system.');
    } else {
      buffer.writeln('• Found $totalEnrollments total enrollments');
      buffer.writeln('• $activeStudents active students');
      buffer.writeln('• Data mismatch detected');
    }
    
    if (diagnostics['suggestedFix'] != null) {
      buffer.writeln();
      buffer.writeln('Suggested fix: ${diagnostics['suggestedFix']}');
    }
    
    return buffer.toString();
  }

  /// Fetch students from server
  Future<bool> fetchStudentsFromServer(int classId, int sectionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final syncService = ref.read(syncServiceProvider);

      // Reinitialize if needed
      if (!syncService.isInitialized) {
        final success = await syncService.reinitialize();
        if (!success) {
          state = state.copyWith(
            isLoading: false,
            error: 'Server not configured',
          );
          return false;
        }
      }

      await syncService.fetchStudents(classId, sectionId);

      // Reload from cache
      final selectedDate = ref.read(selectedDateProvider);
      await loadStudents(classId, sectionId, selectedDate);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Mark attendance for a student
  Future<void> markAttendance(
    int studentId,
    int classId,
    int sectionId,
    DateTime date,
    String status, {
    String? remarks,
  }) async {
    // Update local state first (optimistic)
    final newStatus = Map<int, String>.from(state.attendanceStatus);
    newStatus[studentId] = status;

    final newRemarks = Map<int, String>.from(state.remarks);
    if (remarks != null && remarks.isNotEmpty) {
      newRemarks[studentId] = remarks;
    } else {
      newRemarks.remove(studentId);
    }

    final stats = _calculateStats(state.students.length, newStatus);

    state = state.copyWith(
      attendanceStatus: newStatus,
      remarks: newRemarks,
      stats: stats,
    );

    // Save to database
    try {
      await _db.saveAttendance(PendingAttendancesCompanion(
        studentId: Value(studentId),
        classId: Value(classId),
        sectionId: Value(sectionId),
        date: Value(DateTime(date.year, date.month, date.day)),
        status: Value(status),
        remarks: Value(remarks),
        markedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));
    } catch (e) {
      // Revert state on error
      newStatus.remove(studentId);
      state = state.copyWith(
        attendanceStatus: newStatus,
        stats: _calculateStats(state.students.length, newStatus),
        error: 'Failed to save attendance: $e',
      );
    }
  }

  /// Mark all students with same status
  Future<void> markAll(
    int classId,
    int sectionId,
    DateTime date,
    String status,
  ) async {
    final newStatus = <int, String>{};

    for (final student in state.students) {
      newStatus[student.studentId] = status;
    }

    final stats = _calculateStats(state.students.length, newStatus);

    state = state.copyWith(
      attendanceStatus: newStatus,
      stats: stats,
    );

    // Save all to database
    try {
      final attendances = state.students
          .map((s) => PendingAttendancesCompanion(
                studentId: Value(s.studentId),
                classId: Value(classId),
                sectionId: Value(sectionId),
                date: Value(DateTime(date.year, date.month, date.day)),
                status: Value(status),
                markedAt: Value(DateTime.now()),
                isSynced: const Value(false),
              ))
          .toList();

      await _db.saveAttendanceBatch(attendances);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save attendance: $e');
    }
  }

  /// Clear all attendance for current class/date
  Future<void> clearAll(int classId, int sectionId, DateTime date) async {
    state = state.copyWith(
      attendanceStatus: {},
      remarks: {},
      stats: AttendanceStats(total: state.students.length),
    );

    try {
      final attendances =
          await _db.getAttendanceForClass(classId, sectionId, date);
      for (final record in attendances) {
        await _db.deleteAttendance(record.id);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear attendance: $e');
    }
  }

  /// Add remark for a student
  Future<void> addRemark(
    int studentId,
    int classId,
    int sectionId,
    DateTime date,
    String remarks,
  ) async {
    final newRemarks = Map<int, String>.from(state.remarks);
    newRemarks[studentId] = remarks;

    state = state.copyWith(remarks: newRemarks);

    // Update in database if attendance already marked
    final existing = await _db.getStudentAttendance(studentId, date);
    if (existing != null) {
      await _db.saveAttendance(PendingAttendancesCompanion(
        studentId: Value(studentId),
        classId: Value(classId),
        sectionId: Value(sectionId),
        date: Value(DateTime(date.year, date.month, date.day)),
        status: Value(existing.status),
        remarks: Value(remarks.isEmpty ? null : remarks),
        markedAt: Value(existing.markedAt),
        isSynced: const Value(false),
      ));
    }
  }

  /// Calculate attendance stats
  AttendanceStats _calculateStats(
    int total,
    Map<int, String> attendanceStatus,
  ) {
    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;
    int halfDay = 0;

    for (final status in attendanceStatus.values) {
      switch (status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'leave':
          leave++;
          break;
        case 'half_day':
          halfDay++;
          break;
      }
    }

    return AttendanceStats(
      present: present,
      absent: absent,
      late: late,
      leave: leave,
      halfDay: halfDay,
      total: total,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Pending attendance count provider (for badges)
@riverpod
Future<int> pendingAttendanceCount(Ref ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getPendingCount();
}

/// Class attendance summary provider
@riverpod
Future<Map<String, dynamic>> classAttendanceSummary(
  Ref ref,
  int classId,
  int sectionId,
  DateTime date,
) async {
  final db = ref.watch(databaseProvider);
  final stats = await db.getAttendanceStats(classId, sectionId, date);
  final count = await db.getAttendanceCount(classId, sectionId, date);

  return {
    'stats': stats,
    'count': count,
  };
}
