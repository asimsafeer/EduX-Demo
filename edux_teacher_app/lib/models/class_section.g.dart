// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClassSectionImpl _$$ClassSectionImplFromJson(Map<String, dynamic> json) =>
    _$ClassSectionImpl(
      classId: (json['classId'] as num).toInt(),
      sectionId: (json['sectionId'] as num).toInt(),
      className: json['className'] as String,
      sectionName: json['sectionName'] as String,
      subjectName: json['subjectName'] as String?,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      isClassTeacher: json['isClassTeacher'] as bool? ?? false,
    );

Map<String, dynamic> _$$ClassSectionImplToJson(_$ClassSectionImpl instance) =>
    <String, dynamic>{
      'classId': instance.classId,
      'sectionId': instance.sectionId,
      'className': instance.className,
      'sectionName': instance.sectionName,
      'subjectName': instance.subjectName,
      'totalStudents': instance.totalStudents,
      'isClassTeacher': instance.isClassTeacher,
    };

_$ClassSummaryImpl _$$ClassSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ClassSummaryImpl(
      classId: (json['classId'] as num).toInt(),
      sectionId: (json['sectionId'] as num).toInt(),
      className: json['className'] as String,
      sectionName: json['sectionName'] as String,
      totalStudents: (json['totalStudents'] as num).toInt(),
      markedCount: (json['markedCount'] as num).toInt(),
      lastMarkedAt: json['lastMarkedAt'] == null
          ? null
          : DateTime.parse(json['lastMarkedAt'] as String),
    );

Map<String, dynamic> _$$ClassSummaryImplToJson(_$ClassSummaryImpl instance) =>
    <String, dynamic>{
      'classId': instance.classId,
      'sectionId': instance.sectionId,
      'className': instance.className,
      'sectionName': instance.sectionName,
      'totalStudents': instance.totalStudents,
      'markedCount': instance.markedCount,
      'lastMarkedAt': instance.lastMarkedAt?.toIso8601String(),
    };
