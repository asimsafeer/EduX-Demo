/// EduX Teacher App - Sync Service
/// 
/// OPTIMIZED VERSION - Added proper timeouts, chunked sync, progress callbacks,
/// comprehensive error handling, and detailed logging
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/attendance_record.dart';
import '../models/class_section.dart';
import '../models/student.dart';
import '../models/sync_models.dart';
import '../models/teacher.dart';

/// Service for syncing with the main EduX server
class SyncService {
  final AppDatabase _db;
  Dio? _dio;

  SyncService(this._db);

  /// Get current dio instance
  Dio? get dio => _dio;

  /// Initialize with server address
  Future<void> initialize(String serverIp, int port) async {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://$serverIp:$port',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60), // Increased for large datasets
      sendTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add auth interceptor
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _db.getConfig(ConfigKeys.authToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Log request
        debugPrint('[SyncService] Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response
        debugPrint('[SyncService] Response: ${response.statusCode} for ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle 401 - token expired
        if (error.response?.statusCode == 401) {
          _db.deleteConfig(ConfigKeys.authToken);
        }
        
        // Log error
        debugPrint('[SyncService] Error: ${error.type} - ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Check if initialized
  bool get isInitialized => _dio != null;

  /// Reinitialize with saved server config
  Future<bool> reinitialize() async {
    final serverIp = await _db.getConfig(ConfigKeys.serverIp);
    final serverPort = await _db.getConfig(ConfigKeys.serverPort);

    if (serverIp != null && serverPort != null) {
      final port = int.tryParse(serverPort);
      if (port != null) {
        await initialize(serverIp, port);
        return true;
      }
    }
    return false;
  }

  /// Login to server
  Future<Teacher?> login(
    String username,
    String password,
    String deviceId,
    String deviceName,
  ) async {
    if (_dio == null) {
      throw StateError('SyncService not initialized');
    }

    try {
      debugPrint('[SyncService] Attempting login for $username');
      
      final response = await _dio!.post('/api/v1/auth/login', data: {
        'username': username,
        'password': password,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'appVersion': AppConstants.appVersion,
      });

      debugPrint('[SyncService] Login response received');

      if (response.data['success'] == true) {
        final data = response.data;
        debugPrint('[SyncService] Login success - teacherId: ${data['teacherId']}');

        final teacher = Teacher(
          id: data['teacherId'] as int,
          name: data['teacherName'] as String,
          email: data['email'] as String? ?? '',
          photoUrl: data['photoUrl'] as String?,
          token: data['token'] as String?,
          tokenExpiry: data['tokenExpiry'] != null
              ? DateTime.parse(data['tokenExpiry'] as String)
              : null,
          permissions: (data['permissions'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
        );

        // Save credentials
        await _db.setConfig(ConfigKeys.authToken, teacher.token);
        await _db.setConfig(ConfigKeys.teacherId, teacher.id.toString());
        await _db.setConfig(ConfigKeys.teacherName, teacher.name);
        await _db.setConfig(ConfigKeys.teacherEmail, teacher.email);
        if (teacher.photoUrl != null) {
          await _db.setConfig(ConfigKeys.teacherPhoto, teacher.photoUrl!);
        }

        return teacher;
      } else {
        final errorMsg = response.data['error'] as String?;
        final errorCode = response.data['errorCode'] as String?;
        debugPrint('[SyncService] Login failed - error: $errorMsg, code: $errorCode');
        throw Exception(errorMsg ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch teacher's classes from server
  Future<List<ClassSection>> fetchClasses() async {
    if (_dio == null) throw StateError('SyncService not initialized');

    try {
      debugPrint('[SyncService] Fetching classes...');
      final stopwatch = Stopwatch()..start();
      
      final response = await _dio!.get('/api/v1/teacher/classes');

      if (response.data['classes'] == null) {
        return [];
      }

      final classes = (response.data['classes'] as List)
          .map((json) => ClassSection.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache in local DB
      await _db.cacheClasses(classes
          .map((c) => CachedClassesCompanion(
                classId: Value(c.classId),
                sectionId: Value(c.sectionId),
                className: Value(c.className),
                sectionName: Value(c.sectionName),
                subjectName: Value(c.subjectName),
                totalStudents: Value(c.totalStudents),
                isClassTeacher: Value(c.isClassTeacher),
              ))
          .toList());

      debugPrint('[SyncService] Fetched ${classes.length} classes in ${stopwatch.elapsedMilliseconds}ms');
      return classes;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch students for a class
  Future<List<Student>> fetchStudents(int classId, int sectionId) async {
    if (_dio == null) throw StateError('SyncService not initialized');

    try {
      debugPrint('[SyncService] Fetching students for class $classId-$sectionId...');
      final stopwatch = Stopwatch()..start();
      
      final response =
          await _dio!.get('/api/v1/class/$classId/$sectionId/students');

      if (response.data['students'] == null) {
        return [];
      }

      final students = (response.data['students'] as List)
          .map((json) => Student.fromJson({
                ...json as Map<String, dynamic>,
                'classId': classId,
                'sectionId': sectionId,
              }))
          .toList();

      // Cache in local DB
      await _db.cacheStudents(students
          .map((s) => CachedStudentsCompanion(
                studentId: Value(s.studentId),
                classId: Value(classId),
                sectionId: Value(sectionId),
                name: Value(s.name),
                rollNumber: Value(s.rollNumber ?? ''),
                gender: Value(s.gender ?? ''),
                photoUrl: Value(s.photoUrl),
              ))
          .toList());

      debugPrint('[SyncService] Fetched ${students.length} students in ${stopwatch.elapsedMilliseconds}ms');
      return students;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// FIXED: Fetch students with diagnostics for better error reporting
  Future<Map<String, dynamic>> fetchStudentsWithDiagnostics(int classId, int sectionId) async {
    if (_dio == null) throw StateError('SyncService not initialized');

    try {
      debugPrint('[SyncService] Fetching students with diagnostics for class $classId-$sectionId...');
      
      final response = await _dio!.get('/api/v1/class/$classId/$sectionId/students');
      
      final data = response.data as Map<String, dynamic>;
      final students = (data['students'] as List?) ?? [];
      
      // Cache students if any were returned
      if (students.isNotEmpty) {
        final studentObjects = students
            .map((json) => Student.fromJson({
                  ...(json as Map<String, dynamic>),
                  'classId': classId,
                  'sectionId': sectionId,
                }))
            .toList();
        
        await _db.cacheStudents(studentObjects
            .map((s) => CachedStudentsCompanion(
                  studentId: Value(s.studentId),
                  classId: Value(classId),
                  sectionId: Value(sectionId),
                  name: Value(s.name),
                  rollNumber: Value(s.rollNumber ?? ''),
                  gender: Value(s.gender ?? ''),
                  photoUrl: Value(s.photoUrl),
                ))
            .toList());
      }
      
      // Store the academic year from server for reference
      if (data['academicYear'] != null) {
        await _db.setConfig('last_server_academic_year', data['academicYear'] as String);
      }
      
      debugPrint('[SyncService] Server returned ${students.length} students, academicYear: ${data['academicYear']}');
      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Sync pending attendance to server
  /// FIXED: Gets academic year from server instead of generating locally
  Future<SyncResult> syncAttendance() async {
    if (_dio == null) throw StateError('SyncService not initialized');

    final pending = await _db.getPendingAttendance();
    if (pending.isEmpty) {
      return const SyncResult(
        success: true,
        processed: 0,
        message: 'No pending attendance to sync',
      );
    }

    final teacherIdStr = await _db.getConfig(ConfigKeys.teacherId);
    final deviceId = await _db.getConfig(ConfigKeys.deviceId);
    
    // FIXED: Get academic year from server if available
    String academicYear = await _getServerAcademicYear();

    if (teacherIdStr == null || deviceId == null) {
      return const SyncResult(
        success: false,
        processed: 0,
        message: 'Not authenticated',
      );
    }

    final teacherId = int.parse(teacherIdStr);

    // FIXED: Create records with correct academic year from server
    final records = pending
        .map((a) => AttendanceRecord.fromPending(
              studentId: a.studentId,
              classId: a.classId,
              sectionId: a.sectionId,
              date: a.date,
              status: a.status,
              remarks: a.remarks,
              markedAt: a.markedAt,
              academicYear: academicYear, // Use server's academic year
            ))
        .toList();

    final request = SyncRequest(
      deviceId: deviceId,
      teacherId: teacherId,
      syncTimestamp: DateTime.now(),
      attendanceRecords: records,
    );

    try {
      debugPrint('[SyncService] Syncing ${records.length} attendance records...');
      final stopwatch = Stopwatch()..start();
      
      final response = await _dio!.post(
        '/api/v1/sync/attendance',
        data: request.toJson(),
      );

      final syncResponse =
          SyncResponse.fromJson(response.data as Map<String, dynamic>);

      if (syncResponse.success) {
        // Mark all as synced
        await _db.markAttendanceSyncedBatch(
          pending.map((p) => p.id).toList(),
        );

        await _db.setConfig(
            ConfigKeys.lastSync, DateTime.now().toIso8601String());

        debugPrint('[SyncService] Sync completed in ${stopwatch.elapsedMilliseconds}ms');
        return SyncResult.fromSyncResponse(syncResponse);
      } else {
        return SyncResult(
          success: false,
          processed: 0,
          message: syncResponse.errorMessage ?? 'Sync failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Check server status
  Future<ServerStatus?> checkServerStatus() async {
    if (_dio == null) return null;

    try {
      final response = await _dio!.get('/api/v1/sync/status');
      return ServerStatus.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// FIXED: Get academic year from server if available, fallback to local generation
  Future<String> _getServerAcademicYear() async {
    // First try to get from cached server response
    final serverYear = await _db.getConfig('last_server_academic_year');
    if (serverYear != null && serverYear.isNotEmpty) {
      return serverYear;
    }
    
    // Fallback to local generation
    return _getLocalAcademicYear();
  }
  
  /// Get local academic year (fallback only)
  String _getLocalAcademicYear() {
    final now = DateTime.now();
    if (now.month >= 4) {
      return '${now.year}-${now.year + 1}';
    } else {
      return '${now.year - 1}-${now.year}';
    }
  }

  /// Handle Dio errors with user-friendly messages
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timed out. The server is taking too long to respond. '
          'This may happen with large class data. Please try again.',
        );

      case DioExceptionType.connectionError:
        return Exception(
            'Cannot connect to server. Please check if the main system is running and you are on the same network.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data as Map<String, dynamic>?;

        if (statusCode == 401) {
          return Exception('Session expired. Please log in again.');
        } else if (statusCode == 403) {
          return Exception(data?['error'] ?? 'Access denied.');
        } else if (statusCode == 404) {
          return Exception('Server endpoint not found. Please update your app.');
        } else if (statusCode == 429) {
          return Exception('Too many requests. Please wait a moment and try again.');
        } else if (statusCode == 503) {
          return Exception('Server is busy. Please try again in a moment.');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later or contact support.');
        }
        return Exception(data?['error'] ?? 'Server error: $statusCode');

      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return Exception('Security error. Please check your connection.');

      case DioExceptionType.unknown:
        return Exception('Network error: ${e.message}');
    }
  }

  /// Retry operation with exponential backoff
  Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = AppConstants.maxSyncRetries,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;

        // Wait with exponential backoff
        final delay = Duration(
          seconds: AppConstants.syncRetryDelay.inSeconds * (attempt + 1),
        );
        debugPrint('[SyncService] Retry attempt ${attempt + 1} after ${delay.inSeconds}s delay');
        await Future.delayed(delay);
      }
    }
    throw StateError('Unreachable');
  }

  // ===========================================================================
  // BULK DATA SYNC - OPTIMIZED VERSION
  // ===========================================================================

  /// Fetch ALL data (classes + students for all classes) with progress tracking
  /// Uses optimized single-query approach on server
  Future<FullSyncResult> fetchAllData({
    Function(int current, int total, String status, String? className)? onProgress,
  }) async {
    if (_dio == null) throw StateError('SyncService not initialized');

    try {
      debugPrint('[SyncService] Starting full sync...');
      final stopwatch = Stopwatch()..start();
      
      onProgress?.call(0, 100, 'Connecting to server...', null);

      // Try the optimized bulk endpoint first
      try {
        final result = await _fetchAllDataBulkOptimized(
          onProgress: onProgress,
        );
        
        debugPrint('[SyncService] Full sync completed in ${stopwatch.elapsedMilliseconds}ms');
        return result;
      } catch (e) {
        debugPrint('[SyncService] Bulk endpoint failed, falling back to chunked sync: $e');
        onProgress?.call(0, 100, 'Using fallback sync method...', null);
        
        // Fall back to chunked sync
        return await _fetchAllDataChunked(onProgress: onProgress);
      }
    } catch (e) {
      debugPrint('[SyncService] Full sync failed: $e');
      return FullSyncResult(
        classes: const [],
        studentsByClass: const {},
        errors: {},
        success: false,
        message: 'Failed to fetch data: $e',
      );
    }
  }

  /// Optimized bulk data fetch using single-query endpoint
  Future<FullSyncResult> _fetchAllDataBulkOptimized({
    Function(int current, int total, String status, String? className)? onProgress,
  }) async {
    onProgress?.call(10, 100, 'Fetching data from server...', null);
    
    final response = await _dio!.get(
      '/api/v1/teacher/full-sync',
      options: Options(
        receiveTimeout: const Duration(seconds: 90), // Longer timeout for bulk data
      ),
    );
    
    final data = response.data as Map<String, dynamic>;
    final classesJson = data['classes'] as List<dynamic>;
    final studentsByClassSection = data['studentsByClassSection'] as Map<String, dynamic>;
    final processingTimeMs = data['processingTimeMs'] as int?;
    
    debugPrint('[SyncServer] Server processing time: ${processingTimeMs}ms');

    // Parse classes
    final classes = classesJson
        .map((json) => ClassSection.fromJson(json as Map<String, dynamic>))
        .toList();

    if (classes.isEmpty) {
      return const FullSyncResult(
        classes: [],
        studentsByClass: {},
        errors: {},
        success: true,
        message: 'No classes assigned',
      );
    }

    onProgress?.call(30, 100, 'Processing ${classes.length} classes...', null);

    // Process students for each class
    final studentsByClass = <ClassSection, List<Student>>{};
    final errors = <ClassSection, String>{};
    int currentIndex = 0;

    for (final classSection in classes) {
      currentIndex++;
      final progress = 30 + ((currentIndex / classes.length) * 60).round();
      
      onProgress?.call(
        progress, 
        100, 
        'Processing class $currentIndex of ${classes.length}...',
        classSection.displayName,
      );

      try {
        final compositeKey = classSection.classId * 10000 + classSection.sectionId;
        final studentsJson = studentsByClassSection[compositeKey.toString()] as List<dynamic>?;
        
        if (studentsJson != null) {
          final students = studentsJson
              .map((json) => Student.fromJson({
                    ...(json as Map<String, dynamic>),
                    'classId': classSection.classId,
                    'sectionId': classSection.sectionId,
                  }))
              .toList();

          // Cache the students
          await _db.cacheStudents(students.map((s) => CachedStudentsCompanion(
                studentId: Value(s.studentId),
                classId: Value(s.classId),
                sectionId: Value(s.sectionId),
                name: Value(s.name),
                rollNumber: Value(s.rollNumber ?? ''),
                gender: Value(s.gender ?? ''),
                photoUrl: Value(s.photoUrl),
              )).toList());

          studentsByClass[classSection] = students;
        } else {
          errors[classSection] = 'No student data received';
        }
      } catch (e) {
        errors[classSection] = e.toString();
      }
    }

    onProgress?.call(95, 100, 'Caching class information...', null);

    // Cache the classes
    await _db.cacheClasses(classes.map((c) => CachedClassesCompanion(
          classId: Value(c.classId),
          sectionId: Value(c.sectionId),
          className: Value(c.className),
          sectionName: Value(c.sectionName),
          subjectName: Value(c.subjectName),
          totalStudents: Value(c.totalStudents),
          isClassTeacher: Value(c.isClassTeacher),
        )).toList());

    onProgress?.call(100, 100, 'Sync complete!', null);

    final success = errors.isEmpty || studentsByClass.isNotEmpty;
    final totalStudents = studentsByClass.values.fold(0, (sum, list) => sum + list.length);
    
    final message = errors.isEmpty
        ? 'Successfully synced ${classes.length} classes with $totalStudents students'
        : 'Synced ${studentsByClass.length}/${classes.length} classes. ${errors.length} failed.';

    return FullSyncResult(
      classes: classes,
      studentsByClass: studentsByClass,
      errors: errors,
      success: success,
      message: message,
    );
  }

  /// Fallback: Fetch data in chunks to prevent timeout
  Future<FullSyncResult> _fetchAllDataChunked({
    Function(int current, int total, String status, String? className)? onProgress,
  }) async {
    onProgress?.call(10, 100, 'Fetching classes...', null);
    
    // Step 1: Fetch all classes
    final classes = await fetchClasses();
    
    if (classes.isEmpty) {
      return const FullSyncResult(
        classes: [],
        studentsByClass: {},
        errors: {},
        success: true,
        message: 'No classes assigned',
      );
    }

    onProgress?.call(20, 100, 'Found ${classes.length} classes', null);

    // Step 2: Fetch students for each class with error handling
    final studentsByClass = <ClassSection, List<Student>>{};
    final errors = <ClassSection, String>{};
    int currentIndex = 0;

    for (final classSection in classes) {
      currentIndex++;
      final progress = 20 + ((currentIndex / classes.length) * 75).round();
      
      onProgress?.call(
        progress,
        100,
        'Syncing class $currentIndex of ${classes.length}...',
        classSection.displayName,
      );

      try {
        final students = await retryWithBackoff(
          () => fetchStudents(classSection.classId, classSection.sectionId),
          maxRetries: 2,
        );
        studentsByClass[classSection] = students;
      } catch (e) {
        errors[classSection] = e.toString();
        // Continue with other classes even if one fails
      }
    }

    onProgress?.call(100, 100, 'Sync complete!', null);

    final totalStudents = studentsByClass.values.fold(0, (sum, list) => sum + list.length);
    final success = errors.isEmpty || studentsByClass.isNotEmpty;
    
    final message = errors.isEmpty
        ? 'Successfully synced ${classes.length} classes with $totalStudents students'
        : 'Synced ${studentsByClass.length}/${classes.length} classes. ${errors.length} failed.';

    return FullSyncResult(
      classes: classes,
      studentsByClass: studentsByClass,
      errors: errors,
      success: success,
      message: message,
    );
  }

  /// Validate data integrity - check if cached data matches expected counts
  Future<DataIntegrityReport> validateDataIntegrity() async {
    final classes = await _db.getCachedClasses();
    final mismatches = <ClassIntegrityMismatch>[];
    final missingStudents = <ClassSection>[];

    for (final classInfo in classes) {
      final cachedStudents = await _db.getCachedStudents(
        classInfo.classId,
        classInfo.sectionId,
      );

      // Check for missing student data
      if (cachedStudents.isEmpty && classInfo.totalStudents > 0) {
        missingStudents.add(
          ClassSection(
            classId: classInfo.classId,
            sectionId: classInfo.sectionId,
            className: classInfo.className,
            sectionName: classInfo.sectionName,
            totalStudents: classInfo.totalStudents,
          ),
        );
      }

      // Check for count mismatch
      if (cachedStudents.length != classInfo.totalStudents) {
        mismatches.add(
          ClassIntegrityMismatch(
            classSection: ClassSection(
              classId: classInfo.classId,
              sectionId: classInfo.sectionId,
              className: classInfo.className,
              sectionName: classInfo.sectionName,
              totalStudents: classInfo.totalStudents,
            ),
            expected: classInfo.totalStudents,
            actual: cachedStudents.length,
          ),
        );
      }
    }

    return DataIntegrityReport(
      mismatches: mismatches,
      missingStudents: missingStudents,
      totalClasses: classes.length,
      checkedAt: DateTime.now(),
    );
  }

  /// Fetch and cache students for a specific class with better error handling
  Future<List<Student>> fetchAndCacheStudents(
    int classId,
    int sectionId, {
    bool clearExisting = true,
  }) async {
    if (_dio == null) throw StateError('SyncService not initialized');

    try {
      // Clear existing cache if requested
      if (clearExisting) {
        await _db.clearCachedStudents(classId, sectionId);
      }

      // Fetch from server
      final students = await retryWithBackoff(
        () => fetchStudents(classId, sectionId),
        maxRetries: 3,
      );

      return students;
    } catch (e) {
      throw Exception('Failed to fetch students for class $classId-$sectionId: $e');
    }
  }
  
  /// FIXED: Validate data integrity and check for academic year mismatches
  Future<DataIntegrityReport> validateDataIntegrity() async {
    final classes = await _db.getCachedClasses();
    final mismatches = <ClassIntegrityMismatch>[];
    final missingStudents = <ClassSection>[];
    
    // Get the last server academic year
    final serverYear = await _db.getConfig('last_server_academic_year');
    final localYear = _getLocalAcademicYear();
    
    // Check for academic year mismatch
    bool yearMismatch = false;
    if (serverYear != null && serverYear != localYear) {
      yearMismatch = true;
      debugPrint('[SyncService] Academic year mismatch detected: server=$serverYear, local=$localYear');
    }

    for (final classInfo in classes) {
      final cachedStudents = await _db.getCachedStudents(
        classInfo.classId,
        classInfo.sectionId,
      );

      // Check for missing student data
      if (cachedStudents.isEmpty && classInfo.totalStudents > 0) {
        missingStudents.add(
          ClassSection(
            classId: classInfo.classId,
            sectionId: classInfo.sectionId,
            className: classInfo.className,
            sectionName: classInfo.sectionName,
            totalStudents: classInfo.totalStudents,
          ),
        );
      }

      // Check for count mismatch
      if (cachedStudents.length != classInfo.totalStudents) {
        mismatches.add(
          ClassIntegrityMismatch(
            classSection: ClassSection(
              classId: classInfo.classId,
              sectionId: classInfo.sectionId,
              className: classInfo.className,
              sectionName: classInfo.sectionName,
              totalStudents: classInfo.totalStudents,
            ),
            expected: classInfo.totalStudents,
            actual: cachedStudents.length,
          ),
        );
      }
    }

    return DataIntegrityReport(
      mismatches: mismatches,
      missingStudents: missingStudents,
      totalClasses: classes.length,
      checkedAt: DateTime.now(),
      academicYearMismatch: yearMismatch,
      serverAcademicYear: serverYear,
      localAcademicYear: localYear,
    );
  }
  
  /// FIXED: Clear all cache when academic year changes or data is corrupted
  Future<void> clearAllCache() async {
    debugPrint('[SyncService] Clearing all cached data');
    await _db.clearAllData();
  }
}
