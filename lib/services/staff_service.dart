/// EduX School Management System
/// Staff Service - Business logic for staff management
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/staff_repository.dart';

/// Validation result for staff data
class StaffValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const StaffValidationResult({required this.isValid, required this.errors});
}

/// Staff creation/update data transfer object
class StaffFormData {
  final String? employeeId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String gender;
  final String? cnic;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? address;
  final String? city;
  final List<int>? photo;
  final String? qualification;
  final String? specialization;
  final int? experienceYears;
  final String? previousEmployer;
  final String designation;
  final String? department;
  final int roleId;
  final double basicSalary;
  final DateTime joiningDate;
  final DateTime? endDate;
  final String status;
  final String? bankName;
  final String? accountNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? notes;
  final int? userId;

  const StaffFormData({
    this.employeeId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.gender,
    this.cnic,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.address,
    this.city,
    this.photo,
    this.qualification,
    this.specialization,
    this.experienceYears,
    this.previousEmployer,
    required this.designation,
    this.department,
    required this.roleId,
    required this.basicSalary,
    required this.joiningDate,
    this.endDate,
    this.status = 'active',
    this.bankName,
    this.accountNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.notes,
    this.userId,
  });
}

/// Staff service for business logic
class StaffService {
  final AppDatabase _db;
  final StaffRepository _staffRepository;
  static const _uuid = Uuid();

  StaffService(this._db) : _staffRepository = StaffRepositoryImpl(_db);

  /// Validate staff form data
  Future<StaffValidationResult> validateStaff(
    StaffFormData data, {
    int? excludeStaffId,
  }) async {
    final errors = <String, String>{};

    // Required fields
    if (data.firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    } else if (data.firstName.trim().length < 2) {
      errors['firstName'] = 'First name must be at least 2 characters';
    }

    if (data.lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }

    if (data.phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!_isValidPhone(data.phone)) {
      errors['phone'] = 'Invalid phone number format';
    }

    if (data.gender.isEmpty) {
      errors['gender'] = 'Gender is required';
    }

    if (data.designation.trim().isEmpty) {
      errors['designation'] = 'Designation is required';
    }

    if (data.roleId <= 0) {
      errors['roleId'] = 'Role is required';
    } else {
      // Validate role exists
      final role = await _staffRepository.getRoleById(data.roleId);
      if (role == null) {
        errors['roleId'] = 'Invalid role selected';
      }
    }

    if (data.basicSalary <= 0) {
      errors['basicSalary'] = 'Salary must be greater than 0';
    }

    // Optional field validations
    if (data.email != null && data.email!.isNotEmpty) {
      if (!_isValidEmail(data.email!)) {
        errors['email'] = 'Invalid email format';
      }
    }

    if (data.cnic != null && data.cnic!.isNotEmpty) {
      if (!_isValidCnic(data.cnic!)) {
        errors['cnic'] = 'CNIC must be 13 digits (with or without dashes)';
      }
    }

    if (data.alternatePhone != null && data.alternatePhone!.isNotEmpty) {
      if (!_isValidPhone(data.alternatePhone!)) {
        errors['alternatePhone'] = 'Invalid alternate phone format';
      }
    }

    // Date validations
    if (data.dateOfBirth != null) {
      if (data.dateOfBirth!.isAfter(DateTime.now())) {
        errors['dateOfBirth'] = 'Date of birth cannot be in the future';
      }
      // Must be at least 18 years old
      final age = DateTime.now().difference(data.dateOfBirth!).inDays ~/ 365;
      if (age < 18) {
        errors['dateOfBirth'] = 'Staff member must be at least 18 years old';
      }
    }

    if (data.joiningDate.isAfter(
      DateTime.now().add(const Duration(days: 30)),
    )) {
      errors['joiningDate'] =
          'Joining date cannot be more than 30 days in future';
    }

    if (data.endDate != null && data.endDate!.isBefore(data.joiningDate)) {
      errors['endDate'] = 'End date cannot be before joining date';
    }

    // Employee ID uniqueness (if provided)
    if (data.employeeId != null && data.employeeId!.isNotEmpty) {
      final isUnique = await _staffRepository.isEmployeeIdUnique(
        data.employeeId!,
        excludeId: excludeStaffId,
      );
      if (!isUnique) {
        errors['employeeId'] = 'Employee ID already exists';
      }
    }

    return StaffValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Create a new staff member
  Future<int> createStaff(StaffFormData data) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    // Validate
    final validation = await validateStaff(data);
    if (!validation.isValid) {
      throw StaffValidationException(validation.errors);
    }

    // Generate employee ID if not provided
    final employeeId = data.employeeId?.isNotEmpty == true
        ? data.employeeId!
        : await _staffRepository.generateEmployeeId();

    // Create staff record
    final companion = StaffCompanion.insert(
      uuid: _uuid.v4(),
      employeeId: employeeId,
      firstName: data.firstName.trim(),
      lastName: data.lastName.trim(),
      dateOfBirth: Value(data.dateOfBirth),
      gender: data.gender,
      cnic: Value(data.cnic?.replaceAll('-', '')),
      phone: data.phone.trim(),
      alternatePhone: Value(data.alternatePhone?.trim()),
      email: Value(data.email?.trim().toLowerCase()),
      address: Value(data.address?.trim()),
      city: Value(data.city?.trim()),
      photo: Value(data.photo != null ? Uint8List.fromList(data.photo!) : null),
      qualification: Value(data.qualification?.trim()),
      specialization: Value(data.specialization?.trim()),
      experienceYears: Value(data.experienceYears),
      previousEmployer: Value(data.previousEmployer?.trim()),
      designation: data.designation.trim(),
      department: Value(data.department?.trim()),
      roleId: data.roleId,
      basicSalary: data.basicSalary,
      joiningDate: data.joiningDate,
      endDate: Value(data.endDate),
      status: Value(data.status),
      bankName: Value(data.bankName?.trim()),
      accountNumber: Value(data.accountNumber?.trim()),
      emergencyContactName: Value(data.emergencyContactName?.trim()),
      emergencyContactPhone: Value(data.emergencyContactPhone?.trim()),
      notes: Value(data.notes?.trim()),
      userId: Value(data.userId),
    );

    final id = await _staffRepository.create(companion);

    // Log activity
    await _logActivity(
      action: 'create',
      module: 'staff',
      details:
          'Created staff member: ${data.firstName} ${data.lastName} ($employeeId)',
    );

    return id;
  }

  /// Update an existing staff member
  Future<bool> updateStaff(int staffId, StaffFormData data) async {
    // Check staff exists
    final existing = await _staffRepository.getById(staffId);
    if (existing == null) {
      throw StaffNotFoundException('Staff member not found');
    }

    // Validate
    final validation = await validateStaff(data, excludeStaffId: staffId);
    if (!validation.isValid) {
      throw StaffValidationException(validation.errors);
    }

    // Update staff record
    final companion = StaffCompanion(
      firstName: Value(data.firstName.trim()),
      lastName: Value(data.lastName.trim()),
      dateOfBirth: Value(data.dateOfBirth),
      gender: Value(data.gender),
      cnic: Value(data.cnic?.replaceAll('-', '')),
      phone: Value(data.phone.trim()),
      alternatePhone: Value(data.alternatePhone?.trim()),
      email: Value(data.email?.trim().toLowerCase()),
      address: Value(data.address?.trim()),
      city: Value(data.city?.trim()),
      photo: Value(data.photo != null ? Uint8List.fromList(data.photo!) : null),
      qualification: Value(data.qualification?.trim()),
      specialization: Value(data.specialization?.trim()),
      experienceYears: Value(data.experienceYears),
      previousEmployer: Value(data.previousEmployer?.trim()),
      designation: Value(data.designation.trim()),
      department: Value(data.department?.trim()),
      roleId: Value(data.roleId),
      basicSalary: Value(data.basicSalary),
      joiningDate: Value(data.joiningDate),
      endDate: Value(data.endDate),
      status: Value(data.status),
      bankName: Value(data.bankName?.trim()),
      accountNumber: Value(data.accountNumber?.trim()),
      emergencyContactName: Value(data.emergencyContactName?.trim()),
      emergencyContactPhone: Value(data.emergencyContactPhone?.trim()),
      notes: Value(data.notes?.trim()),
      userId: Value(data.userId),
    );

    final success = await _staffRepository.update(staffId, companion);

    if (success) {
      await _logActivity(
        action: 'update',
        module: 'staff',
        details: 'Updated staff member: ${data.firstName} ${data.lastName}',
      );
    }

    return success;
  }

  /// Delete a staff member
  Future<bool> deleteStaff(int staffId) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final existing = await _staffRepository.getById(staffId);
    if (existing == null) {
      throw StaffNotFoundException('Staff member not found');
    }

    final success = await _staffRepository.delete(staffId);

    if (success) {
      await _logActivity(
        action: 'delete',
        module: 'staff',
        details:
            'Deleted staff member: ${existing.fullName} (${existing.staff.employeeId})',
      );
    }

    return success;
  }

  /// Delete multiple staff members
  Future<int> bulkDelete(List<int> ids) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    if (ids.isEmpty) return 0;

    final count = await _staffRepository.deleteMultiple(ids);

    if (count > 0) {
      await _logActivity(
        action: 'bulk_delete',
        module: 'staff',
        details: 'Deleted $count staff members',
      );
    }

    return count;
  }

  /// Get staff member with details
  Future<StaffWithRole?> getStaffWithDetails(int staffId) async {
    return await _staffRepository.getById(staffId);
  }

  /// Search staff with filters
  Future<List<StaffWithRole>> searchStaff(StaffFilters filters) async {
    return await _staffRepository.search(filters);
  }

  /// Get staff count
  Future<int> getStaffCount({
    int? roleId,
    String? department,
    String? status,
  }) async {
    return await _staffRepository.count(
      roleId: roleId,
      department: department,
      status: status,
    );
  }

  /// Get all teachers
  Future<List<StaffWithRole>> getTeachers() async {
    return await _staffRepository.getTeachers();
  }

  /// Get unassigned staff (no user account)
  Future<List<StaffWithRole>> getUnassignedStaff() async {
    return await _staffRepository.getUnassignedStaff();
  }

  /// Get all roles
  Future<List<StaffRole>> getAllRoles() async {
    return await _staffRepository.getAllRoles();
  }

  /// Get distinct departments
  Future<List<String>> getDistinctDepartments() async {
    return await _staffRepository.getDistinctDepartments();
  }

  /// Get distinct designations
  Future<List<String>> getDistinctDesignations() async {
    return await _staffRepository.getDistinctDesignations();
  }

  /// Update staff status
  Future<bool> updateStatus(int staffId, String status) async {
    final existing = await _staffRepository.getById(staffId);
    if (existing == null) {
      throw StaffNotFoundException('Staff member not found');
    }

    final validStatuses = ['active', 'on_leave', 'resigned', 'terminated'];
    if (!validStatuses.contains(status)) {
      throw StaffValidationException({'status': 'Invalid status'});
    }

    final companion = StaffCompanion(
      status: Value(status),
      endDate: status == 'resigned' || status == 'terminated'
          ? Value(DateTime.now())
          : const Value.absent(),
    );

    final success = await _staffRepository.update(staffId, companion);

    if (success) {
      await _logActivity(
        action: 'update',
        module: 'staff',
        details: 'Updated status for ${existing.fullName} to $status',
      );
    }

    return success;
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Pakistani phone format: 03XX-XXXXXXX or 03XXXXXXXXX
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    return cleaned.length >= 10 &&
        cleaned.length <= 13 &&
        RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }

  bool _isValidCnic(String cnic) {
    // Pakistani CNIC: 13 digits, optionally with dashes (XXXXX-XXXXXXX-X)
    final cleaned = cnic.replaceAll('-', '');
    return cleaned.length == 13 && RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }

  Future<void> _logActivity({
    required String action,
    required String module,
    required String details,
  }) async {
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            action: action,
            module: module,
            description: details,
            userId: const Value(null),
          ),
        );
  }
}

/// Exception for validation errors
class StaffValidationException implements Exception {
  final Map<String, String> errors;

  StaffValidationException(this.errors);

  @override
  String toString() => 'StaffValidationException: ${errors.values.join(', ')}';
}

/// Exception for not found errors
class StaffNotFoundException implements Exception {
  final String message;

  StaffNotFoundException(this.message);

  @override
  String toString() => 'StaffNotFoundException: $message';
}
