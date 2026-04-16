/// EduX School Management System
/// Sync device service - manages registered teacher devices
library;

import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../models/models.dart';

/// Service for managing sync devices
class SyncDeviceService {
  final AppDatabase _db;

  SyncDeviceService(this._db);

  /// Factory constructor using singleton database
  factory SyncDeviceService.instance() => SyncDeviceService(AppDatabase.instance);

  // ============================================
  // DEVICE REGISTRATION
  // ============================================

  /// Register a new device or update existing one
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

  /// Unregister a device by device UUID
  Future<bool> unregisterDevice(String deviceId) async {
    final result = await (_db.delete(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .go();
    return result > 0;
  }

  // ============================================
  // DEVICE QUERIES
  // ============================================

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

    return query
        .map((row) => SyncDeviceModel.fromRow(
              row,
              row.read<String>('teacher_name'),
            ))
        .toList();
  }

  /// Get devices for a specific teacher
  Future<List<SyncDevice>> getDevicesForTeacher(int teacherId) async {
    return await (_db.select(_db.syncDevices)
          ..where((d) => d.teacherId.equals(teacherId)))
        .get();
  }

  /// Get device count
  Future<int> getDeviceCount() async {
    final query = _db.selectOnly(_db.syncDevices)
      ..addColumns([_db.syncDevices.id.count()]);
    final result = await query.getSingle();
    return result.read(_db.syncDevices.id.count()) ?? 0;
  }

  /// Get active device count
  Future<int> getActiveDeviceCount() async {
    final query = _db.selectOnly(_db.syncDevices)
      ..addColumns([_db.syncDevices.id.count()])
      ..where(_db.syncDevices.isActive.equals(true));
    final result = await query.getSingle();
    return result.read(_db.syncDevices.id.count()) ?? 0;
  }

  // ============================================
  // DEVICE MANAGEMENT
  // ============================================

  /// Revoke device access (deactivate)
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

  /// Update sync token
  Future<void> updateSyncToken(String deviceId, String syncToken) async {
    await (_db.update(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .write(SyncDevicesCompanion(
          syncToken: Value(syncToken),
        ));
  }

  // ============================================
  // AUTHORIZATION
  // ============================================

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

  /// Check if device exists (regardless of active status)
  Future<bool> deviceExists(String deviceId) async {
    final device = await (_db.select(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return device != null;
  }

  /// Check if device is active
  Future<bool> isDeviceActive(String deviceId) async {
    final device = await (_db.select(_db.syncDevices)
          ..where((d) => d.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return device?.isActive ?? false;
  }

  // ============================================
  // SYNC LOGS
  // ============================================

  /// Log a sync operation
  Future<void> logSyncOperation({
    required String deviceId,
    required int teacherId,
    required String syncType,
    required int recordsCount,
    required String status,
    String? errorMessage,
  }) async {
    await _db.into(_db.syncLogs).insert(SyncLogsCompanion(
      deviceId: Value(deviceId),
      teacherId: Value(teacherId),
      syncType: Value(syncType),
      recordsCount: Value(recordsCount),
      status: Value(status),
      errorMessage: Value(errorMessage),
    ));
  }

  /// Get sync logs for a device
  Future<List<SyncLog>> getDeviceLogs(String deviceId,
      {int limit = 50}) async {
    return await (_db.select(_db.syncLogs)
          ..where((l) => l.deviceId.equals(deviceId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get all sync logs
  Future<List<SyncLog>> getAllLogs({int limit = 100}) async {
    return await (_db.select(_db.syncLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get sync logs for a teacher
  Future<List<SyncLog>> getTeacherLogs(int teacherId, {int limit = 50}) async {
    return await (_db.select(_db.syncLogs)
          ..where((l) => l.teacherId.equals(teacherId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Clear old sync logs (keep last N days)
  Future<int> clearOldLogs(int daysToKeep) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    return await (_db.delete(_db.syncLogs)
          ..where((l) => l.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
