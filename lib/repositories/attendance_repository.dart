/// EduX School Management System
/// Attendance Repository - Data access layer for attendance management
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../services/working_days_service.dart';

/// Attendance record with student details
class AttendanceRecord {
  final StudentAttendanceData attendance;
  final Student student;
  final String? rollNumber;

  const AttendanceRecord({
    required this.attendance,
    required this.student,
    this.rollNumber,
  });
}

/// Daily attendance summary for a class/section
class DailyAttendanceSummary {
  final DateTime date;
  final int classId;
  final int sectionId;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final bool isMarked;

  const DailyAttendanceSummary({
    required this.date,
    required this.classId,
    required this.sectionId,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.isMarked,
  });

  double get attendancePercentage {
    if (totalStudents == 0) return 0;
    return ((presentCount + lateCount) / totalStudents) * 100;
  }
}

/// Attendance statistics for a student or class
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
    this.firstDate,
    this.lastDate,
  });

  double get attendancePercentage {
    if (totalDays == 0) return 0;
    return ((presentDays + lateDays) / totalDays) * 100;
  }

  double get absentPercentage {
    if (totalDays == 0) return 0;
    return (absentDays / totalDays) * 100;
  }

  static const empty = AttendanceStats(
    totalDays: 0,
    presentDays: 0,
    absentDays: 0,
    lateDays: 0,
    leaveDays: 0,
  );
}

/// Calendar day indicator for month view
class CalendarDayIndicator {
  final DateTime date;
  final CalendarDayStatus status;
  final int? presentCount;
  final int? totalCount;

  const CalendarDayIndicator({
    required this.date,
    required this.status,
    this.presentCount,
    this.totalCount,
  });
}

/// Calendar day status enum
enum CalendarDayStatus {
  notMarked, // Empty/gray
  allPresent, // Green
  partial, // Yellow (some absent)
  highAbsence, // Red (>50% absent)
  holiday, // Gray (holiday/weekend)
}

/// Attendance filter parameters
class AttendanceFilters {
  final DateTime? date;
  final int? classId;
  final int? sectionId;
  final int? studentId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? academicYear;
  final int? limit;
  final int? offset;

  const AttendanceFilters({
    this.date,
    this.classId,
    this.sectionId,
    this.studentId,
    this.status,
    this.startDate,
    this.endDate,
    this.academicYear,
    this.limit,
    this.offset,
  });

  AttendanceFilters copyWith({
    DateTime? date,
    int? classId,
    int? sectionId,
    int? studentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? academicYear,
    int? limit,
    int? offset,
    bool clearDate = false,
    bool clearClassId = false,
    bool clearSectionId = false,
    bool clearStudentId = false,
    bool clearStatus = false,
  }) {
    return AttendanceFilters(
      date: clearDate ? null : (date ?? this.date),
      classId: clearClassId ? null : (classId ?? this.classId),
      sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
      studentId: clearStudentId ? null : (studentId ?? this.studentId),
      status: clearStatus ? null : (status ?? this.status),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      academicYear: academicYear ?? this.academicYear,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Student with attendance status for a specific date
class StudentAttendanceEntry {
  final Student student;
  final Enrollment? enrollment;
  final StudentAttendanceData? attendance;

  const StudentAttendanceEntry({
    required this.student,
    this.enrollment,
    this.attendance,
  });

  String? get status => attendance?.status;
  String? get remarks => attendance?.remarks;
  bool get isMarked => attendance != null;

  /// Get admission number for display/sorting
  String get admissionNumber => student.admissionNumber;

  /// Get numeric admission number for proper sorting
  int get admissionNumberNumeric {
    // Extract numeric part from admission number
    final match = RegExp(r'\d+').firstMatch(student.admissionNumber);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    // If no number found, return a large value to place at end
    return 999999;
  }
}

/// Low attendance alert data
class LowAttendanceAlert {
  final Student student;
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;
  final double attendancePercentage;
  final int absentDays;
  final int totalDays;

  const LowAttendanceAlert({
    required this.student,
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.attendancePercentage,
    required this.absentDays,
    required this.totalDays,
  });
}

/// Abstract attendance repository interface
abstract class AttendanceRepository {
  // Single record operations
  Future<StudentAttendanceData?> getById(int id);
  Future<StudentAttendanceData?> getByStudentAndDate(
    int studentId,
    DateTime date,
  );
  Future<int> create(StudentAttendanceCompanion attendance);
  Future<bool> update(int id, StudentAttendanceCompanion attendance);
  Future<int> delete(int id);
  Future<int> upsert(StudentAttendanceCompanion attendance);

  // Batch operations
  Future<void> upsertBatch(List<StudentAttendanceCompanion> attendances);
  Future<int> deleteByDate(DateTime date, int classId, int sectionId);

  // Query operations
  Future<List<StudentAttendanceEntry>> getClassAttendanceForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
  });

  Future<List<StudentAttendanceData>> getStudentHistory({
    required int studentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<AttendanceRecord>> search(AttendanceFilters filters);

  // Statistics
  Future<AttendanceStats> getStudentStats({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<AttendanceStats> getClassStats({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<DailyAttendanceSummary> getDailySummary({
    required int classId,
    required int sectionId,
    required DateTime date,
  });

  // Calendar
  Future<List<CalendarDayIndicator>> getCalendarIndicators({
    required int classId,
    required int sectionId,
    required int year,
    required int month,
  });

  Future<List<DateTime>> getUnmarkedDates({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // Alerts
  Future<List<LowAttendanceAlert>> getLowAttendanceAlerts({
    required double threshold,
    required DateTime startDate,
    required DateTime endDate,
    int? classId,
  });

  // Counts
  Future<int> countByStatus({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
  });

  Future<int> countMarkedForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
  });

  Future<int> getTotalAttendanceForDate(DateTime date, {String? status});

  // Lock status
  Future<DailyAttendanceStatusData?> getDailyStatus(
    int classId,
    int sectionId,
    DateTime date,
  );

  Future<bool> lockAttendance(
    int classId,
    int sectionId,
    DateTime date,
    int lockedBy,
  );

  Future<bool> unlockAttendance(int classId, int sectionId, DateTime date);
}

/// Implementation of AttendanceRepository using Drift database
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AppDatabase _db;

  AttendanceRepositoryImpl(this._db);

  @override
  Future<StudentAttendanceData?> getById(int id) async {
    return await (_db.select(
      _db.studentAttendance,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<StudentAttendanceData?> getByStudentAndDate(
    int studentId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    return await (_db.select(_db.studentAttendance)..where(
          (t) =>
              t.studentId.equals(studentId) &
              t.date.isBiggerOrEqualValue(dateOnly) &
              t.date.isSmallerThanValue(dateEnd),
        ))
        .getSingleOrNull();
  }

  @override
  Future<int> create(StudentAttendanceCompanion attendance) async {
    return await _db.into(_db.studentAttendance).insert(attendance);
  }

  @override
  Future<bool> update(int id, StudentAttendanceCompanion attendance) async {
    return await (_db.update(
          _db.studentAttendance,
        )..where((t) => t.id.equals(id))).write(attendance) >
        0;
  }

  @override
  Future<int> delete(int id) async {
    return await (_db.delete(
      _db.studentAttendance,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> upsert(StudentAttendanceCompanion attendance) async {
    return await _db
        .into(_db.studentAttendance)
        .insert(
          attendance,
          onConflict: DoUpdate(
            (old) => attendance,
            target: [
              _db.studentAttendance.studentId,
              _db.studentAttendance.date,
            ],
          ),
        );
  }

  @override
  Future<void> upsertBatch(List<StudentAttendanceCompanion> attendances) async {
    await _db.batch((batch) {
      for (final attendance in attendances) {
        batch.insert(
          _db.studentAttendance,
          attendance,
          onConflict: DoUpdate(
            (old) => attendance,
            target: [
              _db.studentAttendance.studentId,
              _db.studentAttendance.date,
            ],
          ),
        );
      }
    });
  }

  @override
  Future<int> deleteByDate(DateTime date, int classId, int sectionId) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    return await (_db.delete(_db.studentAttendance)..where(
          (t) =>
              t.classId.equals(classId) &
              t.sectionId.equals(sectionId) &
              t.date.isBiggerOrEqualValue(dateOnly) &
              t.date.isSmallerThanValue(dateEnd),
        ))
        .go();
  }

  @override
  Future<List<StudentAttendanceEntry>> getClassAttendanceForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String academicYear,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    // Get all enrolled students for the class/section
    final enrolledStudentsQuery =
        _db.select(_db.students).join([
            innerJoin(
              _db.enrollments,
              _db.enrollments.studentId.equalsExp(_db.students.id),
            ),
          ])
          ..where(
            _db.enrollments.classId.equals(classId) &
                _db.enrollments.sectionId.equals(sectionId) &
                _db.enrollments.academicYear.equals(academicYear) &
                _db.enrollments.isCurrent.equals(true) &
                _db.students.status.equals('active'),
          )
          ..orderBy([OrderingTerm.asc(_db.students.admissionNumber)]);

    var enrolledRows = await enrolledStudentsQuery.get();

    // Fallback: If no students found for the specific academic year,
    // try finding students who are currently marked as 'current' in this class/section
    if (enrolledRows.isEmpty) {
      final fallbackQuery =
          _db.select(_db.students).join([
              innerJoin(
                _db.enrollments,
                _db.enrollments.studentId.equalsExp(_db.students.id),
              ),
            ])
            ..where(
              _db.enrollments.classId.equals(classId) &
                  _db.enrollments.sectionId.equals(sectionId) &
                  _db.enrollments.isCurrent.equals(true) &
                  _db.students.status.equals('active'),
            )
            ..orderBy([OrderingTerm.asc(_db.students.admissionNumber)]);

      enrolledRows = await fallbackQuery.get();
    }

    // Get attendance records for this date
    final attendanceQuery = _db.select(_db.studentAttendance)
      ..where(
        (t) =>
            t.classId.equals(classId) &
            t.sectionId.equals(sectionId) &
            t.date.isBiggerOrEqualValue(dateOnly) &
            t.date.isSmallerThanValue(dateEnd),
      );

    final attendanceRecords = await attendanceQuery.get();
    final attendanceMap = {for (final a in attendanceRecords) a.studentId: a};

    // Combine students with their attendance
    final result = <StudentAttendanceEntry>[];
    for (final row in enrolledRows) {
      final student = row.readTable(_db.students);
      final enrollment = row.readTable(_db.enrollments);
      final attendance = attendanceMap[student.id];

      result.add(
        StudentAttendanceEntry(
          student: student,
          enrollment: enrollment,
          attendance: attendance,
        ),
      );
    }

    return result;
  }

  @override
  Future<List<StudentAttendanceData>> getStudentHistory({
    required int studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _db.select(_db.studentAttendance)
      ..where((t) => t.studentId.equals(studentId));

    if (startDate != null) {
      query = query..where((t) => t.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      final endDateNext = endDate.add(const Duration(days: 1));
      query = query..where((t) => t.date.isSmallerThanValue(endDateNext));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return await query.get();
  }

  @override
  Future<List<AttendanceRecord>> search(AttendanceFilters filters) async {
    final query = _db.select(_db.studentAttendance).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.studentAttendance.studentId),
      ),
      leftOuterJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
    ]);

    if (filters.date != null) {
      final dateOnly = DateTime(
        filters.date!.year,
        filters.date!.month,
        filters.date!.day,
      );
      final dateEnd = dateOnly.add(const Duration(days: 1));
      query.where(
        _db.studentAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.studentAttendance.date.isSmallerThanValue(dateEnd),
      );
    }

    if (filters.classId != null) {
      query.where(_db.studentAttendance.classId.equals(filters.classId!));
    }

    if (filters.sectionId != null) {
      query.where(_db.studentAttendance.sectionId.equals(filters.sectionId!));
    }

    if (filters.studentId != null) {
      query.where(_db.studentAttendance.studentId.equals(filters.studentId!));
    }

    if (filters.status != null) {
      query.where(_db.studentAttendance.status.equals(filters.status!));
    }

    if (filters.startDate != null) {
      query.where(
        _db.studentAttendance.date.isBiggerOrEqualValue(filters.startDate!),
      );
    }

    if (filters.endDate != null) {
      final endDateNext = filters.endDate!.add(const Duration(days: 1));
      query.where(_db.studentAttendance.date.isSmallerThanValue(endDateNext));
    }

    if (filters.academicYear != null) {
      query.where(
        _db.studentAttendance.academicYear.equals(filters.academicYear!),
      );
    }

    query.orderBy([OrderingTerm.desc(_db.studentAttendance.date)]);

    if (filters.limit != null) {
      query.limit(filters.limit!, offset: filters.offset ?? 0);
    }

    final rows = await query.get();

    return rows.map((row) {
      final attendance = row.readTable(_db.studentAttendance);
      final student = row.readTable(_db.students);
      final enrollment = row.readTableOrNull(_db.enrollments);

      return AttendanceRecord(
        attendance: attendance,
        student: student,
        rollNumber: enrollment?.rollNumber,
      );
    }).toList();
  }

  @override
  Future<AttendanceStats> getStudentStats({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final endDateNext = endDate.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.studentAttendance)
      ..addColumns([
        _db.studentAttendance.status,
        _db.studentAttendance.status.count(),
        _db.studentAttendance.date.min(),
        _db.studentAttendance.date.max(),
      ])
      ..where(
        _db.studentAttendance.studentId.equals(studentId) &
            _db.studentAttendance.date.isBiggerOrEqualValue(startDate) &
            _db.studentAttendance.date.isSmallerThanValue(endDateNext),
      )
      ..groupBy([_db.studentAttendance.status]);

    final rows = await query.get();

    int present = 0, absent = 0, late = 0, leave = 0;
    DateTime? firstDate, lastDate;

    for (final row in rows) {
      final status = row.read(_db.studentAttendance.status);
      final count = row.read(_db.studentAttendance.status.count()) ?? 0;

      switch (status) {
        case 'present':
          present = count;
          break;
        case 'absent':
          absent = count;
          break;
        case 'late':
          late = count;
          break;
        case 'leave':
          leave = count;
          break;
      }

      final minDate = row.read(_db.studentAttendance.date.min());
      final maxDate = row.read(_db.studentAttendance.date.max());
      if (minDate != null &&
          (firstDate == null || minDate.isBefore(firstDate))) {
        firstDate = minDate;
      }
      if (maxDate != null && (lastDate == null || maxDate.isAfter(lastDate))) {
        lastDate = maxDate;
      }
    }

    return AttendanceStats(
      totalDays: present + absent + late + leave,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      leaveDays: leave,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  @override
  Future<AttendanceStats> getClassStats({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final endDateNext = endDate.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.studentAttendance)
      ..addColumns([
        _db.studentAttendance.status,
        _db.studentAttendance.status.count(),
        _db.studentAttendance.date.min(),
        _db.studentAttendance.date.max(),
      ])
      ..where(
        _db.studentAttendance.classId.equals(classId) &
            _db.studentAttendance.sectionId.equals(sectionId) &
            _db.studentAttendance.date.isBiggerOrEqualValue(startDate) &
            _db.studentAttendance.date.isSmallerThanValue(endDateNext),
      )
      ..groupBy([_db.studentAttendance.status]);

    final rows = await query.get();

    int present = 0, absent = 0, late = 0, leave = 0;
    DateTime? firstDate, lastDate;

    for (final row in rows) {
      final status = row.read(_db.studentAttendance.status);
      final count = row.read(_db.studentAttendance.status.count()) ?? 0;

      switch (status) {
        case 'present':
          present = count;
          break;
        case 'absent':
          absent = count;
          break;
        case 'late':
          late = count;
          break;
        case 'leave':
          leave = count;
          break;
      }

      final minDate = row.read(_db.studentAttendance.date.min());
      final maxDate = row.read(_db.studentAttendance.date.max());
      if (minDate != null &&
          (firstDate == null || minDate.isBefore(firstDate))) {
        firstDate = minDate;
      }
      if (maxDate != null && (lastDate == null || maxDate.isAfter(lastDate))) {
        lastDate = maxDate;
      }
    }

    return AttendanceStats(
      totalDays: present + absent + late + leave,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      leaveDays: leave,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  @override
  Future<DailyAttendanceSummary> getDailySummary({
    required int classId,
    required int sectionId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    // Get total enrolled students count
    final totalQuery =
        _db.selectOnly(_db.enrollments).join([
            innerJoin(
              _db.students,
              _db.students.id.equalsExp(_db.enrollments.studentId),
            ),
          ])
          ..addColumns([_db.enrollments.id.count()])
          ..where(
            _db.enrollments.classId.equals(classId) &
                _db.enrollments.sectionId.equals(sectionId) &
                _db.enrollments.isCurrent.equals(true) &
                _db.students.status.equals('active'),
          );

    final totalRow = await totalQuery.getSingle();
    final totalStudents = totalRow.read(_db.enrollments.id.count()) ?? 0;

    // Get attendance counts by status
    final statsQuery = _db.selectOnly(_db.studentAttendance)
      ..addColumns([
        _db.studentAttendance.status,
        _db.studentAttendance.status.count(),
      ])
      ..where(
        _db.studentAttendance.classId.equals(classId) &
            _db.studentAttendance.sectionId.equals(sectionId) &
            _db.studentAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.studentAttendance.date.isSmallerThanValue(dateEnd),
      )
      ..groupBy([_db.studentAttendance.status]);

    final statRows = await statsQuery.get();

    int present = 0, absent = 0, late = 0, leave = 0;
    bool isMarked = false;

    for (final row in statRows) {
      final status = row.read(_db.studentAttendance.status);
      final count = row.read(_db.studentAttendance.status.count()) ?? 0;
      isMarked = true;

      switch (status) {
        case 'present':
          present = count;
          break;
        case 'absent':
          absent = count;
          break;
        case 'late':
          late = count;
          break;
        case 'leave':
          leave = count;
          break;
      }
    }

    return DailyAttendanceSummary(
      date: dateOnly,
      classId: classId,
      sectionId: sectionId,
      totalStudents: totalStudents,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      leaveCount: leave,
      isMarked: isMarked,
    );
  }

  @override
  Future<DailyAttendanceStatusData?> getDailyStatus(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    return await (_db.select(_db.dailyAttendanceStatus)..where(
          (t) =>
              t.classId.equals(classId) &
              t.sectionId.equals(sectionId) &
              t.date.equals(dateOnly),
        ))
        .getSingleOrNull();
  }

  @override
  Future<bool> lockAttendance(
    int classId,
    int sectionId,
    DateTime date,
    int lockedBy,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    await _db
        .into(_db.dailyAttendanceStatus)
        .insert(
          DailyAttendanceStatusCompanion(
            classId: Value(classId),
            sectionId: Value(sectionId),
            date: Value(dateOnly),
            isLocked: const Value(true),
            lockedBy: Value(lockedBy),
            lockedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (old) => DailyAttendanceStatusCompanion(
              isLocked: const Value(true),
              lockedBy: Value(lockedBy),
              lockedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
            target: [
              _db.dailyAttendanceStatus.classId,
              _db.dailyAttendanceStatus.sectionId,
              _db.dailyAttendanceStatus.date,
            ],
          ),
        );
    return true;
  }

  @override
  Future<bool> unlockAttendance(
    int classId,
    int sectionId,
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final count =
        await (_db.update(_db.dailyAttendanceStatus)..where(
              (t) =>
                  t.classId.equals(classId) &
                  t.sectionId.equals(sectionId) &
                  t.date.equals(dateOnly),
            ))
            .write(
              const DailyAttendanceStatusCompanion(
                isLocked: Value(false),
                lockedBy: Value(null),
                lockedAt: Value(null),
              ),
            );

    return count > 0;
  }

  @override
  Future<List<CalendarDayIndicator>> getCalendarIndicators({
    required int classId,
    required int sectionId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month
    final endDateNext = endDate.add(const Duration(days: 1));

    // Get total students in class
    final totalQuery = _db.selectOnly(_db.enrollments)
      ..addColumns([_db.enrollments.id.count()])
      ..where(
        _db.enrollments.classId.equals(classId) &
            _db.enrollments.sectionId.equals(sectionId) &
            _db.enrollments.isCurrent.equals(true),
      );

    final totalRow = await totalQuery.getSingle();
    final totalStudents = totalRow.read(_db.enrollments.id.count()) ?? 0;

    // Get daily attendance summaries
    final query = await _db
        .customSelect(
          '''
      SELECT 
        date as att_date,
        SUM(CASE WHEN status = 'present' OR status = 'late' THEN 1 ELSE 0 END) as present_count,
        COUNT(*) as total_count
      FROM student_attendance
      WHERE class_id = ? AND section_id = ?
        AND date >= ? AND date < ?
      GROUP BY date
      ''',
          variables: [
            Variable.withInt(classId),
            Variable.withInt(sectionId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDateNext),
          ],
        )
        .get();

    final indicators = <CalendarDayIndicator>[];
    final markedDates = <DateTime, (int present, int total)>{};

    for (final row in query) {
      final dateTs = row.read<int>('att_date');
      final presentCount = row.read<int>('present_count');
      final totalCount = row.read<int>('total_count');

      final date = DateTime.fromMillisecondsSinceEpoch(dateTs * 1000);
      markedDates[DateTime(date.year, date.month, date.day)] = (
        presentCount,
        totalCount,
      );
    }

    // Get school working days configuration
    final workingDaysService = WorkingDaysService.instance();
    final workingDays = await workingDaysService.getWorkingDays();

    // Generate indicators for each day of the month
    for (
      var day = startDate;
      !day.isAfter(endDate);
      day = day.add(const Duration(days: 1))
    ) {
      final dayOnly = DateTime(day.year, day.month, day.day);

      // Check if working day using school settings (REPLACED hardcoded weekend check)
      final dayName = WorkingDaysService.getDayName(day.weekday);
      final isWorkingDay = workingDays.contains(dayName);
      if (!isWorkingDay) {
        indicators.add(
          CalendarDayIndicator(
            date: dayOnly,
            status: CalendarDayStatus.holiday,
          ),
        );
        continue;
      }

      // Check if future date
      if (day.isAfter(DateTime.now())) {
        indicators.add(
          CalendarDayIndicator(
            date: dayOnly,
            status: CalendarDayStatus.notMarked,
          ),
        );
        continue;
      }

      final attendance = markedDates[dayOnly];
      if (attendance == null) {
        indicators.add(
          CalendarDayIndicator(
            date: dayOnly,
            status: CalendarDayStatus.notMarked,
          ),
        );
        continue;
      }

      final (presentCount, totalCount) = attendance;
      final percentage = totalStudents > 0
          ? (presentCount / totalStudents) * 100
          : 0.0;

      CalendarDayStatus status;
      if (presentCount == totalStudents) {
        status = CalendarDayStatus.allPresent;
      } else if (percentage >= 50) {
        status = CalendarDayStatus.partial;
      } else {
        status = CalendarDayStatus.highAbsence;
      }

      indicators.add(
        CalendarDayIndicator(
          date: dayOnly,
          status: status,
          presentCount: presentCount,
          totalCount: totalCount,
        ),
      );
    }

    return indicators;
  }

  @override
  Future<List<DateTime>> getUnmarkedDates({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final markedDatesQuery = await _db
        .customSelect(
          '''
      SELECT DISTINCT date as att_date
      FROM student_attendance
      WHERE class_id = ? AND section_id = ?
        AND date >= ? AND date <= ?
      ''',
          variables: [
            Variable.withInt(classId),
            Variable.withInt(sectionId),
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate.add(const Duration(days: 1))),
          ],
        )
        .get();

    final markedDates = markedDatesQuery.map((r) {
      final ts = r.read<int>('att_date');
      final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    final unmarkedDates = <DateTime>[];
    final now = DateTime.now();

    // Get school working days configuration
    final workingDaysService = WorkingDaysService.instance();
    final workingDays = await workingDaysService.getWorkingDays();

    for (
      var day = startDate;
      !day.isAfter(endDate) && !day.isAfter(now);
      day = day.add(const Duration(days: 1))
    ) {
      final dayOnly = DateTime(day.year, day.month, day.day);

      // Skip non-working days using school settings (REPLACED hardcoded weekend check)
      final dayName = WorkingDaysService.getDayName(day.weekday);
      final isWorkingDay = workingDays.contains(dayName);
      if (!isWorkingDay) {
        continue;
      }

      if (!markedDates.contains(dayOnly)) {
        unmarkedDates.add(dayOnly);
      }
    }

    return unmarkedDates;
  }

  @override
  Future<List<LowAttendanceAlert>> getLowAttendanceAlerts({
    required double threshold,
    required DateTime startDate,
    required DateTime endDate,
    int? classId,
  }) async {
    final endDateNext = endDate.add(const Duration(days: 1));

    // Complex query to get students with low attendance
    String classCondition = classId != null ? 'AND e.class_id = ?' : '';
    List<Variable> variables = [
      Variable.withDateTime(startDate),
      Variable.withDateTime(endDateNext),
      if (classId != null) Variable.withInt(classId),
      Variable.withReal(threshold),
    ];

    final query = await _db.customSelect('''
      SELECT 
        s.*,
        e.class_id,
        e.section_id,
        c.name as class_name,
        sec.name as section_name,
        COUNT(sa.id) as total_days,
        SUM(CASE WHEN sa.status = 'absent' THEN 1 ELSE 0 END) as absent_days,
        SUM(CASE WHEN sa.status IN ('present', 'late') THEN 1 ELSE 0 END) as present_days,
        CASE 
          WHEN COUNT(sa.id) = 0 THEN 0 
          ELSE (CAST(SUM(CASE WHEN sa.status IN ('present', 'late') THEN 1 ELSE 0 END) AS REAL) / COUNT(sa.id)) * 100 
        END as attendance_percentage
      FROM students s
      INNER JOIN enrollments e ON e.student_id = s.id AND e.is_current = 1
      INNER JOIN classes c ON c.id = e.class_id
      INNER JOIN sections sec ON sec.id = e.section_id
      LEFT JOIN student_attendance sa ON sa.student_id = s.id 
        AND sa.date >= ? AND sa.date < ?
      WHERE s.status = 'active' $classCondition
      GROUP BY s.id
      HAVING attendance_percentage < ? AND total_days > 0
      ORDER BY attendance_percentage ASC
      ''', variables: variables).get();

    return query.map((row) {
      return LowAttendanceAlert(
        student: Student(
          id: row.read<int>('id'),
          uuid: row.read<String>('uuid'),
          admissionNumber: row.read<String>('admission_number'),
          studentName: row.read<String>('student_name'),
          fatherName: row.readNullable<String>('father_name'),
          dateOfBirth: row.readNullable<DateTime>('date_of_birth'),
          gender: row.readNullable<String>('gender') ?? 'unknown',
          status: row.readNullable<String>('status') ?? 'active',
          admissionDate: row.read<DateTime>('admission_date'),
          createdAt: row.read<DateTime>('created_at'),
          updatedAt: row.read<DateTime>('updated_at'),
          photo: row.readNullable<Uint8List>('photo'),
          email: row.readNullable<String>('email'),
          phone: row.readNullable<String>('phone'),
          address: row.readNullable<String>('address'),
          city: row.readNullable<String>('city'),
          bloodGroup: row.readNullable<String>('blood_group'),
          religion: row.readNullable<String>('religion'),
          nationality: row.readNullable<String>('nationality') ?? 'Pakistani',
          cnic: row.readNullable<String>('cnic'),
          notes: row.readNullable<String>('notes'),
          previousSchool: row.readNullable<String>('previous_school'),
          medicalInfo: row.readNullable<String>('medical_info'),
          allergies: row.readNullable<String>('allergies'),
          specialNeeds: row.readNullable<String>('special_needs'),
          leavingDate: row.readNullable<DateTime>('leaving_date'),
          leavingReason: row.readNullable<String>('leaving_reason'),
        ),
        classId: row.read<int>('class_id'),
        sectionId: row.read<int>('section_id'),
        className: row.read<String>('class_name'),
        sectionName: row.read<String>('section_name'),
        attendancePercentage: row.read<double>('attendance_percentage'),
        absentDays: row.read<int>('absent_days'),
        totalDays: row.read<int>('total_days'),
      );
    }).toList();
  }

  @override
  Future<int> countByStatus({
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.studentAttendance)
      ..addColumns([_db.studentAttendance.id.count()])
      ..where(
        _db.studentAttendance.classId.equals(classId) &
            _db.studentAttendance.sectionId.equals(sectionId) &
            _db.studentAttendance.status.equals(status) &
            _db.studentAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.studentAttendance.date.isSmallerThanValue(dateEnd),
      );

    final result = await query.getSingle();
    return result.read(_db.studentAttendance.id.count()) ?? 0;
  }

  @override
  Future<int> countMarkedForDate({
    required int classId,
    required int sectionId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.studentAttendance)
      ..addColumns([_db.studentAttendance.id.count()])
      ..where(
        _db.studentAttendance.classId.equals(classId) &
            _db.studentAttendance.sectionId.equals(sectionId) &
            _db.studentAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.studentAttendance.date.isSmallerThanValue(dateEnd),
      );

    final result = await query.getSingle();
    return result.read(_db.studentAttendance.id.count()) ?? 0;
  }

  @override
  Future<int> getTotalAttendanceForDate(DateTime date, {String? status}) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateEnd = dateOnly.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.studentAttendance)
      ..addColumns([_db.studentAttendance.id.count()])
      ..where(
        _db.studentAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.studentAttendance.date.isSmallerThanValue(dateEnd),
      );

    if (status != null) {
      query.where(_db.studentAttendance.status.equals(status));
    }

    final result = await query.getSingle();
    return result.read(_db.studentAttendance.id.count()) ?? 0;
  }
}
