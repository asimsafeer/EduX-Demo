/// EduX Teacher App - Teacher Model
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher.freezed.dart';
part 'teacher.g.dart';

/// Teacher model representing logged-in teacher
@freezed
class Teacher with _$Teacher {
  const factory Teacher({
    required int id,
    required String name,
    required String email,
    String? photoUrl,
    String? token,
    DateTime? tokenExpiry,
    @Default([]) List<String> permissions,
  }) = _Teacher;

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
}

/// Teacher login request
@freezed
class TeacherLoginRequest with _$TeacherLoginRequest {
  const factory TeacherLoginRequest({
    required String username,
    required String password,
    required String deviceId,
    required String deviceName,
    String? appVersion,
  }) = _TeacherLoginRequest;

  factory TeacherLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$TeacherLoginRequestFromJson(json);
}

/// Teacher login response
@freezed
class TeacherLoginResponse with _$TeacherLoginResponse {
  const factory TeacherLoginResponse({
    required bool success,
    String? token,
    int? teacherId,
    String? teacherName,
    String? email,
    String? photoUrl,
    DateTime? tokenExpiry,
    @Default([]) List<String> permissions,
    String? error,
    String? errorCode,
  }) = _TeacherLoginResponse;

  factory TeacherLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$TeacherLoginResponseFromJson(json);
}
