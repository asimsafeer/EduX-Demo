/// EduX School Management System
/// Attendance tracking database tables
library;

import 'package:drift/drift.dart';
import 'student_tables.dart';
import 'academic_tables.dart';
import 'school_tables.dart';

/// Student attendance table
class StudentAttendance extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Student foreign key
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();

  /// Class foreign key
  IntColumn get classId => integer().references(Classes, #id)();

  /// Section foreign key
  IntColumn get sectionId => integer().references(Sections, #id)();

  /// Attendance date
  DateTimeColumn get date => dateTime()();

  /// Attendance status (present, absent, late, leave)
  TextColumn get status => text()();

  /// Remarks/notes
  TextColumn get remarks => text().nullable()();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Marked by (user ID)
  IntColumn get markedBy => integer().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(student_id, date)'];
}

/// Staff attendance table
class StaffAttendance extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Staff ID (foreign key handled in query)
  IntColumn get staffId => integer()();

  /// Attendance date
  DateTimeColumn get date => dateTime()();

  /// Attendance status (present, absent, late, leave, half_day)
  TextColumn get status => text()();

  /// Check-in time (HH:mm format)
  TextColumn get checkIn => text().nullable()();

  /// Check-out time (HH:mm format)
  TextColumn get checkOut => text().nullable()();

  /// Remarks/notes
  TextColumn get remarks => text().nullable()();

  /// Marked by (user ID)
  IntColumn get markedBy => integer().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(staff_id, date)'];
}

/// Daily attendance status (locked/unlocked)
/// DailyAttendanceStatus table
@DataClassName('DailyAttendanceStatusData')
class DailyAttendanceStatus extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Class foreign key
  IntColumn get classId => integer().references(Classes, #id)();

  /// Section foreign key
  IntColumn get sectionId => integer().references(Sections, #id)();

  /// Date
  DateTimeColumn get date => dateTime()();

  /// Is locked
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();

  /// Locked by (user ID)
  IntColumn get lockedBy => integer().nullable().references(Users, #id)();

  /// Locked at
  DateTimeColumn get lockedAt => dateTime().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(class_id, section_id, date)'];
}
