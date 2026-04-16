/// EduX School Management System
/// Staff Import Service - Excel import with validation
library;

import 'package:drift/drift.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/staff_repository.dart';

// =============================================================================
// Enums and Data Classes
// =============================================================================

enum ErrorSeverity { info, warning, error }

enum ErrorType { required, invalid, duplicate, notFound, format }

/// Detailed error for import validation
class ImportError {
  final int rowIndex;
  final String? field;
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;

  ImportError({
    required this.rowIndex,
    this.field,
    required this.message,
    required this.type,
    this.severity = ErrorSeverity.error,
  });
}

/// Preview item for the UI
class ImportPreviewItem {
  final int rowIndex;
  final Map<String, dynamic> data;
  final bool isValid;

  ImportPreviewItem({
    required this.rowIndex,
    required this.data,
    required this.isValid,
  });
}

/// Result of the preview operation
class ImportPreviewResult {
  final List<ImportPreviewItem> previewItems;
  final List<ImportError> errors;
  final int totalRows;

  ImportPreviewResult({
    required this.previewItems,
    required this.errors,
    required this.totalRows,
  });

  int get validRows => previewItems.where((i) => i.isValid).length;
  int get errorRows => previewItems.where((i) => !i.isValid).length;
}

/// Result of the final import operation
class ImportResult {
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.errors,
  });
}

// =============================================================================
// Service Implementation
// =============================================================================

/// Staff import service for Excel imports
class StaffImportService {
  final AppDatabase _db;
  final StaffRepository _staffRepo;
  final _uuid = const Uuid();

  StaffImportService(this._db) : _staffRepo = StaffRepositoryImpl(_db);

  /// Preview and validate import file
  Future<ImportPreviewResult> previewImport(Uint8List fileBytes) async {
    try {
      final excel = xl.Excel.decodeBytes(fileBytes);
      final sheet = excel.tables.keys.firstOrNull != null
          ? excel.tables[excel.tables.keys.first]!
          : null;

      if (sheet == null) {
        throw Exception('No sheets found in Excel file');
      }

      // Pre-load roles for validation
      final allRoles = await _staffRepo.getAllRoles();
      final validRoles = allRoles
          .map((r) => r.name.toLowerCase())
          .toSet();

      // Pre-load existing staff for duplicate checking
      final allStaff = await _staffRepo.getAll();
      final existingPhones = allStaff
          .map((s) => s.staff.phone.replaceAll(RegExp(r'[\s-]'), ''))
          .toSet();
      // Check Name + Phone combination or just Phone?
      // Phone should be unique usually.
      
      final previewItems = <ImportPreviewItem>[];
      final errors = <ImportError>[];

      // Skip header row
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        // Skip empty rows
        if (row.every(
          (c) => c?.value == null || c!.value.toString().trim().isEmpty,
        )) {
          continue;
        }

        final rowData = _extractRowData(row);
        final rowErrors = _validateRow(
          i,
          rowData,
          validRoles,
          existingPhones,
        );

        // Add to existing checks for internal duplication
        if (rowData['phone'] != null) {
          final cleanPhone = rowData['phone'].toString().replaceAll(RegExp(r'[\s-]'), '');
          if (cleanPhone.isNotEmpty) {
             existingPhones.add(cleanPhone);
          }
        }

        errors.addAll(rowErrors);
        previewItems.add(
          ImportPreviewItem(
            rowIndex: i,
            data: rowData,
            isValid: rowErrors.isEmpty,
          ),
        );
      }

      return ImportPreviewResult(
        previewItems: previewItems,
        errors: errors,
        totalRows: previewItems.length,
      );
    } catch (e) {
      throw Exception('Failed to preview file: $e');
    }
  }

  /// Perform the actual import
  Future<ImportResult> importStaff(
    Uint8List fileBytes, {
    required int userId,
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final preview = await previewImport(fileBytes);

    int success = 0;
    int failed = 0;
    final errors = <String>[];

    // Get roles again to map name to ID
    final allRoles = await _staffRepo.getAllRoles();
    final roleMap = {
      for (var r in allRoles) r.name.toLowerCase(): r.id
    };

    for (final item in preview.previewItems) {
      if (!item.isValid) {
        failed++;
        continue;
      }

      try {
        await _db.transaction(() async {
          await _importSingleRow(item.data, roleMap);
        });
        success++;
      } catch (e) {
        failed++;
        errors.add('Row ${item.rowIndex + 1}: ${e.toString()}');
      }
    }

    // Log activity
    if (success > 0) {
      await _db
          .into(_db.activityLogs)
          .insert(
            ActivityLogsCompanion.insert(
              module: 'staff',
              action: 'import',
              description: 'Imported $success staff members',
              details: Value(
                'Files: ${preview.totalRows}, Success: $success, Failed: $failed',
              ),
              userId: Value(userId),
            ),
          );
    }

    return ImportResult(
      successCount: success,
      failedCount: failed,
      skippedCount: 0,
      errors: errors,
    );
  }

  Map<String, dynamic> _extractRowData(List<xl.Data?> row) {
    // Helper to get safe string value
    String? getValue(int index) {
      if (index >= row.length || row[index] == null) return null;
      return row[index]!.value?.toString().trim();
    }

    return {
      'firstName': getValue(0),
      'lastName': getValue(1),
      'phone': getValue(2),
      'gender': getValue(3),
      'designation': getValue(4),
      'role': getValue(5),
      'joiningDate': getValue(6),
      'basicSalary': getValue(7),
      'email': getValue(8),
      'cnic': getValue(9),
      'address': getValue(10),
      'department': getValue(11),
      'bankName': getValue(12),
      'accountNumber': getValue(13),
    };
  }

  List<ImportError> _validateRow(
    int rowIndex,
    Map<String, dynamic> data,
    Set<String> validRoles,
    Set<String> existingPhones,
  ) {
    final errors = <ImportError>[];

    // Required fields check
    if (data['firstName']?.isEmpty ?? true) {
      errors.add(ImportError(rowIndex: rowIndex, field: 'First Name', message: 'First name is required', type: ErrorType.required));
    }

    if (data['lastName']?.isEmpty ?? true) {
      errors.add(ImportError(rowIndex: rowIndex, field: 'Last Name', message: 'Last name is required', type: ErrorType.required));
    }

    if (data['phone']?.isEmpty ?? true) {
      errors.add(ImportError(rowIndex: rowIndex, field: 'Phone', message: 'Phone is required', type: ErrorType.required));
    } else {
        final cleanPhone = data['phone']!.replaceAll(RegExp(r'[\s-]'), '');
        if (existingPhones.contains(cleanPhone)) {
             errors.add(ImportError(rowIndex: rowIndex, field: 'Phone', message: 'Phone number already exists', type: ErrorType.duplicate));
        }
    }

    if (data['gender']?.isEmpty ?? true) {
        errors.add(ImportError(rowIndex: rowIndex, field: 'Gender', message: 'Gender is required', type: ErrorType.required));
    } else {
        final gender = data['gender']!.toLowerCase();
        if (gender != 'male' && gender != 'female') {
            errors.add(ImportError(rowIndex: rowIndex, field: 'Gender', message: 'Gender must be "male" or "female"', type: ErrorType.invalid));
        }
    }

    if (data['designation']?.isEmpty ?? true) {
        errors.add(ImportError(rowIndex: rowIndex, field: 'Designation', message: 'Designation is required', type: ErrorType.required));
    }

    if (data['role']?.isEmpty ?? true) {
        errors.add(ImportError(rowIndex: rowIndex, field: 'Role', message: 'Role is required', type: ErrorType.required));
    } else {
        if (!validRoles.contains(data['role']!.toLowerCase())) {
            errors.add(ImportError(rowIndex: rowIndex, field: 'Role', message: 'Role not found', type: ErrorType.notFound));
        }
    }

    // Date validations
    if (data['joiningDate'] != null) {
      try {
        if (!RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(data['joiningDate'])) {
           errors.add(ImportError(rowIndex: rowIndex, field: 'Joining Date', message: 'Invalid format (DD/MM/YYYY)', type: ErrorType.format));
        }
      } catch (_) {}
    }

    return errors;
  }

  Future<void> _importSingleRow(Map<String, dynamic> data, Map<String, int> roleMap) async {
    // Generate Employee ID
    final employeeId = await _staffRepo.generateEmployeeId();

    final joiningDate = _parseDate(data['joiningDate']) ?? DateTime.now();
    final roleId = roleMap[data['role'].toString().toLowerCase()]!;
    final salary = double.tryParse(data['basicSalary']?.toString() ?? '0') ?? 0.0;

    final companion = StaffCompanion.insert(
      uuid: _uuid.v4(),
      employeeId: employeeId,
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      gender: data['gender'].toString().toLowerCase(),
      designation: data['designation'],
      roleId: roleId,
      basicSalary: salary,
      joiningDate: joiningDate,
      email: Value(data['email']),
      cnic: Value(data['cnic']?.toString().replaceAll('-', '')),
      address: Value(data['address']),
      department: Value(data['department']),
      bankName: Value(data['bankName']),
      accountNumber: Value(data['accountNumber']),
      status: const Value('active'),
    );

    await _staffRepo.create(companion);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }
}
