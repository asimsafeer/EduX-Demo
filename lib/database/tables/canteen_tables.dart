/// EduX School Management System
/// Canteen/Tuck Shop Management Tables
library;

import 'package:drift/drift.dart';
import 'school_tables.dart';

/// Canteen/Tuck Shop definitions
class Canteens extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Shop name
  TextColumn get name => text().withLength(max: 100)();

  /// Operator/Contractor name
  TextColumn get operatorName => text().withLength(max: 100)();

  /// Operator contact number
  TextColumn get operatorPhone => text().withLength(max: 20).nullable()();

  /// Business model (rent, profit_share)
  TextColumn get businessModel => text().withDefault(const Constant('rent'))();

  /// Monthly rent amount (for rent model)
  RealColumn get monthlyRent => real().withDefault(const Constant(0))();

  /// School's current investment (for profit share model)
  RealColumn get totalInvestment => real().withDefault(const Constant(0))();

  /// Is currently active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Canteen financial transactions (Rent payments, Profit shares, Investments)
class CanteenTransactions extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Canteen foreign key
  IntColumn get canteenId =>
      integer().references(Canteens, #id, onDelete: KeyAction.cascade)();

  /// Transaction type (income_rent, income_profit, expense_investment, expense_maintenance)
  TextColumn get type => text()();

  /// Transaction amount
  RealColumn get amount => real()();

  /// Transaction date
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  /// Description/Notes
  TextColumn get description => text().nullable()();

  /// User who recorded the transaction
  IntColumn get recordedBy => integer().nullable().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
