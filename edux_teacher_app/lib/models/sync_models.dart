/// EduX Teacher App - Sync Related Models
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'attendance_record.dart';
import 'class_section.dart';
import 'student.dart';

part 'sync_models.freezed.dart';
part 'sync_models.g.dart';

/// Sync request to server
@freezed
class SyncRequest with _$SyncRequest {
  const factory SyncRequest({
    required String deviceId,
    required int teacherId,
    required DateTime syncTimestamp,
    required List<AttendanceRecord> attendanceRecords,
    String? syncToken,
  }) = _SyncRequest;

  factory SyncRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncRequestFromJson(json);
}

/// Sync response from server
@freezed
class SyncResponse with _$SyncResponse {
  const factory SyncResponse({
    required bool success,
    required int processed,
    required int created,
    required int updated,
    required int conflicts,
    @Default([]) List<String> errors,
    DateTime? serverTimestamp,
    String? syncToken,
    String? errorMessage,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);
}

/// Sync result for UI
@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult({
    required bool success,
    required int processed,
    @Default(0) int created,
    @Default(0) int updated,
    @Default(0) int conflicts,
    required String message,
    DateTime? timestamp,
  }) = _SyncResult;

  factory SyncResult.fromSyncResponse(SyncResponse response) {
    return SyncResult(
      success: response.success,
      processed: response.processed,
      created: response.created,
      updated: response.updated,
      conflicts: response.conflicts,
      message: response.success
          ? 'Successfully synced ${response.processed} records'
          : (response.errorMessage ?? 'Sync failed'),
      timestamp: response.serverTimestamp,
    );
  }
}

/// Discovered server info
@freezed
class DiscoveredServer with _$DiscoveredServer {
  const factory DiscoveredServer({
    required String name,
    required String ipAddress,
    required int port,
    String? version,
    String? schoolName,
  }) = _DiscoveredServer;

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) =>
      _$DiscoveredServerFromJson(json);

  const DiscoveredServer._();

  String get displayUrl => 'http://$ipAddress:$port';
}

/// Sync status for UI
@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    @Default(false) bool isOnline,
    @Default(false) bool isSyncing,
    @Default(0) int pendingCount,
    String? serverAddress,
    DateTime? lastSyncTime,
    String? error,
  }) = _SyncStatus;

  factory SyncStatus.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusFromJson(json);

  factory SyncStatus.initial() => const SyncStatus();
}

/// Server status response
@freezed
class ServerStatus with _$ServerStatus {
  const factory ServerStatus({
    required String status,
    required DateTime timestamp,
    required String version,
    String? serverName,
    int? port,
  }) = _ServerStatus;

  factory ServerStatus.fromJson(Map<String, dynamic> json) =>
      _$ServerStatusFromJson(json);
}

/// Sync conflict
@freezed
class SyncConflict with _$SyncConflict {
  const factory SyncConflict({
    required int studentId,
    required String studentName,
    required DateTime date,
    required String teacherStatus,
    String? officeStatus,
    int? existingRecordId,
  }) = _SyncConflict;

  factory SyncConflict.fromJson(Map<String, dynamic> json) =>
      _$SyncConflictFromJson(json);
}

/// Full sync result
@freezed
class FullSyncResult with _$FullSyncResult {
  const factory FullSyncResult({
    required List<ClassSection> classes,
    required Map<ClassSection, List<Student>> studentsByClass,
    required Map<ClassSection, String> errors,
    required bool success,
    required String message,
  }) = _FullSyncResult;

  const FullSyncResult._();

  /// Get total number of students synced
  int get totalStudentsSynced => 
      studentsByClass.values.fold(0, (sum, list) => sum + list.length);

  /// Get number of classes with errors
  int get errorCount => errors.length;

  /// Check if all classes synced successfully
  bool get allSuccess => errors.isEmpty;
}

/// Data integrity mismatch
@freezed
class ClassIntegrityMismatch with _$ClassIntegrityMismatch {
  const factory ClassIntegrityMismatch({
    required ClassSection classSection,
    required int expected,
    required int actual,
  }) = _ClassIntegrityMismatch;

  const ClassIntegrityMismatch._();

  bool get isSevere => actual == 0 && expected > 0;
}

/// Data integrity report
@freezed
class DataIntegrityReport with _$DataIntegrityReport {
  const factory DataIntegrityReport({
    @Default([]) List<ClassIntegrityMismatch> mismatches,
    @Default([]) List<ClassSection> missingStudents,
    @Default(0) int totalClasses,
    DateTime? checkedAt,
    // FIXED: Added academic year tracking
    bool? academicYearMismatch,
    String? serverAcademicYear,
    String? localAcademicYear,
  }) = _DataIntegrityReport;

  const DataIntegrityReport._();

  bool get hasIssues => mismatches.isNotEmpty || missingStudents.isNotEmpty || (academicYearMismatch ?? false);
  bool get hasCriticalIssues => missingStudents.isNotEmpty || (academicYearMismatch ?? false);
  int get missingCount => missingStudents.length;
  int get mismatchCount => mismatches.length;

  List<ClassSection> get classesNeedingRefresh => [
    ...missingStudents,
    ...mismatches.map((m) => m.classSection),
  ];
  
  /// Check if cache should be cleared due to academic year change
  bool get shouldClearCache => academicYearMismatch ?? false;
}
