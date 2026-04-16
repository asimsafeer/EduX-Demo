/// EduX School Management System
/// Academic management database tables
library;

import 'package:drift/drift.dart';

/// Classes table - school class definitions
@DataClassName('SchoolClass')
class Classes extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class name (e.g., "Playgroup", "Class 1", "Class 10")
  TextColumn get name => text().withLength(max: 50)();

  /// Class level (pre_primary, primary, middle, secondary)
  TextColumn get level => text()();

  /// Numeric grade level for sorting (0 for playgroup, 1 for nursery, etc.)
  IntColumn get gradeLevel => integer()();

  /// Display order for sorting
  IntColumn get displayOrder => integer()();

  /// Class description
  TextColumn get description => text().nullable()();

  /// Monthly tuition fee (default)
  RealColumn get monthlyFee => real().withDefault(const Constant(0))();

  /// Is class currently active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Sections table - class sections (A, B, C, etc.)
class Sections extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class foreign key
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// Section name (e.g., "A", "B", "C")
  TextColumn get name => text().withLength(max: 10)();

  /// Maximum capacity of students
  IntColumn get capacity => integer().nullable()();

  /// Class teacher (staff ID) - optional foreign key handled in query
  IntColumn get classTeacherId => integer().nullable()();

  /// Room number/name
  TextColumn get roomNumber => text().nullable()();

  /// Is section currently active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Subjects table - subject definitions
class Subjects extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Subject code (e.g., "ENG", "MATH")
  TextColumn get code => text().withLength(max: 10)();

  /// Subject name (e.g., "English", "Mathematics")
  TextColumn get name => text().withLength(max: 100)();

  /// Subject type (core, elective, optional)
  TextColumn get type => text().withDefault(const Constant('core'))();

  /// Credit hours per week
  IntColumn get creditHours => integer().nullable()();

  /// Subject description
  TextColumn get description => text().nullable()();

  /// Is subject currently active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Class-Subject relationship table
class ClassSubjects extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class foreign key
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// Subject foreign key
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();

  /// Assigned teacher (staff ID) - optional foreign key handled in query
  IntColumn get teacherId => integer().nullable()();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Periods per week
  IntColumn get periodsPerWeek => integer().withDefault(const Constant(0))();

  /// Is compulsory for this class
  BoolColumn get isCompulsory => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Timetable slots table
class TimetableSlots extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class foreign key
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// Section foreign key
  IntColumn get sectionId =>
      integer().references(Sections, #id, onDelete: KeyAction.cascade)();

  /// Subject foreign key
  IntColumn get subjectId => integer().references(Subjects, #id)();

  /// Teacher (staff ID) - optional foreign key handled in query
  IntColumn get teacherId => integer().nullable()();

  /// Day of week (monday, tuesday, etc.)
  TextColumn get dayOfWeek => text()();

  /// Period number (1, 2, 3, etc.)
  IntColumn get periodNumber => integer()();

  /// Start time (HH:mm format)
  TextColumn get startTime => text()();

  /// End time (HH:mm format)
  TextColumn get endTime => text()();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Is break period
  BoolColumn get isBreak => boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Period definitions table
class PeriodDefinitions extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Period number
  IntColumn get periodNumber => integer()();

  /// Period name (e.g., "Period 1", "Lunch Break")
  TextColumn get name => text()();

  /// Start time (HH:mm format)
  TextColumn get startTime => text()();

  /// End time (HH:mm format)
  TextColumn get endTime => text()();

  /// Duration in minutes
  IntColumn get durationMinutes => integer()();

  /// Is break period
  BoolColumn get isBreak => boolean().withDefault(const Constant(false))();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Display order
  IntColumn get displayOrder => integer()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Class-specific working days - allows different classes to have different working days
/// e.g., Playgroup (Mon-Fri) vs Class 1-10 (Mon-Sat)
class ClassWorkingDays extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class foreign key
  IntColumn get classId =>
      integer().references(Classes, #id, onDelete: KeyAction.cascade)();

  /// Comma-separated working days (e.g., "monday,tuesday,wednesday,thursday,friday")
  /// If null or empty, falls back to school default working days
  TextColumn get workingDays => text().nullable()();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
    'UNIQUE (class_id, academic_year)',
  ];
}
