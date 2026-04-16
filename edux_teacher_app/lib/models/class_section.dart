/// EduX Teacher App - Class Section Model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_section.freezed.dart';
part 'class_section.g.dart';

/// Class/Section model for teacher's assigned classes
@freezed
class ClassSection with _$ClassSection {
  const factory ClassSection({
    required int classId,
    required int sectionId,
    required String className,
    required String sectionName,
    String? subjectName,
    @Default(0) int totalStudents,
    @Default(false) bool isClassTeacher,
  }) = _ClassSection;

  factory ClassSection.fromJson(Map<String, dynamic> json) =>
      _$ClassSectionFromJson(json);

  const ClassSection._();

  /// Display name for the class
  String get displayName => '$className - $sectionName';

  /// Full display name including subject
  String get fullDisplayName {
    if (subjectName != null && subjectName!.isNotEmpty) {
      return '$className - $sectionName ($subjectName)';
    }
    return displayName;
  }
}

/// Class summary with attendance info
@freezed
class ClassSummary with _$ClassSummary {
  const factory ClassSummary({
    required int classId,
    required int sectionId,
    required String className,
    required String sectionName,
    required int totalStudents,
    required int markedCount,
    DateTime? lastMarkedAt,
  }) = _ClassSummary;

  factory ClassSummary.fromJson(Map<String, dynamic> json) =>
      _$ClassSummaryFromJson(json);

  const ClassSummary._();

  bool get isComplete => markedCount == totalStudents;
  int get remainingCount => totalStudents - markedCount;
  double get completionPercentage =>
      totalStudents > 0 ? (markedCount / totalStudents) * 100 : 0;
}
