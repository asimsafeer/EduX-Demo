# Phase 2: Teacher Mobile App - Core Structure

## Overview
This phase creates the Flutter mobile app that teachers will use to mark attendance on their Android devices.

**Duration:** 3-4 weeks  
**Status:** 📋 Waiting for Phase 1 completion  
**Dependencies:** Phase 1 (Main System Server) must be complete

---

## What We're Building

A new Flutter project separate from the main EduX desktop app:

```
edux_teacher_app/                    # New Flutter project (Android-focused)
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                        # Constants, theme, utilities
│   ├── database/                    # Local SQLite (Drift)
│   ├── models/                      # Data classes
│   ├── providers/                   # Riverpod state management
│   ├── services/                    # Business logic
│   └── screens/                     # UI screens
├── android/
├── pubspec.yaml
└── README.md
```

### Key Features
1. **Auto-discovery** - Find main system on local network via mDNS
2. **Offline-first** - Works without internet after initial login
3. **Quick attendance** - Optimized for fast mobile marking
4. **End-of-day sync** - Upload all marked attendance at once

---

## Implementation Tasks

### Task 2.1: Create New Flutter Project

**Command:**
```bash
flutter create --org com.edux --project-name teacher_app edux_teacher_app
cd edux_teacher_app
```

**Checklist:**
- [ ] Create new Flutter project
- [ ] Verify `flutter run` works on Android emulator
- [ ] Configure app name: "EduX Teacher"
- [ ] Configure package name: `com.edux.teacher`

---

### Task 2.2: Configure pubspec.yaml

**File:** `edux_teacher_app/pubspec.yaml`

```yaml
name: edux_teacher_app
description: Teacher Attendance App for EduX School Management System

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Database (Drift/SQLite)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  path: ^1.9.0

  # Network
  dio: ^5.4.0
  multicast_dns: ^0.3.2+7
  connectivity_plus: ^5.0.2
  network_info_plus: ^4.0.2

  # UI
  google_fonts: ^6.2.1
  lucide_icons: ^0.257.0
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  flutter_slidable: ^3.0.1

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  crypto: ^3.0.3
  json_annotation: ^4.9.0

  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.2.0

  # Images
  cached_network_image: ^3.3.1

  # Code Generation
  freezed_annotation: ^2.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # Code Generation
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  json_serializable: ^6.8.0
  freezed: ^2.5.2

flutter:
  uses-material-design: true
  
  assets:
    - assets/logo.png
    - assets/placeholder_avatar.png
```

**Checklist:**
- [ ] Create pubspec.yaml with all dependencies
- [ ] Run `flutter pub get`
- [ ] Verify no dependency conflicts

---

### Task 2.3: Create Core Structure

**New File:** `edux_teacher_app/lib/core/constants/app_constants.dart`

```dart
/// App-wide constants for Teacher App
class AppConstants {
  AppConstants._();

  static const String appName = 'EduX Teacher';
  static const String appVersion = '1.0.0';

  // Sync server
  static const int syncServerPort = 8181;
  static const String mdnsServiceName = '_edux-sync._tcp';
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Database
  static const String dbFileName = 'teacher_cache.db';
  static const int dbVersion = 1;

  // Sync
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 2);
  static const Duration tokenRefreshThreshold = Duration(minutes: 30);

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // Cache
  static const Duration cacheValidity = Duration(hours: 24);
}

/// Attendance status values (must match main system)
class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'present';
  static const String absent = 'absent';
  static const String late = 'late';
  static const String leave = 'leave';

  static const List<String> all = [present, absent, late, leave];

  static String getDisplayName(String status) {
    switch (status) {
      case present:
        return 'Present';
      case absent:
        return 'Absent';
      case late:
        return 'Late';
      case leave:
        return 'Leave';
      default:
        return status;
    }
  }

  static String getShortCode(String status) {
    switch (status) {
      case present:
        return 'P';
      case absent:
        return 'A';
      case late:
        return 'L';
      case leave:
        return 'LV';
      default:
        return status[0].toUpperCase();
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case present:
        return Colors.green;
      case absent:
        return Colors.red;
      case late:
        return Colors.orange;
      case leave:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
```

**New File:** `edux_teacher_app/lib/core/theme/app_theme.dart`

```dart
/// App theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFEF7FF),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
```

**New File:** `edux_teacher_app/lib/core/core.dart`

```dart
export 'constants/app_constants.dart';
export 'theme/app_theme.dart';
```

---

### Task 2.4: Create Database Layer

**New File:** `edux_teacher_app/lib/database/tables/cached_classes.dart`

```dart
import 'package:drift/drift.dart';

/// Cached class/section assignments for teacher
@DataClassName('CachedClass')
class CachedClasses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  TextColumn get className => text()();
  TextColumn get sectionName => text()();
  IntColumn get totalStudents => integer().withDefault(const Constant(0))();
  BoolColumn get isClassTeacher => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(class_id, section_id)',
  ];
}
```

**New File:** `edux_teacher_app/lib/database/tables/cached_students.dart`

```dart
import 'package:drift/drift.dart';

/// Cached student roster for classes
@DataClassName('CachedStudent')
class CachedStudents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  TextColumn get name => text()();
  TextColumn get rollNumber => text().nullable()();
  TextColumn get gender => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(student_id, class_id, section_id)',
  ];
}
```

**New File:** `edux_teacher_app/lib/database/tables/pending_attendance.dart`

```dart
import 'package:drift/drift.dart';

/// Attendance marked offline, pending sync
@DataClassName('PendingAttendance')
class PendingAttendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get markedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get syncError => text().nullable()();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(student_id, date)',
  ];
}
```

**New File:** `edux_teacher_app/lib/database/tables/sync_config.dart`

```dart
import 'package:drift/drift.dart';

/// App configuration and sync state
@DataClassName('SyncConfigEntry')
class SyncConfig extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {key};
}

/// Predefined config keys
class ConfigKeys {
  ConfigKeys._();
  
  static const String deviceId = 'device_id';
  static const String serverIp = 'server_ip';
  static const String serverPort = 'server_port';
  static const String authToken = 'auth_token';
  static const String teacherId = 'teacher_id';
  static const String teacherName = 'teacher_name';
  static const String teacherEmail = 'teacher_email';
  static const String lastSync = 'last_sync';
  static const String cacheVersion = 'cache_version';
}
```

**New File:** `edux_teacher_app/lib/database/app_database.dart`

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/cached_classes.dart';
import 'tables/cached_students.dart';
import 'tables/pending_attendance.dart';
import 'tables/sync_config.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CachedClasses,
    CachedStudents,
    PendingAttendances,
    SyncConfig,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'teacher_cache.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // Config helpers
  Future<String?> getConfig(String key) async {
    final entry = await (select(syncConfig)..where((c) => c.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  Future<void> setConfig(String key, String? value) async {
    await into(syncConfig).insert(
      SyncConfigEntry(key: key, value: value),
      onConflict: DoUpdate((old) => SyncConfigEntry(key: key, value: value)),
    );
  }

  // Class cache helpers
  Future<List<CachedClass>> getCachedClasses() async {
    return await select(cachedClasses).get();
  }

  Future<void> cacheClasses(List<CachedClassesCompanion> classes) async {
    await batch((batch) {
      batch.deleteAll(cachedClasses);
      for (final cls in classes) {
        batch.insert(cachedClasses, cls);
      }
    });
  }

  // Student cache helpers
  Future<List<CachedStudent>> getCachedStudents(int classId, int sectionId) async {
    return await (select(cachedStudents)
          ..where((s) => s.classId.equals(classId) & s.sectionId.equals(sectionId)))
        .get();
  }

  Future<void> cacheStudents(List<CachedStudentsCompanion> students) async {
    await batch((batch) {
      for (final student in students) {
        batch.insert(
          cachedStudents,
          student,
          onConflict: DoUpdate((old) => student),
        );
      }
    });
  }

  // Attendance helpers
  Future<List<PendingAttendance>> getPendingAttendance() async {
    return await (select(pendingAttendances)
          ..where((a) => a.isSynced.equals(false)))
        .get();
  }

  Future<List<PendingAttendance>> getAttendanceForClass(int classId, int sectionId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await (select(pendingAttendances)
          ..where((a) => 
            a.classId.equals(classId) & 
            a.sectionId.equals(sectionId) &
            a.date.isBiggerOrEqualValue(startOfDay) &
            a.date.isSmallerThanValue(endOfDay)))
        .get();
  }

  Future<void> saveAttendance(PendingAttendancesCompanion attendance) async {
    await into(pendingAttendances).insert(
      attendance,
      onConflict: DoUpdate((old) => attendance),
    );
  }

  Future<void> markAttendanceSynced(int id) async {
    await (update(pendingAttendances)..where((a) => a.id.equals(id)))
        .write(const PendingAttendancesCompanion(isSynced: Value(true)));
  }

  Future<void> updateSyncError(int id, String error) async {
    await (update(pendingAttendances)..where((a) => a.id.equals(id)))
        .write(PendingAttendancesCompanion(
          syncError: Value(error),
          syncAttempts: const Value(1),
        ));
  }

  Future<int> getPendingCount() async {
    final query = selectOnly(pendingAttendances)
      ..addColumns([pendingAttendances.id.count()])
      ..where(pendingAttendances.isSynced.equals(false));
    
    final result = await query.getSingle();
    return result.read(pendingAttendances.id.count()) ?? 0;
  }

  Future<void> clearAllData() async {
    await batch((batch) {
      batch.deleteAll(cachedClasses);
      batch.deleteAll(cachedStudents);
      batch.deleteAll(pendingAttendances);
      batch.deleteAll(syncConfig);
    });
  }
}
```

**Checklist:**
- [ ] Create all table definitions
- [ ] Create AppDatabase with helpers
- [ ] Run code generation
- [ ] Verify no compilation errors

---

### Task 2.5: Create Models

**New File:** `edux_teacher_app/lib/models/teacher.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher.freezed.dart';
part 'teacher.g.dart';

@freezed
class Teacher with _$Teacher {
  const factory Teacher({
    required int id,
    required String name,
    required String email,
    String? photoUrl,
    String? token,
    DateTime? tokenExpiry,
  }) = _Teacher;

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
}
```

**New File:** `edux_teacher_app/lib/models/class_section.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_section.freezed.dart';
part 'class_section.g.dart';

@freezed
class ClassSection with _$ClassSection {
  const factory ClassSection({
    required int classId,
    required int sectionId,
    required String className,
    required String sectionName,
    required int totalStudents,
    required bool isClassTeacher,
  }) = _ClassSection;

  factory ClassSection.fromJson(Map<String, dynamic> json) => _$ClassSectionFromJson(json);
  
  String get displayName => '$className - $sectionName';
}
```

**New File:** `edux_teacher_app/lib/models/student.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

@freezed
class Student with _$Student {
  const factory Student({
    required int studentId,
    required String name,
    String? rollNumber,
    String? gender,
    String? photoUrl,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
}
```

**New File:** `edux_teacher_app/lib/models/attendance_record.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_record.freezed.dart';

@freezed
class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required int studentId,
    required int classId,
    required int sectionId,
    required DateTime date,
    required String status,
    String? remarks,
    DateTime? markedAt,
    @Default(false) bool isSynced,
  }) = _AttendanceRecord;
}
```

**New File:** `edux_teacher_app/lib/models/sync_status.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status.freezed.dart';

@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required bool isOnline,
    required bool isSyncing,
    required int pendingCount,
    String? serverAddress,
    DateTime? lastSyncTime,
    String? error,
  }) = _SyncStatus;
  
  factory SyncStatus.initial() => const SyncStatus(
    isOnline: false,
    isSyncing: false,
    pendingCount: 0,
  );
}
```

**Checklist:**
- [ ] Create all model files
- [ ] Run code generation for freezed
- [ ] Verify all models compile

---

### Task 2.6: Create Services

**New File:** `edux_teacher_app/lib/services/discovery_service.dart`

```dart
/// Discovers EduX servers on local network via mDNS
class DiscoveryService {
  static const String _serviceName = '_edux-sync._tcp';
  
  /// Search for EduX servers on the network
  /// Returns list of discovered servers with IP and port
  Future<List<DiscoveredServer>> discoverServers({Duration timeout = const Duration(seconds: 5)}) async {
    final servers = <DiscoveredServer>[];
    final client = MDnsClient();
    
    try {
      await client.start();
      
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceName),
      ).timeout(timeout, onTimeout: (sink) => sink.close())) {
        
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName.name),
        )) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            servers.add(DiscoveredServer(
              name: ptr.domainName.name,
              ipAddress: ip.address.address,
              port: srv.port,
            ));
          }
        }
      }
    } finally {
      client.stop();
    }
    
    return servers;
  }
  
  /// Test if a server is reachable
  Future<bool> testConnection(String ip, int port) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://$ip:$port',
        connectTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class DiscoveredServer {
  final String name;
  final String ipAddress;
  final int port;
  
  const DiscoveredServer({
    required this.name,
    required this.ipAddress,
    required this.port,
  });
  
  String get displayUrl => 'http://$ipAddress:$port';
}
```

**New File:** `edux_teacher_app/lib/services/sync_service.dart`

```dart
/// Handles communication with main EduX server
class SyncService {
  final AppDatabase _db;
  Dio? _dio;
  
  SyncService(this._db);
  
  /// Initialize with server address
  Future<void> initialize(String serverIp, int port) async {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://$serverIp:$port',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add auth interceptor
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _db.getConfig(ConfigKeys.authToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
  
  /// Login to server
  Future<Teacher?> login(String username, String password, String deviceId, String deviceName) async {
    if (_dio == null) throw StateError('SyncService not initialized');
    
    try {
      final response = await _dio!.post('/api/v1/auth/login', data: {
        'username': username,
        'password': password,
        'deviceId': deviceId,
        'deviceName': deviceName,
      });
      
      if (response.data['success'] == true) {
        final teacher = Teacher(
          id: response.data['teacherId'],
          name: response.data['teacherName'],
          email: response.data['email'],
          token: response.data['token'],
          tokenExpiry: DateTime.parse(response.data['tokenExpiry']),
        );
        
        // Save credentials
        await _db.setConfig(ConfigKeys.authToken, teacher.token);
        await _db.setConfig(ConfigKeys.teacherId, teacher.id.toString());
        await _db.setConfig(ConfigKeys.teacherName, teacher.name);
        await _db.setConfig(ConfigKeys.teacherEmail, teacher.email);
        
        return teacher;
      }
      return null;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch teacher's classes from server
  Future<List<ClassSection>> fetchClasses() async {
    if (_dio == null) throw StateError('SyncService not initialized');
    
    try {
      final response = await _dio!.get('/api/v1/teacher/classes');
      final classes = (response.data['classes'] as List)
          .map((json) => ClassSection.fromJson(json))
          .toList();
      
      // Cache in local DB
      await _db.cacheClasses(classes.map((c) => CachedClassesCompanion(
        classId: Value(c.classId),
        sectionId: Value(c.sectionId),
        className: Value(c.className),
        sectionName: Value(c.sectionName),
        totalStudents: Value(c.totalStudents),
        isClassTeacher: Value(c.isClassTeacher),
      )).toList());
      
      return classes;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch students for a class
  Future<List<Student>> fetchStudents(int classId, int sectionId) async {
    if (_dio == null) throw StateError('SyncService not initialized');
    
    try {
      final response = await _dio!.get('/api/v1/class/$classId/$sectionId/students');
      final students = (response.data['students'] as List)
          .map((json) => Student.fromJson(json))
          .toList();
      
      // Cache in local DB
      await _db.cacheStudents(students.map((s) => CachedStudentsCompanion(
        studentId: Value(s.studentId),
        classId: Value(classId),
        sectionId: Value(sectionId),
        name: Value(s.name),
        rollNumber: Value(s.rollNumber),
        gender: Value(s.gender),
      )).toList());
      
      return students;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Sync pending attendance to server
  Future<SyncResult> syncAttendance() async {
    if (_dio == null) throw StateError('SyncService not initialized');
    
    final pending = await _db.getPendingAttendance();
    if (pending.isEmpty) {
      return const SyncResult(success: true, processed: 0, message: 'Nothing to sync');
    }
    
    final teacherId = int.parse(await _db.getConfig(ConfigKeys.teacherId) ?? '0');
    final deviceId = await _db.getConfig(ConfigKeys.deviceId) ?? '';
    
    final records = pending.map((a) => {
      'studentId': a.studentId,
      'classId': a.classId,
      'sectionId': a.sectionId,
      'date': a.date.toIso8601String().split('T')[0],
      'status': a.status,
      'remarks': a.remarks,
      'markedAt': a.markedAt.toIso8601String(),
      'academicYear': _getCurrentAcademicYear(),
    }).toList();
    
    try {
      final response = await _dio!.post('/api/v1/sync/attendance', data: {
        'deviceId': deviceId,
        'teacherId': teacherId,
        'syncTimestamp': DateTime.now().toIso8601String(),
        'attendanceRecords': records,
      });
      
      if (response.data['success'] == true) {
        // Mark all as synced
        for (final item in pending) {
          await _db.markAttendanceSynced(item.id);
        }
        
        await _db.setConfig(ConfigKeys.lastSync, DateTime.now().toIso8601String());
        
        return SyncResult(
          success: true,
          processed: response.data['processed'] ?? 0,
          created: response.data['created'] ?? 0,
          updated: response.data['updated'] ?? 0,
          conflicts: response.data['conflicts'] ?? 0,
          message: 'Synced successfully',
        );
      } else {
        return SyncResult(
          success: false,
          processed: 0,
          message: response.data['error'] ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  String _getCurrentAcademicYear() {
    final now = DateTime.now();
    if (now.month >= 4) {
      return '${now.year}-${now.year + 1}';
    } else {
      return '${now.year - 1}-${now.year}';
    }
  }
  
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please check your network.');
      case DioExceptionType.connectionError:
        return Exception('Cannot connect to server. Please check if the main system is running.');
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return Exception('Session expired. Please log in again.');
        }
        return Exception('Server error: ${e.response?.statusMessage}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}

class SyncResult {
  final bool success;
  final int processed;
  final int? created;
  final int? updated;
  final int? conflicts;
  final String message;
  
  const SyncResult({
    required this.success,
    required this.processed,
    this.created,
    this.updated,
    this.conflicts,
    required this.message,
  });
}
```

**New File:** `edux_teacher_app/lib/services/device_service.dart`

```dart
/// Manages device-specific functionality
class DeviceService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  
  DeviceService(this._db);
  
  /// Get or create device ID
  Future<String> getDeviceId() async {
    var deviceId = await _db.getConfig(ConfigKeys.deviceId);
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _db.setConfig(ConfigKeys.deviceId, deviceId);
    }
    return deviceId;
  }
  
  /// Get device name (for display in main system)
  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    }
    return 'Unknown Device';
  }
  
  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await _db.getConfig(ConfigKeys.authToken);
    return token != null && token.isNotEmpty;
  }
  
  /// Logout and clear all data
  Future<void> logout() async {
    await _db.clearAllData();
  }
}
```

**Checklist:**
- [ ] Create discovery service with mDNS
- [ ] Create sync service with all API methods
- [ ] Create device service
- [ ] Error handling for all network operations

---

### Task 2.7: Create Providers

**New File:** `edux_teacher_app/lib/providers/providers.dart`

```dart
export 'auth_provider.dart';
export 'sync_provider.dart';
export 'classes_provider.dart';
export 'attendance_provider.dart';
```

**New File:** `edux_teacher_app/lib/providers/auth_provider.dart`

```dart
part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  late final AppDatabase _db;
  late final DeviceService _deviceService;
  late final SyncService _syncService;
  
  @override
  AsyncValue<Teacher?> build() {
    _db = ref.watch(databaseProvider);
    _deviceService = ref.watch(deviceServiceProvider);
    _syncService = ref.watch(syncServiceProvider);
    _checkAuthStatus();
    return const AsyncValue.data(null);
  }
  
  Future<void> _checkAuthStatus() async {
    final isAuth = await _deviceService.isAuthenticated();
    if (isAuth) {
      final teacher = Teacher(
        id: int.parse(await _db.getConfig(ConfigKeys.teacherId) ?? '0'),
        name: await _db.getConfig(ConfigKeys.teacherName) ?? '',
        email: await _db.getConfig(ConfigKeys.teacherEmail) ?? '',
      );
      state = AsyncValue.data(teacher);
    }
  }
  
  Future<void> login(String serverIp, int port, String username, String password) async {
    state = const AsyncValue.loading();
    
    try {
      // Initialize sync service
      await _syncService.initialize(serverIp, port);
      
      // Get device info
      final deviceId = await _deviceService.getDeviceId();
      final deviceName = await _deviceService.getDeviceName();
      
      // Attempt login
      final teacher = await _syncService.login(username, password, deviceId, deviceName);
      
      if (teacher != null) {
        // Save server config
        await _db.setConfig(ConfigKeys.serverIp, serverIp);
        await _db.setConfig(ConfigKeys.serverPort, port.toString());
        
        state = AsyncValue.data(teacher);
      } else {
        state = const AsyncValue.data(null);
        throw Exception('Invalid username or password');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> logout() async {
    await _deviceService.logout();
    state = const AsyncValue.data(null);
  }
}

@riverpod
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}

@riverpod
DeviceService deviceService(DeviceServiceRef ref) {
  final db = ref.watch(databaseProvider);
  return DeviceService(db);
}

@riverpod
SyncService syncService(SyncServiceRef ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
}
```

(Other providers would follow similar patterns - abbreviated for brevity)

---

### Task 2.8: Create Main App Entry Point

**New File:** `edux_teacher_app/lib/app.dart`

```dart
class TeacherApp extends ConsumerWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
```

**Modified File:** `edux_teacher_app/lib/main.dart`

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ProviderScope(
      child: const TeacherApp(),
    ),
  );
}
```

---

## Phase 2 Completion Criteria

- [ ] New Flutter project created and runs
- [ ] Database layer fully implemented with Drift
- [ ] All models created with freezed
- [ ] Services for discovery, sync, and device management
- [ ] Riverpod providers for state management
- [ ] App launches without errors
- [ ] Can discover server on network (test with Phase 1 server running)

---

**Next Phase:** Phase 3 (Attendance UI)
