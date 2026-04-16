/// EduX School Management System
/// Fee Service - Business logic for fee types and structures management
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/fee_repository.dart';

/// Validation result for fee data
class FeeValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const FeeValidationResult({required this.isValid, this.errors = const {}});

  factory FeeValidationResult.valid() =>
      const FeeValidationResult(isValid: true);

  factory FeeValidationResult.invalid(Map<String, String> errors) =>
      FeeValidationResult(isValid: false, errors: errors);
}

/// Fee type form data
class FeeTypeFormData {
  final String name;
  final String? description;
  final bool isMonthly;
  final bool isRefundable;
  final bool isMandatory =
      true; // Not in DB, defaulting to true or removing if unused
  final int displayOrder;
  final bool isActive;

  const FeeTypeFormData({
    required this.name,
    this.description,
    this.isMonthly = true,
    this.isRefundable = false,
    this.displayOrder = 0,
    this.isActive = true,
  });
}

/// Fee structure form data
class FeeStructureFormData {
  final int classId;
  final int feeTypeId;
  final String academicYear;
  final double amount;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  const FeeStructureFormData({
    required this.classId,
    required this.feeTypeId,
    required this.academicYear,
    required this.amount,
    this.effectiveFrom,
    this.effectiveTo,
  });
}

/// Bulk fee structure update data
class BulkFeeStructureData {
  final int classId;
  final String academicYear;
  final Map<int, double> feeTypeAmounts; // feeTypeId -> amount

  const BulkFeeStructureData({
    required this.classId,
    required this.academicYear,
    required this.feeTypeAmounts,
  });
}

/// Fee service for business logic
class FeeService {
  final AppDatabase _db;
  final FeeRepository _feeRepo;

  FeeService(this._db) : _feeRepo = DriftFeeRepository(_db);

  // ============================================
  // FEE TYPE MANAGEMENT
  // ============================================

  /// Get all fee types
  Future<List<FeeType>> getAllFeeTypes({bool activeOnly = true}) async {
    return await _feeRepo.getAllFeeTypes(activeOnly: activeOnly);
  }

  /// Get fee types with usage statistics
  Future<List<FeeTypeWithUsage>> getFeeTypesWithUsage() async {
    return await _feeRepo.getFeeTypesWithUsage();
  }

  /// Validate fee type form data
  Future<FeeValidationResult> validateFeeType(
    FeeTypeFormData data, {
    int? excludeId,
  }) async {
    final errors = <String, String>{};

    // Name validation
    if (data.name.trim().isEmpty) {
      errors['name'] = 'Fee type name is required';
    } else if (data.name.trim().length < 2) {
      errors['name'] = 'Fee type name must be at least 2 characters';
    } else if (data.name.trim().length > 100) {
      errors['name'] = 'Fee type name must be at most 100 characters';
    } else {
      // Check uniqueness
      final isUnique = await _feeRepo.isFeeTypeNameUnique(
        data.name.trim(),
        excludeId: excludeId,
      );
      if (!isUnique) {
        errors['name'] = 'A fee type with this name already exists';
      }
    }

    // Display order validation
    if (data.displayOrder < 0) {
      errors['displayOrder'] = 'Display order cannot be negative';
    }

    return errors.isEmpty
        ? FeeValidationResult.valid()
        : FeeValidationResult.invalid(errors);
  }

  /// Create a new fee type
  Future<int> createFeeType(FeeTypeFormData data) async {
    // Validate
    final validation = await validateFeeType(data);
    if (!validation.isValid) {
      throw FeeValidationException(validation.errors);
    }

    // Create
    final id = await _feeRepo.createFeeType(
      FeeTypesCompanion.insert(
        name: data.name.trim(),
        description: Value(data.description?.trim()),
        isMonthly: Value(data.isMonthly),
        isRefundable: Value(data.isRefundable),
        displayOrder: Value(data.displayOrder),
        isActive: Value(data.isActive),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'create',
      module: 'fees',
      details: 'Created fee type: ${data.name}',
    );

    return id;
  }

  /// Update an existing fee type
  Future<bool> updateFeeType(int id, FeeTypeFormData data) async {
    // Check exists
    final existing = await _feeRepo.getFeeTypeById(id);
    if (existing == null) {
      throw FeeNotFoundException('Fee type not found');
    }

    // Validate
    final validation = await validateFeeType(data, excludeId: id);
    if (!validation.isValid) {
      throw FeeValidationException(validation.errors);
    }

    // Update
    final result = await _feeRepo.updateFeeType(
      id,
      FeeTypesCompanion(
        name: Value(data.name.trim()),
        description: Value(data.description?.trim()),
        isMonthly: Value(data.isMonthly),
        isRefundable: Value(data.isRefundable),
        displayOrder: Value(data.displayOrder),
        isActive: Value(data.isActive),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'update',
      module: 'fees',
      details: 'Updated fee type: ${data.name}',
    );

    return result;
  }

  /// Delete a fee type
  Future<bool> deleteFeeType(int id) async {
    final existing = await _feeRepo.getFeeTypeById(id);
    if (existing == null) {
      throw FeeNotFoundException('Fee type not found');
    }

    final result = await _feeRepo.deleteFeeType(id);

    // Log activity
    await _logActivity(
      action: 'delete',
      module: 'fees',
      details: 'Deleted fee type: ${existing.name}',
    );

    return result;
  }

  // ============================================
  // FEE STRUCTURE MANAGEMENT
  // ============================================

  /// Get fee structures for a class
  Future<List<FeeStructureWithDetails>> getClassFeeStructures(
    int classId,
    String academicYear,
  ) async {
    return await _feeRepo.getFeeStructuresWithDetails(
      classId: classId,
      academicYear: academicYear,
    );
  }

  /// Get all class fee summaries
  Future<List<ClassFeeSummary>> getAllClassFeeSummaries(
    String academicYear,
  ) async {
    return await _feeRepo.getClassFeeSummaries(academicYear);
  }

  /// Validate fee structure form data
  FeeValidationResult validateFeeStructure(FeeStructureFormData data) {
    final errors = <String, String>{};

    // Class ID validation
    if (data.classId <= 0) {
      errors['classId'] = 'Please select a class';
    }

    // Fee type ID validation
    if (data.feeTypeId <= 0) {
      errors['feeTypeId'] = 'Please select a fee type';
    }

    // Academic year validation
    if (data.academicYear.isEmpty) {
      errors['academicYear'] = 'Academic year is required';
    } else if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(data.academicYear)) {
      errors['academicYear'] =
          'Invalid academic year format (should be YYYY-YYYY)';
    }

    // Amount validation
    if (data.amount < 0) {
      errors['amount'] = 'Amount cannot be negative';
    } else if (data.amount > 9999999) {
      errors['amount'] = 'Amount exceeds maximum allowed value';
    }

    // Date range validation
    if (data.effectiveFrom != null &&
        data.effectiveTo != null &&
        data.effectiveFrom!.isAfter(data.effectiveTo!)) {
      errors['effectiveTo'] = 'End date must be after start date';
    }

    return errors.isEmpty
        ? FeeValidationResult.valid()
        : FeeValidationResult.invalid(errors);
  }

  /// Create a fee structure
  Future<int> createFeeStructure(FeeStructureFormData data) async {
    // Validate
    final validation = validateFeeStructure(data);
    if (!validation.isValid) {
      throw FeeValidationException(validation.errors);
    }

    // Check if class exists
    final classInfo = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(data.classId))).getSingleOrNull();
    if (classInfo == null) {
      throw FeeNotFoundException('Class not found');
    }

    // Check if fee type exists
    final feeType = await _feeRepo.getFeeTypeById(data.feeTypeId);
    if (feeType == null) {
      throw FeeNotFoundException('Fee type not found');
    }

    // Create
    final id = await _feeRepo.createFeeStructure(
      FeeStructuresCompanion.insert(
        classId: data.classId,
        feeTypeId: data.feeTypeId,
        academicYear: data.academicYear,
        amount: data.amount,
        effectiveFrom: data.effectiveFrom ?? DateTime.now(),
        effectiveTo: Value(data.effectiveTo),
        isActive: const Value(true),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'create',
      module: 'fees',
      details:
          'Created fee structure: ${feeType.name} for ${classInfo.name} - ${data.amount}',
    );

    return id;
  }

  /// Update a fee structure
  Future<bool> updateFeeStructure(int id, FeeStructureFormData data) async {
    // Check exists
    final existing = await _feeRepo.getFeeStructureById(id);
    if (existing == null) {
      throw FeeNotFoundException('Fee structure not found');
    }

    // Validate
    final validation = validateFeeStructure(data);
    if (!validation.isValid) {
      throw FeeValidationException(validation.errors);
    }

    // Update
    final result = await _feeRepo.updateFeeStructure(
      id,
      FeeStructuresCompanion(
        amount: Value(data.amount),
        effectiveFrom: data.effectiveFrom == null
            ? const Value.absent()
            : Value(data.effectiveFrom!),
        effectiveTo: Value(data.effectiveTo),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'update',
      module: 'fees',
      details: 'Updated fee structure ID $id to amount ${data.amount}',
    );

    return result;
  }

  /// Bulk update fee structures for a class
  Future<void> updateClassFeeStructures(BulkFeeStructureData data) async {
    // Validate
    if (data.classId <= 0) {
      throw FeeValidationException({'classId': 'Please select a class'});
    }

    if (data.academicYear.isEmpty) {
      throw FeeValidationException({
        'academicYear': 'Academic year is required',
      });
    }

    if (data.feeTypeAmounts.isEmpty) {
      throw FeeValidationException({
        'feeTypeAmounts': 'At least one fee type amount is required',
      });
    }

    // Check for negative amounts
    for (final entry in data.feeTypeAmounts.entries) {
      if (entry.value < 0) {
        throw FeeValidationException({
          'amount_${entry.key}': 'Amount cannot be negative',
        });
      }
    }

    // Build structure companions
    final structures = <FeeStructuresCompanion>[];
    for (final entry in data.feeTypeAmounts.entries) {
      if (entry.value > 0) {
        // Only create structures for non-zero amounts
        structures.add(
          FeeStructuresCompanion.insert(
            classId: data.classId,
            feeTypeId: entry.key,
            academicYear: data.academicYear,
            amount: entry.value,
            effectiveFrom: DateTime.now(),
            isActive: const Value(true),
          ),
        );
      }
    }

    // Upsert
    await _feeRepo.upsertFeeStructures(
      structures,
      data.classId,
      data.academicYear,
    );

    // Log activity
    await _logActivity(
      action: 'bulk_update',
      module: 'fees',
      details:
          'Updated fee structures for class ID ${data.classId} for ${data.academicYear}',
    );
  }

  /// Delete a fee structure
  Future<bool> deleteFeeStructure(int id) async {
    final existing = await _feeRepo.getFeeStructureById(id);
    if (existing == null) {
      throw FeeNotFoundException('Fee structure not found');
    }

    final result = await _feeRepo.deleteFeeStructure(id);

    // Log activity
    await _logActivity(
      action: 'delete',
      module: 'fees',
      details: 'Deleted fee structure ID $id',
    );

    return result;
  }

  // ============================================
  // CALCULATION HELPERS
  // ============================================

  /// Calculate total fees for a class
  Future<double> calculateTotalClassFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = false,
  }) async {
    return await _feeRepo.calculateTotalFees(
      classId: classId,
      academicYear: academicYear,
      monthlyOnly: monthlyOnly,
    );
  }

  /// Get applicable fee structures for a student
  Future<List<FeeStructureWithDetails>> getStudentApplicableFees({
    required int classId,
    required String academicYear,
    bool monthlyOnly = true,
  }) async {
    return await _feeRepo.getStudentApplicableFees(
      classId: classId,
      academicYear: academicYear,
      monthlyOnly: monthlyOnly,
    );
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

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

/// Exception for fee validation errors
class FeeValidationException implements Exception {
  final Map<String, String> errors;

  FeeValidationException(this.errors);

  @override
  String toString() =>
      'Validation failed: ${errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
}

/// Exception for not found errors
class FeeNotFoundException implements Exception {
  final String message;

  FeeNotFoundException(this.message);

  @override
  String toString() => message;
}
