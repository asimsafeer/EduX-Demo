// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SyncRequestImpl _$$SyncRequestImplFromJson(Map<String, dynamic> json) =>
    _$SyncRequestImpl(
      deviceId: json['deviceId'] as String,
      teacherId: (json['teacherId'] as num).toInt(),
      syncTimestamp: DateTime.parse(json['syncTimestamp'] as String),
      attendanceRecords: (json['attendanceRecords'] as List<dynamic>)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      syncToken: json['syncToken'] as String?,
    );

Map<String, dynamic> _$$SyncRequestImplToJson(_$SyncRequestImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'teacherId': instance.teacherId,
      'syncTimestamp': instance.syncTimestamp.toIso8601String(),
      'attendanceRecords': instance.attendanceRecords,
      'syncToken': instance.syncToken,
    };

_$SyncResponseImpl _$$SyncResponseImplFromJson(Map<String, dynamic> json) =>
    _$SyncResponseImpl(
      success: json['success'] as bool,
      processed: (json['processed'] as num).toInt(),
      created: (json['created'] as num).toInt(),
      updated: (json['updated'] as num).toInt(),
      conflicts: (json['conflicts'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      serverTimestamp: json['serverTimestamp'] == null
          ? null
          : DateTime.parse(json['serverTimestamp'] as String),
      syncToken: json['syncToken'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$SyncResponseImplToJson(_$SyncResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'processed': instance.processed,
      'created': instance.created,
      'updated': instance.updated,
      'conflicts': instance.conflicts,
      'errors': instance.errors,
      'serverTimestamp': instance.serverTimestamp?.toIso8601String(),
      'syncToken': instance.syncToken,
      'errorMessage': instance.errorMessage,
    };

_$DiscoveredServerImpl _$$DiscoveredServerImplFromJson(
        Map<String, dynamic> json) =>
    _$DiscoveredServerImpl(
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: (json['port'] as num).toInt(),
      version: json['version'] as String?,
      schoolName: json['schoolName'] as String?,
    );

Map<String, dynamic> _$$DiscoveredServerImplToJson(
        _$DiscoveredServerImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'ipAddress': instance.ipAddress,
      'port': instance.port,
      'version': instance.version,
      'schoolName': instance.schoolName,
    };

_$SyncStatusImpl _$$SyncStatusImplFromJson(Map<String, dynamic> json) =>
    _$SyncStatusImpl(
      isOnline: json['isOnline'] as bool? ?? false,
      isSyncing: json['isSyncing'] as bool? ?? false,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      serverAddress: json['serverAddress'] as String?,
      lastSyncTime: json['lastSyncTime'] == null
          ? null
          : DateTime.parse(json['lastSyncTime'] as String),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$SyncStatusImplToJson(_$SyncStatusImpl instance) =>
    <String, dynamic>{
      'isOnline': instance.isOnline,
      'isSyncing': instance.isSyncing,
      'pendingCount': instance.pendingCount,
      'serverAddress': instance.serverAddress,
      'lastSyncTime': instance.lastSyncTime?.toIso8601String(),
      'error': instance.error,
    };

_$ServerStatusImpl _$$ServerStatusImplFromJson(Map<String, dynamic> json) =>
    _$ServerStatusImpl(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      version: json['version'] as String,
      serverName: json['serverName'] as String?,
      port: (json['port'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ServerStatusImplToJson(_$ServerStatusImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
      'version': instance.version,
      'serverName': instance.serverName,
      'port': instance.port,
    };

_$SyncConflictImpl _$$SyncConflictImplFromJson(Map<String, dynamic> json) =>
    _$SyncConflictImpl(
      studentId: (json['studentId'] as num).toInt(),
      studentName: json['studentName'] as String,
      date: DateTime.parse(json['date'] as String),
      teacherStatus: json['teacherStatus'] as String,
      officeStatus: json['officeStatus'] as String?,
      existingRecordId: (json['existingRecordId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SyncConflictImplToJson(_$SyncConflictImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'date': instance.date.toIso8601String(),
      'teacherStatus': instance.teacherStatus,
      'officeStatus': instance.officeStatus,
      'existingRecordId': instance.existingRecordId,
    };
