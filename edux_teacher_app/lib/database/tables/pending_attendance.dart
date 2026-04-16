/// EduX Teacher App - Pending Attendance Table
library;

import 'package:drift/drift.dart';

/// Attendance marked offline, pending sync
@DataClassName('PendingAttendance')
class PendingAttendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get markedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get syncError => text().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE(student_id, date)',
      ];
}
