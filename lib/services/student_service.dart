/// EduX School Management System
/// Student Service - Business logic for student management
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/student_repository.dart';
import '../repositories/guardian_repository.dart';
import '../repositories/enrollment_repository.dart';

/// Validation result for student data
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult({required this.isValid, this.errors = const {}});

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(Map<String, String> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// Student creation/update data transfer object
class StudentFormData {
  final String studentName;
  final String fatherName;
  final String? fatherOccupation;
  final String? cast;
  final String? motherTongue;
  final String? admissionNumber;
  final DateTime admissionDate;
  final String gender;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? religion;
  final String? nationality;
  final String? cnic;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
  final String? medicalInfo;
  final String? allergies;
  final String? specialNeeds;
  final String? previousSchool;
  final String? notes;
  final Uint8List? photo;
  final int classId;
  final int sectionId;
  final String academicYear;
  final String? rollNumber;
  final String status;

  const StudentFormData({
    required this.studentName,
    required this.fatherName,
    this.fatherOccupation,
    this.cast,
    this.motherTongue,
    this.admissionNumber,
    required this.admissionDate,
    required this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.religion,
    this.nationality,
    this.cnic,
    this.address,
    this.city,
    this.phone,
    this.email,
    this.medicalInfo,
    this.allergies,
    this.specialNeeds,
    this.previousSchool,
    this.notes,
    this.photo,
    required this.classId,
    required this.sectionId,
    required this.academicYear,
    this.rollNumber,
    this.status = 'active',
  });
}

/// Student service for business logic
class StudentService {
  final AppDatabase _db;
  final StudentRepository _studentRepo;
  final GuardianRepository _guardianRepo;
  final EnrollmentRepository _enrollmentRepo;
  final _uuid = const Uuid();

  StudentService(this._db)
    : _studentRepo = StudentRepositoryImpl(_db),
      _guardianRepo = GuardianRepositoryImpl(_db),
      _enrollmentRepo = EnrollmentRepositoryImpl(_db);

  /// Validate student form data
  Future<ValidationResult> validateStudent(
    StudentFormData data, {
    int? excludeStudentId,
  }) async {
    final errors = <String, String>{};

    // Student name validation
    if (data.studentName.trim().isEmpty) {
      errors['studentName'] = 'Student name is required';
    } else if (data.studentName.trim().length < 2) {
      errors['studentName'] = 'Student name must be at least 2 characters';
    } else if (data.studentName.trim().length > 50) {
      errors['studentName'] = 'Student name must be at most 50 characters';
    }

    // Father name validation (Optional now)
    /*
    if (data.fatherName.trim().isEmpty) {
      errors['fatherName'] = 'Father name is required';
    } else if (data.fatherName.trim().length < 2) {
      errors['fatherName'] = 'Father name must be at least 2 characters';
    } else if (data.fatherName.trim().length > 50) {
      errors['fatherName'] = 'Father name must be at most 50 characters';
    }
    */

    // Admission number validation
    if (data.admissionNumber != null && data.admissionNumber!.isNotEmpty) {
      final isUnique = await _studentRepo.isAdmissionNumberUnique(
        data.admissionNumber!,
        excludeId: excludeStudentId,
      );
      if (!isUnique) {
        errors['admissionNumber'] = 'Admission number already exists';
      }
    }

    // Gender validation
    if (data.gender.isEmpty) {
      errors['gender'] = 'Gender is required';
    } else if (!['male', 'female'].contains(data.gender.toLowerCase())) {
      errors['gender'] = 'Invalid gender value';
    }

    // Email validation (if provided)
    if (data.email != null && data.email!.isNotEmpty) {
      if (!_isValidEmail(data.email!)) {
        errors['email'] = 'Invalid email format';
      }
    }

    // Phone validation (if provided)
    if (data.phone != null && data.phone!.isNotEmpty) {
      if (!_isValidPhone(data.phone!)) {
        errors['phone'] = 'Invalid phone number format';
      }
    }

    // CNIC validation (if provided)
    if (data.cnic != null && data.cnic!.isNotEmpty) {
      if (!_isValidCnic(data.cnic!)) {
        errors['cnic'] = 'Invalid CNIC format (should be XXXXX-XXXXXXX-X)';
      }
    }

    // Class/Section validation
    if (data.classId <= 0) {
      errors['classId'] = 'Please select a class';
    }
    if (data.sectionId <= 0) {
      errors['sectionId'] = 'Please select a section';
    }

    // Date of birth validation
    if (data.dateOfBirth != null) {
      if (data.dateOfBirth!.isAfter(DateTime.now())) {
        errors['dateOfBirth'] = 'Date of birth cannot be in the future';
      }
      // Check if age is reasonable (between 3 and 25 years)
      final age = DateTime.now().difference(data.dateOfBirth!).inDays ~/ 365;
      if (age < 3) {
        errors['dateOfBirth'] = 'Student must be at least 3 years old';
      } else if (age > 25) {
        errors['dateOfBirth'] = 'Please verify the date of birth';
      }
    }

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  /// Create a new student with enrollment
  Future<int> createStudent(StudentFormData data) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    // Validate first
    final validation = await validateStudent(data);
    if (!validation.isValid) {
      throw ValidationException(validation.errors);
    }

    // Generate admission number if not provided
    final admissionNumber =
        data.admissionNumber ?? await _studentRepo.generateAdmissionNumber();

    // Create student
    final studentId = await _studentRepo.create(
      StudentsCompanion.insert(
        uuid: _uuid.v4(),
        admissionNumber: admissionNumber,
        studentName: data.studentName.trim(),
        fatherName: Value(
          data.fatherName.trim().isEmpty ? null : data.fatherName.trim(),
        ),
        fatherOccupation: Value(data.fatherOccupation),
        cast: Value(data.cast),
        motherTongue: Value(data.motherTongue),
        admissionDate: data.admissionDate,
        gender: data.gender.toLowerCase(),
        dateOfBirth: Value(data.dateOfBirth),
        bloodGroup: Value(data.bloodGroup),
        religion: Value(data.religion),
        nationality: Value(data.nationality ?? 'Pakistani'),
        cnic: Value(data.cnic),
        address: Value(data.address),
        city: Value(data.city),
        phone: Value(data.phone),
        email: Value(data.email),
        medicalInfo: Value(data.medicalInfo),
        allergies: Value(data.allergies),
        specialNeeds: Value(data.specialNeeds),
        previousSchool: Value(data.previousSchool),
        notes: Value(data.notes),
        photo: Value(data.photo),
        status: Value(data.status),
      ),
    );

    // Create initial enrollment
    final rollNo = (data.rollNumber == null || data.rollNumber!.isEmpty)
        ? await _enrollmentRepo.generateNextRollNumber(
            data.classId,
            data.sectionId,
          )
        : data.rollNumber;

    await _enrollmentRepo.create(
      EnrollmentsCompanion.insert(
        studentId: studentId,
        classId: data.classId,
        sectionId: data.sectionId,
        academicYear: data.academicYear,
        enrollmentDate: data.admissionDate,
        rollNumber: Value(rollNo),
        status: Value(data.status),
        isCurrent: const Value(true),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'create',
      module: 'students',
      details:
          'Created student: ${data.studentName} ${data.fatherName} ($admissionNumber)',
    );

    return studentId;
  }

  /// Update an existing student
  Future<bool> updateStudent(int studentId, StudentFormData data) async {
    // Validate first
    final validation = await validateStudent(data, excludeStudentId: studentId);
    if (!validation.isValid) {
      throw ValidationException(validation.errors);
    }

    // Get existing student for comparison
    final existingStudent = await _studentRepo.getById(studentId);
    if (existingStudent == null) {
      throw NotFoundException('Student not found');
    }

    // Update student
    final updated = await _studentRepo.update(
      studentId,
      StudentsCompanion(
        studentName: Value(data.studentName.trim()),
        fatherName: Value(
          data.fatherName.trim().isEmpty ? null : data.fatherName.trim(),
        ),
        fatherOccupation: Value(data.fatherOccupation),
        cast: Value(data.cast),
        motherTongue: Value(data.motherTongue),
        gender: Value(data.gender.toLowerCase()),
        dateOfBirth: Value(data.dateOfBirth),
        bloodGroup: Value(data.bloodGroup),
        religion: Value(data.religion),
        nationality: Value(data.nationality ?? 'Pakistani'),
        cnic: Value(data.cnic),
        address: Value(data.address),
        city: Value(data.city),
        phone: Value(data.phone),
        email: Value(data.email),
        medicalInfo: Value(data.medicalInfo),
        allergies: Value(data.allergies),
        specialNeeds: Value(data.specialNeeds),
        previousSchool: Value(data.previousSchool),
        notes: Value(data.notes),
        photo: data.photo != null ? Value(data.photo) : const Value.absent(),
        status: Value(data.status),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Check if class/section/status changed
    final currentEnrollment = await _enrollmentRepo.getCurrentEnrollment(
      studentId,
    );
    if (currentEnrollment != null) {
      bool needsEnrollmentUpdate = false;
      var enrollmentUpdate = const EnrollmentsCompanion();

      // Check class/section/rollNo changes
      if (currentEnrollment.classId != data.classId ||
          currentEnrollment.sectionId != data.sectionId ||
          (data.rollNumber != null &&
              data.rollNumber != currentEnrollment.rollNumber)) {
        needsEnrollmentUpdate = true;
        // If class/section changed and no roll number provided, generate one
        final newRollNo = (data.rollNumber == null || data.rollNumber!.isEmpty)
            ? await _enrollmentRepo.generateNextRollNumber(
                data.classId,
                data.sectionId,
              )
            : data.rollNumber;

        enrollmentUpdate = enrollmentUpdate.copyWith(
          classId: Value(data.classId),
          sectionId: Value(data.sectionId),
          rollNumber: Value(newRollNo),
        );
      }

      // Check status change
      if (currentEnrollment.status != data.status) {
        needsEnrollmentUpdate = true;
        enrollmentUpdate = enrollmentUpdate.copyWith(
          status: Value(data.status),
        );
      }

      if (needsEnrollmentUpdate) {
        await _enrollmentRepo.update(
          currentEnrollment.id,
          enrollmentUpdate.copyWith(updatedAt: Value(DateTime.now())),
        );
      }
    }

    // Log activity
    await _logActivity(
      action: 'update',
      module: 'students',
      details: 'Updated student: ${data.studentName} ${data.fatherName}',
    );

    return updated;
  }

  /// Delete a student
  Future<bool> deleteStudent(int studentId) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final student = await _studentRepo.getById(studentId);
    if (student == null) {
      throw NotFoundException('Student not found');
    }

    final deleted = await _studentRepo.delete(studentId);

    if (deleted) {
      await _logActivity(
        action: 'delete',
        module: 'students',
        details:
            'Deleted student: ${student.studentName} ${student.fatherName} (${student.admissionNumber})',
      );
    }

    return deleted;
  }

  /// Delete multiple students
  Future<int> bulkDelete(List<int> ids) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    if (ids.isEmpty) return 0;

    final count = await _studentRepo.deleteMultiple(ids);

    if (count > 0) {
      await _logActivity(
        action: 'bulk_delete',
        module: 'students',
        details: 'Deleted $count students',
      );
    }

    return count;
  }

  /// Get student with full details
  Future<StudentWithEnrollment?> getStudentWithDetails(int studentId) async {
    return await _studentRepo.getWithCurrentEnrollment(studentId);
  }

  /// Get student guardians
  Future<List<StudentGuardianLink>> getStudentGuardians(int studentId) async {
    return await _guardianRepo.getByStudentId(studentId);
  }

  /// Add guardian to student
  Future<void> addGuardianToStudent(
    int studentId,
    int guardianId, {
    bool isPrimary = false,
    bool canPickup = true,
    bool isEmergencyContact = false,
  }) async {
    await _guardianRepo.linkToStudent(
      studentId,
      guardianId,
      isPrimary: isPrimary,
      canPickup: canPickup,
      isEmergencyContact: isEmergencyContact,
    );

    await _logActivity(
      action: 'link',
      module: 'students',
      details: 'Linked guardian ID $guardianId to student ID $studentId',
    );
  }

  /// Remove guardian from student
  Future<void> removeGuardianFromStudent(int studentId, int guardianId) async {
    await _guardianRepo.unlinkFromStudent(studentId, guardianId);

    await _logActivity(
      action: 'unlink',
      module: 'students',
      details: 'Unlinked guardian ID $guardianId from student ID $studentId',
    );
  }

  /// Promote student to next class
  Future<bool> promoteStudent(
    int studentId,
    int newClassId,
    int newSectionId,
    String newAcademicYear, {
    String? rollNumber,
  }) async {
    final student = await _studentRepo.getById(studentId);
    if (student == null) {
      throw NotFoundException('Student not found');
    }

    final result = await _enrollmentRepo.promoteStudent(
      studentId,
      newClassId,
      newSectionId,
      newAcademicYear,
      rollNumber: rollNumber,
    );

    if (result) {
      await _logActivity(
        action: 'promote',
        module: 'students',
        details:
            'Promoted student: ${student.studentName} ${student.fatherName}',
      );
    }

    return result;
  }

  /// Withdraw student from school
  Future<bool> withdrawStudent(
    int studentId, {
    required String reason,
    DateTime? leavingDate,
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final student = await _studentRepo.getById(studentId);
    if (student == null) {
      throw NotFoundException('Student not found');
    }

    final result = await _enrollmentRepo.withdrawStudent(
      studentId,
      reason: reason,
      leavingDate: leavingDate,
    );

    if (result) {
      await _logActivity(
        action: 'withdraw',
        module: 'students',
        details:
            'Withdrew student: ${student.studentName} ${student.fatherName}. Reason: $reason',
      );
    }

    return result;
  }

  /// Bulk update status for multiple students
  Future<int> bulkUpdateStatus(List<int> studentIds, String newStatus) async {
    if (studentIds.isEmpty) return 0;

    final count = await _studentRepo.bulkUpdateStatus(studentIds, newStatus);

    // Also update enrollment status for each student
    for (final studentId in studentIds) {
      final enrollment = await _enrollmentRepo.getCurrentEnrollment(studentId);
      if (enrollment != null) {
        await _enrollmentRepo.update(
          enrollment.id,
          EnrollmentsCompanion(
            status: Value(newStatus),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    if (count > 0) {
      await _logActivity(
        action: 'bulk_status_update',
        module: 'students',
        details: 'Updated status of $count students to $newStatus',
      );
    }

    return count;
  }

  /// Bulk promote students to a new class/section, or graduate them
  ///
  /// If [targetClassId] and [targetSectionId] are provided, students are
  /// promoted to that class. If they are null, students are graduated.
  Future<int> bulkPromoteStudents({
    required List<int> studentIds,
    int? targetClassId,
    int? targetSectionId,
    required String academicYear,
  }) async {
    if (studentIds.isEmpty) return 0;

    int promotedCount = 0;

    // If no target class, graduate all
    if (targetClassId == null || targetSectionId == null) {
      await bulkUpdateStatus(studentIds, 'graduated');
      // End their current enrollments
      for (final studentId in studentIds) {
        final enrollment = await _enrollmentRepo.getCurrentEnrollment(
          studentId,
        );
        if (enrollment != null) {
          await _enrollmentRepo.update(
            enrollment.id,
            EnrollmentsCompanion(
              isCurrent: const Value(false),
              status: const Value('graduated'),
              endDate: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      await _logActivity(
        action: 'bulk_graduate',
        module: 'students',
        details: 'Graduated ${studentIds.length} students',
      );
      return studentIds.length;
    }

    // Promote each student to the target class/section
    for (final studentId in studentIds) {
      try {
        await _enrollmentRepo.promoteStudent(
          studentId,
          targetClassId,
          targetSectionId,
          academicYear,
        );
        promotedCount++;
      } catch (e) {
        // Log but continue with others
        debugPrint('Failed to promote student $studentId: $e');
      }
    }

    if (promotedCount > 0) {
      await _logActivity(
        action: 'bulk_promote',
        module: 'students',
        details: 'Promoted $promotedCount students to new class',
      );
    }

    return promotedCount;
  }

  /// Get the next class (by gradeLevel) for promotion
  Future<SchoolClass?> getNextClass(int currentClassId) async {
    final currentClass = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(currentClassId))).getSingleOrNull();

    if (currentClass == null) return null;

    // Find the next class by gradeLevel
    final nextClass =
        await (_db.select(_db.classes)
              ..where(
                (t) =>
                    t.gradeLevel.isBiggerThanValue(currentClass.gradeLevel) &
                    t.isActive.equals(true),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.gradeLevel)])
              ..limit(1))
            .getSingleOrNull();

    return nextClass;
  }

  /// Check if a class is the highest level (no class with higher gradeLevel)
  Future<bool> isHighestClass(int classId) async {
    final nextClass = await getNextClass(classId);
    return nextClass == null;
  }

  /// Search students with filters
  Future<List<StudentWithEnrollment>> searchStudents(
    StudentFilters filters,
  ) async {
    return await _studentRepo.search(filters);
  }

  /// Get student count
  Future<int> getStudentCount({
    int? classId,
    int? sectionId,
    String? status,
    DateTime? admissionFrom,
    DateTime? admissionTo,
  }) async {
    return await _studentRepo.count(
      classId: classId,
      sectionId: sectionId,
      status: status,
      admissionFrom: admissionFrom,
      admissionTo: admissionTo,
    );
  }

  /// Get enrollment history
  Future<List<EnrollmentWithDetails>> getEnrollmentHistory(
    int studentId,
  ) async {
    return await _enrollmentRepo.getEnrollmentHistory(studentId);
  }

  // Private helper methods
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Pakistani phone format: 03XX-XXXXXXX or +92XXXXXXXXXX
    final phoneRegex = RegExp(r'^(\+92|0)?3[0-9]{2}[0-9]{7}$');
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return phoneRegex.hasMatch(cleanPhone);
  }

  bool _isValidCnic(String cnic) {
    // Pakistani CNIC format: XXXXX-XXXXXXX-X
    final cnicRegex = RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$');
    return cnicRegex.hasMatch(cnic);
  }

  Future<void> _logActivity({
    required String action,
    required String module,
    required String details,
  }) async {
    try {
      await _db
          .into(_db.activityLogs)
          .insert(
            ActivityLogsCompanion.insert(
              action: action,
              module: module,
              description: details,
              details: Value(details),
            ),
          );
    } catch (_) {
      // Silently ignore logging errors
    }
  }
}

/// Exception for validation errors
class ValidationException implements Exception {
  final Map<String, String> errors;

  ValidationException(this.errors);

  @override
  String toString() =>
      'Validation failed: ${errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
}

/// Exception for not found errors
class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => message;
}
