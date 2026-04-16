/// EduX Teacher App - Cached Classes Table
library;

import 'package:drift/drift.dart';

/// Cached class/section assignments for teacher
@DataClassName('CachedClass')
class CachedClasses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer()();
  IntColumn get sectionId => integer()();
  TextColumn get className => text()();
  TextColumn get sectionName => text()();
  TextColumn get subjectName => text().nullable()();
  IntColumn get totalStudents => integer().withDefault(const Constant(0))();
  BoolColumn get isClassTeacher => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
        'UNIQUE(class_id, section_id)',
      ];
}
