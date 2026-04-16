/// EduX Teacher App - Student Model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

/// Student model
@freezed
class Student with _$Student {
  const factory Student({
    required int studentId,
    required String name,
    String? rollNumber,
    String? gender,
    String? photoUrl,
    required int classId,
    required int sectionId,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

  const Student._();

  /// Display name with roll number
  String get displayName {
    if (rollNumber != null && rollNumber!.isNotEmpty) {
      return '$name (Roll: $rollNumber)';
    }
    return name;
  }

  /// Initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.substring(0, parts.first.length > 1 ? 2 : 1).toUpperCase();
  }
}

/// Student with attendance status
@freezed
class StudentAttendance with _$StudentAttendance {
  const factory StudentAttendance({
    required Student student,
    String? status,
    String? remarks,
    DateTime? markedAt,
    @Default(false) bool isSynced,
  }) = _StudentAttendance;

  factory StudentAttendance.fromJson(Map<String, dynamic> json) =>
      _$StudentAttendanceFromJson(json);
}
