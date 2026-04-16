/// EduX School Management System
/// Sync-related database tables for teacher mobile app synchronization
library;

import 'package:drift/drift.dart';
import 'staff_tables.dart';

/// Sync devices table - tracks registered teacher mobile devices
class SyncDevices extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Device UUID (from mobile device)
  TextColumn get deviceId => text().unique()();

  /// User-friendly device name
  TextColumn get deviceName => text().nullable()();

  /// Teacher/staff foreign key
  IntColumn get teacherId => integer().references(Staff, #id)();

  /// Last sync timestamp
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  /// Is device active (can sync)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Device registration timestamp
  DateTimeColumn get registeredAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Last known IP address
  TextColumn get lastIpAddress => text().nullable()();

  /// Sync token for incremental sync
  TextColumn get syncToken => text().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE(device_id, teacher_id)',
      ];
}

/// Sync logs table - audit trail for all sync operations
class SyncLogs extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Device UUID reference
  TextColumn get deviceId => text().references(SyncDevices, #deviceId)();

  /// Teacher/staff foreign key
  IntColumn get teacherId => integer().references(Staff, #id)();

  /// Sync type: 'upload', 'download', 'full'
  TextColumn get syncType => text()();

  /// Number of records processed
  IntColumn get recordsCount => integer().withDefault(const Constant(0))();

  /// Status: 'success', 'partial', 'failed'
  TextColumn get status => text()();

  /// Error message if failed
  TextColumn get errorMessage => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
