/// EduX School Management System
/// Invoice Repository - Data access layer for invoices and invoice items
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/constants/app_constants.dart';

/// Invoice with full details
class InvoiceWithDetails {
  final Invoice invoice;
  final Student student;
  final Enrollment enrollment;
  final SchoolClass schoolClass;
  final Section? section;
  final List<InvoiceItemWithType> items;
  final List<PaymentSummary> payments;

  const InvoiceWithDetails({
    required this.invoice,
    required this.student,
    required this.enrollment,
    required this.schoolClass,
    this.section,
    this.items = const [],
    this.payments = const [],
  });

  String get studentName => '${student.studentName} ${student.fatherName}';
  String get classSection => section != null
      ? '${schoolClass.name}-${section!.name}'
      : schoolClass.name;

  int get daysOverdue {
    if (invoice.status == FeeConstants.invoiceStatusPaid) return 0;
    final now = DateTime.now();
    if (now.isBefore(invoice.dueDate)) return 0;
    return now.difference(invoice.dueDate).inDays;
  }

  bool get isOverdue => daysOverdue > 0 && invoice.status != 'paid';
}

/// Invoice item with fee type details
class InvoiceItemWithType {
  final InvoiceItem item;
  final FeeType feeType;

  const InvoiceItemWithType({required this.item, required this.feeType});
}

/// Payment summary for invoice
class PaymentSummary {
  final int id;
  final String receiptNumber;
  final double amount;
  final String paymentMode;
  final DateTime paymentDate;

  const PaymentSummary({
    required this.id,
    required this.receiptNumber,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
  });
}

/// Invoice filter parameters
class InvoiceFilters {
  final String? month;
  final String? status;
  final int? classId;
  final int? sectionId;
  final int? studentId;
  final String? academicYear;
  final String? searchQuery;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final int limit;
  final int offset;

  const InvoiceFilters({
    this.month,
    this.status,
    this.classId,
    this.sectionId,
    this.studentId,
    this.academicYear,
    this.searchQuery,
    this.dueDateFrom,
    this.dueDateTo,
    this.limit = 50,
    this.offset = 0,
  });

  InvoiceFilters copyWith({
    String? month,
    String? status,
    int? classId,
    int? sectionId,
    int? studentId,
    String? academicYear,
    String? searchQuery,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    int? limit,
    int? offset,
    bool clearMonth = false,
    bool clearStatus = false,
    bool clearClassId = false,
    bool clearStudentId = false,
  }) {
    return InvoiceFilters(
      month: clearMonth ? null : (month ?? this.month),
      status: clearStatus ? null : (status ?? this.status),
      classId: clearClassId ? null : (classId ?? this.classId),
      sectionId: sectionId ?? this.sectionId,
      studentId: clearStudentId ? null : (studentId ?? this.studentId),
      academicYear: academicYear ?? this.academicYear,
      searchQuery: searchQuery ?? this.searchQuery,
      dueDateFrom: dueDateFrom ?? this.dueDateFrom,
      dueDateTo: dueDateTo ?? this.dueDateTo,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Invoice statistics summary
class InvoiceStats {
  final int totalCount;
  final int pendingCount;
  final int partialCount;
  final int paidCount;
  final int overdueCount;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;

  const InvoiceStats({
    required this.totalCount,
    required this.pendingCount,
    required this.partialCount,
    required this.paidCount,
    required this.overdueCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
  });
}

/// Defaulter information
class DefaulterInfo {
  final Student student;
  final Enrollment enrollment;
  final SchoolClass schoolClass;
  final Section? section;
  final Guardian? primaryGuardian;
  final double totalPending;
  final int pendingMonths;
  final int maxDaysOverdue;
  final List<String> pendingMonthsList;

  const DefaulterInfo({
    required this.student,
    required this.enrollment,
    required this.schoolClass,
    this.section,
    this.primaryGuardian,
    required this.totalPending,
    required this.pendingMonths,
    required this.maxDaysOverdue,
    required this.pendingMonthsList,
  });

  String get studentName => '${student.studentName} ${student.fatherName}';
  String get classSection => section != null
      ? '${schoolClass.name}-${section!.name}'
      : schoolClass.name;
}

/// Abstract invoice repository interface
abstract class InvoiceRepository {
  // CRUD operations
  Future<Invoice?> getById(int id);
  Future<Invoice?> getByInvoiceNumber(String invoiceNumber);
  Future<int> create(InvoicesCompanion invoice);
  Future<bool> update(int id, InvoicesCompanion invoice);
  Future<bool> delete(int id);

  // Invoice items
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId);
  Future<int> createInvoiceItem(InvoiceItemsCompanion item);
  Future<void> createInvoiceItems(List<InvoiceItemsCompanion> items);
  Future<bool> deleteInvoiceItems(int invoiceId);

  // Query operations
  Future<List<InvoiceWithDetails>> getInvoices(InvoiceFilters filters);
  Future<InvoiceWithDetails?> getInvoiceWithDetails(int invoiceId);
  Future<List<Invoice>> getStudentInvoices(int studentId, {String? status});
  Future<List<Invoice>> getUnpaidInvoicesForStudent(int studentId);

  // Status management
  Future<bool> updateStatus(int invoiceId, String status);
  Future<bool> updatePaidAmount(int invoiceId, double paidAmount);
  Future<int> markOverdueInvoices();

  // Invoice number generation
  Future<String> generateInvoiceNumber(String month);

  // Statistics and reports
  Future<InvoiceStats> getInvoiceStats({String? month, int? classId});
  Future<List<DefaulterInfo>> getDefaulters({
    int? classId,
    int minDaysOverdue = 1,
    int limit = 100,
  });

  // Existence checks
  Future<bool> hasInvoiceForMonth(int studentId, String month);
  Future<List<int>> getStudentsWithInvoices(String month, int classId);

  // Outstanding fees
  Future<double> getTotalOutstanding();
}

/// Drift implementation of InvoiceRepository
class DriftInvoiceRepository implements InvoiceRepository {
  final AppDatabase _db;

  DriftInvoiceRepository(this._db);

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  @override
  Future<Invoice?> getById(int id) async {
    return await (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Invoice?> getByInvoiceNumber(String invoiceNumber) async {
    return await (_db.select(
      _db.invoices,
    )..where((t) => t.invoiceNumber.equals(invoiceNumber))).getSingleOrNull();
  }

  @override
  Future<int> create(InvoicesCompanion invoice) async {
    return await _db.into(_db.invoices).insert(invoice);
  }

  @override
  Future<bool> update(int id, InvoicesCompanion invoice) async {
    final updated = invoice.copyWith(updatedAt: Value(DateTime.now()));
    return await (_db.update(
          _db.invoices,
        )..where((t) => t.id.equals(id))).write(updated) >
        0;
  }

  @override
  Future<bool> delete(int id) async {
    return await _db.transaction(() async {
      // Delete invoice items first
      await deleteInvoiceItems(id);
      // Delete invoice
      return await (_db.delete(
            _db.invoices,
          )..where((t) => t.id.equals(id))).go() >
          0;
    });
  }

  // ============================================
  // INVOICE ITEMS
  // ============================================

  @override
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    return await (_db.select(
      _db.invoiceItems,
    )..where((t) => t.invoiceId.equals(invoiceId))).get();
  }

  @override
  Future<int> createInvoiceItem(InvoiceItemsCompanion item) async {
    return await _db.into(_db.invoiceItems).insert(item);
  }

  @override
  Future<void> createInvoiceItems(List<InvoiceItemsCompanion> items) async {
    await _db.batch((batch) {
      batch.insertAll(_db.invoiceItems, items);
    });
  }

  @override
  Future<bool> deleteInvoiceItems(int invoiceId) async {
    return await (_db.delete(
          _db.invoiceItems,
        )..where((t) => t.invoiceId.equals(invoiceId))).go() >
        0;
  }

  // ============================================
  // QUERY OPERATIONS
  // ============================================

  @override
  Future<List<InvoiceWithDetails>> getInvoices(InvoiceFilters filters) async {
    final query = _db.select(_db.invoices).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.invoices.studentId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
    ]);

    Expression<bool>? whereCondition;

    if (filters.month != null) {
      whereCondition = _db.invoices.month.equals(filters.month!);
    }

    if (filters.status != null) {
      final condition = _db.invoices.status.equals(filters.status!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.classId != null) {
      final condition = _db.enrollments.classId.equals(filters.classId!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.sectionId != null) {
      final condition = _db.enrollments.sectionId.equals(filters.sectionId!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.studentId != null) {
      final condition = _db.invoices.studentId.equals(filters.studentId!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.academicYear != null) {
      final condition = _db.invoices.academicYear.equals(filters.academicYear!);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final searchTerm = '%${filters.searchQuery!.toLowerCase()}%';
      final condition =
          _db.students.studentName.lower().like(searchTerm) |
          _db.students.fatherName.lower().like(searchTerm) |
          _db.students.admissionNumber.lower().like(searchTerm) |
          _db.invoices.invoiceNumber.lower().like(searchTerm);
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.dueDateFrom != null) {
      final condition = _db.invoices.dueDate.isBiggerOrEqualValue(
        filters.dueDateFrom!,
      );
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (filters.dueDateTo != null) {
      final condition = _db.invoices.dueDate.isSmallerOrEqualValue(
        filters.dueDateTo!,
      );
      whereCondition = whereCondition == null
          ? condition
          : whereCondition & condition;
    }

    if (whereCondition != null) {
      query.where(whereCondition);
    }

    query.orderBy([OrderingTerm.desc(_db.invoices.createdAt)]);
    query.limit(filters.limit, offset: filters.offset);

    final rows = await query.get();
    final results = <InvoiceWithDetails>[];

    for (final row in rows) {
      final invoice = row.readTable(_db.invoices);

      // Get invoice items with fee types
      final items = await _getInvoiceItemsWithTypes(invoice.id);

      // Get payment summaries
      final payments = await _getPaymentSummaries(invoice.id);

      results.add(
        InvoiceWithDetails(
          invoice: invoice,
          student: row.readTable(_db.students),
          enrollment: row.readTable(_db.enrollments),
          schoolClass: row.readTable(_db.classes),
          section: row.readTableOrNull(_db.sections),
          items: items,
          payments: payments,
        ),
      );
    }

    return results;
  }

  @override
  Future<InvoiceWithDetails?> getInvoiceWithDetails(int invoiceId) async {
    final query = _db.select(_db.invoices).join([
      innerJoin(
        _db.students,
        _db.students.id.equalsExp(_db.invoices.studentId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.students.id) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
      leftOuterJoin(
        _db.sections,
        _db.sections.id.equalsExp(_db.enrollments.sectionId),
      ),
    ]);

    query.where(_db.invoices.id.equals(invoiceId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final invoice = row.readTable(_db.invoices);
    final items = await _getInvoiceItemsWithTypes(invoice.id);
    final payments = await _getPaymentSummaries(invoice.id);

    return InvoiceWithDetails(
      invoice: invoice,
      student: row.readTable(_db.students),
      enrollment: row.readTable(_db.enrollments),
      schoolClass: row.readTable(_db.classes),
      section: row.readTableOrNull(_db.sections),
      items: items,
      payments: payments,
    );
  }

  @override
  Future<List<Invoice>> getStudentInvoices(
    int studentId, {
    String? status,
  }) async {
    var query = _db.select(_db.invoices)
      ..where((t) => t.studentId.equals(studentId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (status != null) {
      query = query..where((t) => t.status.equals(status));
    }

    return await query.get();
  }

  @override
  Future<List<Invoice>> getUnpaidInvoicesForStudent(int studentId) async {
    return await (_db.select(_db.invoices)
          ..where(
            (t) =>
                t.studentId.equals(studentId) &
                (t.status.equals('pending') |
                    t.status.equals('partial') |
                    t.status.equals('overdue')),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  // ============================================
  // STATUS MANAGEMENT
  // ============================================

  @override
  Future<bool> updateStatus(int invoiceId, String status) async {
    return await update(invoiceId, InvoicesCompanion(status: Value(status)));
  }

  @override
  Future<bool> updatePaidAmount(int invoiceId, double paidAmount) async {
    final invoice = await getById(invoiceId);
    if (invoice == null) return false;

    // Don't update status for cancelled invoices
    if (invoice.status == FeeConstants.invoiceStatusCancelled) {
      return false;
    }

    String newStatus;
    if (paidAmount >= invoice.netAmount) {
      newStatus = 'paid';
    } else if (paidAmount > 0) {
      newStatus = 'partial';
    } else {
      newStatus = invoice.dueDate.isBefore(DateTime.now())
          ? 'overdue'
          : 'pending';
    }

    final balanceAmount = invoice.netAmount - paidAmount;

    return await update(
      invoiceId,
      InvoicesCompanion(
        paidAmount: Value(paidAmount),
        balanceAmount: Value(balanceAmount < 0 ? 0 : balanceAmount),
        status: Value(newStatus),
        lastPaymentDate: paidAmount > 0
            ? Value(DateTime.now())
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<int> markOverdueInvoices() async {
    final now = DateTime.now();
    return await (_db.update(_db.invoices)..where(
          (t) =>
              t.dueDate.isSmallerThanValue(now) &
              (t.status.equals('pending') | t.status.equals('partial')),
        ))
        .write(const InvoicesCompanion(status: Value('overdue')));
  }

  // ============================================
  // INVOICE NUMBER GENERATION
  // ============================================

  @override
  Future<String> generateInvoiceNumber(String month) async {
    // Get sequence from number_sequences table
    final sequence = await (_db.select(
      _db.numberSequences,
    )..where((t) => t.name.equals('invoice'))).getSingleOrNull();

    if (sequence == null) {
      // Create sequence if not exists
      await _db
          .into(_db.numberSequences)
          .insert(
            NumberSequencesCompanion.insert(
              name: 'invoice',
              prefix: const Value('INV-'),
              currentNumber: const Value(1),
              minDigits: const Value(6),
            ),
          );
      return 'INV-$month-000001';
    }

    // Increment and get new number
    final nextNumber = sequence.currentNumber + 1;
    final paddedNumber = nextNumber.toString().padLeft(sequence.minDigits, '0');

    // Update sequence
    await (_db.update(_db.numberSequences)
          ..where((t) => t.name.equals('invoice')))
        .write(NumberSequencesCompanion(currentNumber: Value(nextNumber)));

    return 'INV-$month-$paddedNumber';
  }

  // ============================================
  // STATISTICS AND REPORTS
  // ============================================

  @override
  Future<InvoiceStats> getInvoiceStats({String? month, int? classId}) async {
    Expression<bool>? baseCondition;

    if (month != null) {
      baseCondition = _db.invoices.month.equals(month);
    }

    // For class filtering, we need a join
    if (classId != null) {
      // Get all invoices for the month/class combination
      final query = _db.select(_db.invoices).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.invoices.studentId) &
              _db.enrollments.isCurrent.equals(true),
        ),
      ]);

      if (baseCondition != null) {
        query.where(baseCondition);
      }
      query.where(_db.enrollments.classId.equals(classId));

      final invoices = (await query.get())
          .map((r) => r.readTable(_db.invoices))
          .toList();

      return _calculateStats(invoices);
    }

    // Simple query without class filter
    var query = _db.select(_db.invoices);
    if (baseCondition != null) {
      query = query..where((t) => baseCondition!);
    }

    final invoices = await query.get();
    return _calculateStats(invoices);
  }

  InvoiceStats _calculateStats(List<Invoice> invoices) {
    int pendingCount = 0;
    int partialCount = 0;
    int paidCount = 0;
    int overdueCount = 0;
    double totalAmount = 0;
    double paidAmount = 0;

    for (final invoice in invoices) {
      totalAmount += invoice.netAmount;
      paidAmount += invoice.paidAmount;

      switch (invoice.status) {
        case 'pending':
          pendingCount++;
          break;
        case 'partial':
          partialCount++;
          break;
        case 'paid':
          paidCount++;
          break;
        case 'overdue':
          overdueCount++;
          break;
      }
    }

    return InvoiceStats(
      totalCount: invoices.length,
      pendingCount: pendingCount,
      partialCount: partialCount,
      paidCount: paidCount,
      overdueCount: overdueCount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      pendingAmount: totalAmount - paidAmount,
    );
  }

  @override
  Future<List<DefaulterInfo>> getDefaulters({
    int? classId,
    int minDaysOverdue = 1,
    int limit = 100,
  }) async {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: minDaysOverdue));

    // Get students with unpaid invoices past due date
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([
        _db.invoices.studentId,
        _db.invoices.balanceAmount.sum(),
        _db.invoices.id.count(),
      ])
      ..where(
        _db.invoices.status.isIn(['pending', 'partial', 'overdue']) &
            _db.invoices.dueDate.isSmallerOrEqualValue(cutoffDate),
      )
      ..groupBy([_db.invoices.studentId]);

    final studentAggregates = await query.get();

    final defaulters = <DefaulterInfo>[];

    for (final row in studentAggregates) {
      final studentId = row.read(_db.invoices.studentId)!;
      final totalPending = row.read(_db.invoices.balanceAmount.sum()) ?? 0.0;
      final pendingCount = row.read(_db.invoices.id.count()) ?? 0;

      // Get student with enrollment
      final studentQuery = _db.select(_db.students).join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.students.id) &
              _db.enrollments.isCurrent.equals(true),
        ),
        innerJoin(
          _db.classes,
          _db.classes.id.equalsExp(_db.enrollments.classId),
        ),
        leftOuterJoin(
          _db.sections,
          _db.sections.id.equalsExp(_db.enrollments.sectionId),
        ),
      ]);
      studentQuery.where(_db.students.id.equals(studentId));

      if (classId != null) {
        studentQuery.where(_db.enrollments.classId.equals(classId));
      }

      final studentRow = await studentQuery.getSingleOrNull();
      if (studentRow == null) continue;

      // Get overdue invoices for this student
      final overdueInvoices =
          await (_db.select(_db.invoices)
                ..where(
                  (t) =>
                      t.studentId.equals(studentId) &
                      t.status.isIn(['pending', 'partial', 'overdue']) &
                      t.dueDate.isSmallerOrEqualValue(cutoffDate),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
              .get();

      if (overdueInvoices.isEmpty) continue;

      // Calculate max days overdue
      final oldestDueDate = overdueInvoices.first.dueDate;
      final maxDaysOverdue = now.difference(oldestDueDate).inDays;

      // Get pending months list
      final pendingMonthsList = overdueInvoices
          .map((i) => i.month)
          .toSet()
          .toList();

      // Get primary guardian
      final guardianQuery = _db.select(_db.guardians).join([
        innerJoin(
          _db.studentGuardians,
          _db.studentGuardians.guardianId.equalsExp(_db.guardians.id) &
              _db.studentGuardians.studentId.equals(studentId) &
              _db.studentGuardians.isPrimary.equals(true),
        ),
      ]);
      final guardianRow = await guardianQuery.getSingleOrNull();

      defaulters.add(
        DefaulterInfo(
          student: studentRow.readTable(_db.students),
          enrollment: studentRow.readTable(_db.enrollments),
          schoolClass: studentRow.readTable(_db.classes),
          section: studentRow.readTableOrNull(_db.sections),
          primaryGuardian: guardianRow?.readTableOrNull(_db.guardians),
          totalPending: totalPending,
          pendingMonths: pendingCount,
          maxDaysOverdue: maxDaysOverdue,
          pendingMonthsList: pendingMonthsList,
        ),
      );

      // Apply limit check (limit: 0 or negative means no limit)
      if (limit > 0 && defaulters.length >= limit) break;
    }

    // Sort by max days overdue descending
    defaulters.sort((a, b) => b.maxDaysOverdue.compareTo(a.maxDaysOverdue));

    return defaulters;
  }

  // ============================================
  // EXISTENCE CHECKS
  // ============================================

  @override
  Future<bool> hasInvoiceForMonth(int studentId, String month) async {
    final existing =
        await (_db.select(_db.invoices)..where(
              (t) => t.studentId.equals(studentId) & t.month.equals(month),
            ))
            .getSingleOrNull();
    return existing != null;
  }

  @override
  Future<List<int>> getStudentsWithInvoices(String month, int classId) async {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([_db.invoices.studentId])
      ..join([
        innerJoin(
          _db.enrollments,
          _db.enrollments.studentId.equalsExp(_db.invoices.studentId) &
              _db.enrollments.isCurrent.equals(true),
        ),
      ])
      ..where(
        _db.invoices.month.equals(month) &
            _db.enrollments.classId.equals(classId),
      );

    final rows = await query.get();
    return rows.map((r) => r.read(_db.invoices.studentId)!).toList();
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  Future<List<InvoiceItemWithType>> _getInvoiceItemsWithTypes(
    int invoiceId,
  ) async {
    final query = _db.select(_db.invoiceItems).join([
      innerJoin(
        _db.feeTypes,
        _db.feeTypes.id.equalsExp(_db.invoiceItems.feeTypeId),
      ),
    ]);
    query.where(_db.invoiceItems.invoiceId.equals(invoiceId));

    final rows = await query.get();

    return rows.map((row) {
      return InvoiceItemWithType(
        item: row.readTable(_db.invoiceItems),
        feeType: row.readTable(_db.feeTypes),
      );
    }).toList();
  }

  Future<List<PaymentSummary>> _getPaymentSummaries(int invoiceId) async {
    final payments =
        await (_db.select(_db.payments)
              ..where(
                (t) =>
                    t.invoiceId.equals(invoiceId) & t.isCancelled.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
            .get();

    return payments
        .map(
          (p) => PaymentSummary(
            id: p.id,
            receiptNumber: p.receiptNumber,
            amount: p.amount,
            paymentMode: p.paymentMode,
            paymentDate: p.paymentDate,
          ),
        )
        .toList();
  }

  @override
  Future<double> getTotalOutstanding() async {
    final sumExpr = _db.invoices.balanceAmount.sum();
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([sumExpr])
      ..where(_db.invoices.status.isIn(['pending', 'partial', 'overdue']));

    final result = await query.getSingle();
    return result.read(sumExpr) ?? 0.0;
  }
}
