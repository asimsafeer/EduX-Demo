/// EduX School Management System
/// Sync device models for API communication
library;

import 'package:drift/drift.dart';

import '../../database/database.dart';

/// Sync device model for API responses
class SyncDeviceModel {
  final int id;
  final String deviceId;
  final String? deviceName;
  final int teacherId;
  final String teacherName;
  final DateTime? lastSyncAt;
  final bool isActive;
  final DateTime registeredAt;
  final String? lastIpAddress;

  SyncDeviceModel({
    required this.id,
    required this.deviceId,
    this.deviceName,
    required this.teacherId,
    required this.teacherName,
    this.lastSyncAt,
    required this.isActive,
    required this.registeredAt,
    this.lastIpAddress,
  });

  factory SyncDeviceModel.fromRow(QueryRow row, String teacherName) {
    return SyncDeviceModel(
      id: row.read<int>('id'),
      deviceId: row.read<String>('device_id'),
      deviceName: row.readNullable<String>('device_name'),
      teacherId: row.read<int>('teacher_id'),
      teacherName: teacherName,
      lastSyncAt: row.readNullable<DateTime>('last_sync_at'),
      isActive: row.read<bool>('is_active'),
      registeredAt: row.read<DateTime>('registered_at'),
      lastIpAddress: row.readNullable<String>('last_ip_address'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'isActive': isActive,
        'registeredAt': registeredAt.toIso8601String(),
        'lastIpAddress': lastIpAddress,
      };
}

/// Device registration request from teacher app
class DeviceRegistrationRequest {
  final String deviceId;
  final String? deviceName;
  final String username;
  final String password;
  final String? appVersion;

  DeviceRegistrationRequest({
    required this.deviceId,
    this.deviceName,
    required this.username,
    required this.password,
    this.appVersion,
  });

  factory DeviceRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationRequest(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      username: json['username'] as String,
      password: json['password'] as String,
      appVersion: json['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'username': username,
        'password': password,
        'appVersion': appVersion,
      };
}

/// Login response for teacher app
class TeacherLoginResponse {
  final bool success;
  final String? token;
  final int? teacherId;
  final String? teacherName;
  final String? email;
  final String? photoUrl;
  final String? error;
  final String? errorCode;
  final DateTime? tokenExpiry;
  final List<String> permissions;

  TeacherLoginResponse({
    required this.success,
    this.token,
    this.teacherId,
    this.teacherName,
    this.email,
    this.photoUrl,
    this.error,
    this.errorCode,
    this.tokenExpiry,
    this.permissions = const [],
  });

  factory TeacherLoginResponse.success({
    required String token,
    required int teacherId,
    required String teacherName,
    String? email,
    String? photoUrl,
    DateTime? tokenExpiry,
    List<String> permissions = const [],
  }) {
    return TeacherLoginResponse(
      success: true,
      token: token,
      teacherId: teacherId,
      teacherName: teacherName,
      email: email,
      photoUrl: photoUrl,
      tokenExpiry: tokenExpiry,
      permissions: permissions,
    );
  }

  factory TeacherLoginResponse.error(String error, {String? errorCode}) {
    return TeacherLoginResponse(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        if (token != null) 'token': token,
        if (teacherId != null) 'teacherId': teacherId,
        if (teacherName != null) 'teacherName': teacherName,
        if (email != null) 'email': email,
        'photoUrl': photoUrl, // Always include, even if null
        if (error != null) 'error': error,
        if (errorCode != null) 'errorCode': errorCode,
        if (tokenExpiry != null) 'tokenExpiry': tokenExpiry!.toIso8601String(),
        'permissions': permissions,
      };
}

/// Device info model for UI display
class DeviceInfoModel {
  final int id;
  final String deviceId;
  final String? deviceName;
  final int teacherId;
  final String teacherName;
  final DateTime? lastSyncAt;
  final bool isActive;
  final DateTime registeredAt;
  final String? lastIpAddress;
  final String? syncToken;

  DeviceInfoModel({
    required this.id,
    required this.deviceId,
    this.deviceName,
    required this.teacherId,
    required this.teacherName,
    this.lastSyncAt,
    required this.isActive,
    required this.registeredAt,
    this.lastIpAddress,
    this.syncToken,
  });

  factory DeviceInfoModel.fromDeviceAndTeacher(
    SyncDevice device,
    String teacherName,
  ) {
    return DeviceInfoModel(
      id: device.id,
      deviceId: device.deviceId,
      deviceName: device.deviceName,
      teacherId: device.teacherId,
      teacherName: teacherName,
      lastSyncAt: device.lastSyncAt,
      isActive: device.isActive,
      registeredAt: device.registeredAt,
      lastIpAddress: device.lastIpAddress,
      syncToken: device.syncToken,
    );
  }

  /// Get display name for the device
  String get displayName => deviceName ?? 'Unknown Device';

  /// Get formatted last sync time
  String get formattedLastSync {
    if (lastSyncAt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(lastSyncAt!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSyncAt!.day}/${lastSyncAt!.month}/${lastSyncAt!.year}';
  }

  /// Check if device is online (synced in last 5 minutes)
  bool get isOnline {
    if (lastSyncAt == null) return false;
    final diff = DateTime.now().difference(lastSyncAt!);
    return diff.inMinutes < 5;
  }
}
