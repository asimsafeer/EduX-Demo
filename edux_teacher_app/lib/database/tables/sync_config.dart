/// EduX Teacher App - Sync Config Table
library;

import 'package:drift/drift.dart';

/// App configuration and sync state
@DataClassName('SyncConfigEntry')
class SyncConfig extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// Note: ConfigKeys is defined in lib/core/constants/app_constants.dart
