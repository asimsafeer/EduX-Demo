/// EduX School Management System
/// Staff management database tables
library;

import 'package:drift/drift.dart';
import 'school_tables.dart';
import 'academic_tables.dart';

/// Staff roles table
class StaffRoles extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Role name (e.g., "Teacher", "Accountant")
  TextColumn get name => text().withLength(max: 50).unique()();

  /// Role description
  TextColumn get description => text().nullable()();

  /// Can this role teach classes
  BoolColumn get canTeach => boolean().withDefault(const Constant(false))();

  /// Can access student records
  BoolColumn get canAccessStudents =>
      boolean().withDefault(const Constant(true))();

  /// Can access fee management
  BoolColumn get canAccessFees =>
      boolean().withDefault(const Constant(false))();

  /// Can mark attendance
  BoolColumn get canMarkAttendance =>
      boolean().withDefault(const Constant(false))();

  /// Can enter exam marks
  BoolColumn get canEnterMarks =>
      boolean().withDefault(const Constant(false))();

  /// Can view reports
  BoolColumn get canViewReports =>
      boolean().withDefault(const Constant(true))();

  /// Display order
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// Is system role (cannot be deleted)
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Staff table - employee information
class Staff extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for external references
  TextColumn get uuid => text().unique()();

  /// Unique employee ID
  TextColumn get employeeId => text().unique()();

  /// First name
  TextColumn get firstName => text().withLength(min: 1, max: 50)();

  /// Last name
  TextColumn get lastName => text().withLength(min: 1, max: 50)();

  /// Date of birth
  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  /// Gender (male, female)
  TextColumn get gender => text()();

  /// CNIC number
  TextColumn get cnic => text().nullable()();

  /// Primary phone number
  TextColumn get phone => text()();

  /// Alternate phone number
  TextColumn get alternatePhone => text().nullable()();

  /// Email address
  TextColumn get email => text().nullable()();

  /// Residential address
  TextColumn get address => text().nullable()();

  /// City
  TextColumn get city => text().nullable()();

  /// Staff photo as binary data
  BlobColumn get photo => blob().nullable()();

  /// Highest qualification
  TextColumn get qualification => text().nullable()();

  /// Specialization/Subject expertise
  TextColumn get specialization => text().nullable()();

  /// Years of experience
  IntColumn get experienceYears => integer().nullable()();

  /// Previous employer
  TextColumn get previousEmployer => text().nullable()();

  /// Designation/Job title
  TextColumn get designation => text()();

  /// Department
  TextColumn get department => text().nullable()();

  /// Staff role foreign key
  IntColumn get roleId => integer().references(StaffRoles, #id)();

  /// Basic salary
  RealColumn get basicSalary => real()();

  /// Date of joining
  DateTimeColumn get joiningDate => dateTime()();

  /// Date of leaving (if applicable)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Employment status (active, on_leave, resigned, terminated)
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Bank name for salary
  TextColumn get bankName => text().nullable()();

  /// Bank account number
  TextColumn get accountNumber => text().nullable()();

  /// Emergency contact name
  TextColumn get emergencyContactName => text().nullable()();

  /// Emergency contact phone
  TextColumn get emergencyContactPhone => text().nullable()();

  /// Notes
  TextColumn get notes => text().nullable()();

  /// Is linked to a user account
  IntColumn get userId => integer().nullable().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Leave types table
class LeaveTypes extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Leave type name (e.g., "Sick Leave", "Casual Leave")
  TextColumn get name => text().withLength(max: 50)();

  /// Description
  TextColumn get description => text().nullable()();

  /// Maximum days allowed per year
  IntColumn get maxDays => integer()();

  /// Is paid leave
  BoolColumn get isPaid => boolean().withDefault(const Constant(true))();

  /// Can be carried forward to next year
  BoolColumn get canCarryForward =>
      boolean().withDefault(const Constant(false))();

  /// Maximum days that can be carried forward
  IntColumn get maxCarryForwardDays =>
      integer().withDefault(const Constant(0))();

  /// Is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Leave requests table
class LeaveRequests extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Staff foreign key
  IntColumn get staffId =>
      integer().references(Staff, #id, onDelete: KeyAction.cascade)();

  /// Leave type foreign key
  IntColumn get leaveTypeId => integer().references(LeaveTypes, #id)();

  /// Leave start date
  DateTimeColumn get startDate => dateTime()();

  /// Leave end date
  DateTimeColumn get endDate => dateTime()();

  /// Total days of leave
  IntColumn get totalDays => integer()();

  /// Is half day leave
  BoolColumn get isHalfDay => boolean().withDefault(const Constant(false))();

  /// Reason for leave
  TextColumn get reason => text()();

  /// Request status (pending, approved, rejected)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Approved/Rejected by (user ID)
  IntColumn get approvedBy => integer().nullable().references(Users, #id)();

  /// Approval/Rejection date
  DateTimeColumn get actionDate => dateTime().nullable()();

  /// Remarks from approver
  TextColumn get remarks => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Staff subject assignments table
class StaffSubjectAssignments extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Staff foreign key
  IntColumn get staffId =>
      integer().references(Staff, #id, onDelete: KeyAction.cascade)();

  /// Class foreign key
  IntColumn get classId => integer().references(Classes, #id)();

  /// Section foreign key (null means all sections)
  IntColumn get sectionId => integer().nullable().references(Sections, #id)();

  /// Subject foreign key
  IntColumn get subjectId => integer().references(Subjects, #id)();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Is class teacher for this class/section
  BoolColumn get isClassTeacher =>
      boolean().withDefault(const Constant(false))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Payroll table - salary records
class Payroll extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Staff foreign key
  IntColumn get staffId =>
      integer().references(Staff, #id, onDelete: KeyAction.cascade)();

  /// Payroll month (YYYY-MM format)
  TextColumn get month => text()();

  /// Basic salary for this month
  RealColumn get basicSalary => real()();

  /// Total allowances
  RealColumn get allowances => real().withDefault(const Constant(0))();

  /// Allowances breakdown (JSON)
  TextColumn get allowancesBreakdown => text().nullable()();

  /// Total deductions
  RealColumn get deductions => real().withDefault(const Constant(0))();

  /// Deductions breakdown (JSON)
  TextColumn get deductionsBreakdown => text().nullable()();

  /// Net salary (basic + allowances - deductions)
  RealColumn get netSalary => real()();

  /// Working days in month
  IntColumn get workingDays => integer()();

  /// Days present
  IntColumn get daysPresent => integer()();

  /// Days absent
  IntColumn get daysAbsent => integer()();

  /// Leave days (paid)
  IntColumn get leaveDays => integer().withDefault(const Constant(0))();

  /// Payment status (pending, paid)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Payment date
  DateTimeColumn get paidDate => dateTime().nullable()();

  /// Payment mode (cash, bank_transfer, cheque)
  TextColumn get paymentMode => text().nullable()();

  /// Reference number
  TextColumn get referenceNumber => text().nullable()();

  /// Remarks
  TextColumn get remarks => text().nullable()();

  /// Processed by (user ID)
  IntColumn get processedBy => integer().nullable().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(staff_id, month)'];
}

/// Staff tasks table
class StaffTasks extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Staff foreign key
  IntColumn get staffId =>
      integer().references(Staff, #id, onDelete: KeyAction.cascade)();

  /// Task title
  TextColumn get title => text().withLength(max: 100)();

  /// Task description
  TextColumn get description => text().nullable()();

  /// Due date
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Priority (low, medium, high)
  TextColumn get priority => text().withDefault(const Constant('medium'))();

  /// Status (pending, in_progress, completed)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Assigned by (user ID)
  IntColumn get assignedBy => integer().nullable().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
