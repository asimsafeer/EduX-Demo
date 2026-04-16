/// EduX School Management System
/// Invoice Service - Business logic for invoice generation and management
library;

import 'package:drift/drift.dart';

import '../core/constants/app_constants.dart';

import '../database/app_database.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/fee_repository.dart';
import '../repositories/concession_repository.dart';
import 'fee_service.dart';

/// Invoice generation input data
class InvoiceGenerationData {
  final int studentId;
  final String month; // Format: YYYY-MM
  final String academicYear;
  final DateTime dueDate;
  final int generatedBy;
  final String? remarks;

  const InvoiceGenerationData({
    required this.studentId,
    required this.month,
    required this.academicYear,
    required this.dueDate,
    required this.generatedBy,
    this.remarks,
  });
}

/// Bulk invoice generation input
class BulkInvoiceGenerationData {
  final String month;
  final String academicYear;
  final DateTime dueDate;
  final int? classId; // null means all classes
  final int? sectionId;
  final int generatedBy;
  final String? remarks;

  const BulkInvoiceGenerationData({
    required this.month,
    required this.academicYear,
    required this.dueDate,
    required this.generatedBy,
    this.classId,
    this.sectionId,
    this.remarks,
  });
}

/// Generic invoice generation with selectable fee types
class GenericInvoiceGenerationData {
  final int studentId;
  final String month;
  final String academicYear;
  final DateTime dueDate;
  final int generatedBy;
  final String? remarks;
  final List<int> selectedFeeTypeIds; // Empty means all applicable fees

  const GenericInvoiceGenerationData({
    required this.studentId,
    required this.month,
    required this.academicYear,
    required this.dueDate,
    required this.generatedBy,
    this.remarks,
    this.selectedFeeTypeIds = const [],
  });
}

/// Bulk generic invoice generation with selectable fee types
class BulkGenericInvoiceGenerationData {
  final String month;
  final String academicYear;
  final DateTime dueDate;
  final int? classId;
  final int? sectionId;
  final int generatedBy;
  final String? remarks;
  final List<int> selectedFeeTypeIds; // Empty means all applicable fees

  const BulkGenericInvoiceGenerationData({
    required this.month,
    required this.academicYear,
    required this.dueDate,
    required this.generatedBy,
    this.classId,
    this.sectionId,
    this.remarks,
    this.selectedFeeTypeIds = const [],
  });
}

/// Bulk invoice generation result
class BulkInvoiceResult {
  final int totalStudents;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final double totalAmount;
  final List<String> errors;
  final List<int> generatedInvoiceIds;

  const BulkInvoiceResult({
    required this.totalStudents,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    required this.totalAmount,
    required this.errors,
    required this.generatedInvoiceIds,
  });
}

/// Invoice generation result
class InvoiceGenerationResult {
  final bool success;
  final int? invoiceId;
  final String? invoiceNumber;
  final double? amount;
  final String? error;

  const InvoiceGenerationResult({
    required this.success,
    this.invoiceId,
    this.invoiceNumber,
    this.amount,
    this.error,
  });

  factory InvoiceGenerationResult.success({
    required int invoiceId,
    required String invoiceNumber,
    required double amount,
  }) => InvoiceGenerationResult(
    success: true,
    invoiceId: invoiceId,
    invoiceNumber: invoiceNumber,
    amount: amount,
  );

  factory InvoiceGenerationResult.failure(String error) =>
      InvoiceGenerationResult(success: false, error: error);
}

/// Invoice service for business logic
class InvoiceService {
  final AppDatabase _db;
  final InvoiceRepository _invoiceRepo;
  final FeeRepository _feeRepo;
  final ConcessionRepository _concessionRepo;

  InvoiceService(this._db)
    : _invoiceRepo = DriftInvoiceRepository(_db),
      _feeRepo = DriftFeeRepository(_db),
      _concessionRepo = DriftConcessionRepository(_db);

  // ============================================
  // INVOICE QUERIES
  // ============================================

  /// Get invoices with filters
  Future<List<InvoiceWithDetails>> getInvoices(InvoiceFilters filters) async {
    return await _invoiceRepo.getInvoices(filters);
  }

  /// Get invoice with full details
  Future<InvoiceWithDetails?> getInvoiceWithDetails(int invoiceId) async {
    return await _invoiceRepo.getInvoiceWithDetails(invoiceId);
  }

  /// Get student's invoices
  Future<List<Invoice>> getStudentInvoices(int studentId) async {
    return await _invoiceRepo.getStudentInvoices(studentId);
  }

  /// Get unpaid invoices for a student
  Future<List<Invoice>> getUnpaidInvoicesForStudent(int studentId) async {
    return await _invoiceRepo.getUnpaidInvoicesForStudent(studentId);
  }

  /// Get invoice statistics
  Future<InvoiceStats> getInvoiceStats({String? month, int? classId}) async {
    return await _invoiceRepo.getInvoiceStats(month: month, classId: classId);
  }

  // ============================================
  // INVOICE GENERATION
  // ============================================

  /// Generate invoice for a single student
  Future<InvoiceGenerationResult> generateInvoice(
    InvoiceGenerationData data,
  ) async {
    try {
      // Check if invoice already exists for this month
      final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(
        data.studentId,
        data.month,
      );
      if (hasInvoice) {
        return InvoiceGenerationResult.failure(
          'Invoice already exists for ${data.month}',
        );
      }

      // Get student with enrollment
      final studentQuery = _db.select(_db.students).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.students.id) &
              _db.enrollments.isCurrent.equals(true),
        ),
      ]);
      studentQuery.where(_db.students.id.equals(data.studentId));
      final studentRow = await studentQuery.getSingleOrNull();

      if (studentRow == null) {
        return InvoiceGenerationResult.failure(
          'Student not found or not enrolled',
        );
      }

      final student = studentRow.readTable(_db.students);
      final enrollment = studentRow.readTable(_db.enrollments);

      // Check student is active
      if (student.status != 'active') {
        return InvoiceGenerationResult.failure(
          'Student is not active (status: ${student.status})',
        );
      }

      // Get applicable fees for the class
      final feeStructures = await _feeRepo.getStudentApplicableFees(
        classId: enrollment.classId,
        academicYear: data.academicYear,
        monthlyOnly: true,
      );

      if (feeStructures.isEmpty) {
        return InvoiceGenerationResult.failure(
          'No fee structures configured for this class',
        );
      }

      // Get student's concessions
      final discountInfo = await _concessionRepo.getStudentDiscountInfo(
        data.studentId,
      );

      // Calculate totals
      double totalAmount = 0;
      double totalDiscount = 0;
      final invoiceItems = <InvoiceItemsCompanion>[];

      for (final structure in feeStructures) {
        final feeAmount = structure.structure.amount;
        final discount = discountInfo.calculateDiscount(
          feeAmount,
          structure.feeType.id,
        );

        final netAmount = feeAmount - discount;
        totalAmount += feeAmount;
        totalDiscount += discount;

        invoiceItems.add(
          InvoiceItemsCompanion.insert(
            invoiceId: 0, // Will be set after invoice creation
            feeTypeId: structure.feeType.id,
            description: structure.feeType.name,
            amount: feeAmount,
            discount: Value(discount),
            netAmount: netAmount,
          ),
        );
      }

      final netAmount = totalAmount - totalDiscount;

      // Generate invoice number
      final invoiceNumber = await _invoiceRepo.generateInvoiceNumber(
        data.month,
      );

      // Create invoice
      final invoiceId = await _db.transaction(() async {
        final id = await _invoiceRepo.create(
          InvoicesCompanion.insert(
            invoiceNumber: invoiceNumber,
            studentId: data.studentId,
            month: data.month,
            academicYear: data.academicYear,
            totalAmount: totalAmount,
            discountAmount: Value(totalDiscount),
            netAmount: netAmount,
            paidAmount: const Value(0),
            balanceAmount: netAmount,
            issueDate: DateTime.now(),
            dueDate: data.dueDate,
            generatedBy: data.generatedBy,
            status: const Value('pending'),
            notes: Value(data.remarks),
          ),
        );

        // Create invoice items
        final itemsWithInvoiceId = invoiceItems
            .map(
              (item) => InvoiceItemsCompanion.insert(
                invoiceId: id,
                feeTypeId: item.feeTypeId.value,
                description: item.description.value,
                amount: item.amount.value,
                discount: item.discount,
                netAmount: item.netAmount.value,
              ),
            )
            .toList();

        await _invoiceRepo.createInvoiceItems(itemsWithInvoiceId);

        return id;
      });

      // Log activity
      await _logActivity(
        action: 'create',
        module: 'invoices',
        details:
            'Generated invoice $invoiceNumber for ${student.studentName} ${student.fatherName} - ${data.month}',
      );

      return InvoiceGenerationResult.success(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        amount: netAmount,
      );
    } catch (e) {
      return InvoiceGenerationResult.failure('Error generating invoice: $e');
    }
  }

  /// Generate invoices in bulk for a class or all classes
  Future<BulkInvoiceResult> generateBulkInvoices(
    BulkInvoiceGenerationData data,
  ) async {
    final errors = <String>[];
    final generatedIds = <int>[];
    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    double totalAmount = 0;

    // Get enrolled students
    var studentQuery = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true) &
            _db.enrollments.status.equals('active'),
      ),
    ]);

    studentQuery.where(_db.students.status.equals('active'));

    if (data.classId != null) {
      studentQuery.where(_db.enrollments.classId.equals(data.classId!));
    }

    if (data.sectionId != null) {
      studentQuery.where(_db.enrollments.sectionId.equals(data.sectionId!));
    }

    final studentRows = await studentQuery.get();
    final totalStudents = studentRows.length;

    // Get students who already have invoices for this month
    final existingInvoiceStudents = <int>{};
    if (data.classId != null) {
      existingInvoiceStudents.addAll(
        await _invoiceRepo.getStudentsWithInvoices(data.month, data.classId!),
      );
    }

    for (final row in studentRows) {
      final student = row.readTable(_db.students);

      // Skip if already has invoice
      if (existingInvoiceStudents.contains(student.id)) {
        skippedCount++;
        continue;
      }

      // Check again for invoice existence (in case classId was null)
      if (data.classId == null) {
        final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(
          student.id,
          data.month,
        );
        if (hasInvoice) {
          skippedCount++;
          continue;
        }
      }

      // Generate invoice
      final result = await generateInvoice(
        InvoiceGenerationData(
          studentId: student.id,
          month: data.month,
          academicYear: data.academicYear,
          dueDate: data.dueDate,
          generatedBy: data.generatedBy,
          remarks: data.remarks,
        ),
      );

      if (result.success) {
        successCount++;
        totalAmount += result.amount ?? 0;
        if (result.invoiceId != null) {
          generatedIds.add(result.invoiceId!);
        }
      } else {
        errorCount++;
        errors.add('${student.studentName} ${student.fatherName}: ${result.error}');
      }
    }

    // Log activity
    await _logActivity(
      action: 'bulk_create',
      module: 'invoices',
      details:
          'Bulk generated $successCount invoices for ${data.month}, skipped $skippedCount, errors $errorCount',
    );

    return BulkInvoiceResult(
      totalStudents: totalStudents,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      totalAmount: totalAmount,
      errors: errors
          .take(50)
          .toList(), // Limit errors to avoid too large response
      generatedInvoiceIds: generatedIds,
    );
  }

  // ============================================
  // GENERIC INVOICE GENERATION (with selectable fee types)
  // ============================================

  /// Generate generic invoice for a single student with selectable fee types
  Future<InvoiceGenerationResult> generateGenericInvoice(
    GenericInvoiceGenerationData data,
  ) async {
    try {
      // Check if invoice already exists for this month
      final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(
        data.studentId,
        data.month,
      );
      if (hasInvoice) {
        return InvoiceGenerationResult.failure(
          'Invoice already exists for ${data.month}',
        );
      }

      // Get student with enrollment
      final studentQuery = _db.select(_db.students).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.students.id) &
              _db.enrollments.isCurrent.equals(true),
        ),
      ]);
      studentQuery.where(_db.students.id.equals(data.studentId));
      final studentRow = await studentQuery.getSingleOrNull();

      if (studentRow == null) {
        return InvoiceGenerationResult.failure(
          'Student not found or not enrolled',
        );
      }

      final student = studentRow.readTable(_db.students);
      final enrollment = studentRow.readTable(_db.enrollments);

      // Check student is active
      if (student.status != 'active') {
        return InvoiceGenerationResult.failure(
          'Student is not active (status: ${student.status})',
        );
      }

      // Get applicable fees for the class
      final feeStructures = await _feeRepo.getStudentApplicableFees(
        classId: enrollment.classId,
        academicYear: data.academicYear,
        monthlyOnly: false, // Include all fee types (monthly + one-time)
      );

      if (feeStructures.isEmpty) {
        return InvoiceGenerationResult.failure(
          'No fee structures configured for this class',
        );
      }

      // Filter by selected fee types if specified
      final selectedFeeTypes = data.selectedFeeTypeIds.isEmpty
          ? feeStructures
          : feeStructures.where((fs) => data.selectedFeeTypeIds.contains(fs.feeType.id)).toList();

      if (selectedFeeTypes.isEmpty) {
        return InvoiceGenerationResult.failure(
          'No fee types selected or available',
        );
      }

      // Get student's concessions
      final discountInfo = await _concessionRepo.getStudentDiscountInfo(
        data.studentId,
      );

      // Calculate totals
      double totalAmount = 0;
      double totalDiscount = 0;
      final invoiceItems = <InvoiceItemsCompanion>[];

      for (final structure in selectedFeeTypes) {
        final feeAmount = structure.structure.amount;
        final discount = discountInfo.calculateDiscount(
          feeAmount,
          structure.feeType.id,
        );

        final netAmount = feeAmount - discount;
        totalAmount += feeAmount;
        totalDiscount += discount;

        invoiceItems.add(
          InvoiceItemsCompanion.insert(
            invoiceId: 0, // Will be set after invoice creation
            feeTypeId: structure.feeType.id,
            description: structure.feeType.name,
            amount: feeAmount,
            discount: Value(discount),
            netAmount: netAmount,
          ),
        );
      }

      final netAmount = totalAmount - totalDiscount;

      // Generate invoice number
      final invoiceNumber = await _invoiceRepo.generateInvoiceNumber(
        data.month,
      );

      // Create invoice
      final invoiceId = await _db.transaction(() async {
        final id = await _invoiceRepo.create(
          InvoicesCompanion.insert(
            invoiceNumber: invoiceNumber,
            studentId: data.studentId,
            month: data.month,
            academicYear: data.academicYear,
            totalAmount: totalAmount,
            discountAmount: Value(totalDiscount),
            netAmount: netAmount,
            paidAmount: const Value(0),
            balanceAmount: netAmount,
            issueDate: DateTime.now(),
            dueDate: data.dueDate,
            generatedBy: data.generatedBy,
            status: const Value('pending'),
            notes: Value(data.remarks),
          ),
        );

        // Create invoice items
        final itemsWithInvoiceId = invoiceItems
            .map(
              (item) => InvoiceItemsCompanion.insert(
                invoiceId: id,
                feeTypeId: item.feeTypeId.value,
                description: item.description.value,
                amount: item.amount.value,
                discount: item.discount,
                netAmount: item.netAmount.value,
              ),
            )
            .toList();

        await _invoiceRepo.createInvoiceItems(itemsWithInvoiceId);

        return id;
      });

      // Log activity
      await _logActivity(
        action: 'create',
        module: 'invoices',
        details:
            'Generated generic invoice $invoiceNumber for ${student.studentName} ${student.fatherName} - ${data.month} (${selectedFeeTypes.length} fee types)',
      );

      return InvoiceGenerationResult.success(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        amount: netAmount,
      );
    } catch (e) {
      return InvoiceGenerationResult.failure('Error generating invoice: $e');
    }
  }

  /// Generate generic invoices in bulk with selectable fee types
  Future<BulkInvoiceResult> generateBulkGenericInvoices(
    BulkGenericInvoiceGenerationData data,
  ) async {
    final errors = <String>[];
    final generatedIds = <int>[];
    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    double totalAmount = 0;

    // Get enrolled students
    var studentQuery = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true) &
            _db.enrollments.status.equals('active'),
      ),
    ]);

    studentQuery.where(_db.students.status.equals('active'));

    if (data.classId != null) {
      studentQuery.where(_db.enrollments.classId.equals(data.classId!));
    }

    if (data.sectionId != null) {
      studentQuery.where(_db.enrollments.sectionId.equals(data.sectionId!));
    }

    final studentRows = await studentQuery.get();
    final totalStudents = studentRows.length;

    // Get students who already have invoices for this month
    final existingInvoiceStudents = <int>{};
    if (data.classId != null) {
      existingInvoiceStudents.addAll(
        await _invoiceRepo.getStudentsWithInvoices(data.month, data.classId!),
      );
    }

    for (final row in studentRows) {
      final student = row.readTable(_db.students);

      // Skip if already has invoice
      if (existingInvoiceStudents.contains(student.id)) {
        skippedCount++;
        continue;
      }

      // Check again for invoice existence (in case classId was null)
      if (data.classId == null) {
        final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(
          student.id,
          data.month,
        );
        if (hasInvoice) {
          skippedCount++;
          continue;
        }
      }

      // Generate generic invoice with selected fee types
      final result = await generateGenericInvoice(
        GenericInvoiceGenerationData(
          studentId: student.id,
          month: data.month,
          academicYear: data.academicYear,
          dueDate: data.dueDate,
          generatedBy: data.generatedBy,
          remarks: data.remarks,
          selectedFeeTypeIds: data.selectedFeeTypeIds,
        ),
      );

      if (result.success) {
        successCount++;
        totalAmount += result.amount ?? 0;
        if (result.invoiceId != null) {
          generatedIds.add(result.invoiceId!);
        }
      } else {
        errorCount++;
        errors.add('${student.studentName} ${student.fatherName}: ${result.error}');
      }
    }

    // Log activity
    await _logActivity(
      action: 'bulk_create',
      module: 'invoices',
      details:
          'Bulk generated $successCount generic invoices for ${data.month}, skipped $skippedCount, errors $errorCount',
    );

    return BulkInvoiceResult(
      totalStudents: totalStudents,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      totalAmount: totalAmount,
      errors: errors.take(50).toList(),
      generatedInvoiceIds: generatedIds,
    );
  }

  /// Preview generic invoice before generation
  Future<InvoicePreview> previewGenericInvoice({
    required int studentId,
    required String month,
    required String academicYear,
    List<int> selectedFeeTypeIds = const [],
  }) async {
    // Get student with enrollment
    final studentQuery = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
    ]);
    studentQuery.where(_db.students.id.equals(studentId));
    final studentRow = await studentQuery.getSingleOrNull();

    if (studentRow == null) {
      throw FeeNotFoundException('Student not found or not enrolled');
    }

    final student = studentRow.readTable(_db.students);
    final enrollment = studentRow.readTable(_db.enrollments);
    final schoolClass = studentRow.readTable(_db.classes);

    // Check if invoice already exists
    final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(studentId, month);

    // Get applicable fees (all types)
    final feeStructures = await _feeRepo.getStudentApplicableFees(
      classId: enrollment.classId,
      academicYear: academicYear,
      monthlyOnly: false,
    );

    // Filter by selected fee types if specified
    final selectedFeeTypes = selectedFeeTypeIds.isEmpty
        ? feeStructures
        : feeStructures.where((fs) => selectedFeeTypeIds.contains(fs.feeType.id)).toList();

    // Get concessions
    final discountInfo = await _concessionRepo.getStudentDiscountInfo(
      studentId,
    );

    // Calculate items
    final items = <InvoicePreviewItem>[];
    double totalAmount = 0;
    double totalDiscount = 0;

    for (final structure in selectedFeeTypes) {
      final feeAmount = structure.structure.amount;
      final discount = discountInfo.calculateDiscount(
        feeAmount,
        structure.feeType.id,
      );

      totalAmount += feeAmount;
      totalDiscount += discount;

      items.add(
        InvoicePreviewItem(
          feeTypeName: structure.feeType.name,
          amount: feeAmount,
          discount: discount,
          netAmount: feeAmount - discount,
        ),
      );
    }

    return InvoicePreview(
      studentName: '${student.studentName} ${student.fatherName}',
      admissionNumber: student.admissionNumber,
      className: schoolClass.name,
      month: month,
      alreadyGenerated: hasInvoice,
      items: items,
      totalAmount: totalAmount,
      totalDiscount: totalDiscount,
      netAmount: totalAmount - totalDiscount,
      hasConcession: discountInfo.hasConcession,
    );
  }

  // ============================================
  // CUSTOM AD-HOC INVOICE GENERATION
  // ============================================

  /// Generate a completely custom invoice with ad-hoc items
  /// This allows creating invoices for ANY purpose (exam fees, fines, activities, etc.)
  /// Not tied to fee structures or fee types
  Future<InvoiceGenerationResult> generateCustomInvoice({
    required int studentId,
    required String month,
    required String academicYear,
    required DateTime dueDate,
    required int generatedBy,
    required List<AdHocInvoiceItemData> adHocItems,
    String? remarks,
  }) async {
    try {
      if (adHocItems.isEmpty) {
        return InvoiceGenerationResult.failure('At least one invoice item is required');
      }

      // Check if invoice already exists for this month
      final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(studentId, month);
      if (hasInvoice) {
        return InvoiceGenerationResult.failure('Invoice already exists for $month');
      }

      // Get student info
      final studentQuery = _db.select(_db.students).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.students.id) &
              _db.enrollments.isCurrent.equals(true),
        ),
      ]);
      studentQuery.where(_db.students.id.equals(studentId));
      final studentRow = await studentQuery.getSingleOrNull();

      if (studentRow == null) {
        return InvoiceGenerationResult.failure('Student not found or not enrolled');
      }

      final student = studentRow.readTable(_db.students);

      // Check student is active
      if (student.status != 'active') {
        return InvoiceGenerationResult.failure('Student is not active');
      }

      // Calculate totals from ad-hoc items
      double totalAmount = 0;
      for (final item in adHocItems) {
        totalAmount += item.amount;
      }

      // Generate invoice number
      final invoiceNumber = await _invoiceRepo.generateInvoiceNumber(month);

      // Create invoice with ad-hoc items
      final invoiceId = await _db.transaction(() async {
        // Create the invoice
        final id = await _invoiceRepo.create(
          InvoicesCompanion.insert(
            invoiceNumber: invoiceNumber,
            studentId: studentId,
            month: month,
            academicYear: academicYear,
            totalAmount: totalAmount,
            discountAmount: const Value(0),
            netAmount: totalAmount,
            paidAmount: const Value(0),
            balanceAmount: totalAmount,
            issueDate: DateTime.now(),
            dueDate: dueDate,
            generatedBy: generatedBy,
            status: const Value('pending'),
            notes: Value(remarks ?? 'Custom invoice with ${adHocItems.length} item(s)'),
          ),
        );

        // Create ad-hoc invoice items (not tied to fee types)
        for (final item in adHocItems) {
          await _db.into(_db.adHocInvoiceItems).insert(
            AdHocInvoiceItemsCompanion.insert(
              invoiceId: id,
              description: item.description,
              amount: item.amount,
              category: Value(item.category),
            ),
          );
        }

        return id;
      });

      // Log activity
      await _logActivity(
        action: 'create_custom',
        module: 'invoices',
        details:
            'Generated custom invoice $invoiceNumber for ${student.studentName} - $month (${adHocItems.length} items)',
      );

      return InvoiceGenerationResult.success(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        amount: totalAmount,
      );
    } catch (e) {
      return InvoiceGenerationResult.failure('Error generating custom invoice: $e');
    }
  }

  /// Get ad-hoc items for an invoice
  Future<List<AdHocInvoiceItem>> getAdHocItems(int invoiceId) async {
    return await (_db.select(_db.adHocInvoiceItems)
      ..where((item) => item.invoiceId.equals(invoiceId)))
      .get();
  }

  /// Get invoice with all details including ad-hoc items
  Future<InvoiceWithFullDetails?> getInvoiceWithFullDetails(int invoiceId) async {
    final invoice = await _invoiceRepo.getInvoiceWithDetails(invoiceId);
    if (invoice == null) return null;

    final adHocItems = await getAdHocItems(invoiceId);

    return InvoiceWithFullDetails(
      invoice: invoice.invoice,
      student: invoice.student,
      items: invoice.items,
      adHocItems: adHocItems,
      payments: invoice.payments,
    );
  }

  // ============================================
  // INVOICE MANAGEMENT
  // ============================================

  /// Cancel an invoice
  Future<bool> cancelInvoice(int invoiceId, String reason) async {
    final invoice = await _invoiceRepo.getById(invoiceId);
    if (invoice == null) {
      throw FeeNotFoundException('Invoice not found');
    }

    if (invoice.status == FeeConstants.invoiceStatusPaid) {
      throw FeeValidationException({
        'status': 'Cannot cancel a fully paid invoice',
      });
    }

    if (invoice.paidAmount > 0) {
      throw FeeValidationException({
        'status': 'Cannot cancel an invoice with payments. Refund first.',
      });
    }

    final result = await _invoiceRepo.update(
      invoiceId,
      InvoicesCompanion(
        status: const Value('cancelled'),
        notes: Value('Cancelled: $reason'),
      ),
    );

    // Log activity
    await _logActivity(
      action: 'cancel',
      module: 'invoices',
      details: 'Cancelled invoice ${invoice.invoiceNumber}: $reason',
    );

    return result;
  }

  /// Update invoice due date
  Future<bool> updateDueDate(int invoiceId, DateTime newDueDate) async {
    final invoice = await _invoiceRepo.getById(invoiceId);
    if (invoice == null) {
      throw FeeNotFoundException('Invoice not found');
    }

    if (invoice.status == FeeConstants.invoiceStatusPaid) {
      throw FeeValidationException({
        'status': 'Cannot update due date for a paid invoice',
      });
    }

    final result = await _invoiceRepo.update(
      invoiceId,
      InvoicesCompanion(dueDate: Value(newDueDate)),
    );

    // Log activity
    await _logActivity(
      action: 'update',
      module: 'invoices',
      details:
          'Updated due date for invoice ${invoice.invoiceNumber} to $newDueDate',
    );

    return result;
  }

  /// Mark overdue invoices
  Future<int> markOverdueInvoices() async {
    final count = await _invoiceRepo.markOverdueInvoices();

    if (count > 0) {
      await _logActivity(
        action: 'bulk_update',
        module: 'invoices',
        details: 'Marked $count invoices as overdue',
      );
    }

    return count;
  }

  // ============================================
  // DEFAULTER MANAGEMENT
  // ============================================

  /// Get defaulter list
  Future<List<DefaulterInfo>> getDefaulters({
    int? classId,
    int minDaysOverdue = 1,
    int limit = 100,
  }) async {
    return await _invoiceRepo.getDefaulters(
      classId: classId,
      minDaysOverdue: minDaysOverdue,
      limit: limit,
    );
  }

  // ============================================
  // INVOICE PREVIEW
  // ============================================

  /// Preview invoice before generation (does not save)
  Future<InvoicePreview> previewInvoice({
    required int studentId,
    required String month,
    required String academicYear,
  }) async {
    // Get student with enrollment
    final studentQuery = _db.select(_db.students).join([
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
    ]);
    studentQuery.where(_db.students.id.equals(studentId));
    final studentRow = await studentQuery.getSingleOrNull();

    if (studentRow == null) {
      throw FeeNotFoundException('Student not found or not enrolled');
    }

    final student = studentRow.readTable(_db.students);
    final enrollment = studentRow.readTable(_db.enrollments);
    final schoolClass = studentRow.readTable(_db.classes);

    // Check if invoice already exists
    final hasInvoice = await _invoiceRepo.hasInvoiceForMonth(studentId, month);

    // Get applicable fees
    final feeStructures = await _feeRepo.getStudentApplicableFees(
      classId: enrollment.classId,
      academicYear: academicYear,
      monthlyOnly: true,
    );

    // Get concessions
    final discountInfo = await _concessionRepo.getStudentDiscountInfo(
      studentId,
    );

    // Calculate items
    final items = <InvoicePreviewItem>[];
    double totalAmount = 0;
    double totalDiscount = 0;

    for (final structure in feeStructures) {
      final feeAmount = structure.structure.amount;
      final discount = discountInfo.calculateDiscount(
        feeAmount,
        structure.feeType.id,
      );

      totalAmount += feeAmount;
      totalDiscount += discount;

      items.add(
        InvoicePreviewItem(
          feeTypeName: structure.feeType.name,
          amount: feeAmount,
          discount: discount,
          netAmount: feeAmount - discount,
        ),
      );
    }

    return InvoicePreview(
      studentName: '${student.studentName} ${student.fatherName}',
      admissionNumber: student.admissionNumber,
      className: schoolClass.name,
      month: month,
      alreadyGenerated: hasInvoice,
      items: items,
      totalAmount: totalAmount,
      totalDiscount: totalDiscount,
      netAmount: totalAmount - totalDiscount,
      hasConcession: discountInfo.hasConcession,
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

/// Invoice preview data
class InvoicePreview {
  final String studentName;
  final String admissionNumber;
  final String className;
  final String month;
  final bool alreadyGenerated;
  final List<InvoicePreviewItem> items;
  final double totalAmount;
  final double totalDiscount;
  final double netAmount;
  final bool hasConcession;

  const InvoicePreview({
    required this.studentName,
    required this.admissionNumber,
    required this.className,
    required this.month,
    required this.alreadyGenerated,
    required this.items,
    required this.totalAmount,
    required this.totalDiscount,
    required this.netAmount,
    required this.hasConcession,
  });
}

/// Invoice preview item
class InvoicePreviewItem {
  final String feeTypeName;
  final double amount;
  final double discount;
  final double netAmount;

  const InvoicePreviewItem({
    required this.feeTypeName,
    required this.amount,
    required this.discount,
    required this.netAmount,
  });
}

// ============================================
// AD-HOC INVOICE DATA CLASSES
// ============================================

/// Data for an ad-hoc invoice item (not tied to fee types)
class AdHocInvoiceItemData {
  final String description;
  final double amount;
  final String category;

  const AdHocInvoiceItemData({
    required this.description,
    required this.amount,
    this.category = 'misc',
  });

  factory AdHocInvoiceItemData.examFee(String examName, double amount) {
    return AdHocInvoiceItemData(
      description: 'Exam Fee - $examName',
      amount: amount,
      category: 'exam',
    );
  }

  factory AdHocInvoiceItemData.lateFine(double amount) {
    return AdHocInvoiceItemData(
      description: 'Late Payment Fine',
      amount: amount,
      category: 'fine',
    );
  }

  factory AdHocInvoiceItemData.damageFee(String item, double amount) {
    return AdHocInvoiceItemData(
      description: 'Damage Fee - $item',
      amount: amount,
      category: 'fine',
    );
  }

  factory AdHocInvoiceItemData.activityFee(String activityName, double amount) {
    return AdHocInvoiceItemData(
      description: 'Activity Fee - $activityName',
      amount: amount,
      category: 'activity',
    );
  }

  factory AdHocInvoiceItemData.miscellaneous(String description, double amount) {
    return AdHocInvoiceItemData(
      description: description,
      amount: amount,
      category: 'misc',
    );
  }
}

/// Invoice with full details including ad-hoc items
class InvoiceWithFullDetails {
  final Invoice invoice;
  final Student student;
  final List<InvoiceItemWithType> items;
  final List<AdHocInvoiceItem> adHocItems;
  final List<PaymentSummary> payments;

  const InvoiceWithFullDetails({
    required this.invoice,
    required this.student,
    required this.items,
    required this.adHocItems,
    required this.payments,
  });

  /// Total from regular fee type items
  double get regularTotal => items.fold(0, (sum, i) => sum + (i.item.netAmount));

  /// Total from ad-hoc items
  double get adHocTotal => adHocItems.fold(0, (sum, i) => sum + i.amount);

  /// Grand total
  double get grandTotal => regularTotal + adHocTotal;

  /// Has ad-hoc items
  bool get hasAdHocItems => adHocItems.isNotEmpty;
}
