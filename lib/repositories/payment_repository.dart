/// EduX School Management System
/// Payment Repository - Data access layer for payment transactions
library;

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../core/constants/app_constants.dart';

/// Payment with full details
class PaymentWithDetails {
  final Payment payment;
  final Invoice invoice;
  final Student student;
  final Enrollment enrollment;
  final SchoolClass schoolClass;
  final Section? section;

  const PaymentWithDetails({
    required this.payment,
    required this.invoice,
    required this.student,
    required this.enrollment,
    required this.schoolClass,
    this.section,
  });

  String get studentName => '${student.studentName} ${student.fatherName}';
  String get classSection => section != null
      ? '${schoolClass.name}-${section!.name}'
      : schoolClass.name;
}

/// Payment filter parameters
class PaymentFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? paymentMode;
  final int? studentId;
  final int? classId;
  final int? collectedBy;
  final String? searchQuery;
  final int limit;
  final int offset;

  const PaymentFilters({
    this.dateFrom,
    this.dateTo,
    this.paymentMode,
    this.studentId,
    this.classId,
    this.collectedBy,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  PaymentFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentMode,
    int? studentId,
    int? classId,
    int? collectedBy,
    String? searchQuery,
    int? limit,
    int? offset,
    bool clearDateRange = false,
    bool clearPaymentMode = false,
    bool clearStudentId = false,
    bool clearClassId = false,
  }) {
    return PaymentFilters(
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      paymentMode: clearPaymentMode ? null : (paymentMode ?? this.paymentMode),
      studentId: clearStudentId ? null : (studentId ?? this.studentId),
      classId: clearClassId ? null : (classId ?? this.classId),
      collectedBy: collectedBy ?? this.collectedBy,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Daily collection summary
class DailyCollectionSummary {
  final DateTime date;
  final double totalAmount;
  final int paymentCount;
  final Map<String, double> byPaymentMode;

  const DailyCollectionSummary({
    required this.date,
    required this.totalAmount,
    required this.paymentCount,
    required this.byPaymentMode,
  });
}

/// Collection summary by mode
class CollectionByMode {
  final String paymentMode;
  final double totalAmount;
  final int count;

  const CollectionByMode({
    required this.paymentMode,
    required this.totalAmount,
    required this.count,
  });
}

/// Collection summary by class
class CollectionByClass {
  final int classId;
  final String className;
  final double totalAmount;
  final int paymentCount;
  final int studentCount;

  const CollectionByClass({
    required this.classId,
    required this.className,
    required this.totalAmount,
    required this.paymentCount,
    required this.studentCount,
  });
}

/// Monthly collection summary
class MonthlyCollectionSummary {
  final String month;
  final double totalInvoiced;
  final double totalCollected;
  final double totalPending;
  final int totalInvoices;
  final int paidInvoices;
  final int pendingInvoices;
  final double collectionRate;

  const MonthlyCollectionSummary({
    required this.month,
    required this.totalInvoiced,
    required this.totalCollected,
    required this.totalPending,
    required this.totalInvoices,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.collectionRate,
  });
}

/// Abstract payment repository interface
abstract class PaymentRepository {
  // CRUD operations
  Future<Payment?> getById(int id);
  Future<Payment?> getByReceiptNumber(String receiptNumber);
  Future<int> create(PaymentsCompanion payment);
  Future<bool> update(int id, PaymentsCompanion payment);
  Future<bool> cancelPayment(int id, String reason);

  // Query operations
  Future<List<PaymentWithDetails>> getPayments(PaymentFilters filters);
  Future<PaymentWithDetails?> getPaymentWithDetails(int paymentId);
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId);
  Future<List<Payment>> getPaymentsByStudent(int studentId);
  Future<List<Payment>> getRecentPayments({int limit = 20});

  // Receipt number generation
  Future<String> generateReceiptNumber();

  // Collection reports
  Future<DailyCollectionSummary> getDailyCollection(DateTime date);
  Future<List<DailyCollectionSummary>> getCollectionHistory({
    required DateTime from,
    required DateTime to,
  });
  Future<List<CollectionByMode>> getCollectionByMode({
    DateTime? from,
    DateTime? to,
  });
  Future<List<CollectionByClass>> getCollectionByClass({
    required DateTime from,
    required DateTime to,
  });
  Future<MonthlyCollectionSummary> getMonthlyCollectionSummary(String month);

  // Statistics
  Future<double> getTotalCollectionForDate(DateTime date);
  Future<double> getTotalCollectionForPeriod({
    required DateTime from,
    required DateTime to,
  });
}

/// Drift implementation of PaymentRepository
class DriftPaymentRepository implements PaymentRepository {
  final AppDatabase _db;

  DriftPaymentRepository(this._db);

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  @override
  Future<Payment?> getById(int id) async {
    return await (_db.select(
      _db.payments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<Payment?> getByReceiptNumber(String receiptNumber) async {
    return await (_db.select(
      _db.payments,
    )..where((t) => t.receiptNumber.equals(receiptNumber))).getSingleOrNull();
  }

  @override
  Future<int> create(PaymentsCompanion payment) async {
    return await _db.into(_db.payments).insert(payment);
  }

  @override
  Future<bool> update(int id, PaymentsCompanion payment) async {
    final updated = payment.copyWith(updatedAt: Value(DateTime.now()));
    return await (_db.update(
          _db.payments,
        )..where((t) => t.id.equals(id))).write(updated) >
        0;
  }

  @override
  Future<bool> cancelPayment(int id, String reason) async {
    return await update(
      id,
      PaymentsCompanion(
        isCancelled: const Value(true),
        cancellationReason: Value(reason),
      ),
    );
  }

  // ============================================
  // QUERY OPERATIONS
  // ============================================

  @override
  Future<List<PaymentWithDetails>> getPayments(PaymentFilters filters) async {
    final query = _db.select(_db.payments).join([
      innerJoin(
        _db.invoices,
        _db.invoices.id.equalsExp(_db.payments.invoiceId),
      ),
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

    // Exclude cancelled payments by default
    Expression<bool> whereCondition = _db.payments.isCancelled.equals(false);

    if (filters.dateFrom != null) {
      whereCondition =
          whereCondition &
          _db.payments.paymentDate.isBiggerOrEqualValue(filters.dateFrom!);
    }

    if (filters.dateTo != null) {
      final endOfDay = DateTime(
        filters.dateTo!.year,
        filters.dateTo!.month,
        filters.dateTo!.day,
        23,
        59,
        59,
      );
      whereCondition =
          whereCondition &
          _db.payments.paymentDate.isSmallerOrEqualValue(endOfDay);
    }

    if (filters.paymentMode != null) {
      whereCondition =
          whereCondition &
          _db.payments.paymentMode.equals(filters.paymentMode!);
    }

    if (filters.studentId != null) {
      whereCondition =
          whereCondition & _db.invoices.studentId.equals(filters.studentId!);
    }

    if (filters.classId != null) {
      whereCondition =
          whereCondition & _db.enrollments.classId.equals(filters.classId!);
    }

    if (filters.collectedBy != null) {
      whereCondition =
          whereCondition & _db.payments.receivedBy.equals(filters.collectedBy!);
    }

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final searchTerm = '%${filters.searchQuery!.toLowerCase()}%';
      whereCondition =
          whereCondition &
          (_db.students.studentName.lower().like(searchTerm) |
              _db.students.fatherName.lower().like(searchTerm) |
              _db.students.admissionNumber.lower().like(searchTerm) |
              _db.payments.receiptNumber.lower().like(searchTerm));
    }

    query.where(whereCondition);
    query.orderBy([OrderingTerm.desc(_db.payments.paymentDate)]);
    
    // Apply pagination (limit: 0 or negative means no limit)
    if (filters.limit > 0) {
      query.limit(filters.limit, offset: filters.offset);
    }

    final rows = await query.get();

    return rows.map((row) {
      return PaymentWithDetails(
        payment: row.readTable(_db.payments),
        invoice: row.readTable(_db.invoices),
        student: row.readTable(_db.students),
        enrollment: row.readTable(_db.enrollments),
        schoolClass: row.readTable(_db.classes),
        section: row.readTableOrNull(_db.sections),
      );
    }).toList();
  }

  @override
  Future<PaymentWithDetails?> getPaymentWithDetails(int paymentId) async {
    final query = _db.select(_db.payments).join([
      innerJoin(
        _db.invoices,
        _db.invoices.id.equalsExp(_db.payments.invoiceId),
      ),
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

    query.where(_db.payments.id.equals(paymentId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return PaymentWithDetails(
      payment: row.readTable(_db.payments),
      invoice: row.readTable(_db.invoices),
      student: row.readTable(_db.students),
      enrollment: row.readTable(_db.enrollments),
      schoolClass: row.readTable(_db.classes),
      section: row.readTableOrNull(_db.sections),
    );
  }

  @override
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    return await (_db.select(_db.payments)
          ..where(
            (t) => t.invoiceId.equals(invoiceId) & t.isCancelled.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .get();
  }

  @override
  Future<List<Payment>> getPaymentsByStudent(int studentId) async {
    final query = _db.select(_db.payments).join([
      innerJoin(
        _db.invoices,
        _db.invoices.id.equalsExp(_db.payments.invoiceId),
      ),
    ]);

    query.where(
      _db.invoices.studentId.equals(studentId) &
          _db.payments.isCancelled.equals(false),
    );
    query.orderBy([OrderingTerm.desc(_db.payments.paymentDate)]);

    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.payments)).toList();
  }

  @override
  Future<List<Payment>> getRecentPayments({int limit = 20}) async {
    return await (_db.select(_db.payments)
          ..where((t) => t.isCancelled.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)])
          ..limit(limit))
        .get();
  }

  // ============================================
  // RECEIPT NUMBER GENERATION
  // ============================================

  @override
  Future<String> generateReceiptNumber() async {
    // Get sequence from number_sequences table
    final sequence = await (_db.select(
      _db.numberSequences,
    )..where((t) => t.name.equals('receipt'))).getSingleOrNull();

    final now = DateTime.now();
    final yearMonth =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}';

    if (sequence == null) {
      // Create sequence if not exists
      await _db
          .into(_db.numberSequences)
          .insert(
            NumberSequencesCompanion.insert(
              name: 'receipt',
              prefix: const Value('RCP-'),
              currentNumber: const Value(1),
              minDigits: const Value(6),
            ),
          );
      return 'RCP-$yearMonth-000001';
    }

    // Increment and get new number
    final nextNumber = sequence.currentNumber + 1;
    final paddedNumber = nextNumber.toString().padLeft(sequence.minDigits, '0');

    // Update sequence
    await (_db.update(_db.numberSequences)
          ..where((t) => t.name.equals('receipt')))
        .write(NumberSequencesCompanion(currentNumber: Value(nextNumber)));

    return 'RCP-$yearMonth-$paddedNumber';
  }

  // ============================================
  // COLLECTION REPORTS
  // ============================================

  @override
  Future<DailyCollectionSummary> getDailyCollection(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final payments =
        await (_db.select(_db.payments)..where(
              (t) =>
                  t.paymentDate.isBiggerOrEqualValue(startOfDay) &
                  t.paymentDate.isSmallerOrEqualValue(endOfDay) &
                  t.isCancelled.equals(false),
            ))
            .get();

    final byMode = <String, double>{};
    double total = 0;

    for (final payment in payments) {
      total += payment.amount;
      byMode[payment.paymentMode] =
          (byMode[payment.paymentMode] ?? 0) + payment.amount;
    }

    return DailyCollectionSummary(
      date: date,
      totalAmount: total,
      paymentCount: payments.length,
      byPaymentMode: byMode,
    );
  }

  @override
  Future<List<DailyCollectionSummary>> getCollectionHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    final summaries = <DailyCollectionSummary>[];
    var currentDate = DateTime(from.year, from.month, from.day);
    final endDate = DateTime(to.year, to.month, to.day);

    while (!currentDate.isAfter(endDate)) {
      final summary = await getDailyCollection(currentDate);
      summaries.add(summary);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summaries;
  }

  @override
  Future<List<CollectionByMode>> getCollectionByMode({
    DateTime? from,
    DateTime? to,
  }) async {
    final sumAmount = _db.payments.amount.sum();
    final countPayments = _db.payments.id.count();

    final query = _db.selectOnly(_db.payments)
      ..addColumns([_db.payments.paymentMode, sumAmount, countPayments])
      ..where(_db.payments.isCancelled.equals(false))
      ..groupBy([_db.payments.paymentMode]);

    if (from != null) {
      query.where(_db.payments.paymentDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      query.where(_db.payments.paymentDate.isSmallerOrEqualValue(endOfDay));
    }

    final rows = await query.get();

    return rows.map((row) {
      return CollectionByMode(
        paymentMode: row.read(_db.payments.paymentMode)!,
        totalAmount: row.read(sumAmount) ?? 0,
        count: row.read(countPayments) ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<CollectionByClass>> getCollectionByClass({
    required DateTime from,
    required DateTime to,
  }) async {
    final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);

    // Get all payments in the date range with class info
    final query = _db.select(_db.payments).join([
      innerJoin(
        _db.invoices,
        _db.invoices.id.equalsExp(_db.payments.invoiceId),
      ),
      innerJoin(
        _db.enrollments,
        _db.enrollments.studentId.equalsExp(_db.invoices.studentId) &
            _db.enrollments.isCurrent.equals(true),
      ),
      innerJoin(_db.classes, _db.classes.id.equalsExp(_db.enrollments.classId)),
    ]);

    query.where(
      _db.payments.paymentDate.isBiggerOrEqualValue(from) &
          _db.payments.paymentDate.isSmallerOrEqualValue(endOfDay) &
          _db.payments.isCancelled.equals(false),
    );

    final rows = await query.get();

    // Group by class
    final classMap = <int, _ClassCollectionData>{};

    for (final row in rows) {
      final schoolClass = row.readTable(_db.classes);
      final payment = row.readTable(_db.payments);
      final invoice = row.readTable(_db.invoices);

      final data = classMap.putIfAbsent(
        schoolClass.id,
        () => _ClassCollectionData(
          classId: schoolClass.id,
          className: schoolClass.name,
        ),
      );

      data.totalAmount += payment.amount;
      data.paymentCount++;
      data.studentIds.add(invoice.studentId);
    }

    return classMap.values
        .map(
          (data) => CollectionByClass(
            classId: data.classId,
            className: data.className,
            totalAmount: data.totalAmount,
            paymentCount: data.paymentCount,
            studentCount: data.studentIds.length,
          ),
        )
        .toList()
      ..sort((a, b) => a.className.compareTo(b.className));
  }

  @override
  Future<MonthlyCollectionSummary> getMonthlyCollectionSummary(
    String month,
  ) async {
    // Get all invoices for the month
    final invoices = await (_db.select(
      _db.invoices,
    )..where((t) => t.month.equals(month))).get();

    double totalInvoiced = 0;
    double totalCollected = 0;
    int paidCount = 0;
    int pendingCount = 0;

    for (final invoice in invoices) {
      totalInvoiced += invoice.netAmount;
      totalCollected += invoice.paidAmount;

      if (invoice.status == FeeConstants.invoiceStatusPaid) {
        paidCount++;
      } else {
        pendingCount++;
      }
    }

    final collectionRate = totalInvoiced > 0
        ? (totalCollected / totalInvoiced) * 100
        : 0.0;

    return MonthlyCollectionSummary(
      month: month,
      totalInvoiced: totalInvoiced,
      totalCollected: totalCollected,
      totalPending: totalInvoiced - totalCollected,
      totalInvoices: invoices.length,
      paidInvoices: paidCount,
      pendingInvoices: pendingCount,
      collectionRate: collectionRate,
    );
  }

  // ============================================
  // STATISTICS
  // ============================================

  @override
  Future<double> getTotalCollectionForDate(DateTime date) async {
    final summary = await getDailyCollection(date);
    return summary.totalAmount;
  }

  @override
  Future<double> getTotalCollectionForPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);

    final sumAmount = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)
      ..addColumns([sumAmount])
      ..where(
        _db.payments.paymentDate.isBiggerOrEqualValue(from) &
            _db.payments.paymentDate.isSmallerOrEqualValue(endOfDay) &
            _db.payments.isCancelled.equals(false),
      );

    final result = await query.getSingle();
    return result.read(sumAmount) ?? 0;
  }
}

/// Helper class for collecting class-wise data
class _ClassCollectionData {
  final int classId;
  final String className;
  double totalAmount = 0;
  int paymentCount = 0;
  final Set<int> studentIds = {};

  _ClassCollectionData({required this.classId, required this.className});
}
