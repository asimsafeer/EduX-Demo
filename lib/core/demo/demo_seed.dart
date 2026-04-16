/// EduX School Management System
/// Demo Data Seeder — populates the database with realistic sample data
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import 'demo_config.dart';

/// Seeds the database with demo data.
/// Idempotent — checks [AppDatabase.isSchoolSetup] before seeding.
class DemoSeed {
  DemoSeed._();

  static const _uuid = Uuid();

  /// Seed the database if it has not been set up yet.
  static Future<void> seedIfNeeded(AppDatabase db) async {
    if (!DemoConfig.isDemo) return;

    final isSetup = await db.isSchoolSetup();
    if (isSetup) {
      debugPrint('[DemoSeed] Database already seeded — skipping.');
      return;
    }

    debugPrint('[DemoSeed] Seeding demo data...');
    await _seed(db);
    debugPrint('[DemoSeed] Demo data seeded successfully.');
  }

  // ── Helpers ────────────────────────────────────────────────

  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  static String _hashPassword(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Main seed routine ──────────────────────────────────────

  static Future<void> _seed(AppDatabase db) async {
    final now = DateTime.now();
    final academicYear = DemoConfig.demoAcademicYear;
    final yearStart = DateTime(2025, 4, 1);
    final yearEnd = DateTime(2026, 3, 31);

    // ── 1. School Settings ─────────────────────────────────
    await db.into(db.schoolSettings).insert(
      SchoolSettingsCompanion.insert(
        schoolName: DemoConfig.demoSchoolName,
        institutionType: const Value('School'),
        address: const Value('123 Main Boulevard, Gulberg III'),
        city: const Value('Lahore'),
        state: const Value('Punjab'),
        country: const Value('Pakistan'),
        phone: const Value('042-35761234'),
        email: const Value('info@springfield.edu.pk'),
        principalName: const Value('Mr. Ahmed Khan'),
        currencySymbol: const Value('Rs.'),
        currentAcademicYear: Value(academicYear),
        academicYearStart: Value(yearStart),
        academicYearEnd: Value(yearEnd),
        workingDays: const Value(
          'monday,tuesday,wednesday,thursday,friday,saturday',
        ),
        schoolStartTime: const Value('08:00'),
        schoolEndTime: const Value('14:00'),
        isSetupComplete: const Value(true),
      ),
    );

    // ── 2. Academic Year ───────────────────────────────────
    await db.into(db.academicYears).insert(
      AcademicYearsCompanion.insert(
        name: academicYear,
        startDate: yearStart,
        endDate: yearEnd,
        isCurrent: const Value(true),
      ),
    );

    // ── 3. Admin User ──────────────────────────────────────
    final salt = _generateSalt();
    final hash = _hashPassword(DemoConfig.demoPassword, salt);

    await db.into(db.users).insert(
      UsersCompanion.insert(
        uuid: _uuid.v4(),
        username: DemoConfig.demoUsername,
        passwordHash: hash,
        passwordSalt: salt,
        fullName: 'Demo Administrator',
        role: 'admin',
        isActive: const Value(true),
        isSystemAdmin: const Value(true),
      ),
    );
    const adminUserId = 1; // first user

    // ── 4. Classes ─────────────────────────────────────────
    final classData = [
      ('Nursery', 'pre_primary', 1, 1500.0),
      ('KG', 'pre_primary', 2, 1800.0),
      ('Class 1', 'primary', 3, 2000.0),
      ('Class 2', 'primary', 4, 2000.0),
      ('Class 3', 'primary', 5, 2200.0),
    ];

    await db.batch((b) {
      for (var i = 0; i < classData.length; i++) {
        final (name, level, grade, fee) = classData[i];
        b.insert(
          db.classes,
          ClassesCompanion.insert(
            name: name,
            level: level,
            gradeLevel: grade,
            displayOrder: i + 1,
            monthlyFee: Value(fee),
          ),
        );
      }
    });

    // ── 5. Sections (2 per class) ──────────────────────────
    await db.batch((b) {
      for (var classId = 1; classId <= 5; classId++) {
        for (final section in ['A', 'B']) {
          b.insert(
            db.sections,
            SectionsCompanion.insert(
              classId: classId,
              name: section,
              capacity: const Value(30),
            ),
          );
        }
      }
    });

    // ── 6. Subjects ────────────────────────────────────────
    final subjectData = [
      ('ENG', 'English', 'core'),
      ('MATH', 'Mathematics', 'core'),
      ('URD', 'Urdu', 'core'),
      ('SCI', 'Science', 'core'),
      ('ISL', 'Islamiat', 'core'),
      ('GK', 'General Knowledge', 'elective'),
    ];

    await db.batch((b) {
      for (final (code, name, type) in subjectData) {
        b.insert(
          db.subjects,
          SubjectsCompanion.insert(
            code: code,
            name: name,
            type: Value(type),
          ),
        );
      }
    });

    // ── 7. Staff ───────────────────────────────────────────
    // Roles seeded by _seedData(): 1=Admin, 2=Principal, 3=Teacher, 4=Accountant, 5=Staff
    final staffList = [
      ('Ahmed', 'Khan', 'male', 'Principal', 2, 60000.0),
      ('Fatima', 'Zahra', 'female', 'Senior Teacher', 3, 35000.0),
      ('Muhammad', 'Ali', 'male', 'Teacher', 3, 30000.0),
      ('Ayesha', 'Siddiqui', 'female', 'Teacher', 3, 30000.0),
      ('Usman', 'Ghani', 'male', 'Teacher', 3, 28000.0),
      ('Zainab', 'Noor', 'female', 'Teacher', 3, 28000.0),
      ('Bilal', 'Ahmed', 'male', 'Teacher', 3, 25000.0),
      ('Hira', 'Malik', 'female', 'Teacher', 3, 25000.0),
      ('Hamza', 'Tariq', 'male', 'Teacher', 3, 22000.0),
      ('Sana', 'Raza', 'female', 'Teacher', 3, 22000.0),
      ('Imran', 'Hussain', 'male', 'Teacher', 3, 20000.0),
      ('Kashif', 'Mehmood', 'male', 'Accountant', 4, 32000.0),
    ];

    final joiningDate = DateTime(2024, 4, 1);

    await db.batch((b) {
      for (var i = 0; i < staffList.length; i++) {
        final (first, last, gender, designation, roleId, salary) = staffList[i];
        b.insert(
          db.staff,
          StaffCompanion.insert(
            uuid: _uuid.v4(),
            employeeId: 'EMP-${(i + 1).toString().padLeft(4, '0')}',
            firstName: first,
            lastName: last,
            gender: gender,
            phone: '0300${(1000000 + i).toString()}',
            designation: designation,
            roleId: roleId,
            basicSalary: salary,
            joiningDate: joiningDate,
          ),
        );
      }
    });

    // ── 8. Students ────────────────────────────────────────
    final maleNames = [
      'Abdullah', 'Hassan', 'Ibrahim', 'Zaid', 'Omar',
      'Yousuf', 'Daniyal', 'Rayyan', 'Aariz', 'Saad',
      'Faizan', 'Arham', 'Rehan', 'Shayan', 'Taha',
      'Uzair', 'Waqas', 'Junaid', 'Asad', 'Farhan',
      'Kashif', 'Moiz', 'Nabeel', 'Qasim', 'Rameez',
      'Shaheer', 'Talha', 'Waseem', 'Yasir', 'Zubair',
    ];

    final femaleNames = [
      'Amina', 'Fatima', 'Zara', 'Maryam', 'Aisha',
      'Hania', 'Inaya', 'Khadija', 'Laiba', 'Noor',
      'Rida', 'Sadia', 'Ume Habiba', 'Warda', 'Arooj',
      'Bushra', 'Dua', 'Esha', 'Ghazal', 'Hifza',
      'Javeria', 'Komal', 'Maham', 'Nimra', 'Palwasha',
      'Rabia', 'Samreen', 'Tayyaba', 'Urooj', 'Zunaira',
    ];

    final fatherNames = [
      'Muhammad Akram', 'Abdul Rashid', 'Khalid Mehmood',
      'Tariq Aziz', 'Shahid Iqbal', 'Naveed Ahmed',
      'Sajid Hussain', 'Wasim Raja', 'Amir Khan', 'Zahid Ali',
      'Rizwan Baig', 'Saleem Dar', 'Faisal Javed', 'Nasir Hayat',
      'Kamran Yousuf',
    ];

    final admissionDate = DateTime(2025, 4, 1);
    var maleIdx = 0;
    var femaleIdx = 0;
    var studentId = 0;

    // 12 students per class (6 per section)
    for (var classId = 1; classId <= 5; classId++) {
      for (var sectionOffset = 0; sectionOffset < 2; sectionOffset++) {
        final sectionId = (classId - 1) * 2 + sectionOffset + 1;
        for (var roll = 1; roll <= 6; roll++) {
          studentId++;
          final isMale = (studentId % 2 == 1);
          final name = isMale
              ? maleNames[maleIdx++ % maleNames.length]
              : femaleNames[femaleIdx++ % femaleNames.length];
          final father = fatherNames[(studentId - 1) % fatherNames.length];

          await db.into(db.students).insert(
            StudentsCompanion.insert(
              uuid: _uuid.v4(),
              admissionNumber: 'ADM-${studentId.toString().padLeft(5, '0')}',
              studentName: name,
              fatherName: Value(father),
              gender: isMale ? 'male' : 'female',
              admissionDate: admissionDate,
              status: const Value('active'),
              city: const Value('Lahore'),
              nationality: const Value('Pakistani'),
            ),
          );

          await db.into(db.enrollments).insert(
            EnrollmentsCompanion.insert(
              studentId: studentId,
              classId: classId,
              sectionId: sectionId,
              academicYear: academicYear,
              rollNumber: Value(roll.toString()),
              enrollmentDate: admissionDate,
              isCurrent: const Value(true),
            ),
          );
        }
      }
    }
    // Total: 60 students, 60 enrollments

    // Update number sequences for admission
    await (db.update(db.numberSequences)
          ..where((t) => t.name.equals('admission')))
        .write(
      NumberSequencesCompanion(currentNumber: Value(studentId)),
    );

    // ── 9. Class-Subject assignments ───────────────────────
    // Assign all 6 subjects to all 5 classes
    await db.batch((b) {
      for (var classId = 1; classId <= 5; classId++) {
        for (var subjectId = 1; subjectId <= 6; subjectId++) {
          b.insert(
            db.classSubjects,
            ClassSubjectsCompanion.insert(
              classId: classId,
              subjectId: subjectId,
              academicYear: academicYear,
              periodsPerWeek: const Value(5),
            ),
          );
        }
      }
    });

    // ── 10. Staff-Subject assignments ──────────────────────
    // Distribute teachers (staffId 2..11) across classes
    var teacherIdx = 2; // staff IDs 2-11 are teachers
    await db.batch((b) {
      for (var classId = 1; classId <= 5; classId++) {
        for (var sectionOffset = 0; sectionOffset < 2; sectionOffset++) {
          final sectionId = (classId - 1) * 2 + sectionOffset + 1;
          // Assign 3 core subjects per section to rotating teachers
          for (var subjectId = 1; subjectId <= 3; subjectId++) {
            b.insert(
              db.staffSubjectAssignments,
              StaffSubjectAssignmentsCompanion.insert(
                staffId: teacherIdx,
                classId: classId,
                sectionId: Value(sectionId),
                subjectId: subjectId,
                academicYear: academicYear,
                isClassTeacher: Value(subjectId == 1), // first teacher is CT
              ),
            );
            teacherIdx = (teacherIdx >= 11) ? 2 : teacherIdx + 1;
          }
        }
      }
    });

    // ── 11. Attendance (last 5 school days) ────────────────
    final rng = Random(42); // deterministic for consistency
    final recentDays = _getRecentSchoolDays(now, 5);

    await db.batch((b) {
      for (final day in recentDays) {
        for (var sid = 1; sid <= 60; sid++) {
          // Determine class/section from student order
          final cIdx = ((sid - 1) ~/ 12); // 0-4
          final classId = cIdx + 1;
          final sOffset = ((sid - 1) % 12) < 6 ? 0 : 1;
          final sectionId = cIdx * 2 + sOffset + 1;

          // ~85% present, ~10% absent, ~5% late
          final roll = rng.nextDouble();
          final status =
              roll < 0.85 ? 'present' : (roll < 0.95 ? 'absent' : 'late');

          b.insert(
            db.studentAttendance,
            StudentAttendanceCompanion.insert(
              studentId: sid,
              classId: classId,
              sectionId: sectionId,
              date: day,
              status: status,
              academicYear: academicYear,
              markedBy: adminUserId,
            ),
          );
        }
      }
    });

    // ── 12. Exam + Marks ───────────────────────────────────
    // Create one exam per class
    for (var classId = 1; classId <= 5; classId++) {
      final examId = await db.into(db.exams).insert(
        ExamsCompanion.insert(
          uuid: _uuid.v4(),
          name: 'Mid-Term Exam 2025',
          type: 'term_exam',
          academicYear: academicYear,
          classId: classId,
          startDate: DateTime(2025, 6, 15),
          endDate: Value(DateTime(2025, 6, 25)),
          status: const Value('completed'),
          createdBy: adminUserId,
        ),
      );

      // Add 3 exam subjects: English, Math, Urdu
      final examSubjectIds = <int>[];
      for (var subjectId = 1; subjectId <= 3; subjectId++) {
        final esId = await db.into(db.examSubjects).insert(
          ExamSubjectsCompanion.insert(
            examId: examId,
            subjectId: subjectId,
            maxMarks: 100,
            passingMarks: 40,
            examDate: Value(DateTime(2025, 6, 14 + subjectId * 2)),
          ),
        );
        examSubjectIds.add(esId);
      }

      // Enter marks for students in this class (12 students)
      final startSid = (classId - 1) * 12 + 1;
      final endSid = startSid + 12;
      await db.batch((b) {
        for (var sid = startSid; sid < endSid; sid++) {
          for (final esId in examSubjectIds) {
            final marks = 45.0 + rng.nextInt(51); // 45-95
            b.insert(
              db.studentMarks,
              StudentMarksCompanion.insert(
                examId: examId,
                examSubjectId: esId,
                studentId: sid,
                marksObtained: Value(marks),
                enteredBy: adminUserId,
              ),
            );
          }
        }
      });
    }

    // ── 13. Fee Structures ─────────────────────────────────
    // Tuition fee (feeTypeId=1) per class
    await db.batch((b) {
      for (var classId = 1; classId <= 5; classId++) {
        final fee = classData[classId - 1].$4;
        b.insert(
          db.feeStructures,
          FeeStructuresCompanion.insert(
            classId: classId,
            feeTypeId: 1, // Tuition Fee
            amount: fee,
            academicYear: academicYear,
            effectiveFrom: yearStart,
          ),
        );
      }
    });

    // ── 14. Invoices & Payments ────────────────────────────
    var invoiceSeq = 0;
    var receiptSeq = 0;

    for (var sid = 1; sid <= 60; sid++) {
      invoiceSeq++;
      final classIdx = ((sid - 1) ~/ 12);
      final fee = classData[classIdx].$4;
      final invoiceNum = 'INV-${invoiceSeq.toString().padLeft(6, '0')}';
      final issueDate = DateTime(2025, 4, 5);
      final dueDate = DateTime(2025, 4, 15);

      // Decide status: first 40 paid, next 15 partial, last 5 pending
      final String status;
      final double paidAmount;
      if (sid <= 40) {
        status = 'paid';
        paidAmount = fee;
      } else if (sid <= 55) {
        status = 'partial';
        paidAmount = (fee * 0.5).roundToDouble();
      } else {
        status = 'pending';
        paidAmount = 0;
      }

      final balance = fee - paidAmount;

      await db.into(db.invoices).insert(
        InvoicesCompanion.insert(
          invoiceNumber: invoiceNum,
          studentId: sid,
          month: 'April 2025',
          academicYear: academicYear,
          totalAmount: fee,
          netAmount: fee,
          paidAmount: Value(paidAmount),
          balanceAmount: balance,
          status: Value(status),
          issueDate: issueDate,
          dueDate: dueDate,
          lastPaymentDate: paidAmount > 0 ? Value(DateTime(2025, 4, 10)) : const Value.absent(),
          generatedBy: adminUserId,
        ),
      );

      // Invoice item
      await db.into(db.invoiceItems).insert(
        InvoiceItemsCompanion.insert(
          invoiceId: invoiceSeq, // matches auto-increment
          feeTypeId: 1,
          description: 'Tuition Fee - April 2025',
          amount: fee,
          netAmount: fee,
        ),
      );

      // Payment record for paid/partial
      if (paidAmount > 0) {
        receiptSeq++;
        await db.into(db.payments).insert(
          PaymentsCompanion.insert(
            receiptNumber: 'RCP-${receiptSeq.toString().padLeft(6, '0')}',
            invoiceId: invoiceSeq,
            studentId: sid,
            amount: paidAmount,
            paymentMode: 'cash',
            paymentDate: DateTime(2025, 4, 10),
            receivedBy: adminUserId,
          ),
        );
      }
    }

    // Update number sequences
    await db.batch((b) {
      b.replace(
        db.numberSequences,
        NumberSequencesCompanion(
          id: const Value(2), // invoice sequence
          name: const Value('invoice'),
          prefix: const Value('INV-'),
          currentNumber: Value(invoiceSeq),
          minDigits: const Value(6),
        ),
      );
      b.replace(
        db.numberSequences,
        NumberSequencesCompanion(
          id: const Value(3), // receipt sequence
          name: const Value('receipt'),
          prefix: const Value('RCP-'),
          currentNumber: Value(receiptSeq),
          minDigits: const Value(6),
        ),
      );
      b.replace(
        db.numberSequences,
        NumberSequencesCompanion(
          id: const Value(4), // employee sequence
          name: const Value('employee'),
          prefix: const Value('EMP-'),
          currentNumber: Value(staffList.length),
          minDigits: const Value(4),
        ),
      );
    });
  }

  /// Returns the last [count] weekdays (Mon-Sat) before [from].
  static List<DateTime> _getRecentSchoolDays(DateTime from, int count) {
    final days = <DateTime>[];
    var d = DateTime(from.year, from.month, from.day)
        .subtract(const Duration(days: 1));
    while (days.length < count) {
      // Mon=1 .. Sat=6 are school days, Sun=7 is off
      if (d.weekday != DateTime.sunday) {
        days.add(d);
      }
      d = d.subtract(const Duration(days: 1));
    }
    return days.reversed.toList();
  }
}
