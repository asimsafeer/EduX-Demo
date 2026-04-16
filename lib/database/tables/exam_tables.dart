/// EduX School Management System
/// Examination system database tables
library;

import 'package:drift/drift.dart';
import 'student_tables.dart';
import 'academic_tables.dart';
import 'school_tables.dart';

/// Exams table - exam definitions
class Exams extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for external references
  TextColumn get uuid => text().unique()();

  /// Exam name (e.g., "Annual Exam 2026")
  TextColumn get name => text().withLength(max: 100)();

  /// Exam type (unit_test, monthly_test, term_exam, annual_exam, practice)
  TextColumn get type => text()();

  /// Academic year
  TextColumn get academicYear => text()();

  /// Class foreign key
  IntColumn get classId => integer().references(Classes, #id)();

  /// Exam start date
  DateTimeColumn get startDate => dateTime()();

  /// Exam end date
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Description/notes
  TextColumn get description => text().nullable()();

  /// Exam status (draft, active, completed)
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Created by (user ID)
  IntColumn get createdBy => integer().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exam subjects table - subjects included in an exam
class ExamSubjects extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Exam foreign key
  IntColumn get examId =>
      integer().references(Exams, #id, onDelete: KeyAction.cascade)();

  /// Subject foreign key
  IntColumn get subjectId => integer().references(Subjects, #id)();

  /// Maximum marks for this subject
  RealColumn get maxMarks => real()();

  /// Passing marks for this subject
  RealColumn get passingMarks => real()();

  /// Exam date for this subject
  DateTimeColumn get examDate => dateTime().nullable()();

  /// Exam time for this subject (HH:mm format)
  TextColumn get examTime => text().nullable()();

  /// Duration in minutes
  IntColumn get durationMinutes => integer().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Student marks table - marks obtained by students
class StudentMarks extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Exam foreign key
  IntColumn get examId =>
      integer().references(Exams, #id, onDelete: KeyAction.cascade)();

  /// Exam subject foreign key
  IntColumn get examSubjectId =>
      integer().references(ExamSubjects, #id, onDelete: KeyAction.cascade)();

  /// Student foreign key
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();

  /// Marks obtained
  RealColumn get marksObtained => real().nullable()();

  /// Is student absent for this exam
  BoolColumn get isAbsent => boolean().withDefault(const Constant(false))();

  /// Calculated grade (based on grade settings)
  TextColumn get grade => text().nullable()();

  /// Remarks/notes
  TextColumn get remarks => text().nullable()();

  /// Entered by (user ID)
  IntColumn get enteredBy => integer().references(Users, #id)();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(exam_subject_id, student_id)'];
}

/// Grade settings table - grading criteria
class GradeSettings extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Grade name (e.g., "A+", "A", "B+")
  TextColumn get grade => text().withLength(max: 5)();

  /// Minimum percentage for this grade
  RealColumn get minPercentage => real()();

  /// Maximum percentage for this grade
  RealColumn get maxPercentage => real()();

  /// GPA points
  RealColumn get gpa => real()();

  /// Remarks to show on report card
  TextColumn get remarks => text().nullable()();

  /// Display order for sorting
  IntColumn get displayOrder => integer()();

  /// Is this grade a passing grade
  BoolColumn get isPassing => boolean().withDefault(const Constant(true))();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exam result summaries table (cached for performance)
class ExamResults extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Exam foreign key
  IntColumn get examId =>
      integer().references(Exams, #id, onDelete: KeyAction.cascade)();

  /// Student foreign key
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();

  /// Total marks obtained
  RealColumn get totalMarksObtained => real()();

  /// Total maximum marks
  RealColumn get totalMaxMarks => real()();

  /// Percentage
  RealColumn get percentage => real()();

  /// Overall grade
  TextColumn get overallGrade => text()();

  /// GPA
  RealColumn get gpa => real()();

  /// Rank in class
  IntColumn get classRank => integer().nullable()();

  /// Pass/Fail status
  BoolColumn get isPassed => boolean()();

  /// Teacher remarks
  TextColumn get teacherRemarks => text().nullable()();

  /// Principal remarks
  TextColumn get principalRemarks => text().nullable()();

  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Record update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(exam_id, student_id)'];
}
