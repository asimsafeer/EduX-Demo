/// EduX School Management System
/// Staff Attendance Repository - Data access layer for staff attendance
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Data class for staff attendance with staff details
class StaffAttendanceWithDetails {
  final StaffAttendanceData attendance;
  final StaffData staff;

  const StaffAttendanceWithDetails({
    required this.attendance,
    required this.staff,
  });

  String get staffName => '${staff.firstName} ${staff.lastName}'.trim();
}

/// Staff attendance statistics
class StaffAttendanceStats {
  final int totalDays;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int onLeave;

  const StaffAttendanceStats({
    required this.totalDays,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.onLeave,
  });

  double get presentPercentage =>
      totalDays > 0 ? ((present + late + halfDay) / totalDays) * 100 : 0;

  int get workingDays => present + late + halfDay;
}

/// Daily attendance summary
class DailyStaffAttendanceSummary {
  final DateTime date;
  final int total;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int onLeave;
  final bool isMarked;

  const DailyStaffAttendanceSummary({
    required this.date,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.onLeave,
    required this.isMarked,
  });
}

/// Abstract staff attendance repository interface
abstract class StaffAttendanceRepository {
  Future<StaffAttendanceData?> getAttendanceById(int id);
  Future<StaffAttendanceData?> getAttendance(int staffId, DateTime date);

  Future<int> markAttendance(StaffAttendanceCompanion attendance);
  Future<bool> updateAttendance(int id, StaffAttendanceCompanion attendance);
  Future<bool> deleteAttendance(int id);

  Future<List<StaffAttendanceWithDetails>> getAttendanceForDate(DateTime date);
  Future<List<StaffAttendanceData>> getStaffAttendanceHistory(
    int staffId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<StaffAttendanceStats> getStaffStats(
    int staffId, {
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<DailyStaffAttendanceSummary> getDailySummary(DateTime date);

  Future<bool> isAttendanceMarked(DateTime date);
  Future<int> getAttendanceCountForDate(DateTime date);

  Future<Map<DateTime, DailyStaffAttendanceSummary>> getMonthlyCalendar(
    int year,
    int month,
  );
}

/// Implementation of StaffAttendanceRepository using Drift database
class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  final AppDatabase _db;

  StaffAttendanceRepositoryImpl(this._db);

  @override
  Future<StaffAttendanceData?> getAttendanceById(int id) async {
    return await (_db.select(
      _db.staffAttendance,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<StaffAttendanceData?> getAttendance(int staffId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    return await (_db.select(_db.staffAttendance)..where(
          (t) =>
              t.staffId.equals(staffId) &
              t.date.isBiggerOrEqualValue(dateOnly) &
              t.date.isSmallerThanValue(nextDay),
        ))
        .getSingleOrNull();
  }

  @override
  Future<int> markAttendance(StaffAttendanceCompanion attendance) async {
    return await _db
        .into(_db.staffAttendance)
        .insert(attendance, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<bool> updateAttendance(
    int id,
    StaffAttendanceCompanion attendance,
  ) async {
    final rowsAffected = await (_db.update(
      _db.staffAttendance,
    )..where((t) => t.id.equals(id))).write(attendance);
    return rowsAffected > 0;
  }

  @override
  Future<bool> deleteAttendance(int id) async {
    final rowsAffected = await (_db.delete(
      _db.staffAttendance,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  @override
  Future<List<StaffAttendanceWithDetails>> getAttendanceForDate(
    DateTime date,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final query =
        _db.select(_db.staffAttendance).join([
            innerJoin(
              _db.staff,
              _db.staff.id.equalsExp(_db.staffAttendance.staffId),
            ),
          ])
          ..where(
            _db.staffAttendance.date.isBiggerOrEqualValue(dateOnly) &
                _db.staffAttendance.date.isSmallerThanValue(nextDay),
          )
          ..orderBy([OrderingTerm.asc(_db.staff.firstName)]);

    final results = await query.get();
    return results.map((row) {
      return StaffAttendanceWithDetails(
        attendance: row.readTable(_db.staffAttendance),
        staff: row.readTable(_db.staff),
      );
    }).toList();
  }

  @override
  Future<List<StaffAttendanceData>> getStaffAttendanceHistory(
    int staffId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _db.select(_db.staffAttendance)
      ..where((t) => t.staffId.equals(staffId));

    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.date)]);

    return await query.get();
  }

  @override
  Future<StaffAttendanceStats> getStaffStats(
    int staffId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await getStaffAttendanceHistory(
      staffId,
      startDate: startDate,
      endDate: endDate,
    );

    int present = 0;
    int absent = 0;
    int late = 0;
    int halfDay = 0;
    int onLeave = 0;

    for (final record in records) {
      switch (record.status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'half_day':
          halfDay++;
          break;
        case 'leave':
          onLeave++;
          break;
      }
    }

    return StaffAttendanceStats(
      totalDays: records.length,
      present: present,
      absent: absent,
      late: late,
      halfDay: halfDay,
      onLeave: onLeave,
    );
  }

  @override
  Future<DailyStaffAttendanceSummary> getDailySummary(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    // Get total active staff
    final totalStaff =
        await (_db.selectOnly(_db.staff)
              ..addColumns([_db.staff.id.count()])
              ..where(_db.staff.status.equals('active')))
            .getSingle();
    final total = totalStaff.read(_db.staff.id.count()) ?? 0;

    // Get attendance records for the date
    final attendanceQuery = _db.select(_db.staffAttendance)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(dateOnly) &
            t.date.isSmallerThanValue(nextDay),
      );

    final records = await attendanceQuery.get();

    int present = 0;
    int absent = 0;
    int late = 0;
    int halfDay = 0;
    int onLeave = 0;

    for (final record in records) {
      switch (record.status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'half_day':
          halfDay++;
          break;
        case 'leave':
          onLeave++;
          break;
      }
    }

    return DailyStaffAttendanceSummary(
      date: dateOnly,
      total: total,
      present: present,
      absent: absent,
      late: late,
      halfDay: halfDay,
      onLeave: onLeave,
      isMarked: records.isNotEmpty,
    );
  }

  @override
  Future<bool> isAttendanceMarked(DateTime date) async {
    final count = await getAttendanceCountForDate(date);
    return count > 0;
  }

  @override
  Future<int> getAttendanceCountForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.staffAttendance)
      ..addColumns([_db.staffAttendance.id.count()])
      ..where(
        _db.staffAttendance.date.isBiggerOrEqualValue(dateOnly) &
            _db.staffAttendance.date.isSmallerThanValue(nextDay),
      );

    final result = await query.getSingle();
    return result.read(_db.staffAttendance.id.count()) ?? 0;
  }

  @override
  Future<Map<DateTime, DailyStaffAttendanceSummary>> getMonthlyCalendar(
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final calendar = <DateTime, DailyStaffAttendanceSummary>{};

    for (
      var day = startDate;
      day.isBefore(endDate.add(const Duration(days: 1)));
      day = day.add(const Duration(days: 1))
    ) {
      // Skip weekends (Friday and Saturday in Pakistan)
      if (day.weekday == DateTime.friday || day.weekday == DateTime.saturday) {
        continue;
      }
      calendar[day] = await getDailySummary(day);
    }

    return calendar;
  }
}
