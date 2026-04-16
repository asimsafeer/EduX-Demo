// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceRecordImpl _$$AttendanceRecordImplFromJson(
        Map<String, dynamic> json) =>
    _$AttendanceRecordImpl(
      studentId: (json['studentId'] as num).toInt(),
      classId: (json['classId'] as num).toInt(),
      sectionId: (json['sectionId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      markedAt: json['markedAt'] == null
          ? null
          : DateTime.parse(json['markedAt'] as String),
      academicYear: json['academicYear'] as String?,
    );

Map<String, dynamic> _$$AttendanceRecordImplToJson(
        _$AttendanceRecordImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'classId': instance.classId,
      'sectionId': instance.sectionId,
      'date': instance.date.toIso8601String(),
      'status': instance.status,
      'remarks': instance.remarks,
      'markedAt': instance.markedAt?.toIso8601String(),
      'academicYear': instance.academicYear,
    };

_$AttendanceStatsImpl _$$AttendanceStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$AttendanceStatsImpl(
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      leave: (json['leave'] as num?)?.toInt() ?? 0,
      halfDay: (json['halfDay'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$AttendanceStatsImplToJson(
        _$AttendanceStatsImpl instance) =>
    <String, dynamic>{
      'present': instance.present,
      'absent': instance.absent,
      'late': instance.late,
      'leave': instance.leave,
      'halfDay': instance.halfDay,
      'total': instance.total,
    };
