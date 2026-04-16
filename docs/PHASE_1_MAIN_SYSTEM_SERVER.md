# Phase 1: Main System Server Implementation

## Overview
This phase implements the server-side infrastructure for the teacher mobile app sync system within the main EduX desktop application.

**Duration:** 2-3 weeks  
**Status:** 📋 Ready to start  
**Dependencies:** None (foundation phase)

---

## What We're Building

### Core Components

1. **Database Layer** (New tables)
   - `SyncDevices` - Track registered teacher devices
   - `SyncLogs` - Audit trail for all sync operations

2. **HTTP Server** (New module)
   - REST API for teacher authentication
   - Endpoints for class/student data
   - Attendance sync endpoint
   - Built with `shelf` package

3. **mDNS Service Discovery** (New module)
   - Broadcast server presence on local network
   - Teacher apps auto-discover the main system

4. **Device Management UI** (New screen)
   - View all connected teacher devices
   - Approve/revoke device access
   - View sync history per device

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN SYSTEM (Desktop)                     │
│                                                              │
│  ┌───────────────────┐      ┌─────────────────────────────┐ │
│  │  Database Layer   │      │     HTTP Server Layer       │ │
│  │                   │      │                             │ │
│  │  • Students       │      │  ┌─────────────────────┐    │ │
│  │  • Staff          │◄────►│  │  Server Routes      │    │ │
│  │  • Users          │      │  │  - POST /auth/login │    │ │
│  │  • Attendance     │      │  │  - GET /classes     │    │ │
│  │  • NEW:           │      │  │  - POST /sync       │    │ │
│  │    SyncDevices    │      │  └─────────────────────┘    │ │
│  │    SyncLogs       │      │           │                 │ │
│  └───────────────────┘      │           ▼                 │ │
│                             │  ┌─────────────────────┐    │ │
│                             │  │  mDNS Broadcaster   │    │ │
│                             │  │  (Service Discovery)│    │ │
│                             │  └─────────────────────┘    │ │
│                             └─────────────────────────────┘ │
│                                             │                │
│                                             ▼                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Device Management UI (Settings)             │  │
│  │  - View connected devices                             │  │
│  │  - Approve/revoke access                              │  │
│  │  - View sync logs                                     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Tasks

### Task 1.1: Add Dependencies

**File:** `pubspec.yaml`

Add these dependencies:
```yaml
dependencies:
  # ... existing dependencies ...
  
  # HTTP Server
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  
  # mDNS Service Discovery
  multicast_dns: ^0.3.2+7
  
  # Network utilities
  network_info_plus: ^4.0.2
```

**Checklist:**
- [ ] Add dependencies to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Verify packages download without errors

---

### Task 1.2: Create Database Tables

**New File:** `lib/database/tables/sync_tables.dart`

Create tables for:
1. `SyncDevices` - Registered teacher devices
2. `SyncLogs` - Sync operation audit log

**Table Schema:**

```dart
// SyncDevices Table
class SyncDevices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().unique()();        // UUID from mobile
  TextColumn get deviceName => text().nullable()();    // User-friendly name
  IntColumn get teacherId => integer().references(Staff, #id)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get registeredAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastIpAddress => text().nullable()();
  TextColumn get syncToken => text().nullable()();     // For incremental sync
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(device_id, teacher_id)',
  ];
}

// SyncLogs Table
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().references(SyncDevices, #deviceId)();
  IntColumn get teacherId => integer().references(Staff, #id)();
  TextColumn get syncType => text()();                  // 'upload', 'download', 'full'
  IntColumn get recordsCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();                    // 'success', 'partial', 'failed'
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

**Modified File:** `lib/database/tables/tables.dart`

Add export:
```dart
export 'sync_tables.dart';
```

**Modified File:** `lib/database/app_database.dart`

Add new tables to @DriftDatabase annotation:
```dart
@DriftDatabase(
  tables: [
    // ... existing tables ...
    SyncDevices,        // NEW
    SyncLogs,           // NEW
  ],
)
```

**Checklist:**
- [ ] Create `sync_tables.dart` with both tables
- [ ] Export from `tables.dart`
- [ ] Add to AppDatabase annotation
- [ ] Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Verify no compilation errors

---

### Task 1.3: Create Sync Models

**New File:** `lib/sync/models/sync_device_model.dart`

Data classes for sync operations:

```dart
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
}

/// Device registration request
class DeviceRegistrationRequest {
  final String deviceId;
  final String? deviceName;
  final String username;
  final String password;

  DeviceRegistrationRequest({
    required this.deviceId,
    this.deviceName,
    required this.username,
    required this.password,
  });

  factory DeviceRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationRequest(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

/// Login response for teacher app
class TeacherLoginResponse {
  final bool success;
  final String? token;
  final int? teacherId;
  final String? teacherName;
  final String? email;
  final String? error;
  final DateTime? tokenExpiry;

  TeacherLoginResponse({
    required this.success,
    this.token,
    this.teacherId,
    this.teacherName,
    this.email,
    this.error,
    this.tokenExpiry,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    if (token != null) 'token': token,
    if (teacherId != null) 'teacherId': teacherId,
    if (teacherName != null) 'teacherName': teacherName,
    if (email != null) 'email': email,
    if (error != null) 'error': error,
    if (tokenExpiry != null) 'tokenExpiry': tokenExpiry!.toIso8601String(),
  };
}
```

**New File:** `lib/sync/models/sync_payload.dart`

Sync request/response models:

```dart
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
}

/// Sync request from teacher app
class SyncRequest {
  final String deviceId;
  final int teacherId;
  final DateTime syncTimestamp;
  final List<SyncAttendanceRecord> attendanceRecords;

  SyncRequest({
    required this.deviceId,
    required this.teacherId,
    required this.syncTimestamp,
    required this.attendanceRecords,
  });

  factory SyncRequest.fromJson(Map<String, dynamic> json) {
    return SyncRequest(
      deviceId: json['deviceId'] as String,
      teacherId: json['teacherId'] as int,
      syncTimestamp: DateTime.parse(json['syncTimestamp'] as String),
      attendanceRecords: (json['attendanceRecords'] as List)
          .map((e) => SyncAttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

  SyncResponse({
    required this.success,
    required this.processed,
    required this.created,
    required this.updated,
    required this.conflicts,
    required this.errors,
    required this.serverTimestamp,
    this.syncToken,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'processed': processed,
    'created': created,
    'updated': updated,
    'conflicts': conflicts,
    'errors': errors,
    'serverTimestamp': serverTimestamp.toIso8601String(),
    if (syncToken != null) 'syncToken': syncToken,
  };
}
```

**New File:** `lib/sync/models/models.dart`

```dart
export 'sync_device_model.dart';
export 'sync_payload.dart';
```

**Checklist:**
- [ ] Create `sync_device_model.dart`
- [ ] Create `sync_payload.dart`
- [ ] Create models barrel file
- [ ] All models have fromJson/toJson methods

---

### Task 1.4: Create Sync Device Service

**New File:** `lib/sync/services/sync_device_service.dart`

Service for managing registered devices:

```dart
/// Service for managing sync devices
class SyncDeviceService {
  final AppDatabase _db;
  final AuthService _authService;

  SyncDeviceService(this._db, this._authService);

  /// Register a new device
  Future<SyncDevice?> registerDevice({
    required String deviceId,
    required String? deviceName,
    required int teacherId,
    required String ipAddress,
  }) async {
    final now = DateTime.now();
    
    final companion = SyncDevicesCompanion(
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      teacherId: Value(teacherId),
      lastIpAddress: Value(ipAddress),
      registeredAt: Value(now),
      lastSyncAt: Value(now),
      isActive: const Value(true),
    );

    try {
      final id = await _db.into(_db.syncDevices).insert(
        companion,
        onConflict: DoUpdate(
          (old) => companion.copyWith(
            lastSyncAt: Value(now),
            lastIpAddress: Value(ipAddress),
            isActive: const Value(true),
          ),
          target: [_db.syncDevices.deviceId],
        ),
      );

      return await getDeviceById(id);
    } catch (e) {
      return null;
    }
  }

  /// Get device by database ID
  Future<SyncDevice?> getDeviceById(int id) async {
    return await (_db.select(_db.syncDevices)
          ..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get device by device UUID
  Future<SyncDevice?> getDeviceByDeviceId(String deviceId) async {
    return await (_db.select(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  /// Get all registered devices with teacher info
  Future<List<SyncDeviceModel>> getAllDevices() async {
    final query = await _db.customSelect('''
      SELECT 
        d.*,
        s.first_name || ' ' || s.last_name as teacher_name
      FROM sync_devices d
      INNER JOIN staff s ON s.id = d.teacher_id
      ORDER BY d.registered_at DESC
    ''').get();

    return query.map((row) => SyncDeviceModel.fromRow(
      row,
      row.read<String>('teacher_name'),
    )).toList();
  }

  /// Get devices for a specific teacher
  Future<List<SyncDevice>> getDevicesForTeacher(int teacherId) async {
    return await (_db.select(_db.syncDevices)
          ..where((d) => d.teacherId.equals(teacherId)))
        .get();
  }

  /// Revoke device access
  Future<bool> revokeDevice(int deviceId) async {
    final result = await (_db.update(_db.syncDevices)
          ..where((d) => d.id.equals(deviceId)))
        .write(const SyncDevicesCompanion(
          isActive: Value(false),
        ));
    return result > 0;
  }

  /// Re-enable device access
  Future<bool> enableDevice(int deviceId) async {
    final result = await (_db.update(_db.syncDevices)
          ..where((d) => d.id.equals(deviceId)))
        .write(const SyncDevicesCompanion(
          isActive: Value(true),
        ));
    return result > 0;
  }

  /// Delete a device registration
  Future<bool> deleteDevice(int deviceId) async {
    final result = await (_db.delete(_db.syncDevices)
          ..where((d) => d.id.equals(deviceId)))
        .go();
    return result > 0;
  }

  /// Update last sync time
  Future<void> updateLastSync(String deviceId, String ipAddress) async {
    await (_db.update(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(
          lastSyncAt: Value(DateTime.now()),
          lastIpAddress: Value(ipAddress),
        ));
  }

  /// Check if device is registered and active
  Future<bool> isDeviceAuthorized(String deviceId, int teacherId) async {
    final device = await (_db.select(_db.syncDevices)
          ..where((d) => 
            d.deviceId.equals(deviceId) & 
            d.teacherId.equals(teacherId) &
            d.isActive.equals(true)))
        .getSingleOrNull();
    return device != null;
  }
}
```

**Checklist:**
- [ ] Create sync device service
- [ ] All CRUD operations implemented
- [ ] Device authorization logic

---

### Task 1.5: Create Sync Processor

**New File:** `lib/sync/services/sync_processor.dart`

Processes incoming sync data from teacher apps:

```dart
/// Processes attendance sync data from teacher apps
class SyncProcessor {
  final AppDatabase _db;
  final AttendanceService _attendanceService;

  SyncProcessor(this._db, this._attendanceService);

  /// Process a sync request from teacher app
  Future<SyncResponse> processSync(SyncRequest request, String ipAddress) async {
    final serverTimestamp = DateTime.now();
    final errors = <String>[];
    int created = 0;
    int updated = 0;
    int conflicts = 0;

    // Update device last sync time
    await _updateDeviceLastSync(request.deviceId, ipAddress);

    // Process each attendance record
    for (final record in request.attendanceRecords) {
      try {
        final result = await _processAttendanceRecord(record, request.teacherId);
        if (result == 'created') created++;
        if (result == 'updated') updated++;
        if (result == 'conflict') conflicts++;
      } catch (e) {
        errors.add('Student ${record.studentId}: ${e.toString()}');
      }
    }

    // Log the sync operation
    await _logSyncOperation(request, created + updated, errors.isEmpty ? 'success' : 'partial', 
        errors.isNotEmpty ? errors.join('; ') : null);

    return SyncResponse(
      success: errors.isEmpty,
      processed: request.attendanceRecords.length,
      created: created,
      updated: updated,
      conflicts: conflicts,
      errors: errors,
      serverTimestamp: serverTimestamp,
    );
  }

  /// Process a single attendance record
  /// Returns: 'created', 'updated', 'conflict', or throws
  Future<String> _processAttendanceRecord(SyncAttendanceRecord record, int teacherId) async {
    // Check if attendance is locked for this date/class/section
    final isLocked = await _isAttendanceLocked(record.classId, record.sectionId, record.date);
    if (isLocked) {
      throw Exception('Attendance is locked for this date');
    }

    // Check for existing record
    final existing = await _getExistingAttendance(record.studentId, record.date);

    if (existing == null) {
      // Create new record
      await _attendanceService.markAttendance(
        studentId: record.studentId,
        classId: record.classId,
        sectionId: record.sectionId,
        date: record.date,
        status: record.status,
        academicYear: record.academicYear,
        markedBy: teacherId,
        remarks: record.remarks,
      );
      return 'created';
    } else {
      // Check for conflict (different status)
      if (existing.status != record.status) {
        // Conflict detected - we'll update but mark as conflict
        // In Phase 4, this will be enhanced with proper conflict resolution
        await _attendanceService.updateAttendance(
          attendanceId: existing.id,
          status: record.status,
          updatedBy: teacherId,
          remarks: record.remarks,
        );
        return 'conflict';
      } else {
        // Same status, just update remarks if changed
        if (existing.remarks != record.remarks) {
          await _attendanceService.updateAttendance(
            attendanceId: existing.id,
            status: record.status,
            updatedBy: teacherId,
            remarks: record.remarks,
          );
        }
        return 'updated';
      }
    }
  }

  /// Check if attendance is locked
  Future<bool> _isAttendanceLocked(int classId, int sectionId, DateTime date) async {
    final status = await (_db.select(_db.dailyAttendanceStatus)
          ..where((s) => 
            s.classId.equals(classId) & 
            s.sectionId.equals(sectionId) &
            s.date.equals(date)))
        .getSingleOrNull();
    return status?.isLocked ?? false;
  }

  /// Get existing attendance record
  Future<StudentAttendanceData?> _getExistingAttendance(int studentId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return await (_db.select(_db.studentAttendance)
          ..where((a) => 
            a.studentId.equals(studentId) & 
            a.date.equals(dateOnly)))
        .getSingleOrNull();
  }

  /// Update device last sync
  Future<void> _updateDeviceLastSync(String deviceId, String ipAddress) async {
    await (_db.update(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(
          lastSyncAt: Value(DateTime.now()),
          lastIpAddress: Value(ipAddress),
        ));
  }

  /// Log sync operation
  Future<void> _logSyncOperation(SyncRequest request, int recordsCount, String status, String? error) async {
    await _db.into(_db.syncLogs).insert(SyncLogsCompanion(
      deviceId: Value(request.deviceId),
      teacherId: Value(request.teacherId),
      syncType: const Value('upload'),
      recordsCount: Value(recordsCount),
      status: Value(status),
      errorMessage: Value(error),
    ));
  }
}
```

**Checklist:**
- [ ] Create sync processor
- [ ] Attendance creation logic
- [ ] Conflict detection (basic)
- [ ] Lock checking
- [ ] Sync logging

---

### Task 1.6: Create HTTP Server with Shelf

**New File:** `lib/sync/server/sync_server.dart`

Main HTTP server implementation:

```dart
/// Main sync server for teacher app communication
class SyncServer {
  static const int defaultPort = 8181;
  
  final AppDatabase _db;
  final AuthService _authService;
  final SyncDeviceService _deviceService;
  final SyncProcessor _syncProcessor;
  
  HttpServer? _server;
  bool get isRunning => _server != null;
  int get port => _server?.port ?? defaultPort;
  
  SyncServer(this._db, this._authService, this._deviceService, this._syncProcessor);

  /// Start the server
  Future<void> start({int port = defaultPort}) async {
    if (_server != null) {
      throw StateError('Server is already running');
    }

    final router = _buildRouter();
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(router);

    _server = await io.serve(handler, '0.0.0.0', port);
    print('Sync server running on port ${port}');
  }

  /// Stop the server
  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  /// Build route handlers
  Router _buildRouter() {
    final router = Router();

    // Health check
    router.get('/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}));
    });

    // Auth endpoints
    router.post('/api/v1/auth/login', _handleLogin);
    
    // Protected endpoints (require auth)
    router.get('/api/v1/teacher/classes', _handleGetClasses);
    router.get('/api/v1/class/<classId>/<sectionId>/students', _handleGetStudents);
    router.post('/api/v1/sync/attendance', _handleSyncAttendance);
    router.get('/api/v1/sync/status', _handleSyncStatus);

    return router;
  }

  /// Handle teacher login
  Future<Response> _handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body);
      final loginRequest = DeviceRegistrationRequest.fromJson(json);

      // Authenticate user
      final user = await _authService.login(loginRequest.username, loginRequest.password);
      if (user == null) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'error': 'Invalid credentials',
        }));
      }

      // Check if user is linked to a staff record
      final staff = await (_db.select(_db.staff)
            ..where((s) => s.userId.equals(user.id)))
          .getSingleOrNull();

      if (staff == null) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'error': 'User is not a teacher',
        }));
      }

      // Get client IP
      final ipAddress = request.context['shelf.io.connection_info']?.remoteAddress?.address ?? 'unknown';

      // Register/update device
      await _deviceService.registerDevice(
        deviceId: loginRequest.deviceId,
        deviceName: loginRequest.deviceName,
        teacherId: staff.id,
        ipAddress: ipAddress,
      );

      // Generate simple token (in production, use JWT)
      final token = _generateToken(user.id);
      final expiry = DateTime.now().add(const Duration(hours: 4));

      return Response.ok(jsonEncode(TeacherLoginResponse(
        success: true,
        token: token,
        teacherId: staff.id,
        teacherName: '${staff.firstName} ${staff.lastName}',
        email: user.email,
        tokenExpiry: expiry,
      ).toJson()));

    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'error': e.toString(),
      }));
    }
  }

  /// Handle get classes for teacher
  Future<Response> _handleGetClasses(Request request) async {
    try {
      final teacherId = int.parse(request.context['teacherId'] as String);
      final academicYear = await _db.getCurrentAcademicYear();
      
      if (academicYear == null) {
        return Response.internalServerError(body: jsonEncode({
          'error': 'No active academic year',
        }));
      }

      // Get classes where teacher is assigned
      final assignments = await (_db.select(_db.staffSubjectAssignments)
            ..where((a) => 
              a.staffId.equals(teacherId) &
              a.academicYear.equals(academicYear.name)))
          .get();

      final classIds = assignments.map((a) => a.classId).toSet();
      final classes = <Map<String, dynamic>>[];

      for (final classId in classIds) {
        final classData = await (_db.select(_db.classes)
              ..where((c) => c.id.equals(classId)))
            .getSingleOrNull();
        
        if (classData != null) {
          // Get sections for this class
          final sections = assignments
              .where((a) => a.classId == classId)
              .map((a) => a.sectionId)
              .toSet();

          for (final sectionId in sections) {
            final section = await (_db.select(_db.sections)
                  ..where((s) => s.id.equals(sectionId!)))
                .getSingleOrNull();

            // Count students
            final studentCount = await _getStudentCount(classId, sectionId!, academicYear.name);

            classes.add({
              'classId': classId,
              'sectionId': sectionId,
              'className': classData.name,
              'sectionName': section?.name ?? 'N/A',
              'totalStudents': studentCount,
              'isClassTeacher': assignments.any((a) => 
                  a.classId == classId && 
                  a.sectionId == sectionId && 
                  a.isClassTeacher),
            });
          }
        }
      }

      return Response.ok(jsonEncode({'classes': classes}));

    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'error': e.toString(),
      }));
    }
  }

  /// Handle get students for class/section
  Future<Response> _handleGetStudents(Request request, String classId, String sectionId) async {
    try {
      final cId = int.parse(classId);
      final sId = int.parse(sectionId);
      final academicYear = await _db.getCurrentAcademicYear();
      
      if (academicYear == null) {
        return Response.internalServerError(body: jsonEncode({
          'error': 'No active academic year',
        }));
      }

      final query = _db.select(_db.students).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.students.id),
        ),
      ])
        ..where(
          _db.enrollments.classId.equals(cId) &
          _db.enrollments.sectionId.equals(sId) &
          _db.enrollments.academicYear.equals(academicYear.name) &
          _db.enrollments.isCurrent.equals(true) &
          _db.students.status.equals('active'),
        )
        ..orderBy([OrderingTerm.asc(_db.enrollments.rollNumber)]);

      final results = await query.get();

      final students = results.map((row) {
        final student = row.readTable(_db.students);
        final enrollment = row.readTable(_db.enrollments);
        return {
          'studentId': student.id,
          'name': student.studentName,
          'rollNumber': enrollment.rollNumber,
          'gender': student.gender,
        };
      }).toList();

      return Response.ok(jsonEncode({
        'students': students,
        'lastUpdated': DateTime.now().toIso8601String(),
      }));

    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'error': e.toString(),
      }));
    }
  }

  /// Handle attendance sync
  Future<Response> _handleSyncAttendance(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body);
      final syncRequest = SyncRequest.fromJson(json);

      final ipAddress = request.context['shelf.io.connection_info']?.remoteAddress?.address ?? 'unknown';

      final response = await _syncProcessor.processSync(syncRequest, ipAddress);

      return Response.ok(jsonEncode(response.toJson()));

    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'error': e.toString(),
      }));
    }
  }

  /// Handle sync status check
  Future<Response> _handleSyncStatus(Request request) async {
    // Return server status and timestamp
    return Response.ok(jsonEncode({
      'status': 'active',
      'timestamp': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
    }));
  }

  /// CORS middleware
  Middleware _corsMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {...response.headers, ..._corsHeaders});
      },
    );
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };

  /// Auth middleware (simple token validation)
  Middleware _authMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        // Public endpoints
        if (request.url.path == '/health' || 
            request.url.path == '/api/v1/auth/login') {
          return null;
        }

        // Validate token
        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.unauthorized(jsonEncode({
            'error': 'Missing or invalid authorization header',
          }));
        }

        final token = authHeader.substring(7);
        final teacherId = _validateToken(token);
        
        if (teacherId == null) {
          return Response.unauthorized(jsonEncode({
            'error': 'Invalid or expired token',
          }));
        }

        // Add teacherId to request context
        return null; // Continue to handler
      },
    );
  }

  /// Generate simple token (replace with JWT in production)
  String _generateToken(int userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId:$timestamp:${_generateRandomString(16)}';
    // In production, use proper JWT
    return base64Encode(utf8.encode(data));
  }

  /// Validate token
  int? _validateToken(String token) {
    try {
      final decoded = utf8.decode(base64Decode(token));
      final parts = decoded.split(':');
      if (parts.length < 2) return null;
      return int.tryParse(parts[0]);
    } catch (e) {
      return null;
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<int> _getStudentCount(int classId, int sectionId, String academicYear) async {
    final query = _db.selectOnly(_db.enrollments)
      ..addColumns([_db.enrollments.id.count()])
      ..where(
        _db.enrollments.classId.equals(classId) &
        _db.enrollments.sectionId.equals(sectionId) &
        _db.enrollments.academicYear.equals(academicYear) &
        _db.enrollments.isCurrent.equals(true),
      );
    
    final result = await query.getSingle();
    return result.read(_db.enrollments.id.count()) ?? 0;
  }
}
```

**Checklist:**
- [ ] Create sync server with all endpoints
- [ ] Implement login handler
- [ ] Implement classes endpoint
- [ ] Implement students endpoint
- [ ] Implement sync endpoint
- [ ] Add CORS middleware
- [ ] Add auth middleware

---

### Task 1.7: Create mDNS Broadcaster

**New File:** `lib/sync/server/mdns_broadcaster.dart`

```dart
/// mDNS service broadcaster for teacher app discovery
class MdnsBroadcaster {
  static const String serviceName = '_edux-sync._tcp';
  
  MDnsServer? _server;
  bool get isRunning => _server != null;

  /// Start broadcasting service
  Future<void> start({int port = SyncServer.defaultPort}) async {
    if (_server != null) {
      throw StateError('mDNS broadcaster already running');
    }

    _server = await MDnsServer.bind();

    // Create service pointer
    final pointer = PtrResourceRecord(
      name: serviceName,
      domainName: FullyQualifiedName('EduX Main System.$serviceName'),
      ttl: 300,
    );

    // Create service record
    final service = SrvResourceRecord(
      name: FullyQualifiedName('EduX Main System.$serviceName'),
      target: FullyQualifiedName(Platform.localHostname),
      port: port,
      ttl: 300,
    );

    // Create text record with metadata
    final text = TxtResourceRecord(
      name: FullyQualifiedName('EduX Main System.$serviceName'),
      text: [
        'version=${AppConstants.appVersion}',
        'port=$port',
      ],
      ttl: 300,
    );

    await _server!.update(pointer);
    await _server!.update(service);
    await _server!.update(text);

    print('mDNS broadcaster started for service: $serviceName');
  }

  /// Stop broadcasting
  Future<void> stop() async {
    await _server?.stop();
    _server = null;
  }
}
```

**Checklist:**
- [ ] Create mDNS broadcaster
- [ ] Configure service name and TXT records

---

### Task 1.8: Create Sync Management UI

**New File:** `lib/sync/ui/sync_management_screen.dart`

Full screen for managing connected devices (similar to existing settings screens).

**Key Features:**
- List all registered devices
- Show server status (running/stopped)
- Start/stop server button
- Revoke device access
- View device details

**New File:** `lib/sync/ui/device_list_tile.dart`

List tile widget for device display.

**New File:** `lib/sync/ui/sync_logs_screen.dart`

Screen to view sync history.

**Modified File:** `lib/features/settings/screens/settings_screen.dart`

Add menu item for "Connected Devices".

**Checklist:**
- [ ] Create sync management screen
- [ ] Create device list tile widget
- [ ] Create sync logs screen
- [ ] Add to settings menu
- [ ] Server start/stop controls

---

### Task 1.9: Create Sync Services Barrel

**New File:** `lib/sync/services/services.dart`

```dart
export 'sync_device_service.dart';
export 'sync_processor.dart';
```

**New File:** `lib/sync/sync.dart`

Main barrel file for sync module:

```dart
export 'models/models.dart';
export 'services/services.dart';
export 'server/sync_server.dart';
export 'server/mdns_broadcaster.dart';
```

---

## Phase 1 Testing Checklist

### Unit Tests
- [ ] SyncDeviceService CRUD operations
- [ ] SyncProcessor attendance processing
- [ ] Token generation/validation
- [ ] Sync response generation

### Integration Tests
- [ ] Server starts and stops correctly
- [ ] mDNS broadcasts service
- [ ] Login endpoint authenticates users
- [ ] Classes endpoint returns correct data
- [ ] Sync endpoint processes attendance

### Manual Tests
- [ ] Start server from UI
- [ ] View empty device list
- [ ] Test login with invalid credentials
- [ ] Test login with valid teacher credentials
- [ ] Verify device appears in list after login
- [ ] Stop server from UI
- [ ] View sync logs

---

## Phase 1 Completion Criteria

- [ ] All database migrations run successfully
- [ ] Server starts and stops without errors
- [ ] mDNS broadcasting works (test with discovery tool)
- [ ] Login endpoint authenticates and returns token
- [ ] Classes endpoint returns teacher's assigned classes
- [ ] Students endpoint returns class roster
- [ ] Sync endpoint processes attendance records
- [ ] Device management UI shows registered devices
- [ ] Server status visible in UI
- [ ] All error cases handled gracefully

---

## Phase 1 Deliverables

1. **Database Layer**
   - `sync_tables.dart` with SyncDevices and SyncLogs tables
   - Migrations in `app_database.dart`

2. **Models**
   - `sync_device_model.dart`
   - `sync_payload.dart`

3. **Services**
   - `sync_device_service.dart`
   - `sync_processor.dart`

4. **Server**
   - `sync_server.dart`
   - `mdns_broadcaster.dart`

5. **UI**
   - `sync_management_screen.dart`
   - `device_list_tile.dart`
   - `sync_logs_screen.dart`

6. **Integration**
   - Updated `settings_screen.dart`
   - Updated `pubspec.yaml`
   - Barrel files

---

**Next Phase:** After Phase 1 complete, move to Phase 2 (Teacher Mobile App)
