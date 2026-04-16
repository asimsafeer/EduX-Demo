/// EduX School Management System
/// Core database tables - School and User management
library;

import 'package:drift/drift.dart';

/// School settings table - stores school configuration
class SchoolSettings extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// School name
  TextColumn get schoolName => text().withLength(max: 200)();

  /// Institution type (School, College, Institute, Academy)
  TextColumn get institutionType =>
      text().withDefault(const Constant('School'))();

  /// School logo as binary data
  BlobColumn get logo => blob().nullable()();

  /// School address
  TextColumn get address => text().nullable()();

  /// City
  TextColumn get city => text().nullable()();

  /// State/Province
  TextColumn get state => text().nullable()();

  /// Postal code
  TextColumn get postalCode => text().nullable()();

  /// Country
  TextColumn get country => text().withDefault(const Constant('Pakistan'))();

  /// Phone number
  TextColumn get phone => text().nullable()();

  /// Alternate phone number
  TextColumn get alternatePhone => text().nullable()();

  /// Email address
  TextColumn get email => text().nullable()();

  /// Website URL
  TextColumn get website => text().nullable()();

  /// Principal name
  TextColumn get principalName => text().nullable()();

  /// Currency symbol for fee display
  TextColumn get currencySymbol => text().withDefault(const Constant('PKR'))();

  /// Current academic year (e.g., "2025-2026")
  TextColumn get currentAcademicYear => text().nullable()();

  /// Academic year start date
  DateTimeColumn get academicYearStart => dateTime().nullable()();

  /// Academic year end date
  DateTimeColumn get academicYearEnd => dateTime().nullable()();

  /// School working days (comma-separated, e.g., "monday,tuesday,...")
  TextColumn get workingDays => text().withDefault(
    const Constant('monday,tuesday,wednesday,thursday,friday,saturday'),
  )();

  /// Bank Name
  TextColumn get bankName => text().nullable()();

  /// Account Title
  TextColumn get accountTitle => text().nullable()();

  /// Account Number / IBAN
  TextColumn get accountNumber => text().nullable()();

  /// Online payment instructions/link
  TextColumn get onlinePaymentInfo => text().nullable()();

  /// School start time (HH:mm format)
  TextColumn get schoolStartTime =>
      text().withDefault(const Constant('08:00'))();

  /// School end time (HH:mm format)
  TextColumn get schoolEndTime => text().withDefault(const Constant('14:00'))();

  /// Is school setup complete
  BoolColumn get isSetupComplete =>
      boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Users table - system users with authentication
class Users extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for external references
  TextColumn get uuid => text().unique()();

  /// Username for login
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();

  /// Password hash (SHA-256)
  TextColumn get passwordHash => text()();

  /// Password salt
  TextColumn get passwordSalt => text()();

  /// User's full name
  TextColumn get fullName => text().withLength(max: 100)();

  /// Email address
  TextColumn get email => text().nullable()();

  /// Phone number
  TextColumn get phone => text().nullable()();

  /// User role (admin, principal, teacher, accountant)
  TextColumn get role => text()();

  /// Profile photo as binary data
  BlobColumn get photo => blob().nullable()();

  /// Is user account active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Is this the system administrator (cannot be deleted)
  BoolColumn get isSystemAdmin =>
      boolean().withDefault(const Constant(false))();

  /// Comma-separated list of permissions (e.g. "view_fees,manage_students")
  TextColumn get permissions => text().nullable()();

  /// Last login timestamp
  DateTimeColumn get lastLogin => dateTime().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Academic years table - track academic year configurations
class AcademicYears extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Academic year name (e.g., "2025-2026")
  TextColumn get name => text().unique()();

  /// Start date
  DateTimeColumn get startDate => dateTime()();

  /// End date
  DateTimeColumn get endDate => dateTime()();

  /// Is this the current active academic year
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  /// Is archived
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
