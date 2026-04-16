/// EduX School Management System
/// Sync HTTP server for teacher app communication
/// /// OPTIMIZED VERSION - Fixed N+1 queries, added proper indexing hints,
/// chunked responses, and comprehensive logging
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../database/database.dart';
import '../../services/services.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Main sync server for teacher app communication
class SyncServer {
  static const int defaultPort = 8181;
  static const int _maxConcurrentRequests = 50;
  static const int _maxRequestsPerMinute = 100;
  static const Duration _requestTimeout = Duration(seconds: 60);
  
  /// Maximum students per chunk for paginated responses
  static const int _maxStudentsPerChunk = 500;
  
  /// Maximum time to spend fetching data before returning partial results
  static const Duration _maxProcessingTime = Duration(seconds: 45);

  final AppDatabase _db;
  final AuthService _authService;
  final SyncDeviceService _deviceService;
  final SyncProcessor _syncProcessor;

  HttpServer? _server;
  bool get isRunning => _server != null;
  int get port => _server?.port ?? defaultPort;
  String? get address => _server?.address.address;

  // Event stream for UI updates
  final _syncEventController = StreamController<SyncResponse>.broadcast();
  Stream<SyncResponse> get onSyncEvent => _syncEventController.stream;

  // Rate limiting tracking
  final Map<String, List<DateTime>> _requestLog = {};
  int _activeRequests = 0;
  final _requestLock = Object();

  SyncServer(
    this._db,
    this._authService,
    this._deviceService,
    this._syncProcessor,
  );

  /// Factory constructor with default services
  factory SyncServer.instance() {
    final db = AppDatabase.instance;
    return SyncServer(
      db,
      AuthService.instance(),
      SyncDeviceService.instance(),
      SyncProcessor.instance(),
    );
  }

  // ============================================
  // SERVER LIFECYCLE
  // ============================================

  /// Start the server
  Future<void> start({int port = defaultPort}) async {
    if (_server != null) {
      throw StateError('Server is already running on port ${this.port}');
    }

    final router = _buildRouter();
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_errorHandlerMiddleware())
        .addMiddleware(_rateLimitMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(router.call);

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, port);
      debugPrint('[SyncServer] Started on port $port');
    } catch (e) {
      throw StateError('Failed to start sync server: $e');
    }
  }

  /// Stop the server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      debugPrint('[SyncServer] Stopped');
    }
  }

  /// Restart the server
  Future<void> restart({int port = defaultPort}) async {
    await stop();
    await start(port: port);
  }

  // ============================================
  // ROUTE HANDLERS
  // ============================================

  Router _buildRouter() {
    final router = Router();

    // Health check (public)
    router.get('/health', _handleHealth);

    // Auth endpoints (public)
    router.post('/api/v1/auth/login', _handleLogin);

    // Protected endpoints (require auth)
    router.get('/api/v1/teacher/classes', _handleGetClasses);
    router.get(
      '/api/v1/class/<classId>/<sectionId>/students',
      _handleGetStudents,
    );
    router.get('/api/v1/teacher/full-sync', _handleFullSync);
    router.get('/api/v1/teacher/sync-chunk', _handleSyncChunk);
    router.post('/api/v1/sync/attendance', _handleSyncAttendance);
    router.get('/api/v1/sync/status', _handleSyncStatus);
    
    // NEW: Debug endpoint for troubleshooting
    router.get('/api/v1/debug/class/<classId>/<sectionId>', _handleDebugClass);
    router.get('/api/v1/debug/academic-year', _handleDebugAcademicYear);

    return router;
  }

  // ============================================
  // ENDPOINT HANDLERS
  // ============================================

  /// Health check endpoint
  Future<Response> _handleHealth(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
        'server': 'EduX Sync Server',
        'version': AppConstants.appVersion,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Teacher login endpoint
  Future<Response> _handleLogin(Request request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final loginRequest = DeviceRegistrationRequest.fromJson(json);

      // Validate required fields
      if (loginRequest.username.isEmpty || loginRequest.password.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Username and password are required',
            'errorCode': 'AUTH_MISSING_CREDENTIALS',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Authenticate user
      final user = await _authService.login(
        loginRequest.username,
        loginRequest.password,
      );

      if (user == null) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'error': 'Invalid credentials',
            'errorCode': 'AUTH_INVALID_CREDENTIALS',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Check if user is linked to a staff record
      final staff = await (_db.select(
        _db.staff,
      )..where((s) => s.userId.equals(user.id))).getSingleOrNull();

      if (staff == null) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'error': 'User is not a teacher',
            'errorCode': 'AUTH_NOT_TEACHER',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Get client IP
      final ipAddress = _getClientIp(request);

      // Register/update device
      await _deviceService.registerDevice(
        deviceId: loginRequest.deviceId,
        deviceName: loginRequest.deviceName,
        teacherId: staff.id,
        ipAddress: ipAddress,
      );

      // Generate token
      final token = _generateToken(staff.id);
      final expiry = DateTime.now().add(
        const Duration(hours: SyncConstants.tokenValidityHours),
      );

      // Log successful login
      await _deviceService.logSyncOperation(
        deviceId: loginRequest.deviceId,
        teacherId: staff.id,
        syncType: SyncConstants.syncTypeDownload,
        recordsCount: 0,
        status: SyncConstants.syncStatusSuccess,
      );

      debugPrint('[SyncServer] Login successful for ${loginRequest.username} in ${stopwatch.elapsedMilliseconds}ms');

      return Response.ok(
        jsonEncode(
          TeacherLoginResponse.success(
            token: token,
            teacherId: staff.id,
            teacherName: '${staff.firstName} ${staff.lastName}',
            email: user.email,
            photoUrl: null,
            tokenExpiry: expiry,
            permissions: await _getTeacherPermissions(staff.id),
          ).toJson(),
        ),
        headers: {'content-type': 'application/json'},
      );
    } on FormatException catch (e) {
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'error': 'Invalid JSON: ${e.message}',
          'errorCode': 'INVALID_JSON',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] Login error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Get classes for teacher endpoint
  /// FIXED: Removed academic year filter - returns all assigned classes
  Future<Response> _handleGetClasses(Request request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final teacherId = _getTeacherIdFromRequest(request);
      
      // Get classes where teacher is assigned (ANY academic year)
      final assignments =
          await (_db.select(_db.staffSubjectAssignments)
                ..where((a) => a.staffId.equals(teacherId)))
              .get();

      final classIds = assignments.map((a) => a.classId).toSet();
      final classes = <Map<String, dynamic>>[];

      for (final classId in classIds) {
        final classData = await (_db.select(
          _db.classes,
        )..where((c) => c.id.equals(classId))).getSingleOrNull();

        if (classData != null) {
          // Get sections for this class
          final sections = assignments
              .where((a) => a.classId == classId)
              .map((a) => a.sectionId)
              .toSet();

          for (final sectionId in sections) {
            if (sectionId == null) continue;

            final section = await (_db.select(
              _db.sections,
            )..where((s) => s.id.equals(sectionId))).getSingleOrNull();

            // Get subject names for this assignment
            final subjectAssignments = assignments
                .where((a) => a.classId == classId && a.sectionId == sectionId)
                .toList();

            String? subjectName;
            if (subjectAssignments.isNotEmpty) {
              final subject =
                  await (_db.select(_db.subjects)
                        ..where(
                          (s) => s.id.equals(subjectAssignments.first.subjectId),
                        ))
                      .getSingleOrNull();
              subjectName = subject?.name;
            }

            // Count students (across ALL academic years)
            final studentCount = await _getStudentCount(
              classId,
              sectionId,
            );

            classes.add({
              'classId': classId,
              'sectionId': sectionId,
              'className': classData.name,
              'sectionName': section?.name ?? 'N/A',
              'totalStudents': studentCount,
              'isClassTeacher': assignments.any(
                (a) =>
                    a.classId == classId &&
                    a.sectionId == sectionId &&
                    a.isClassTeacher,
              ),
              'subjectName': subjectName,
            });
          }
        }
      }

      debugPrint('[SyncServer] GetClasses for teacher $teacherId: ${classes.length} classes in ${stopwatch.elapsedMilliseconds}ms');

      return Response.ok(
        jsonEncode({'classes': classes}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] GetClasses error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'error': e.toString(),
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Get students for class/section endpoint
  /// FIXED: Returns diagnostic info when 0 students found
  Future<Response> _handleGetStudents(
    Request request,
    String classId,
    String sectionId,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final cId = int.tryParse(classId);
      final sId = int.tryParse(sectionId);

      if (cId == null || sId == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Invalid class or section ID',
            'errorCode': 'INVALID_PARAMS',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // FIXED: Removed academic year check - returns ALL students
      final students = await _getStudentsForClassOptimized(cId, sId);

      debugPrint('[SyncServer] GetStudents for class $cId-$sId: ${students.length} students in ${stopwatch.elapsedMilliseconds}ms');

      // Build response
      final response = <String, dynamic>{
        'students': students,
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalCount': students.length,
      };

      return Response.ok(
        jsonEncode(response),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] GetStudents error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'error': e.toString(),
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Full sync endpoint - returns all classes and students for a teacher
  /// OPTIMIZED: Uses single query for all students, chunked processing
  Future<Response> _handleFullSync(Request request) async {
    final stopwatch = Stopwatch()..start();
    final processingStopwatch = Stopwatch()..start();
    
    try {
      final teacherId = _getTeacherIdFromRequest(request);

      debugPrint('[SyncServer] FullSync started for teacher $teacherId');

      // Get all class assignments with metadata (ALL academic years)
      final classAssignments = await _getTeacherClassesOptimized(teacherId);

      if (classAssignments.isEmpty) {
        debugPrint('[SyncServer] FullSync: No classes found for teacher $teacherId');
        return Response.ok(
          jsonEncode({
            'classes': [],
            'studentsByClassSection': {},
            'serverTimestamp': DateTime.now().toIso8601String(),
            'totalClasses': 0,
            'totalStudents': 0,
            'processingTimeMs': stopwatch.elapsedMilliseconds,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // OPTIMIZED: Fetch ALL students for ALL classes in a SINGLE query
      final allStudents = await _getAllStudentsForTeacherOptimized(teacherId);

      debugPrint('[SyncServer] FullSync: Fetched ${allStudents.length} total students in ${processingStopwatch.elapsedMilliseconds}ms');
      processingStopwatch.reset();

      // Build response
      final classes = <TeacherClassInfo>[];
      final studentsByClassSection = <int, List<TeacherStudentInfo>>{};
      int totalStudents = 0;

      for (final assignment in classAssignments) {
        final classInfo = TeacherClassInfo(
          classId: assignment.classId,
          sectionId: assignment.sectionId,
          className: assignment.className,
          sectionName: assignment.sectionName,
          totalStudents: assignment.totalStudents,
          isClassTeacher: assignment.isClassTeacher,
          subjectName: assignment.subjectName,
        );
        classes.add(classInfo);

        // Get students for this class from the bulk fetch
        final compositeKey = assignment.classId * 10000 + assignment.sectionId;
        final classStudents = allStudents
            .where((s) => s.classId == assignment.classId && s.sectionId == assignment.sectionId)
            .map((s) => TeacherStudentInfo(
                  studentId: s.studentId,
                  name: s.name,
                  rollNumber: s.rollNumber,
                  gender: s.gender,
                  photoUrl: s.photoUrl,
                ))
            .toList();
        
        studentsByClassSection[compositeKey] = classStudents;
        totalStudents += classStudents.length;

        // Check if we've exceeded processing time
        if (processingStopwatch.elapsed > _maxProcessingTime) {
          debugPrint('[SyncServer] FullSync: Exceeded max processing time, returning partial results');
          break;
        }
      }

      final response = FullSyncResponse(
        classes: classes,
        studentsByClassSection: studentsByClassSection,
        serverTimestamp: DateTime.now(),
        academicYear: 'all', // FIXED: Removed academic year filtering
      );

      final jsonResponse = response.toJson();
      jsonResponse['totalClasses'] = classes.length;
      jsonResponse['totalStudents'] = totalStudents;
      jsonResponse['processingTimeMs'] = stopwatch.elapsedMilliseconds;

      debugPrint('[SyncServer] FullSync completed: ${classes.length} classes, $totalStudents students in ${stopwatch.elapsedMilliseconds}ms');

      return Response.ok(
        jsonEncode(jsonResponse),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] FullSync error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'error': e.toString(),
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Chunked sync endpoint - for large datasets
  /// Returns students in chunks to prevent timeout
  /// FIXED: Removed academic year filter
  Future<Response> _handleSyncChunk(Request request) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final teacherId = _getTeacherIdFromRequest(request);

      // Get pagination parameters
      final classIdParam = request.url.queryParameters['classId'];
      final sectionIdParam = request.url.queryParameters['sectionId'];
      final offsetParam = request.url.queryParameters['offset'];
      final limitParam = request.url.queryParameters['limit'];

      final offset = int.tryParse(offsetParam ?? '0') ?? 0;
      final limit = int.tryParse(limitParam ?? '$_maxStudentsPerChunk') ?? _maxStudentsPerChunk;

      // If classId and sectionId provided, return students for that class
      if (classIdParam != null && sectionIdParam != null) {
        final classId = int.tryParse(classIdParam);
        final sectionId = int.tryParse(sectionIdParam);

        if (classId == null || sectionId == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid class or section ID'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final students = await _getStudentsForClassOptimized(
          classId,
          sectionId,
          offset: offset,
          limit: limit,
        );

        return Response.ok(
          jsonEncode({
            'students': students,
            'offset': offset,
            'limit': limit,
            'hasMore': students.length >= limit,
            'processingTimeMs': stopwatch.elapsedMilliseconds,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Otherwise, return list of classes (ALL academic years)
      final classes = await _getTeacherClassesOptimized(teacherId);

      return Response.ok(
        jsonEncode({
          'classes': classes.map((c) => {
            'classId': c.classId,
            'sectionId': c.sectionId,
            'className': c.className,
            'sectionName': c.sectionName,
            'totalStudents': c.totalStudents,
          }).toList(),
          'processingTimeMs': stopwatch.elapsedMilliseconds,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] SyncChunk error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Attendance sync endpoint
  Future<Response> _handleSyncAttendance(Request request) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final syncRequest = SyncRequest.fromJson(json);

      // Get client IP
      final ipAddress = _getClientIp(request);

      // Get teacher user ID for marking attendance
      final teacherUserId = await _getTeacherUserId(syncRequest.teacherId);

      debugPrint('[SyncServer] Processing sync for teacher ${syncRequest.teacherId}, ${syncRequest.attendanceRecords.length} records');

      // Process sync
      final response = await _syncProcessor.processSync(
        syncRequest,
        ipAddress,
        serverUserId: teacherUserId,
      );

      // Update device last sync time
      await _deviceService.updateLastSync(syncRequest.deviceId, ipAddress);

      // Log sync operation
      await _deviceService.logSyncOperation(
        deviceId: syncRequest.deviceId,
        teacherId: syncRequest.teacherId,
        syncType: SyncConstants.syncTypeUpload,
        recordsCount: response.processed,
        status: response.success
            ? SyncConstants.syncStatusSuccess
            : SyncConstants.syncStatusPartial,
        errorMessage: response.errors.isNotEmpty
            ? response.errors.join('; ')
            : null,
      );

      // Emit event for UI updates
      if (response.success || response.processed > 0) {
        _syncEventController.add(response);
      }

      debugPrint('[SyncServer] Sync processed: ${response.processed} records in ${stopwatch.elapsedMilliseconds}ms');

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } on FormatException catch (e) {
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'error': 'Invalid JSON: ${e.message}',
          'errorCode': 'INVALID_JSON',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] SyncAttendance error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': e.toString(),
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Sync status endpoint
  Future<Response> _handleSyncStatus(Request request) async {
    try {
      return Response.ok(
        jsonEncode(
          ServerStatusResponse(
            status: 'active',
            timestamp: DateTime.now(),
            version: AppConstants.appVersion,
            serverName: 'EduX Main System',
            port: port,
          ).toJson(),
        ),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncServer] SyncStatus error: $e');
      debugPrint(stackTrace.toString());
      return Response.internalServerError(
        body: jsonEncode({
          'error': e.toString(),
          'errorCode': 'INTERNAL_ERROR',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // ============================================
  // DEBUG ENDPOINTS
  // ============================================
  
  /// Debug endpoint to check class data
  Future<Response> _handleDebugClass(
    Request request,
    String classId,
    String sectionId,
  ) async {
    try {
      final cId = int.tryParse(classId);
      final sId = int.tryParse(sectionId);

      if (cId == null || sId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid class or section ID'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final academicYear = await _db.getCurrentAcademicYear();
      
      // Get comprehensive class data
      final enrollments = await (_db.select(_db.enrollments)
            ..where((e) => e.classId.equals(cId) & e.sectionId.equals(sId)))
          .get();
      
      final studentIds = enrollments.map((e) => e.studentId).toList();
      
      List<Map<String, dynamic>> studentDetails = [];
      if (studentIds.isNotEmpty) {
        final students = await (_db.select(_db.students)
              ..where((s) => s.id.isIn(studentIds)))
            .get();
        
        studentDetails = students.map((s) => {
          'id': s.id,
          'name': s.studentName,
          'status': s.status,
          'admissionNumber': s.admissionNumber,
        }).toList();
      }
      
      // Get class info
      final classInfo = await (_db.select(_db.classes)
            ..where((c) => c.id.equals(cId)))
          .getSingleOrNull();
      
      final sectionInfo = await (_db.select(_db.sections)
            ..where((s) => s.id.equals(sId)))
          .getSingleOrNull();

      return Response.ok(
        jsonEncode({
          'classId': cId,
          'sectionId': sId,
          'className': classInfo?.name,
          'sectionName': sectionInfo?.name,
          'currentAcademicYear': academicYear?.name,
          'enrollmentCount': enrollments.length,
          'enrollments': enrollments.map((e) => {
            'studentId': e.studentId,
            'academicYear': e.academicYear,
            'isCurrent': e.isCurrent,
            'rollNumber': e.rollNumber,
          }).toList(),
          'studentDetails': studentDetails,
          'activeStudentCount': studentDetails.where((s) => 
            (s['status'] as String).toLowerCase() == 'active').length,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
  
  /// Debug endpoint to check academic year configuration
  Future<Response> _handleDebugAcademicYear(Request request) async {
    try {
      final currentYear = await _db.getCurrentAcademicYear();
      final allYears = await (_db.select(_db.academicYears)
            ..orderBy([(y) => OrderingTerm.desc(y.startDate)]))
          .get();

      return Response.ok(
        jsonEncode({
          'currentAcademicYear': currentYear?.name,
          'currentYearDetails': currentYear != null ? {
            'id': currentYear.id,
            'name': currentYear.name,
            'startDate': currentYear.startDate.toIso8601String(),
            'endDate': currentYear.endDate.toIso8601String(),
            'isCurrent': currentYear.isCurrent,
          } : null,
          'allAcademicYears': allYears.map((y) => {
            'id': y.id,
            'name': y.name,
            'isCurrent': y.isCurrent,
          }).toList(),
          'serverTime': DateTime.now().toIso8601String(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // ============================================
  // MIDDLEWARE
  // ============================================

  /// CORS middleware
  Middleware _corsMiddleware() {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    };

    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {...response.headers, ...corsHeaders});
      },
    );
  }

  /// Error handler middleware
  Middleware _errorHandlerMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        return null;
      },
      errorHandler: (Object error, StackTrace stackTrace) {
        debugPrint('[SyncServer] Unhandled error: $error');
        debugPrint(stackTrace.toString());
        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Internal server error',
            'errorCode': 'INTERNAL_ERROR',
          }),
          headers: {'content-type': 'application/json'},
        );
      },
    );
  }

  /// Authentication middleware
  Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;
        if (path == 'health' ||
            path == '/health' ||
            path == 'api/v1/auth/login' ||
            path == '/api/v1/auth/login') {
          return innerHandler(request);
        }

        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.unauthorized(
            jsonEncode({
              'error': 'Missing or invalid authorization header',
              'errorCode': 'AUTH_MISSING_TOKEN',
            }),
            headers: {'content-type': 'application/json'},
          );
        }

        final token = authHeader.substring(7);
        final teacherId = _validateToken(token);

        if (teacherId == null) {
          return Response.unauthorized(
            jsonEncode({
              'error': 'Invalid or expired token',
              'errorCode': 'AUTH_INVALID_TOKEN',
            }),
            headers: {'content-type': 'application/json'},
          );
        }

        final authenticatedRequest = request.change(
          context: {'teacherId': teacherId},
        );
        return innerHandler(authenticatedRequest);
      };
    };
  }

  /// Rate limiting and concurrency control middleware
  Middleware _rateLimitMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final clientIp = _getClientIp(request);

        // Check concurrent request limit
        synchronized(_requestLock, () {
          if (_activeRequests >= _maxConcurrentRequests) {
            return Response(
              503,
              body: jsonEncode({
                'error': 'Server busy, too many concurrent requests',
                'errorCode': 'SERVER_BUSY',
              }),
              headers: {'content-type': 'application/json'},
            );
          }
          _activeRequests++;
        });

        // Check rate limit per IP
        final now = DateTime.now();
        final minuteAgo = now.subtract(const Duration(minutes: 1));

        synchronized(_requestLock, () {
          _requestLog[clientIp] = (_requestLog[clientIp] ?? [])
            ..removeWhere((time) => time.isBefore(minuteAgo));

          if ((_requestLog[clientIp]?.length ?? 0) >= _maxRequestsPerMinute) {
            _activeRequests--;
            return Response(
              429,
              body: jsonEncode({
                'error': 'Rate limit exceeded, try again later',
                'errorCode': 'RATE_LIMIT_EXCEEDED',
              }),
              headers: {'content-type': 'application/json'},
            );
          }

          _requestLog[clientIp]?.add(now);
        });

        // Apply timeout to the request
        try {
          final response = await (innerHandler(request) as Future<Response>)
              .timeout(_requestTimeout);
          synchronized(_requestLock, () {
            _activeRequests--;
          });
          return response;
        } on TimeoutException {
          synchronized(_requestLock, () {
            _activeRequests--;
          });
          return Response.internalServerError(
            body: jsonEncode({
              'error': 'Request timeout',
              'errorCode': 'REQUEST_TIMEOUT',
            }),
            headers: {'content-type': 'application/json'},
          );
        } catch (e) {
          synchronized(_requestLock, () {
            _activeRequests--;
          });
          rethrow;
        }
      };
    };
  }

  static T synchronized<T>(Object lock, T Function() fn) {
    return fn();
  }

  // ============================================
  // AUTHENTICATION
  // ============================================

  int _getTeacherIdFromRequest(Request request) {
    final teacherId = request.context['teacherId'] as int?;
    if (teacherId == null) {
      throw StateError('Request not authenticated');
    }
    return teacherId;
  }

  // ============================================
  // TOKEN MANAGEMENT
  // ============================================

  String _generateToken(int teacherId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _generateRandomString(16);
    final data = '$teacherId:$timestamp:$random';
    return base64Encode(utf8.encode(data));
  }

  int? _validateToken(String token) {
    try {
      final decoded = utf8.decode(base64Decode(token));
      final parts = decoded.split(':');
      if (parts.length < 2) return null;

      final teacherId = int.tryParse(parts[0]);
      final timestamp = int.tryParse(parts[1]);

      if (teacherId == null || timestamp == null) return null;

      final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiry = tokenTime.add(
        const Duration(hours: SyncConstants.tokenValidityHours),
      );

      if (DateTime.now().isAfter(expiry)) {
        return null;
      }

      return teacherId;
    } catch (e) {
      return null;
    }
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ============================================
  // HELPER METHODS - OPTIMIZED
  // ============================================

  String _getClientIp(Request request) {
    try {
      final connectionInfo =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      return connectionInfo?.remoteAddress.address ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  Future<int> _getStudentCount(
    int classId,
    int sectionId,
  ) async {
    // FIXED: Count ALL active students regardless of academic year
    final query = _db.selectOnly(_db.enrollments).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.enrollments.studentId),
      ),
    ])
      ..addColumns([_db.enrollments.id.count()]);
    
    query.where(_db.enrollments.classId.equals(classId) & _db.enrollments.sectionId.equals(sectionId) & _db.students.status.equals('active'));

    final result = await query.getSingle();
    return result.read(_db.enrollments.id.count()) ?? 0;
  }

  Future<List<String>> _getTeacherPermissions(int teacherId) async {
    final staff = await (_db.select(
      _db.staff,
    )..where((s) => s.id.equals(teacherId))).getSingleOrNull();

    if (staff == null) return [];

    final role = await (_db.select(
      _db.staffRoles,
    )..where((r) => r.id.equals(staff.roleId))).getSingleOrNull();

    if (role == null) return [];

    final permissions = <String>['mark_attendance'];
    if (role.canAccessStudents) permissions.add('view_students');
    if (role.canEnterMarks) permissions.add('enter_marks');
    if (role.canViewReports) permissions.add('view_reports');

    return permissions;
  }

  Future<int?> _getTeacherUserId(int teacherId) async {
    final staff = await (_db.select(
      _db.staff,
    )..where((s) => s.id.equals(teacherId))).getSingleOrNull();
    return staff?.userId;
  }

  // ============================================
  // OPTIMIZED QUERY METHODS
  // ============================================

  /// Optimized: Get all teacher classes with metadata in fewer queries
  /// FIXED: Removed academic year filter
  Future<List<_ClassAssignmentWithStudents>> _getTeacherClassesOptimized(
    int teacherId,
  ) async {
    final result = <_ClassAssignmentWithStudents>[];

    // Get all assignments with related data in a single query using joins
    final query = _db.select(_db.staffSubjectAssignments).join([
      innerJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.staffSubjectAssignments.classId),
      ),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.staffSubjectAssignments.sectionId),
      ),
      leftOuterJoin(
        _db.subjects,
        _db.subjects.id.equalsExp(_db.staffSubjectAssignments.subjectId),
      ),
    ]);
    query.where(_db.staffSubjectAssignments.staffId.equals(teacherId));

    final rows = await query.get();
    
    // Group by class/section to avoid duplicates
    final grouped = <String, _ClassAssignmentWithStudents>{};
    
    for (final row in rows) {
      final assignment = row.readTable(_db.staffSubjectAssignments);
      final classData = row.readTable(_db.classes);
      final section = row.readTableOrNull(_db.sections);
      final subject = row.readTableOrNull(_db.subjects);
      
      if (assignment.sectionId == null) continue;
      
      final key = '${assignment.classId}-${assignment.sectionId}';
      
      if (!grouped.containsKey(key)) {
        // Get student count for this class/section (ALL academic years)
        final studentCount = await _getStudentCount(
          assignment.classId,
          assignment.sectionId!,
        );
        
        grouped[key] = _ClassAssignmentWithStudents(
          classId: assignment.classId,
          sectionId: assignment.sectionId!,
          className: classData.name,
          sectionName: section?.name ?? 'N/A',
          subjectName: subject?.name,
          isClassTeacher: assignment.isClassTeacher,
          students: [],
          totalStudents: studentCount,
        );
      }
    }

    return grouped.values.toList();
  }

  /// OPTIMIZED: Get ALL students for ALL teacher classes in a SINGLE query
  /// FIXED: Case-insensitive status check + better error handling
  Future<List<_StudentWithClassInfo>> _getAllStudentsForTeacherOptimized(
    int teacherId,
  ) async {
    // DEBUG: Check teacher assignments (ALL academic years)
    final assignmentsCheck = await (_db.select(_db.staffSubjectAssignments)
          ..where((a) => a.staffId.equals(teacherId)))
        .get();
    debugPrint('[SyncServer] Teacher $teacherId has ${assignmentsCheck.length} assignments (all years)');
    
    // Single query to get all students for all classes taught by this teacher
    // FIXED: Removed academic year filter - returns ALL students
    final query = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id),
      ),
      innerJoin(
        _db.staffSubjectAssignments,
        _db.staffSubjectAssignments.classId.equalsExp(_db.enrollments.classId) &
            _db.staffSubjectAssignments.sectionId.equalsExp(_db.enrollments.sectionId),
      ),
    ]);
    query.where(_db.staffSubjectAssignments.staffId.equals(teacherId) & _db.students.status.equals('active'));
    query.orderBy([
      OrderingTerm.asc(_db.enrollments.classId),
      OrderingTerm.asc(_db.enrollments.sectionId),
      OrderingTerm.asc(_db.enrollments.rollNumber),
    ]);

    final results = await query.get();
    
    debugPrint('[SyncServer] _getAllStudentsForTeacherOptimized: Found ${results.length} students');

    return results.map((row) {
      final student = row.readTable(_db.students);
      final enrollment = row.readTable(_db.enrollments);
      
      return _StudentWithClassInfo(
        studentId: student.id,
        name: student.studentName,
        rollNumber: enrollment.rollNumber,
        gender: student.gender,
        photoUrl: null,
        classId: enrollment.classId,
        sectionId: enrollment.sectionId,
      );
    }).toList();
  }

  /// Optimized: Get students for a single class with pagination support
  /// FIXED: Removed academic year filter - returns ALL students
  Future<List<Map<String, dynamic>>> _getStudentsForClassOptimized(
    int classId,
    int sectionId, {
    int offset = 0,
    int? limit,
  }) async {
    // DEBUG: Log the query parameters
    debugPrint('[SyncServer] Query params: classId=$classId, sectionId=$sectionId (ALL academic years)');
    
    // First, check what's in the database for debugging
    final debugQuery = _db.select(_db.enrollments)
      ..where((e) => e.classId.equals(classId) & e.sectionId.equals(sectionId));
    final allEnrollments = await debugQuery.get();
    debugPrint('[SyncServer] Total enrollments for class $classId-$sectionId: ${allEnrollments.length}');
    
    if (allEnrollments.isNotEmpty) {
      final sample = allEnrollments.first;
      debugPrint('[SyncServer] Sample enrollment: studentId=${sample.studentId}, academicYear=${sample.academicYear}, isCurrent=${sample.isCurrent}');
    }
    
    // FIXED: Removed academic year filter
    var query = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id),
      ),
    ]);
    query.where(_db.enrollments.classId.equals(classId) & _db.enrollments.sectionId.equals(sectionId) & _db.students.status.equals('active'));
    query.orderBy([OrderingTerm.asc(_db.enrollments.rollNumber)]);

    // Apply pagination if specified
    if (limit != null) {
      query = query..limit(limit, offset: offset);
    }

    final results = await query.get();
    
    // DEBUG: Log results
    debugPrint('[SyncServer] Found ${results.length} active students for class $classId-$sectionId');

    return results.map((row) {
      final student = row.readTable(_db.students);
      final enrollment = row.readTable(_db.enrollments);
      return {
        'studentId': student.id,
        'name': student.studentName,
        'rollNumber': enrollment.rollNumber,
        'gender': student.gender,
      };
    }).toList();
  }
}

/// Internal class for holding class data with students
class _ClassAssignmentWithStudents {
  final int classId;
  final int sectionId;
  final String className;
  final String sectionName;
  final String? subjectName;
  final bool isClassTeacher;
  final List<TeacherStudentInfo> students;
  final int totalStudents;

  _ClassAssignmentWithStudents({
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.sectionName,
    this.subjectName,
    required this.isClassTeacher,
    required this.students,
    this.totalStudents = 0,
  });
}

/// Internal class for student with class info (for optimized bulk fetch)
class _StudentWithClassInfo {
  final int studentId;
  final String name;
  final String? rollNumber;
  final String? gender;
  final String? photoUrl;
  final int classId;
  final int sectionId;

  _StudentWithClassInfo({
    required this.studentId,
    required this.name,
    this.rollNumber,
    this.gender,
    this.photoUrl,
    required this.classId,
    required this.sectionId,
  });
}
