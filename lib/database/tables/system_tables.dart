/// EduX School Management System
/// System-level database tables
library;

import 'package:drift/drift.dart';
import 'school_tables.dart';

/// Activity logs table - audit trail
class ActivityLogs extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// User who performed the action (null for system actions)
  IntColumn get userId => integer().nullable().references(Users, #id)();

  /// Action type (login, logout, create, update, delete, export, import)
  TextColumn get action => text()();

  /// Module where action was performed
  TextColumn get module => text()();

  /// Entity type (student, staff, payment, etc.)
  TextColumn get entityType => text().nullable()();

  /// Entity ID that was affected
  IntColumn get entityId => integer().nullable()();

  /// Description of the action
  TextColumn get description => text()();

  /// Additional details (JSON format)
  TextColumn get details => text().nullable()();

  /// Previous values (for updates, JSON format)
  TextColumn get previousValues => text().nullable()();

  /// New values (for creates/updates, JSON format)
  TextColumn get newValues => text().nullable()();

  /// IP address (for future network scenarios)
  TextColumn get ipAddress => text().nullable()();

  /// Timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// System backups table - backup metadata
class Backups extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Backup file name
  TextColumn get fileName => text()();

  /// Full file path
  TextColumn get filePath => text()();

  /// File size in bytes
  IntColumn get fileSize => integer()();

  /// Backup type (manual, auto)
  TextColumn get type => text()();

  /// Backup description/notes
  TextColumn get description => text().nullable()();

  /// Database version at backup time
  IntColumn get dbVersion => integer()();

  /// App version at backup time
  TextColumn get appVersion => text()();

  /// Number of students at backup time
  IntColumn get studentCount => integer()();

  /// Number of staff at backup time
  IntColumn get staffCount => integer()();

  /// Created by (user ID)
  IntColumn get createdBy => integer().nullable().references(Users, #id)();

  /// Is backup valid/verified
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();

  /// Backup timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// System alerts table - notifications and warnings
class SystemAlerts extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Alert type (info, warning, error)
  TextColumn get type => text()();

  /// Alert category (attendance, fee, academic, staff, system)
  TextColumn get category => text()();

  /// Alert title
  TextColumn get title => text()();

  /// Alert message
  TextColumn get message => text()();

  /// Related entity type (optional)
  TextColumn get entityType => text().nullable()();

  /// Related entity ID (optional)
  IntColumn get entityId => integer().nullable()();

  /// Route to navigate when clicked (optional)
  TextColumn get actionRoute => text().nullable()();

  /// Action parameters (JSON, optional)
  TextColumn get actionParams => text().nullable()();

  /// Is alert read
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// Is alert dismissed
  BoolColumn get isDismissed => boolean().withDefault(const Constant(false))();

  /// Alert priority (1-5, 1 being highest)
  IntColumn get priority => integer().withDefault(const Constant(3))();

  /// Expires at (optional, for time-sensitive alerts)
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Created for specific user (null means all users)
  IntColumn get userId => integer().nullable().references(Users, #id)();

  /// Created timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Print templates table - customizable print layouts
class PrintTemplates extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Template name
  TextColumn get name => text()();

  /// Template type (report_card, receipt, invoice, certificate, etc.)
  TextColumn get type => text()();

  /// Template content (JSON configuration)
  TextColumn get content => text()();

  /// Is default template for this type
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Number sequences table - for generating sequential numbers
class NumberSequences extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Sequence name (admission_number, invoice_number, receipt_number, etc.)
  TextColumn get name => text().unique()();

  /// Prefix (e.g., "INV-", "RCP-")
  TextColumn get prefix => text().withDefault(const Constant(''))();

  /// Suffix
  TextColumn get suffix => text().withDefault(const Constant(''))();

  /// Current sequence number
  IntColumn get currentNumber => integer().withDefault(const Constant(0))();

  /// Minimum digits (pad with zeros)
  IntColumn get minDigits => integer().withDefault(const Constant(4))();

  /// Reset period (never, yearly, monthly)
  TextColumn get resetPeriod => text().withDefault(const Constant('never'))();

  /// Last reset date
  DateTimeColumn get lastResetDate => dateTime().nullable()();

  /// Include year in number
  BoolColumn get includeYear => boolean().withDefault(const Constant(true))();

  /// Include month in number
  BoolColumn get includeMonth => boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

