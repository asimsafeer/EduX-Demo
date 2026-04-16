/// EduX Teacher App - Cached Students Table
library;

import 'package:drift/drift.dart';

/// Cached student roster for classes
@DataClassName('CachedStudent')
class CachedStudents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  TextColumn get name => text()();
  TextColumn get rollNumber => text().nullable()();
  TextColumn get gender => text()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
        'UNIQUE(student_id, class_id, section_id)',
      ];
}
