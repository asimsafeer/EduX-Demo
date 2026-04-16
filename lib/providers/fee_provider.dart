/// EduX School Management System
/// Fee Providers - Riverpod state management for fee management module
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../providers/student_provider.dart' show databaseProvider;
import '../providers/auth_provider.dart' show currentUserProvider;
import '../repositories/fee_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/concession_repository.dart';
import '../services/fee_service.dart';
import 'dashboard_provider.dart';
import '../services/invoice_service.dart';
import '../services/invoice_export_service.dart';
import '../services/payment_service.dart';
import '../services/receipt_service.dart';

// ============================================
// REPOSITORY PROVIDERS
// ============================================

/// Fee repository provider
final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftFeeRepository(db);
});

/// Invoice repository provider
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftInvoiceRepository(db);
});

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftPaymentRepository(db);
});

/// Concession repository provider
final concessionRepositoryProvider = Provider<ConcessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftConcessionRepository(db);
});

// ============================================
// SERVICE PROVIDERS
// ============================================

/// Fee service provider
final feeServiceProvider = Provider<FeeService>((ref) {
  final db = ref.watch(databaseProvider);
  return FeeService(db);
});

/// Invoice service provider
final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceService(db);
});

/// Invoice export service provider
final invoiceExportServiceProvider = Provider<InvoiceExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceExportService(db);
});

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentService(db);
});

/// Receipt service provider
final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReceiptService(db);
});

// ============================================
// FEE TYPES PROVIDERS
// ============================================

/// All active fee types
final feeTypesProvider = FutureProvider<List<FeeType>>((ref) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getAllFeeTypes(activeOnly: true);
});

/// All fee types including inactive
final allFeeTypesProvider = FutureProvider<List<FeeType>>((ref) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getAllFeeTypes(activeOnly: false);
});

/// Fee types with usage stats
final feeTypesWithUsageProvider = FutureProvider<List<FeeTypeWithUsage>>((
  ref,
) async {
  final repo = ref.watch(feeRepositoryProvider);
  return await repo.getFeeTypesWithUsage();
});

// ============================================
// FEE STRUCTURE PROVIDERS
// ============================================

/// Current academic year for fee operations
final currentAcademicYearProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  // Academic year typically runs from April to March
  // If current month >= April, year is current-next, else previous-current
  final year = now.month >= 4 ? now.year : now.year - 1;
  return '$year-${year + 1}';
});

/// Selected class ID for fee structure management
final selectedFeeClassIdProvider = StateProvider<int?>((ref) => null);

/// Fee structures for selected class
final classFeeStructuresProvider =
    FutureProvider<List<FeeStructureWithDetails>>((ref) async {
      final classId = ref.watch(selectedFeeClassIdProvider);
      final academicYear = ref.watch(currentAcademicYearProvider);

      if (classId == null) return [];

      final service = ref.watch(feeServiceProvider);
      return await service.getClassFeeStructures(classId, academicYear);
    });

/// All class fee summaries
final classFeeSummariesProvider = FutureProvider<List<ClassFeeSummary>>((
  ref,
) async {
  final academicYear = ref.watch(currentAcademicYearProvider);
  final service = ref.watch(feeServiceProvider);
  return await service.getAllClassFeeSummaries(academicYear);
});

// ============================================
// INVOICE FILTER STATE
// ============================================

/// Current invoice filters state
final invoiceFiltersProvider =
    StateNotifierProvider<InvoiceFiltersNotifier, InvoiceFilters>((ref) {
      return InvoiceFiltersNotifier();
    });

class InvoiceFiltersNotifier extends StateNotifier<InvoiceFilters> {
  InvoiceFiltersNotifier() : super(const InvoiceFilters());

  void setMonth(String? month) {
    state = state.copyWith(month: month, clearMonth: month == null);
    _resetPagination();
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
    _resetPagination();
  }

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId, clearClassId: classId == null);
    _resetPagination();
  }

  void setSectionId(int? sectionId) {
    state = state.copyWith(sectionId: sectionId);
    _resetPagination();
  }

  void setStudentId(int? studentId) {
    state = state.copyWith(
      studentId: studentId,
      clearStudentId: studentId == null,
    );
    _resetPagination();
  }

  void setAcademicYear(String? year) {
    state = state.copyWith(academicYear: year);
    _resetPagination();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    _resetPagination();
  }

  void setDueDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dueDateFrom: from, dueDateTo: to);
    _resetPagination();
  }

  void resetFilters() {
    state = const InvoiceFilters();
  }

  void loadMore() {
    state = state.copyWith(offset: state.offset + state.limit);
  }

  void _resetPagination() {
    if (state.offset != 0) {
      state = state.copyWith(offset: 0);
    }
  }
}

// ============================================
// INVOICE LIST PROVIDERS
// ============================================

/// Invoices list with current filters
final invoicesListProvider = FutureProvider<List<InvoiceWithDetails>>((
  ref,
) async {
  final service = ref.watch(invoiceServiceProvider);
  final filters = ref.watch(invoiceFiltersProvider);
  return await service.getInvoices(filters);
});

/// Invoice statistics for current filter
final invoiceStatsProvider = FutureProvider<InvoiceStats>((ref) async {
  final service = ref.watch(invoiceServiceProvider);
  final filters = ref.watch(invoiceFiltersProvider);
  return await service.getInvoiceStats(
    month: filters.month,
    classId: filters.classId,
  );
});

/// Defaulters list
final defaultersProvider =
    FutureProvider.family<List<DefaulterInfo>, ({int? classId, int minDays})>((
      ref,
      params,
    ) async {
      final service = ref.watch(invoiceServiceProvider);
      return await service.getDefaulters(
        classId: params.classId,
        minDaysOverdue: params.minDays,
      );
    });

/// All defaulters with 30+ days overdue
final allDefaultersProvider = FutureProvider<List<DefaulterInfo>>((ref) async {
  final service = ref.watch(invoiceServiceProvider);
  return await service.getDefaulters(minDaysOverdue: 30);
});

// ============================================
// SINGLE INVOICE PROVIDERS
// ============================================

/// Current selected invoice ID
final selectedInvoiceIdProvider = StateProvider<int?>((ref) => null);

/// Current invoice details
final currentInvoiceProvider = FutureProvider<InvoiceWithDetails?>((ref) async {
  final invoiceId = ref.watch(selectedInvoiceIdProvider);
  if (invoiceId == null) return null;

  final service = ref.watch(invoiceServiceProvider);
  return await service.getInvoiceWithDetails(invoiceId);
});

/// Invoice by ID (for specific lookup)
final invoiceByIdProvider = FutureProvider.family<InvoiceWithDetails?, int>((
  ref,
  invoiceId,
) async {
  final service = ref.watch(invoiceServiceProvider);
  return await service.getInvoiceWithDetails(invoiceId);
});

/// Student's invoices
final studentInvoicesProvider = FutureProvider.family<List<Invoice>, int>((
  ref,
  studentId,
) async {
  final service = ref.watch(invoiceServiceProvider);
  return await service.getStudentInvoices(studentId);
});

/// Student's unpaid invoices
final studentUnpaidInvoicesProvider = FutureProvider.family<List<Invoice>, int>(
  (ref, studentId) async {
    final service = ref.watch(invoiceServiceProvider);
    return await service.getUnpaidInvoicesForStudent(studentId);
  },
);

// ============================================
// PAYMENT FILTER STATE
// ============================================

/// Current payment filters state
final paymentFiltersProvider =
    StateNotifierProvider<PaymentFiltersNotifier, PaymentFilters>((ref) {
      return PaymentFiltersNotifier();
    });

class PaymentFiltersNotifier extends StateNotifier<PaymentFilters> {
  PaymentFiltersNotifier()
    : super(PaymentFilters(dateFrom: DateTime.now(), dateTo: DateTime.now()));

  void setDateFrom(DateTime? date) {
    state = state.copyWith(dateFrom: date, clearDateRange: date == null);
    _resetPagination();
  }

  void setDateTo(DateTime? date) {
    state = state.copyWith(dateTo: date);
    _resetPagination();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      dateFrom: from,
      dateTo: to,
      clearDateRange: from == null && to == null,
    );
    _resetPagination();
  }

  void setPaymentMode(String? mode) {
    state = state.copyWith(paymentMode: mode, clearPaymentMode: mode == null);
    _resetPagination();
  }

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId, clearClassId: classId == null);
    _resetPagination();
  }

  void setStudentId(int? studentId) {
    state = state.copyWith(
      studentId: studentId,
      clearStudentId: studentId == null,
    );
    _resetPagination();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    _resetPagination();
  }

  void resetFilters() {
    state = PaymentFilters(dateFrom: DateTime.now(), dateTo: DateTime.now());
  }

  void loadMore() {
    state = state.copyWith(offset: state.offset + state.limit);
  }

  void _resetPagination() {
    if (state.offset != 0) {
      state = state.copyWith(offset: 0);
    }
  }
}

// ============================================
// PAYMENT LIST PROVIDERS
// ============================================

/// Payments list with current filters
final paymentsListProvider = FutureProvider<List<PaymentWithDetails>>((
  ref,
) async {
  final service = ref.watch(paymentServiceProvider);
  final filters = ref.watch(paymentFiltersProvider);
  return await service.getPayments(filters);
});

/// Recent payments
final recentPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return await service.getRecentPayments(limit: 20);
});

/// Daily collection summary
final dailyCollectionProvider =
    FutureProvider.family<DailyCollectionSummary, DateTime>((ref, date) async {
      final service = ref.watch(paymentServiceProvider);
      return await service.getDailyCollection(date);
    });

/// Today's collection
final todayCollectionProvider = FutureProvider<DailyCollectionSummary>((
  ref,
) async {
  final service = ref.watch(paymentServiceProvider);
  return await service.getDailyCollection(DateTime.now());
});

/// Daily payments list
final dailyPaymentsListProvider =
    FutureProvider.family<List<PaymentWithDetails>, DateTime>((
      ref,
      date,
    ) async {
      final service = ref.watch(paymentServiceProvider);
      return await service.getPayments(
        PaymentFilters(dateFrom: date, dateTo: date, limit: 100),
      );
    });

/// Collection by payment mode
final collectionByModeProvider =
    FutureProvider.family<
      List<CollectionByMode>,
      ({DateTime? from, DateTime? to})
    >((ref, params) async {
      final service = ref.watch(paymentServiceProvider);
      return await service.getCollectionByMode(
        from: params.from,
        to: params.to,
      );
    });

/// Collection by class for date range
final collectionByClassProvider =
    FutureProvider.family<
      List<CollectionByClass>,
      ({DateTime from, DateTime to})
    >((ref, params) async {
      final service = ref.watch(paymentServiceProvider);
      return await service.getCollectionByClass(
        from: params.from,
        to: params.to,
      );
    });

/// Monthly collection summary
final monthlyCollectionProvider =
    FutureProvider.family<MonthlyCollectionSummary, String>((ref, month) async {
      final service = ref.watch(paymentServiceProvider);
      return await service.getMonthlyCollectionSummary(month);
    });

// ============================================
// SINGLE PAYMENT PROVIDERS
// ============================================

/// Current selected payment ID
final selectedPaymentIdProvider = StateProvider<int?>((ref) => null);

/// Current payment details
final currentPaymentProvider = FutureProvider<PaymentWithDetails?>((ref) async {
  final paymentId = ref.watch(selectedPaymentIdProvider);
  if (paymentId == null) return null;

  final service = ref.watch(paymentServiceProvider);
  return await service.getPaymentWithDetails(paymentId);
});

/// Payment by ID
final paymentByIdProvider = FutureProvider.family<PaymentWithDetails?, int>((
  ref,
  paymentId,
) async {
  final service = ref.watch(paymentServiceProvider);
  return await service.getPaymentWithDetails(paymentId);
});

/// Payments for invoice
final invoicePaymentsProvider = FutureProvider.family<List<Payment>, int>((
  ref,
  invoiceId,
) async {
  final service = ref.watch(paymentServiceProvider);
  return await service.getPaymentsForInvoice(invoiceId);
});

// ============================================
// CONCESSION PROVIDERS
// ============================================

/// Concession filters state
final concessionFiltersProvider =
    StateNotifierProvider<ConcessionFiltersNotifier, ConcessionFilters>((ref) {
      return ConcessionFiltersNotifier();
    });

class ConcessionFiltersNotifier extends StateNotifier<ConcessionFilters> {
  ConcessionFiltersNotifier() : super(const ConcessionFilters());

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId);
  }

  void setFeeTypeId(int? feeTypeId) {
    state = state.copyWith(feeTypeId: feeTypeId);
  }

  void setActiveOnly(bool activeOnly) {
    state = state.copyWith(activeOnly: activeOnly);
  }

  void resetFilters() {
    state = const ConcessionFilters();
  }
}

/// Concessions list with current filters
final concessionsListProvider = FutureProvider<List<ConcessionWithDetails>>((
  ref,
) async {
  final repo = ref.watch(concessionRepositoryProvider);
  final filters = ref.watch(concessionFiltersProvider);
  return await repo.getConcessions(filters);
});

/// Student discount info
final studentDiscountInfoProvider =
    FutureProvider.family<StudentDiscountInfo, int>((ref, studentId) async {
      final repo = ref.watch(concessionRepositoryProvider);
      return await repo.getStudentDiscountInfo(studentId);
    });

/// Concession summary
final concessionSummaryProvider = FutureProvider<ConcessionSummary>((
  ref,
) async {
  final repo = ref.watch(concessionRepositoryProvider);
  return await repo.getConcessionSummary();
});

// ============================================
// INVOICE GENERATION STATE
// ============================================

/// Invoice generation form state
final invoiceGenerationProvider =
    StateNotifierProvider.autoDispose<
      InvoiceGenerationNotifier,
      InvoiceGenerationState
    >((ref) => InvoiceGenerationNotifier(ref));

class InvoiceGenerationState {
  final String? month;
  final DateTime? dueDate;
  final int? classId;
  final int? sectionId;
  final bool isGenerating;
  final BulkInvoiceResult? result;
  final String? error;

  const InvoiceGenerationState({
    this.month,
    this.dueDate,
    this.classId,
    this.sectionId,
    this.isGenerating = false,
    this.result,
    this.error,
  });

  InvoiceGenerationState copyWith({
    String? month,
    DateTime? dueDate,
    int? classId,
    int? sectionId,
    bool? isGenerating,
    BulkInvoiceResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return InvoiceGenerationState(
      month: month ?? this.month,
      dueDate: dueDate ?? this.dueDate,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      isGenerating: isGenerating ?? this.isGenerating,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isValid => month != null && dueDate != null;
}

class InvoiceGenerationNotifier extends StateNotifier<InvoiceGenerationState> {
  final Ref _ref;

  InvoiceGenerationNotifier(this._ref) : super(const InvoiceGenerationState());

  void setMonth(String? month) {
    state = state.copyWith(month: month, clearError: true, clearResult: true);
  }

  void setDueDate(DateTime? dueDate) {
    state = state.copyWith(dueDate: dueDate, clearError: true);
  }

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId, sectionId: null, clearError: true);
  }

  void setSectionId(int? sectionId) {
    state = state.copyWith(sectionId: sectionId, clearError: true);
  }

  Future<bool> generateInvoices() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in required fields');
      return false;
    }

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final service = _ref.read(invoiceServiceProvider);
      final academicYear = _ref.read(currentAcademicYearProvider);

      final result = await service.generateBulkInvoices(
        BulkInvoiceGenerationData(
          month: state.month!,
          academicYear: academicYear,
          dueDate: state.dueDate!,
          generatedBy: _ref.read(currentUserProvider)?.id ?? 1,
          classId: state.classId,
          sectionId: state.sectionId,
        ),
      );

      if (!mounted) return false;
      state = state.copyWith(isGenerating: false, result: result);

      // Invalidate invoice providers to refresh data
      _ref.invalidate(invoicesListProvider);
      _ref.invalidate(invoiceStatsProvider);
      _ref.invalidate(dashboardProvider);

      return result.successCount > 0;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating invoices: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const InvoiceGenerationState();
  }
}

// ============================================
// GENERIC INVOICE GENERATION STATE (with fee type selection)
// ============================================

/// Generic invoice generation form state with fee type selection
final genericInvoiceGenerationProvider =
    StateNotifierProvider.autoDispose<
      GenericInvoiceGenerationNotifier,
      GenericInvoiceGenerationState
    >((ref) => GenericInvoiceGenerationNotifier(ref));

class GenericInvoiceGenerationState {
  final String? month;
  final DateTime? dueDate;
  final int? classId;
  final int? sectionId;
  final int? studentId; // For single student generation
  final Set<int> selectedFeeTypeIds;
  final bool isGenerating;
  final BulkInvoiceResult? result;
  final String? error;

  const GenericInvoiceGenerationState({
    this.month,
    this.dueDate,
    this.classId,
    this.sectionId,
    this.studentId,
    this.selectedFeeTypeIds = const {},
    this.isGenerating = false,
    this.result,
    this.error,
  });

  GenericInvoiceGenerationState copyWith({
    String? month,
    DateTime? dueDate,
    int? classId,
    int? sectionId,
    int? studentId,
    Set<int>? selectedFeeTypeIds,
    bool? isGenerating,
    BulkInvoiceResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return GenericInvoiceGenerationState(
      month: month ?? this.month,
      dueDate: dueDate ?? this.dueDate,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      studentId: studentId ?? this.studentId,
      selectedFeeTypeIds: selectedFeeTypeIds ?? this.selectedFeeTypeIds,
      isGenerating: isGenerating ?? this.isGenerating,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isValid => month != null && dueDate != null;
  bool get isSingleStudent => studentId != null;
}

class GenericInvoiceGenerationNotifier
    extends StateNotifier<GenericInvoiceGenerationState> {
  final Ref _ref;

  GenericInvoiceGenerationNotifier(this._ref)
      : super(const GenericInvoiceGenerationState());

  void setMonth(String? month) {
    state = state.copyWith(month: month, clearError: true, clearResult: true);
  }

  void setDueDate(DateTime? dueDate) {
    state = state.copyWith(dueDate: dueDate, clearError: true);
  }

  void setClassId(int? classId) {
    state = state.copyWith(classId: classId, sectionId: null, clearError: true);
  }

  void setSectionId(int? sectionId) {
    state = state.copyWith(sectionId: sectionId, clearError: true);
  }

  void setStudentId(int? studentId) {
    state = state.copyWith(studentId: studentId, clearError: true);
  }

  void toggleFeeType(int feeTypeId) {
    final currentSelection = Set<int>.from(state.selectedFeeTypeIds);
    if (currentSelection.contains(feeTypeId)) {
      currentSelection.remove(feeTypeId);
    } else {
      currentSelection.add(feeTypeId);
    }
    state = state.copyWith(selectedFeeTypeIds: currentSelection, clearError: true);
  }

  void selectAllFeeTypes(List<int> feeTypeIds) {
    state = state.copyWith(
      selectedFeeTypeIds: Set<int>.from(feeTypeIds),
      clearError: true,
    );
  }

  void clearFeeTypeSelection() {
    state = state.copyWith(selectedFeeTypeIds: {}, clearError: true);
  }

  Future<bool> generateInvoices() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in required fields');
      return false;
    }

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final service = _ref.read(invoiceServiceProvider);
      final academicYear = _ref.read(currentAcademicYearProvider);

      final result = await service.generateBulkGenericInvoices(
        BulkGenericInvoiceGenerationData(
          month: state.month!,
          academicYear: academicYear,
          dueDate: state.dueDate!,
          generatedBy: _ref.read(currentUserProvider)?.id ?? 1,
          classId: state.classId,
          sectionId: state.sectionId,
          selectedFeeTypeIds: state.selectedFeeTypeIds.toList(),
        ),
      );

      if (!mounted) return false;
      state = state.copyWith(isGenerating: false, result: result);

      // Invalidate invoice providers to refresh data
      _ref.invalidate(invoicesListProvider);
      _ref.invalidate(invoiceStatsProvider);
      _ref.invalidate(dashboardProvider);

      return result.successCount > 0;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating invoices: $e',
      );
      return false;
    }
  }

  Future<bool> generateSingleInvoice() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in required fields');
      return false;
    }

    if (state.studentId == null) {
      state = state.copyWith(error: 'Please select a student');
      return false;
    }

    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final service = _ref.read(invoiceServiceProvider);
      final academicYear = _ref.read(currentAcademicYearProvider);

      final result = await service.generateGenericInvoice(
        GenericInvoiceGenerationData(
          studentId: state.studentId!,
          month: state.month!,
          academicYear: academicYear,
          dueDate: state.dueDate!,
          generatedBy: _ref.read(currentUserProvider)?.id ?? 1,
          remarks: null,
          selectedFeeTypeIds: state.selectedFeeTypeIds.toList(),
        ),
      );

      // Convert single result to bulk result format for UI consistency
      final bulkResult = BulkInvoiceResult(
        totalStudents: 1,
        successCount: result.success ? 1 : 0,
        skippedCount: result.error?.contains('already exists') == true ? 1 : 0,
        errorCount: result.success ? 0 : 1,
        totalAmount: result.amount ?? 0,
        errors: result.error != null && !result.error!.contains('already exists')
            ? [result.error!]
            : [],
        generatedInvoiceIds: result.invoiceId != null ? [result.invoiceId!] : [],
      );

      if (!mounted) return false;
      state = state.copyWith(isGenerating: false, result: bulkResult);

      // Invalidate invoice providers to refresh data
      _ref.invalidate(invoicesListProvider);
      _ref.invalidate(invoiceStatsProvider);
      _ref.invalidate(dashboardProvider);
      if (state.studentId != null) {
        _ref.invalidate(studentInvoicesProvider(state.studentId!));
        _ref.invalidate(studentUnpaidInvoicesProvider(state.studentId!));
      }

      return result.success;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating invoice: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const GenericInvoiceGenerationState();
  }
}

// ============================================
// PAYMENT COLLECTION STATE
// ============================================

/// Payment collection form state
final paymentCollectionProvider =
    StateNotifierProvider.autoDispose<
      PaymentCollectionNotifier,
      PaymentCollectionState
    >((ref) => PaymentCollectionNotifier(ref));

class PaymentCollectionState {
  final int? invoiceId;
  final int? studentId;
  final double amount;
  final String paymentMode;
  final String? referenceNumber;
  final String? chequeNumber;
  final String? bankName;
  final DateTime? chequeDate;
  final String? remarks;
  final bool isProcessing;
  final PaymentCollectionResult? result;
  final String? error;

  const PaymentCollectionState({
    this.invoiceId,
    this.studentId,
    this.amount = 0,
    this.paymentMode = 'cash',
    this.referenceNumber,
    this.chequeNumber,
    this.bankName,
    this.chequeDate,
    this.remarks,
    this.isProcessing = false,
    this.result,
    this.error,
  });

  PaymentCollectionState copyWith({
    int? invoiceId,
    int? studentId,
    double? amount,
    String? paymentMode,
    String? referenceNumber,
    String? chequeNumber,
    String? bankName,
    DateTime? chequeDate,
    String? remarks,
    bool? isProcessing,
    PaymentCollectionResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PaymentCollectionState(
      invoiceId: invoiceId ?? this.invoiceId,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      bankName: bankName ?? this.bankName,
      chequeDate: chequeDate ?? this.chequeDate,
      remarks: remarks ?? this.remarks,
      isProcessing: isProcessing ?? this.isProcessing,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isValid => invoiceId != null && amount > 0;
}

class PaymentCollectionNotifier extends StateNotifier<PaymentCollectionState> {
  final Ref _ref;

  PaymentCollectionNotifier(this._ref) : super(const PaymentCollectionState());

  void setInvoiceId(int? invoiceId) {
    state = state.copyWith(
      invoiceId: invoiceId,
      clearError: true,
      clearResult: true,
    );
  }

  void setStudentId(int? studentId) {
    state = state.copyWith(
      studentId: studentId,
      clearError: true,
      clearResult: true,
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount, clearError: true);
  }

  void setPaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode, clearError: true);
  }

  void setReferenceNumber(String? reference) {
    state = state.copyWith(referenceNumber: reference);
  }

  void setChequeNumber(String? chequeNumber) {
    state = state.copyWith(chequeNumber: chequeNumber);
  }

  void setBankName(String? bankName) {
    state = state.copyWith(bankName: bankName);
  }

  void setChequeDate(DateTime? date) {
    state = state.copyWith(chequeDate: date);
  }

  void setRemarks(String? remarks) {
    state = state.copyWith(remarks: remarks);
  }

  Future<bool> collectPayment({int? receivedBy}) async {
    final currentUserId = _ref.read(currentUserProvider)?.id ?? 1;
    final actualReceivedBy = receivedBy ?? currentUserId;
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in required fields');
      return false;
    }

    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final service = _ref.read(paymentServiceProvider);

      final result = await service.collectPayment(
        PaymentCollectionData(
          invoiceId: state.invoiceId!,
          amount: state.amount,
          paymentMode: state.paymentMode,
          receivedBy: actualReceivedBy,
          referenceNumber: state.referenceNumber,
          chequeNumber: state.chequeNumber,
          bankName: state.bankName,
          chequeDate: state.chequeDate,
          remarks: state.remarks,
        ),
      );

      state = state.copyWith(isProcessing: false, result: result);

      if (result.success) {
        // Invalidate related providers
        _ref.invalidate(invoicesListProvider);
        _ref.invalidate(invoiceStatsProvider);
        _ref.invalidate(paymentsListProvider);
        _ref.invalidate(todayCollectionProvider);
        _ref.invalidate(dashboardProvider);
        if (state.invoiceId != null) {
          _ref.invalidate(invoiceByIdProvider(state.invoiceId!));
        }
        if (state.studentId != null) {
          _ref.invalidate(studentUnpaidInvoicesProvider(state.studentId!));
        }
        // Also invalidate by the invoice's student ID in case state.studentId is null
        final invoiceDetails = await _ref.read(invoiceServiceProvider).getInvoiceWithDetails(state.invoiceId!);
        if (invoiceDetails != null) {
          _ref.invalidate(studentUnpaidInvoicesProvider(invoiceDetails.invoice.studentId));
        }
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Error collecting payment: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const PaymentCollectionState();
  }
}

// ============================================
// FEE STRUCTURE FORM STATE
// ============================================

/// Fee structure form state
final feeStructureFormProvider =
    StateNotifierProvider.autoDispose<
      FeeStructureFormNotifier,
      FeeStructureFormState
    >((ref) => FeeStructureFormNotifier(ref));

class FeeStructureFormState {
  final int? classId;
  final Map<int, double> feeTypeAmounts;
  final bool isSaving;
  final String? error;
  final bool isSaved;

  const FeeStructureFormState({
    this.classId,
    this.feeTypeAmounts = const {},
    this.isSaving = false,
    this.error,
    this.isSaved = false,
  });

  FeeStructureFormState copyWith({
    int? classId,
    Map<int, double>? feeTypeAmounts,
    bool? isSaving,
    String? error,
    bool? isSaved,
    bool clearError = false,
  }) {
    return FeeStructureFormState(
      classId: classId ?? this.classId,
      feeTypeAmounts: feeTypeAmounts ?? this.feeTypeAmounts,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class FeeStructureFormNotifier extends StateNotifier<FeeStructureFormState> {
  final Ref _ref;

  FeeStructureFormNotifier(this._ref) : super(const FeeStructureFormState());

  void setClassId(int? classId) {
    state = state.copyWith(
      classId: classId,
      feeTypeAmounts: {},
      clearError: true,
    );
    if (classId != null) {
      _loadExistingStructures(classId);
    }
  }

  Future<void> _loadExistingStructures(int classId) async {
    try {
      final service = _ref.read(feeServiceProvider);
      final academicYear = _ref.read(currentAcademicYearProvider);
      final structures = await service.getClassFeeStructures(
        classId,
        academicYear,
      );

      final amounts = <int, double>{};
      for (final s in structures) {
        amounts[s.feeType.id] = s.structure.amount;
      }

      state = state.copyWith(feeTypeAmounts: amounts);
    } catch (_) {
      // Silently fail - will just start with empty amounts
    }
  }

  void setFeeTypeAmount(int feeTypeId, double amount) {
    final newAmounts = Map<int, double>.from(state.feeTypeAmounts);
    if (amount > 0) {
      newAmounts[feeTypeId] = amount;
    } else {
      newAmounts.remove(feeTypeId);
    }
    state = state.copyWith(feeTypeAmounts: newAmounts, clearError: true);
  }

  Future<bool> save() async {
    if (state.classId == null) {
      state = state.copyWith(error: 'Please select a class');
      return false;
    }

    if (state.feeTypeAmounts.isEmpty) {
      state = state.copyWith(error: 'Please set at least one fee amount');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final service = _ref.read(feeServiceProvider);
      final academicYear = _ref.read(currentAcademicYearProvider);

      await service.updateClassFeeStructures(
        BulkFeeStructureData(
          classId: state.classId!,
          academicYear: academicYear,
          feeTypeAmounts: state.feeTypeAmounts,
        ),
      );

      state = state.copyWith(isSaving: false, isSaved: true);

      // Invalidate related providers
      _ref.invalidate(classFeeStructuresProvider);
      _ref.invalidate(classFeeSummariesProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const FeeStructureFormState();
  }
}
