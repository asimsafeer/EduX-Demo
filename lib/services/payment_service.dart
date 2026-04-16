/// EduX School Management System
/// Payment Service - Business logic for payment collection
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/payment_repository.dart';
import '../repositories/invoice_repository.dart';
import '../core/constants/app_constants.dart';
import 'fee_service.dart';

/// Payment collection input data
class PaymentCollectionData {
  final int invoiceId;
  final double amount;
  final String paymentMode;
  final String? referenceNumber;
  final String? chequeNumber;
  final String? bankName;
  final DateTime? chequeDate;
  final String? remarks;
  final int receivedBy;

  const PaymentCollectionData({
    required this.invoiceId,
    required this.amount,
    required this.paymentMode,
    required this.receivedBy,
    this.referenceNumber,
    this.chequeNumber,
    this.bankName,
    this.chequeDate,
    this.remarks,
  });
}

/// Payment collection result
class PaymentCollectionResult {
  final bool success;
  final int? paymentId;
  final String? receiptNumber;
  final double? amount;
  final String? newInvoiceStatus;
  final double? remainingBalance;
  final String? error;

  const PaymentCollectionResult({
    required this.success,
    this.paymentId,
    this.receiptNumber,
    this.amount,
    this.newInvoiceStatus,
    this.remainingBalance,
    this.error,
  });

  factory PaymentCollectionResult.success({
    required int paymentId,
    required String receiptNumber,
    required double amount,
    required String newInvoiceStatus,
    required double remainingBalance,
  }) => PaymentCollectionResult(
    success: true,
    paymentId: paymentId,
    receiptNumber: receiptNumber,
    amount: amount,
    newInvoiceStatus: newInvoiceStatus,
    remainingBalance: remainingBalance,
  );

  factory PaymentCollectionResult.failure(String error) =>
      PaymentCollectionResult(success: false, error: error);
}

/// Payment validation result
class PaymentValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const PaymentValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  factory PaymentValidationResult.valid() =>
      const PaymentValidationResult(isValid: true);

  factory PaymentValidationResult.invalid(Map<String, String> errors) =>
      PaymentValidationResult(isValid: false, errors: errors);
}

/// Payment service for business logic
class PaymentService {
  final AppDatabase _db;
  final PaymentRepository _paymentRepo;
  final InvoiceRepository _invoiceRepo;

  PaymentService(this._db)
    : _paymentRepo = DriftPaymentRepository(_db),
      _invoiceRepo = DriftInvoiceRepository(_db);

  // ============================================
  // PAYMENT QUERIES
  // ============================================

  /// Get payments with filters
  Future<List<PaymentWithDetails>> getPayments(PaymentFilters filters) async {
    return await _paymentRepo.getPayments(filters);
  }

  /// Get payment with full details
  Future<PaymentWithDetails?> getPaymentWithDetails(int paymentId) async {
    return await _paymentRepo.getPaymentWithDetails(paymentId);
  }

  /// Get payments for an invoice
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    return await _paymentRepo.getPaymentsForInvoice(invoiceId);
  }

  /// Get recent payments
  Future<List<Payment>> getRecentPayments({int limit = 20}) async {
    return await _paymentRepo.getRecentPayments(limit: limit);
  }

  // ============================================
  // PAYMENT COLLECTION
  // ============================================

  /// Validate payment data
  Future<PaymentValidationResult> validatePayment(
    PaymentCollectionData data,
  ) async {
    final errors = <String, String>{};

    // Get invoice
    final invoice = await _invoiceRepo.getById(data.invoiceId);
    if (invoice == null) {
      return PaymentValidationResult.invalid({
        'invoiceId': 'Invoice not found',
      });
    }

    // Check invoice status - cannot pay cancelled or already paid invoices
    if (invoice.status == FeeConstants.invoiceStatusPaid) {
      return PaymentValidationResult.invalid({
        'invoiceId': 'Invoice is already fully paid',
      });
    }
    if (invoice.status == FeeConstants.invoiceStatusCancelled) {
      return PaymentValidationResult.invalid({
        'invoiceId': 'Cannot collect payment for a cancelled invoice',
      });
    }

    // Amount validation
    if (data.amount <= 0) {
      errors['amount'] = 'Amount must be greater than zero';
    } else if (data.amount > invoice.balanceAmount) {
      errors['amount'] =
          'Amount cannot exceed balance (${invoice.balanceAmount.toStringAsFixed(2)})';
    }

    // Payment mode validation
    if (data.paymentMode.isEmpty) {
      errors['paymentMode'] = 'Payment mode is required';
    } else if (!FeeConstants.paymentModes.contains(data.paymentMode)) {
      errors['paymentMode'] = 'Invalid payment mode';
    }

    // Cheque-specific validation
    if (data.paymentMode == FeeConstants.paymentModeCheque) {
      if (data.chequeNumber == null || data.chequeNumber!.isEmpty) {
        errors['chequeNumber'] =
            'Cheque number is required for cheque payments';
      }
      if (data.bankName == null || data.bankName!.isEmpty) {
        errors['bankName'] = 'Bank name is required for cheque payments';
      }
      if (data.chequeDate == null) {
        errors['chequeDate'] = 'Cheque date is required for cheque payments';
      }
    }

    // Bank transfer/online specific validation
    if (data.paymentMode == FeeConstants.paymentModeBank ||
        data.paymentMode == FeeConstants.paymentModeOnline) {
      if (data.referenceNumber == null || data.referenceNumber!.isEmpty) {
        errors['referenceNumber'] = 'Reference number is required';
      }
    }

    return errors.isEmpty
        ? PaymentValidationResult.valid()
        : PaymentValidationResult.invalid(errors);
  }

  /// Collect payment
  Future<PaymentCollectionResult> collectPayment(
    PaymentCollectionData data,
  ) async {
    try {
      // Validate
      final validation = await validatePayment(data);
      if (!validation.isValid) {
        final firstError = validation.errors.values.first;
        return PaymentCollectionResult.failure(firstError);
      }

      // Get invoice
      final invoice = await _invoiceRepo.getById(data.invoiceId);
      if (invoice == null) {
        return PaymentCollectionResult.failure('Invoice not found');
      }

      // Generate receipt number
      final receiptNumber = await _paymentRepo.generateReceiptNumber();

      // Calculate new amounts
      final newPaidAmount = invoice.paidAmount + data.amount;
      final newBalance = invoice.netAmount - newPaidAmount;
      final newStatus = newBalance <= 0 ? 'paid' : 'partial';

      // Create payment and update invoice in transaction
      final paymentId = await _db.transaction(() async {
        // Determine reference number (cheque number for cheques, or ref number for others)
        final refNumber = data.paymentMode == FeeConstants.paymentModeCheque
            ? data.chequeNumber
            : data.referenceNumber;

        // Create payment
        final id = await _paymentRepo.create(
          PaymentsCompanion.insert(
            invoiceId: data.invoiceId,
            studentId: invoice.studentId,
            receiptNumber: receiptNumber,
            amount: data.amount,
            paymentMode: data.paymentMode,
            paymentDate: DateTime.now(),
            referenceNumber: Value(refNumber),
            chequeDate: Value(data.chequeDate),
            bankName: Value(data.bankName),
            remarks: Value(data.remarks),
            receivedBy: data.receivedBy,
          ),
        );

        // Update invoice
        await _invoiceRepo.updatePaidAmount(data.invoiceId, newPaidAmount);

        return id;
      });

      // Get student info for logging
      final invoiceDetails = await _invoiceRepo.getInvoiceWithDetails(
        data.invoiceId,
      );

      // Log activity
      await _logActivity(
        action: 'create',
        module: 'payments',
        details:
            'Collected payment $receiptNumber of ${data.amount} for ${invoiceDetails?.studentName ?? 'unknown'} via ${_getPaymentModeDisplay(data.paymentMode)}',
      );

      return PaymentCollectionResult.success(
        paymentId: paymentId,
        receiptNumber: receiptNumber,
        amount: data.amount,
        newInvoiceStatus: newStatus,
        remainingBalance: newBalance < 0 ? 0 : newBalance,
      );
    } catch (e) {
      return PaymentCollectionResult.failure('Error collecting payment: $e');
    }
  }

  /// Cancel a payment
  Future<bool> cancelPayment(int paymentId, String reason) async {
    // Get payment
    final payment = await _paymentRepo.getById(paymentId);
    if (payment == null) {
      throw FeeNotFoundException('Payment not found');
    }

    if (payment.isCancelled) {
      throw FeeValidationException({'status': 'Payment is already cancelled'});
    }

    // Get invoice
    final invoice = await _invoiceRepo.getById(payment.invoiceId);
    if (invoice == null) {
      throw FeeNotFoundException('Invoice not found');
    }

    // Cancel payment and revert invoice in transaction
    await _db.transaction(() async {
      // Cancel payment
      await _paymentRepo.cancelPayment(paymentId, reason);

      // Revert invoice paid amount
      final newPaidAmount = invoice.paidAmount - payment.amount;
      await _invoiceRepo.updatePaidAmount(
        payment.invoiceId,
        newPaidAmount < 0 ? 0 : newPaidAmount,
      );
    });

    // Log activity
    await _logActivity(
      action: 'cancel',
      module: 'payments',
      details:
          'Cancelled payment ${payment.receiptNumber} of ${payment.amount}: $reason',
    );

    return true;
  }

  // ============================================
  // COLLECTION REPORTS
  // ============================================

  /// Get daily collection summary
  Future<DailyCollectionSummary> getDailyCollection(DateTime date) async {
    return await _paymentRepo.getDailyCollection(date);
  }

  /// Get collection history
  Future<List<DailyCollectionSummary>> getCollectionHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    return await _paymentRepo.getCollectionHistory(from: from, to: to);
  }

  /// Get collection by payment mode
  Future<List<CollectionByMode>> getCollectionByMode({
    DateTime? from,
    DateTime? to,
  }) async {
    return await _paymentRepo.getCollectionByMode(from: from, to: to);
  }

  /// Get collection by class
  Future<List<CollectionByClass>> getCollectionByClass({
    required DateTime from,
    required DateTime to,
  }) async {
    return await _paymentRepo.getCollectionByClass(from: from, to: to);
  }

  /// Get monthly collection summary
  Future<MonthlyCollectionSummary> getMonthlyCollectionSummary(
    String month,
  ) async {
    return await _paymentRepo.getMonthlyCollectionSummary(month);
  }

  /// Get total collection for date
  Future<double> getTotalCollectionForDate(DateTime date) async {
    return await _paymentRepo.getTotalCollectionForDate(date);
  }

  /// Get total collection for period
  Future<double> getTotalCollectionForPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    return await _paymentRepo.getTotalCollectionForPeriod(from: from, to: to);
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  String _getPaymentModeDisplay(String mode) {
    return FeeConstants.getPaymentModeDisplayName(mode);
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
