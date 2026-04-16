/// EduX School Management System
/// Student Import Service - Excel import with validation
library;

import 'package:drift/drift.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/demo/demo_config.dart';
import '../database/app_database.dart';
import '../repositories/student_repository.dart';
import '../repositories/guardian_repository.dart';
import '../repositories/enrollment_repository.dart';
import '../repositories/class_repository.dart';
import '../repositories/section_repository.dart';

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

/// Internal row representation
class ImportRow {
  final int rowNumber;
  final Map<String, dynamic> rawData;

  // Parsed fields
  String? studentName;
  String? fatherName;
  String? gender;
  DateTime? dateOfBirth;
  String? admissionNumber;
  DateTime? admissionDate;
  String? className;
  String? sectionName;
  String? phone;
  String? email;
  String? address;
  String? city;

  // Guardian info
  String? guardianName;
  String? guardianPhone;
  String? guardianRelation;
  String? guardianEmail;

  ImportRow(this.rowNumber, this.rawData);
}

// =============================================================================
// Service Implementation
// =============================================================================

/// Student import service for Excel imports
class StudentImportService {
  final AppDatabase _db;
  final StudentRepository _studentRepo;
  final GuardianRepository _guardianRepo;
  final EnrollmentRepository _enrollmentRepo;
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  StudentImportService(this._db)
    : _studentRepo = StudentRepositoryImpl(_db),
      _guardianRepo = GuardianRepositoryImpl(_db),
      _enrollmentRepo = EnrollmentRepositoryImpl(_db),
      _classRepo = ClassRepositoryImpl(_db),
      _sectionRepo = SectionRepositoryImpl(_db);

  final ClassRepository _classRepo;
  final SectionRepository _sectionRepo;

  // For future use
  // ignore: unused_element
  GuardianRepository get guardianRepo => _guardianRepo;
  // ignore: unused_element
  EnrollmentRepository get enrollmentRepo => _enrollmentRepo;
  // ignore: unused_element
  DateFormat get dateFormat => _dateFormat;

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

      // Pre-load valid classes and sections for validation
      final allClasses = await _classRepo.getAll();

      // Map class ID to section names for stricter validation if possible,
      // but for now simplest is just checking if class exists and contains section
      // Map<ClassName, Set<SectionName>>
      final validClassSections = <String, Set<String>>{};

      for (final cls in allClasses) {
        final sections = await _sectionRepo.getByClass(cls.id);
        validClassSections[cls.name.toLowerCase()] = sections
            .map((s) => s.name.toLowerCase())
            .toSet();
      }

      // Pre-load existing students for duplicate checking
      final allStudents = await _studentRepo.getAll();
      final existingAdmissionNumbers = allStudents
          .map((s) => s.admissionNumber.toLowerCase())
          .toSet();
      final existingNames = allStudents
          .map(
            (s) =>
                '${s.studentName.toLowerCase()}|${s.fatherName?.toLowerCase() ?? ''}',
          )
          .toSet();

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
          validClassSections,
          existingAdmissionNumbers,
          existingNames,
        );

        // Add this row to "existing" sets to check for duplicates within the file itself
        if (rowData['admissionNumber'] != null &&
            rowData['admissionNumber'].toString().isNotEmpty) {
          existingAdmissionNumbers.add(
            rowData['admissionNumber'].toString().toLowerCase(),
          );
        }
        if (rowData['studentName'] != null && rowData['fatherName'] != null) {
          existingNames.add(
            '${rowData['studentName'].toString().toLowerCase()}|${rowData['fatherName'].toString().toLowerCase()}',
          );
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
  Future<ImportResult> importStudents(
    Uint8List fileBytes, {
    required int userId,
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final preview = await previewImport(fileBytes);

    int success = 0;
    int failed = 0;
    final errors = <String>[];

    for (final item in preview.previewItems) {
      if (!item.isValid) {
        failed++;
        continue;
      }

      try {
        await _db.transaction(() async {
          await _importSingleRow(item.data);
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
              module: 'students',
              action: 'import',
              description: 'Imported $success students',
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
    // Helper to get safe string value from various CellValue types
    String? getValue(int index) {
      if (index >= row.length || row[index] == null) return null;
      final val = row[index]!.value;
      if (val == null) return null;

      // Handle Excel 4.x CellValue types robustly
      if (val is xl.TextCellValue) return val.value.toString().trim();
      if (val is xl.IntCellValue) return val.value.toString();
      if (val is xl.DoubleCellValue) return val.value.toString();
      if (val is xl.DateCellValue) {
        return DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime(val.year, val.month, val.day));
      }
      return val.toString().trim();
    }

    return {
      'admissionNumber': getValue(0),
      'studentName': getValue(1),
      'fatherName': getValue(2),
      'class': getValue(3),
      'section': getValue(4),
      'gender': getValue(5),
      'dob': getValue(6),
      'phone': getValue(7),
      'email': getValue(8),
      'address': getValue(9),
      'city': getValue(10),
      'guardianName': getValue(11),
      'guardianPhone': getValue(12),
      'guardianRelation': getValue(13),
      'admissionDate': getValue(14),
    };
  }

  List<ImportError> _validateRow(
    int rowIndex,
    Map<String, dynamic> data,
    Map<String, Set<String>> validClassSections,
    Set<String> existingAdmissionNumbers,
    Set<String> existingNames,
  ) {
    final errors = <ImportError>[];

    // Required fields check
    if (data['studentName']?.isEmpty ?? true) {
      errors.add(
        ImportError(
          rowIndex: rowIndex,
          field: 'Student Name',
          message: 'Student name is required',
          type: ErrorType.required,
        ),
      );
    }

    if (data['fatherName']?.isEmpty ?? true) {
      errors.add(
        ImportError(
          rowIndex: rowIndex,
          field: 'Father Name',
          message: 'Father name is required',
          type: ErrorType.required,
        ),
      );
    }

    // Duplicate Check
    // 1. Check Admission Number
    // 2. Check Name + Father Name Combination
    final sName = data['studentName']?.toString().trim().toLowerCase();
    final fName = data['fatherName']?.toString().trim().toLowerCase();
    if (sName != null && fName != null) {
      // Create the key exactly as it is stored in the set
      final key = '$sName|$fName';
      if (existingNames.contains(key)) {
        errors.add(
          ImportError(
            rowIndex: rowIndex,
            field: 'Student Name',
            message:
                'Duplicate detected: "$sName" with father "$fName" already exists in system',
            type: ErrorType.duplicate,
          ),
        );
      }
    }

    // Gender validation
    final gender = data['gender']?.toString().toLowerCase();
    if (gender != 'male' && gender != 'female') {
      errors.add(
        ImportError(
          rowIndex: rowIndex,
          field: 'Gender',
          message: 'Gender must be "male" or "female"',
          type: ErrorType.invalid,
        ),
      );
    }

    // Class & Section Validation
    final className = data['class']?.toString().trim();
    final sectionName = data['section']?.toString().trim();

    if (className == null || className.isEmpty) {
      errors.add(
        ImportError(
          rowIndex: rowIndex,
          field: 'Class',
          message: 'Class is required',
          type: ErrorType.required,
        ),
      );
    } else {
      final lowerClassName = className.toLowerCase();
      if (!validClassSections.containsKey(lowerClassName)) {
        errors.add(
          ImportError(
            rowIndex: rowIndex,
            field: 'Class',
            message: 'Class "$className" not found in system',
            type: ErrorType.notFound,
          ),
        );
      } else if (sectionName != null && sectionName.isNotEmpty) {
        // Validate Section if Class exists
        final lowerSectionName = sectionName.toLowerCase();
        if (!validClassSections[lowerClassName]!.contains(lowerSectionName)) {
          errors.add(
            ImportError(
              rowIndex: rowIndex,
              field: 'Section',
              message:
                  'Section "$sectionName" not found for class "$className"',
              type: ErrorType.notFound,
            ),
          );
        }
      }
    }

    if (sectionName == null || sectionName.isEmpty) {
      errors.add(
        ImportError(
          rowIndex: rowIndex,
          field: 'Section',
          message: 'Section is required',
          type: ErrorType.required,
        ),
      );
    }

    // Date Format validation
    if (data['admissionDate'] != null) {
      try {
        // Try parsing DD/MM/YYYY
        // Simple check, robust parsing handled in import
        if (!RegExp(
          r'^\d{1,2}/\d{1,2}/\d{4}$',
        ).hasMatch(data['admissionDate'])) {
          errors.add(
            ImportError(
              rowIndex: rowIndex,
              field: 'Admission Date',
              message: 'Invalid date format (use DD/MM/YYYY)',
              type: ErrorType.format,
            ),
          );
        }
      } catch (_) {
        errors.add(
          ImportError(
            rowIndex: rowIndex,
            field: 'Admission Date',
            message: 'Invalid date format',
            type: ErrorType.format,
          ),
        );
      }
    }

    return errors;
  }

  Future<void> _importSingleRow(Map<String, dynamic> data) async {
    // 1. Get Class and Section IDs
    // We can assume they exist because of validation, but best to be safe
    final classes = await _classRepo.getAll();
    final targetClass = classes.firstWhere(
      (c) => c.name.toLowerCase() == data['class'].toString().toLowerCase(),
    );

    final sections = await _sectionRepo.getByClass(targetClass.id);
    var targetSection = sections.firstWhere(
      (s) => s.name.toLowerCase() == data['section'].toString().toLowerCase(),
    );

    // Check section capacity and handle overflow - REMOVED per user request
    // final currentCount = await _sectionRepo.getStudentCount(targetSection.id);
    // if (currentCount >= 30) {
    //   targetSection = await _handleSectionOverflow(targetClass.id, sections, targetSection);
    // }

    // 2. Prepare Admission Number
    // Always generate new admission number, ignoring import file input
    String admissionNumber = await _studentRepo.generateAdmissionNumber();

    // 3. Create Student
    final dob = _parseDate(data['dob'] as String?);
    final admissionDate =
        _parseDate(data['admissionDate'] as String?) ?? DateTime.now();

    final student = StudentsCompanion.insert(
      uuid: _uuid.v4(),
      studentName: data['studentName']?.toString() ?? '',
      fatherName: Value(data['fatherName']?.toString()),
      gender: data['gender'].toString().toLowerCase(),
      admissionNumber: admissionNumber,
      admissionDate: admissionDate,
      dateOfBirth: Value(dob),
      phone: Value(data['phone'] as String?),
      email: Value(data['email'] as String?),
      address: Value(data['address'] as String?),
      city: Value(data['city'] as String?),
      status: const Value('active'),
    );

    final studentId = await _studentRepo.create(student);

    // 4. Create Enrollment
    // Get current academic year from somewhere or default to current year
    // For now simple generic academic year
    final now = DateTime.now();
    final academicYear = '${now.year}-${now.year + 1}'; // Simple default

    final rollNo = await _enrollmentRepo.generateNextRollNumber(
      targetClass.id,
      targetSection.id,
    );

    final enrollment = EnrollmentsCompanion.insert(
      studentId: studentId,
      classId: targetClass.id,
      sectionId: targetSection.id,
      academicYear: academicYear,
      enrollmentDate: admissionDate,
      rollNumber: Value(rollNo),
      status: const Value('active'),
      isCurrent: const Value(true),
    );

    await _enrollmentRepo.create(enrollment);

    // 5. Handle Guardian
    final guardianName = data['guardianName']?.toString().trim();
    if (guardianName != null && guardianName.isNotEmpty) {
      // Split name if possible
      final parts = guardianName.split(' ');
      final gFirstName = parts.first;
      final gLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final guardian = GuardiansCompanion.insert(
        uuid: _uuid.v4(),
        firstName: gFirstName,
        lastName: gLastName.isEmpty ? 'Guardian' : gLastName,
        phone: data['guardianPhone']?.toString().trim() ?? '',
        relation: data['guardianRelation']?.toString().trim() ?? 'Guardian',
      );

      final guardianId = await _guardianRepo.create(guardian);

      // Link
      await _guardianRepo.linkToStudent(
        studentId,
        guardianId,
        isPrimary: true,
        canPickup: true,
      );
    }
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
