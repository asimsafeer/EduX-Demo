/// EduX School Management System
/// Sync payload models for request/response
library;

/// Attendance record from teacher app
class SyncAttendanceRecord {
  final int studentId;
  final int classId;
  final int sectionId;
  final DateTime date;
  final String status;
  final String? remarks;
  final DateTime markedAt;
  final String academicYear;

  SyncAttendanceRecord({
    required this.studentId,
    required this.classId,
    required this.sectionId,
    required this.date,
    required this.status,
    this.remarks,
    required this.markedAt,
    required this.academicYear,
  });

  factory SyncAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return SyncAttendanceRecord(
      studentId: json['studentId'] as int,
      classId: json['classId'] as int,
      sectionId: json['sectionId'] as int,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      markedAt: DateTime.parse(json['markedAt'] as String),
      academicYear: json['academicYear'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'date': date.toIso8601String(),
        'status': status,
        'remarks': remarks,
        'markedAt': markedAt.toIso8601String(),
        'academicYear': academicYear,
      };
}

/// Sync request from teacher app
class SyncRequest {
  final String deviceId;
  final int teacherId;
  final DateTime syncTimestamp;
  final List<SyncAttendanceRecord> attendanceRecords;
  final String? syncToken;

  SyncRequest({
    required this.deviceId,
    required this.teacherId,
    required this.syncTimestamp,
    required this.attendanceRecords,
    this.syncToken,
  });

  factory SyncRequest.fromJson(Map<String, dynamic> json) {
    return SyncRequest(
      deviceId: json['deviceId'] as String,
      teacherId: json['teacherId'] as int,
      syncTimestamp: DateTime.parse(json['syncTimestamp'] as String),
      attendanceRecords: (json['attendanceRecords'] as List)
          .map((e) => SyncAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      syncToken: json['syncToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'teacherId': teacherId,
        'syncTimestamp': syncTimestamp.toIso8601String(),
        'attendanceRecords': attendanceRecords.map((e) => e.toJson()).toList(),
        if (syncToken != null) 'syncToken': syncToken,
      };
}

/// Sync response to teacher app
class SyncResponse {
  final bool success;
  final int processed;
  final int created;
  final int updated;
  final int conflicts;
  final List<String> errors;
  final DateTime serverTimestamp;
  final String? syncToken;
  final String? errorMessage;

  SyncResponse({
    required this.success,
    required this.processed,
    required this.created,
    required this.updated,
    required this.conflicts,
    required this.errors,
    required this.serverTimestamp,
    this.syncToken,
    this.errorMessage,
  });

  factory SyncResponse.success({
    required int processed,
    required int created,
    required int updated,
    required int conflicts,
    List<String> errors = const [],
    String? syncToken,
  }) {
    return SyncResponse(
      success: true,
      processed: processed,
      created: created,
      updated: updated,
      conflicts: conflicts,
      errors: errors,
      serverTimestamp: DateTime.now(),
      syncToken: syncToken,
    );
  }

  factory SyncResponse.error(String message, {List<String>? errors}) {
    return SyncResponse(
      success: false,
      processed: 0,
      created: 0,
      updated: 0,
      conflicts: 0,
      errors: errors ?? [],
      serverTimestamp: DateTime.now(),
      errorMessage: message,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'processed': processed,
        'created': created,
        'updated': updated,
        'conflicts': conflicts,
        'errors': errors,
        'serverTimestamp': serverTimestamp.toIso8601String(),
        if (syncToken != null) 'syncToken': syncToken,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

/// Class info for teacher app
class TeacherClassInfo {
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;
  final int totalStudents;
  final bool isClassTeacher;
  final String? subjectName;

  TeacherClassInfo({
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
    required this.totalStudents,
    required this.isClassTeacher,
    this.subjectName,
  });

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'sectionId': sectionId,
        'className': className,
        'sectionName': sectionName,
        'totalStudents': totalStudents,
        'isClassTeacher': isClassTeacher,
        if (subjectName != null) 'subjectName': subjectName,
      };
}

/// Student info for teacher app
class TeacherStudentInfo {
  final int studentId;
  final String name;
  final String? rollNumber;
  final String? gender;
  final String? photoUrl;

  TeacherStudentInfo({
    required this.studentId,
    required this.name,
    this.rollNumber,
    this.gender,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'rollNumber': rollNumber,
        'gender': gender,
        'photoUrl': photoUrl,
      };
}

/// Server status response
class ServerStatusResponse {
  final String status;
  final DateTime timestamp;
  final String version;
  final String? serverName;
  final int? port;

  ServerStatusResponse({
    required this.status,
    required this.timestamp,
    required this.version,
    this.serverName,
    this.port,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        if (serverName != null) 'serverName': serverName,
        if (port != null) 'port': port,
      };
}

/// Conflict record for sync conflicts
class SyncConflict {
  final int studentId;
  final String studentName;
  final DateTime date;
  final String teacherStatus;
  final String? officeStatus;
  final int? existingRecordId;

  SyncConflict({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.teacherStatus,
    this.officeStatus,
    this.existingRecordId,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'date': date.toIso8601String(),
        'teacherStatus': teacherStatus,
        'officeStatus': officeStatus,
        'existingRecordId': existingRecordId,
      };
}

/// Full sync response with all teacher data
class FullSyncResponse {
  final List<TeacherClassInfo> classes;
  final Map<int, List<TeacherStudentInfo>> studentsByClassSection;
  final DateTime serverTimestamp;
  final String academicYear;

  FullSyncResponse({
    required this.classes,
    required this.studentsByClassSection,
    required this.serverTimestamp,
    required this.academicYear,
  });

  Map<String, dynamic> toJson() => {
        'classes': classes.map((c) => c.toJson()).toList(),
        'studentsByClassSection': studentsByClassSection.map(
          (key, value) => MapEntry(
            key.toString(),
            value.map((s) => s.toJson()).toList(),
          ),
        ),
        'serverTimestamp': serverTimestamp.toIso8601String(),
        'academicYear': academicYear,
      };
}


