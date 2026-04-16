/// EduX School Management System
/// Activity Log Service - Audit trail for all operations
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/database.dart';

/// Activity log service for audit trail
class ActivityLogService {
  final AppDatabase _db;

  ActivityLogService(this._db);

  /// Factory constructor using singleton database
  factory ActivityLogService.instance() =>
      ActivityLogService(AppDatabase.instance);

  // ============================================
  // LOG CREATION
  // ============================================

  /// Log an activity
  Future<void> log({
    int? userId,
    required String action,
    required String module,
    required String description,
    String? entityType,
    int? entityId,
    Map<String, dynamic>? details,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            userId: Value(userId),
            action: action,
            module: module,
            description: description,
            entityType: Value(entityType),
            entityId: Value(entityId),
            details: Value(details != null ? jsonEncode(details) : null),
            previousValues: Value(
              previousValues != null ? jsonEncode(previousValues) : null,
            ),
            newValues: Value(newValues != null ? jsonEncode(newValues) : null),
          ),
        );
  }

  // ============================================
  // CONVENIENCE METHODS
  // ============================================

  /// Log user login
  Future<void> logLogin(int userId, String username) async {
    await log(
      userId: userId,
      action: 'login',
      module: 'auth',
      description: 'User "$username" logged in',
    );
  }

  /// Log user logout
  Future<void> logLogout(int userId, String username) async {
    await log(
      userId: userId,
      action: 'logout',
      module: 'auth',
      description: 'User "$username" logged out',
    );
  }

  /// Log session restore
  Future<void> logSessionRestore(int userId, String username) async {
    await log(
      userId: userId,
      action: 'session_restore',
      module: 'auth',
      description: 'Session restored for user "$username"',
    );
  }

  /// Log create operation
  Future<void> logCreate({
    required int? userId,
    required String module,
    required String entityType,
    required int entityId,
    required String description,
    Map<String, dynamic>? newValues,
  }) async {
    await log(
      userId: userId,
      action: 'create',
      module: module,
      description: description,
      entityType: entityType,
      entityId: entityId,
      newValues: newValues,
    );
  }

  /// Log update operation
  Future<void> logUpdate({
    required int? userId,
    required String module,
    required String entityType,
    required int entityId,
    required String description,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
  }) async {
    await log(
      userId: userId,
      action: 'update',
      module: module,
      description: description,
      entityType: entityType,
      entityId: entityId,
      previousValues: previousValues,
      newValues: newValues,
    );
  }

  /// Log delete operation
  Future<void> logDelete({
    required int? userId,
    required String module,
    required String entityType,
    required int entityId,
    required String description,
    Map<String, dynamic>? deletedValues,
  }) async {
    await log(
      userId: userId,
      action: 'delete',
      module: module,
      description: description,
      entityType: entityType,
      entityId: entityId,
      previousValues: deletedValues,
    );
  }

  /// Log backup operation
  Future<void> logBackup({
    required int? userId,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    await log(
      userId: userId,
      action: 'backup',
      module: 'system',
      description: description,
      details: details,
    );
  }

  /// Log restore operation
  Future<void> logRestore({
    required int? userId,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    await log(
      userId: userId,
      action: 'restore',
      module: 'system',
      description: description,
      details: details,
    );
  }

  // ============================================
  // LOG QUERIES
  // ============================================

  /// Get activity logs with filters
  Future<List<ActivityLog>> getLogs({
    int? userId,
    String? action,
    String? module,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = _db.select(_db.activityLogs);

    // Apply filters
    if (userId != null) {
      query = query..where((l) => l.userId.equals(userId));
    }

    if (action != null && action.isNotEmpty) {
      query = query..where((l) => l.action.equals(action));
    }

    if (module != null && module.isNotEmpty) {
      query = query..where((l) => l.module.equals(module));
    }

    if (startDate != null) {
      query = query..where((l) => l.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((l) => l.createdAt.isSmallerOrEqualValue(endDate));
    }

    // Order by most recent first
    query = query..orderBy([(l) => OrderingTerm.desc(l.createdAt)]);

    // Apply pagination
    query = query..limit(limit, offset: offset);

    return await query.get();
  }

  /// Get recent logs (for dashboard)
  Future<List<ActivityLog>> getRecentLogs({int limit = 10}) async {
    return await getLogs(limit: limit);
  }

  /// Get logs for a specific entity
  Future<List<ActivityLog>> getEntityLogs({
    required String entityType,
    required int entityId,
    int limit = 50,
  }) async {
    final query = _db.select(_db.activityLogs)
      ..where((l) => l.entityType.equals(entityType))
      ..where((l) => l.entityId.equals(entityId))
      ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
      ..limit(limit);

    return await query.get();
  }

  /// Get total log count for pagination
  Future<int> getLogCount({
    int? userId,
    String? action,
    String? module,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getLogs(
      userId: userId,
      action: action,
      module: module,
      startDate: startDate,
      endDate: endDate,
      limit: 100000, // Large number to get all
    );
    return logs.length;
  }

  /// Get available modules for filtering
  Future<List<String>> getAvailableModules() async {
    final logs = await _db.select(_db.activityLogs).get();
    final modules = logs.map((l) => l.module).toSet().toList();
    modules.sort();
    return modules;
  }

  /// Get available actions for filtering
  Future<List<String>> getAvailableActions() async {
    final logs = await _db.select(_db.activityLogs).get();
    final actions = logs.map((l) => l.action).toSet().toList();
    actions.sort();
    return actions;
  }

  // ============================================
  // CLEANUP
  // ============================================

  /// Delete old logs (retention policy)
  Future<int> deleteOldLogs({int retentionDays = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    return await (_db.delete(
      _db.activityLogs,
    )..where((l) => l.createdAt.isSmallerThanValue(cutoffDate))).go();
  }
}

/// Extension to parse JSON from activity log
extension ActivityLogExtension on ActivityLog {
  /// Parse details JSON
  Map<String, dynamic>? get parsedDetails {
    if (details == null) return null;
    try {
      return jsonDecode(details!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Parse previous values JSON
  Map<String, dynamic>? get parsedPreviousValues {
    if (previousValues == null) return null;
    try {
      return jsonDecode(previousValues!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Parse new values JSON
  Map<String, dynamic>? get parsedNewValues {
    if (newValues == null) return null;
    try {
      return jsonDecode(newValues!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get action display name
  String get actionDisplayName {
    switch (action.toLowerCase()) {
      case 'login':
        return 'Login';
      case 'logout':
        return 'Logout';
      case 'session_restore':
        return 'Session Restored';
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      case 'backup':
        return 'Backup Created';
      case 'restore':
        return 'Data Restored';
      default:
        return action;
    }
  }

  /// Get module display name
  String get moduleDisplayName {
    switch (module.toLowerCase()) {
      case 'auth':
        return 'Authentication';
      case 'users':
        return 'User Management';
      case 'students':
        return 'Students';
      case 'staff':
        return 'Staff';
      case 'attendance':
        return 'Attendance';
      case 'exams':
        return 'Examinations';
      case 'fees':
        return 'Fees';
      case 'settings':
        return 'Settings';
      case 'system':
        return 'System';
      default:
        return module;
    }
  }
}
