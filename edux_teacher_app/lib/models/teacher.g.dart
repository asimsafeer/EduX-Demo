// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherImpl _$$TeacherImplFromJson(Map<String, dynamic> json) =>
    _$TeacherImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      token: json['token'] as String?,
      tokenExpiry: json['tokenExpiry'] == null
          ? null
          : DateTime.parse(json['tokenExpiry'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TeacherImplToJson(_$TeacherImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'token': instance.token,
      'tokenExpiry': instance.tokenExpiry?.toIso8601String(),
      'permissions': instance.permissions,
    };

_$TeacherLoginRequestImpl _$$TeacherLoginRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$TeacherLoginRequestImpl(
      username: json['username'] as String,
      password: json['password'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      appVersion: json['appVersion'] as String?,
    );

Map<String, dynamic> _$$TeacherLoginRequestImplToJson(
        _$TeacherLoginRequestImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'appVersion': instance.appVersion,
    };

_$TeacherLoginResponseImpl _$$TeacherLoginResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$TeacherLoginResponseImpl(
      success: json['success'] as bool,
      token: json['token'] as String?,
      teacherId: (json['teacherId'] as num?)?.toInt(),
      teacherName: json['teacherName'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      tokenExpiry: json['tokenExpiry'] == null
          ? null
          : DateTime.parse(json['tokenExpiry'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      error: json['error'] as String?,
      errorCode: json['errorCode'] as String?,
    );

Map<String, dynamic> _$$TeacherLoginResponseImplToJson(
        _$TeacherLoginResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'token': instance.token,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'tokenExpiry': instance.tokenExpiry?.toIso8601String(),
      'permissions': instance.permissions,
      'error': instance.error,
      'errorCode': instance.errorCode,
    };
