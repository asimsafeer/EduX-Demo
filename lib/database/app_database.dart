/// EduX School Management System
/// Main Drift Database Configuration
library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/demo/demo_config.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// Main application database
@DriftDatabase(
  tables: [
    // School & Authentication
    SchoolSettings,
    Users,
    AcademicYears,

    // Students
    Students,
    Guardians,
    StudentGuardians,
    Enrollments,

    // Academics
    Classes,
    Sections,
    Subjects,
    ClassSubjects,
    TimetableSlots,
    PeriodDefinitions,
    ClassWorkingDays,

    // Attendance
    StudentAttendance,
    StaffAttendance,

    // Examinations
    Exams,
    ExamSubjects,
    StudentMarks,
    GradeSettings,
    ExamResults,

    // Fees
    FeeTypes,
    FeeStructures,
    Invoices,
    InvoiceItems,
    AdHocInvoiceItems,
    Payments,
    Concessions,

    // Staff
    StaffRoles,
    Staff,
    LeaveTypes,
    LeaveRequests,
    StaffSubjectAssignments,
    Payroll,
    StaffTasks,
    DailyAttendanceStatus,

    // System
    ActivityLogs,
    Backups,
    SystemAlerts,
    PrintTemplates,
    NumberSequences,
    Expenses,
    Canteens,
    CanteenTransactions,

    // Sync
    SyncDevices,
    SyncLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Private constructor
  AppDatabase._internal([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// Singleton instance
  static AppDatabase? _instance;

  /// Get singleton database instance
  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Create an instance for testing
  @visibleForTesting
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase._internal(executor);
  }

  /// Set the singleton instance for testing
  @visibleForTesting
  static void setInstance(AppDatabase db) {
    _instance = db;
  }

  /// Reset the database instance
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }

  /// Database schema version
  @override
  int get schemaVersion => 14;

  /// Database migrations
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes();
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Optimize SQLite for better performance
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA synchronous = NORMAL');
        await customStatement('PRAGMA cache_size = 10000');
        await customStatement('PRAGMA temp_store = MEMORY');

        // Seed initial data if needed
        await _seedData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 12) {
          // Destructive migration: drop all tables and recreate
          final allTables = m.database.allTables.toList();
          for (final table in allTables) {
            await m.database.customStatement(
              'DROP TABLE IF EXISTS "${table.actualTableName}"',
            );
          }
          await m.createAll();
          await _createIndexes();
          return;
        }
        
        if (from < 13) {
          // Add performance indexes for sync operations
          await _createIndexes();
        }

        if (from < 14) {
          // Add showInClassStructure column to fee_types
          await m.database.customStatement(
            'ALTER TABLE fee_types ADD COLUMN show_in_class_structure INTEGER NOT NULL DEFAULT 1',
          );
          // Mark per-student fee types as not applicable to class-wide structure
          await m.database.customStatement(
            "UPDATE fee_types SET show_in_class_structure = 0 WHERE LOWER(name) IN ('transport fee','stationery','lab charges','others')",
          );
        }
      },
    );
  }
  
  /// Create performance indexes for sync and common queries
  Future<void> _createIndexes() async {
    // Indexes for sync queries (staff_subject_assignments)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_staff_subject_assignments_staff_year '
      'ON staff_subject_assignments(staff_id, academic_year)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_staff_subject_assignments_class_section '
      'ON staff_subject_assignments(class_id, section_id, academic_year)',
    );
    
    // Indexes for enrollment queries (critical for sync)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_enrollments_student_current '
      'ON enrollments(student_id, is_current)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_enrollments_class_section_year '
      'ON enrollments(class_id, section_id, academic_year, is_current)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_enrollments_academic_year_current '
      'ON enrollments(academic_year, is_current)',
    );
    
    // Index for student status
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_students_status '
      'ON students(status)',
    );
    
    // Index for staff user lookup
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_staff_user_id '
      'ON staff(user_id)',
    );
    
    // Indexes for attendance sync
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_student_attendance_student_date '
      'ON student_attendance(student_id, date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_student_attendance_class_date '
      'ON student_attendance(class_id, section_id, date)',
    );
    
    debugPrint('[AppDatabase] Performance indexes created successfully');
  }

  /// Seed initial data
  Future<void> _seedData() async {
    // 1. Seed Staff Roles
    final rolesCount = await select(staffRoles).get();
    if (rolesCount.isEmpty) {
      await batch((batch) {
        batch.insertAll(staffRoles, [
          StaffRolesCompanion.insert(
            name: 'Admin',
            description: const Value('System Administrator with full access'),
            canTeach: const Value(false),
            canAccessStudents: const Value(true),
            canAccessFees: const Value(true),
            canMarkAttendance: const Value(true),
            canEnterMarks: const Value(true),
            canViewReports: const Value(true),
            isSystem: const Value(true),
          ),
          StaffRolesCompanion.insert(
            name: 'Principal',
            description: const Value('School Principal'),
            canTeach: const Value(false),
            canAccessStudents: const Value(true),
            canAccessFees: const Value(true),
            canMarkAttendance: const Value(true),
            canEnterMarks: const Value(true),
            canViewReports: const Value(true),
            isSystem: const Value(true),
          ),
          StaffRolesCompanion.insert(
            name: 'Teacher',
            description: const Value('Teaching Staff'),
            canTeach: const Value(true),
            canAccessStudents: const Value(true),
            canMarkAttendance: const Value(true),
            canEnterMarks: const Value(true),
            isSystem: const Value(true),
          ),
          StaffRolesCompanion.insert(
            name: 'Accountant',
            description: const Value('Accounts Officer'),
            canAccessFees: const Value(true),
            canViewReports: const Value(true),
            isSystem: const Value(true),
          ),
          StaffRolesCompanion.insert(
            name: 'Staff',
            description: const Value('General Staff'),
            canViewReports: const Value(false),
            isSystem: const Value(true),
          ),
        ]);
      });
    }

    // 2. Seed Fee Types
    final feeTypesCount = await select(feeTypes).get();
    if (feeTypesCount.isEmpty) {
      await batch((batch) {
        batch.insertAll(feeTypes, [
          FeeTypesCompanion.insert(
            name: 'Tuition Fee',
            description: const Value('Monthly tuition fee'),
            isRefundable: const Value(false),
          ),
          FeeTypesCompanion.insert(
            name: 'Registration Fee',
            description: const Value('One-time registration fee'),
            isRefundable: const Value(false),
          ),
          FeeTypesCompanion.insert(
            name: 'Security Deposit',
            description: const Value('Refundable security deposit'),
            isRefundable: const Value(true),
          ),
          FeeTypesCompanion.insert(
            name: 'Exam Fee',
            description: const Value('Term examination fee'),
            isRefundable: const Value(false),
          ),
          FeeTypesCompanion.insert(
            name: 'Transport Fee',
            description: const Value('Monthly transport charges'),
            isRefundable: const Value(false),
          ),
          FeeTypesCompanion.insert(
            name: 'Lab Charges',
            description: const Value('Science laboratory charges'),
            isRefundable: const Value(false),
          ),
          FeeTypesCompanion.insert(
            name: 'Stationery',
            description: const Value('Books and stationery charges'),
            isRefundable: const Value(false),
          ),
        ]);
      });
    }

    // 3. Seed Leave Types
    final leaveTypesCount = await select(leaveTypes).get();
    if (leaveTypesCount.isEmpty) {
      await batch((batch) {
        batch.insertAll(leaveTypes, [
          LeaveTypesCompanion.insert(
            name: 'Casual Leave',
            maxDays: 10,
            isPaid: const Value(true),
          ),
          LeaveTypesCompanion.insert(
            name: 'Sick Leave',
            maxDays: 8,
            isPaid: const Value(true),
          ),
          LeaveTypesCompanion.insert(
            name: 'Earned Leave',
            maxDays: 14,
            isPaid: const Value(true),
          ),
          LeaveTypesCompanion.insert(
            name: 'Unpaid Leave',
            maxDays: 0,
            isPaid: const Value(false),
          ),
        ]);
      });
    }

    // 4. Seed Grade Settings
    final gradesCount = await select(gradeSettings).get();
    if (gradesCount.isEmpty) {
      await batch((batch) {
        batch.insertAll(gradeSettings, [
          GradeSettingsCompanion.insert(
            grade: 'A+',
            minPercentage: 90,
            maxPercentage: 100,
            gpa: 4.0,
            remarks: const Value('Excellent'),
            displayOrder: 1,
          ),
          GradeSettingsCompanion.insert(
            grade: 'A',
            minPercentage: 80,
            maxPercentage: 89.99,
            gpa: 3.7,
            remarks: const Value('Very Good'),
            displayOrder: 2,
          ),
          GradeSettingsCompanion.insert(
            grade: 'B+',
            minPercentage: 70,
            maxPercentage: 79.99,
            gpa: 3.3,
            remarks: const Value('Good'),
            displayOrder: 3,
          ),
          GradeSettingsCompanion.insert(
            grade: 'B',
            minPercentage: 60,
            maxPercentage: 69.99,
            gpa: 3.0,
            remarks: const Value('Satisfactory'),
            displayOrder: 4,
          ),
          GradeSettingsCompanion.insert(
            grade: 'C',
            minPercentage: 50,
            maxPercentage: 59.99,
            gpa: 2.5,
            remarks: const Value('Pass'),
            displayOrder: 5,
          ),
          GradeSettingsCompanion.insert(
            grade: 'D',
            minPercentage: 40,
            maxPercentage: 49.99,
            gpa: 2.0,
            remarks: const Value('Marginal Pass'),
            displayOrder: 6,
          ),
          GradeSettingsCompanion.insert(
            grade: 'F',
            minPercentage: 0,
            maxPercentage: 39.99,
            gpa: 0.0,
            remarks: const Value('Fail'),
            isPassing: const Value(false),
            displayOrder: 7,
          ),
        ]);
      });
    }

    // 5. Seed Number Types/Sequences
    final seqCount = await select(numberSequences).get();
    if (seqCount.isEmpty) {
      await batch((batch) {
        batch.insertAll(numberSequences, [
          NumberSequencesCompanion.insert(
            name: 'admission',
            prefix: const Value('ADM-'),
            currentNumber: const Value(0),
            minDigits: const Value(5),
          ),
          NumberSequencesCompanion.insert(
            name: 'invoice',
            prefix: const Value('INV-'),
            currentNumber: const Value(0),
            minDigits: const Value(6),
          ),
          NumberSequencesCompanion.insert(
            name: 'receipt',
            prefix: const Value('RCP-'),
            currentNumber: const Value(0),
            minDigits: const Value(6),
          ),
          NumberSequencesCompanion.insert(
            name: 'employee',
            prefix: const Value('EMP-'),
            currentNumber: const Value(0),
            minDigits: const Value(4),
          ),
        ]);
      });
    }
  }

  // ============================================
  // CONVENIENCE METHODS
  // ============================================

  /// Check if school is set up
  Future<bool> isSchoolSetup() async {
    final settings = await select(schoolSettings).getSingleOrNull();
    return settings?.isSetupComplete ?? false;
  }

  /// Get school settings
  Future<SchoolSetting?> getSchoolSettings() async {
    return await select(schoolSettings).getSingleOrNull();
  }

  /// Get current academic year
  Future<AcademicYear?> getCurrentAcademicYear() async {
    return await (select(
      academicYears,
    )..where((t) => t.isCurrent.equals(true))).getSingleOrNull();
  }

  /// Get admin user (to verify setup integrity)
  /// Get admin user (to verify setup integrity)
  Future<User?> getAdminUser() async {
    return await (select(users)
          ..where((u) => u.role.equals(UserRoles.admin))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Reset school settings (for recovery)
  Future<void> resetSchoolSettings() async {
    await delete(schoolSettings).go();
    // Also clear users to be safe, as we're resetting setup
    await delete(users).go();
  }
}

/// Opens a database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final File file;
    if (DemoConfig.isDemo) {
      // Demo: DB lives next to the executable so it ships with the zip
      final exeDir = p.dirname(Platform.resolvedExecutable);
      file = File(p.join(exeDir, 'data', 'edux_demo.db'));
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      file = File(p.join(dbFolder.path, 'edux', DbConstants.dbFileName));
    }

    // Ensure the directory exists
    await file.parent.create(recursive: true);

    return NativeDatabase.createInBackground(file);
  });
}
