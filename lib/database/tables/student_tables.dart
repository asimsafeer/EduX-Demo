/// EduX School Management System
/// Student and Guardian database tables
library;

import 'package:drift/drift.dart';

import 'academic_tables.dart';

/// Students table - complete student information
class Students extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for external references
  TextColumn get uuid => text().unique()();

  /// Unique admission number
  TextColumn get admissionNumber => text().unique()();

  /// Student's name
  TextColumn get studentName => text().withLength(min: 1, max: 50)();

  /// Father's name
  /// Father's name
  TextColumn get fatherName => text().nullable()();

  /// Father's occupation
  TextColumn get fatherOccupation => text().nullable()();

  /// Date of birth
  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  /// Gender (male, female)
  TextColumn get gender => text()();

  /// Blood group
  TextColumn get bloodGroup => text().nullable()();

  /// Religion
  TextColumn get religion => text().nullable()();

  /// Cast/Caste
  TextColumn get cast => text().nullable()();

  /// Mother Tongue
  TextColumn get motherTongue => text().nullable()();

  /// Nationality
  TextColumn get nationality =>
      text().withDefault(const Constant('Pakistani'))();

  /// CNIC/B-Form number
  TextColumn get cnic => text().nullable()();

  /// Residential address
  TextColumn get address => text().nullable()();

  /// City
  TextColumn get city => text().nullable()();

  /// Phone number
  TextColumn get phone => text().nullable()();

  /// Email address
  TextColumn get email => text().nullable()();

  /// Student photo as binary data
  BlobColumn get photo => blob().nullable()();

  /// Medical information/notes
  TextColumn get medicalInfo => text().nullable()();

  /// Known allergies
  TextColumn get allergies => text().nullable()();

  /// Special needs/requirements
  TextColumn get specialNeeds => text().nullable()();

  /// Previous school name
  TextColumn get previousSchool => text().nullable()();

  /// Student status (active, inactive, graduated, withdrawn, transferred)
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Date of admission
  DateTimeColumn get admissionDate => dateTime()();

  /// Date of leaving (if applicable)
  DateTimeColumn get leavingDate => dateTime().nullable()();

  /// Reason for leaving
  TextColumn get leavingReason => text().nullable()();

  /// Additional notes
  TextColumn get notes => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Guardians table - parent/guardian information
class Guardians extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for external references
  TextColumn get uuid => text().unique()();

  /// Guardian's first name
  TextColumn get firstName => text().withLength(min: 1, max: 50)();

  /// Guardian's last name
  TextColumn get lastName => text().withLength(min: 1, max: 50)();

  /// Relation to student (father, mother, guardian, etc.)
  TextColumn get relation => text()();

  /// CNIC number
  TextColumn get cnic => text().nullable()();

  /// Primary phone number
  TextColumn get phone => text()();

  /// Alternate phone number
  TextColumn get alternatePhone => text().nullable()();

  /// Email address
  TextColumn get email => text().nullable()();

  /// Occupation/Profession
  TextColumn get occupation => text().nullable()();

  /// Workplace name
  TextColumn get workplace => text().nullable()();

  /// Residential address
  TextColumn get address => text().nullable()();

  /// City
  TextColumn get city => text().nullable()();

  /// Guardian photo as binary data
  BlobColumn get photo => blob().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Student-Guardian relationship table (many-to-many)
class StudentGuardians extends Table {
  /// Student foreign key
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();

  /// Guardian foreign key
  IntColumn get guardianId =>
      integer().references(Guardians, #id, onDelete: KeyAction.cascade)();

  /// Is this the primary guardian for the student
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Can this guardian pick up the student
  BoolColumn get canPickup => boolean().withDefault(const Constant(true))();

  /// Is emergency contact
  BoolColumn get isEmergencyContact =>
      boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {studentId, guardianId};
}

/// Student enrollments table - class enrollment history
class Enrollments extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Student foreign key
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();

  /// Class foreign key
  IntColumn get classId => integer().references(Classes, #id)();

  /// Section foreign key
  IntColumn get sectionId => integer().references(Sections, #id)();

  /// Academic year (e.g., "2025-2026")
  TextColumn get academicYear => text()();

  /// Roll number within the class/section
  TextColumn get rollNumber => text().nullable()();

  /// Enrollment date
  DateTimeColumn get enrollmentDate => dateTime()();

  /// End date (null if current enrollment)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Enrollment status (active, promoted, transferred, withdrawn)
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Is this the current enrollment
  BoolColumn get isCurrent => boolean().withDefault(const Constant(true))();

  /// Notes about enrollment/promotion
  TextColumn get notes => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
