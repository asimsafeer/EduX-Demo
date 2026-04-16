/// EduX School Management System
/// Expense Management Tables
library;

import 'package:drift/drift.dart';
import 'school_tables.dart';

/// Expenses table - tracks school expenditures
class Expenses extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Expense title/name
  TextColumn get title => text()();

  /// Expense category (e.g., utility, maintenance, supply, event, other)
  TextColumn get category => text()();

  /// Expense amount
  RealColumn get amount => real()();

  /// Expense date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  /// Description/Notes
  TextColumn get description => text().nullable()();

  /// Attachment path (receipt image/pdf)
  TextColumn get attachmentPath => text().nullable()();

  /// User who recorded the expense
  IntColumn get recordedBy => integer().nullable().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
