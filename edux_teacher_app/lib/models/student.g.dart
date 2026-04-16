// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentImpl _$$StudentImplFromJson(Map<String, dynamic> json) =>
    _$StudentImpl(
      studentId: (json['studentId'] as num).toInt(),
      name: json['name'] as String,
      rollNumber: json['rollNumber'] as String?,
      gender: json['gender'] as String?,
      photoUrl: json['photoUrl'] as String?,
      classId: (json['classId'] as num).toInt(),
      sectionId: (json['sectionId'] as num).toInt(),
    );

Map<String, dynamic> _$$StudentImplToJson(_$StudentImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'name': instance.name,
      'rollNumber': instance.rollNumber,
      'gender': instance.gender,
      'photoUrl': instance.photoUrl,
      'classId': instance.classId,
      'sectionId': instance.sectionId,
    };

_$StudentAttendanceImpl _$$StudentAttendanceImplFromJson(
        Map<String, dynamic> json) =>
    _$StudentAttendanceImpl(
      student: Student.fromJson(json['student'] as Map<String, dynamic>),
      status: json['status'] as String?,
      remarks: json['remarks'] as String?,
      markedAt: json['markedAt'] == null
          ? null
          : DateTime.parse(json['markedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$StudentAttendanceImplToJson(
        _$StudentAttendanceImpl instance) =>
    <String, dynamic>{
      'student': instance.student,
      'status': instance.status,
      'remarks': instance.remarks,
      'markedAt': instance.markedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
    };
