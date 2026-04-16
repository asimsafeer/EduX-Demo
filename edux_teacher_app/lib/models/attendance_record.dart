/// EduX Teacher App - Attendance Record Model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_record.freezed.dart';
part 'attendance_record.g.dart';

/// Attendance record for sync
@freezed
class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required int studentId,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
    String? remarks,
    DateTime? markedAt,
    String? academicYear,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);

  const AttendanceRecord._();

  /// Create from pending attendance database record
  /// FIXED: Academic year must be provided from server context
  factory AttendanceRecord.fromPending({
    required int studentId,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
    String? remarks,
    DateTime? markedAt,
    String? academicYear, // FIXED: Should be provided from server
  }) {
    return AttendanceRecord(
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      date: date,
      status: status,
      remarks: remarks,
      markedAt: markedAt ?? DateTime.now(),
      academicYear: academicYear ?? _getFallbackAcademicYear(),
    );
  }

  /// Fallback academic year generation (only used when server year unavailable)
  static String _getFallbackAcademicYear() {
    final now = DateTime.now();
    if (now.month >= 4) {
      return '${now.year}-${now.year + 1}';
    } else {
      return '${now.year - 1}-${now.year}';
    }
  }
}

/// Attendance statistics
@freezed
class AttendanceStats with _$AttendanceStats {
  const factory AttendanceStats({
    @Default(0) int present,
    @Default(0) int absent,
    @Default(0) int late,
    @Default(0) int leave,
    @Default(0) int halfDay,
    @Default(0) int total,
  }) = _AttendanceStats;

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      _$AttendanceStatsFromJson(json);

  const AttendanceStats._();

  bool get isComplete => marked == total && total > 0;
  int get marked => present + absent + late + leave + halfDay;
  int get remaining => total - marked;
  double get percentage => total > 0 ? (marked / total) * 100 : 0;
  double get presentPercentage => marked > 0 ? (present / marked) * 100 : 0;
  double get absentPercentage => marked > 0 ? (absent / marked) * 100 : 0;

  int getByStatus(String status) {
    switch (status) {
      case 'present':
        return present;
      case 'absent':
        return absent;
      case 'late':
        return late;
      case 'leave':
        return leave;
      case 'half_day':
        return halfDay;
      default:
        return 0;
    }
  }
}
