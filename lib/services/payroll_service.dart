/// EduX School Management System
/// Payroll Service - Business logic for payroll management
library;

import 'dart:convert';
import 'package:drift/drift.dart';

import '../core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/widgets.dart';
import '../core/utils/pdf_helper.dart';

import '../database/app_database.dart';
import '../repositories/payroll_repository.dart';

/// Allowance/Deduction item
class PayrollAdjustment {
  final String name;
  final double amount;

  const PayrollAdjustment({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory PayrollAdjustment.fromJson(Map<String, dynamic> json) {
    return PayrollAdjustment(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// Payroll update data
class PayrollUpdateData {
  final List<PayrollAdjustment> allowances;
  final List<PayrollAdjustment> deductions;
  final String? remarks;

  const PayrollUpdateData({
    this.allowances = const [],
    this.deductions = const [],
    this.remarks,
  });

  double get totalAllowances =>
      allowances.fold(0, (sum, item) => sum + item.amount);

  double get totalDeductions =>
      deductions.fold(0, (sum, item) => sum + item.amount);
}

/// Payroll service for business logic
class PayrollService {
  final AppDatabase _db;
  final PayrollRepository _payrollRepository;

  PayrollService(this._db) : _payrollRepository = PayrollRepositoryImpl(_db);

  /// Generate payroll for a month
  Future<bool> generateMonthlyPayroll({
    required String month,
    required int workingDays,
    required int generatedBy,
  }) async {
    // Validate month format (YYYY-MM)
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      throw PayrollValidationException('Invalid month format. Use YYYY-MM');
    }

    // Check if payroll already exists
    final exists = await _payrollRepository.payrollExistsForMonth(month);
    if (exists) {
      throw PayrollValidationException('Payroll already generated for $month');
    }

    // Validate working days
    if (workingDays <= 0 || workingDays > 31) {
      throw PayrollValidationException('Invalid working days');
    }

    final success = await _payrollRepository.generateMonthlyPayroll(
      month: month,
      workingDays: workingDays,
      generatedBy: generatedBy,
    );

    if (success) {
      await _logActivity(
        action: 'generate_payroll',
        module: 'payroll',
        details: 'Generated payroll for $month with $workingDays working days',
      );
    }

    return success;
  }

  /// Update payroll with allowances/deductions
  Future<bool> updatePayroll(int payrollId, PayrollUpdateData data) async {
    final payroll = await _payrollRepository.getById(payrollId);
    if (payroll == null) {
      throw PayrollNotFoundException('Payroll record not found');
    }

    if (payroll.status == FeeConstants.invoiceStatusPaid) {
      throw PayrollValidationException('Cannot update paid payroll');
    }

    // Parse existing breakdowns to preserve absent-day deductions etc.
    final existingDeductions = <String, double>{};
    if (payroll.deductionsBreakdown != null) {
      try {
        final decoded = jsonDecode(payroll.deductionsBreakdown!);
        decoded.forEach((k, v) {
          existingDeductions[k as String] = (v as num).toDouble();
        });
      } catch (_) {}
    }

    final existingAllowances = <String, double>{};
    if (payroll.allowancesBreakdown != null) {
      try {
        final decoded = jsonDecode(payroll.allowancesBreakdown!);
        decoded.forEach((k, v) {
          existingAllowances[k as String] = (v as num).toDouble();
        });
      } catch (_) {}
    }

    // Merge new adjustments with existing ones
    final mergedAllowances = <String, double>{...existingAllowances};
    for (final a in data.allowances) {
      mergedAllowances[a.name] = a.amount;
    }

    final mergedDeductions = <String, double>{...existingDeductions};
    for (final d in data.deductions) {
      mergedDeductions[d.name] = d.amount;
    }

    // Calculate totals from merged maps
    final totalAllowances = mergedAllowances.values.fold(
      0.0,
      (sum, v) => sum + v,
    );
    final totalDeductions = mergedDeductions.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    // Net salary = basic + all allowances - all deductions
    final netSalary = payroll.basicSalary + totalAllowances - totalDeductions;

    // Serialize merged breakdowns
    final allowancesJson = mergedAllowances.isEmpty
        ? null
        : jsonEncode(mergedAllowances);
    final deductionsJson = mergedDeductions.isEmpty
        ? null
        : jsonEncode(mergedDeductions);

    final updated = PayrollCompanion(
      allowances: Value(totalAllowances),
      allowancesBreakdown: Value(allowancesJson),
      deductions: Value(totalDeductions),
      deductionsBreakdown: Value(deductionsJson),
      netSalary: Value(netSalary),
      remarks: Value(data.remarks),
    );

    final success = await _payrollRepository.update(payrollId, updated);

    if (success) {
      await _logActivity(
        action: 'update_payroll',
        module: 'payroll',
        details: 'Updated payroll #$payrollId with allowances: PKR ${totalAllowances.toStringAsFixed(2)}, deductions: PKR ${totalDeductions.toStringAsFixed(2)}',
      );
    }

    return success;
  }

  /// Mark payroll as paid
  Future<bool> markAsPaid({
    required int payrollId,
    required String paymentMode,
    String? referenceNumber,
    required int processedBy,
  }) async {
    final payroll = await _payrollRepository.getById(payrollId);
    if (payroll == null) {
      throw PayrollNotFoundException('Payroll record not found');
    }

    if (payroll.status == FeeConstants.invoiceStatusPaid) {
      throw PayrollValidationException('Payroll already paid');
    }

    final validModes = ['cash', 'bank_transfer', 'cheque'];
    if (!validModes.contains(paymentMode)) {
      throw PayrollValidationException('Invalid payment mode');
    }

    final success = await _payrollRepository.markAsPaid(
      payrollId,
      paidDate: DateTime.now(),
      paymentMode: paymentMode,
      referenceNumber: referenceNumber,
      processedBy: processedBy,
    );

    if (success) {
      await _logActivity(
        action: 'pay_salary',
        module: 'payroll',
        details: 'Paid salary for payroll #$payrollId via $paymentMode',
      );
    }

    return success;
  }

  /// Mark multiple payrolls as paid
  Future<int> markBulkAsPaid({
    required List<int> payrollIds,
    required String paymentMode,
    required int processedBy,
  }) async {
    int paidCount = 0;

    for (final id in payrollIds) {
      try {
        final success = await markAsPaid(
          payrollId: id,
          paymentMode: paymentMode,
          processedBy: processedBy,
        );
        if (success) paidCount++;
      } catch (_) {
        // Skip already paid or invalid payrolls
      }
    }

    return paidCount;
  }

  /// Get payroll by month
  Future<List<PayrollWithStaff>> getPayrollByMonth(String month) async {
    return await _payrollRepository.getByMonth(month);
  }

  /// Get payroll by staff
  Future<List<PayrollWithStaff>> getPayrollByStaff(int staffId) async {
    return await _payrollRepository.getByStaff(staffId);
  }

  /// Get pending payrolls
  Future<List<PayrollWithStaff>> getPendingPayrolls({String? month}) async {
    return await _payrollRepository.getPending(month: month);
  }

  /// Get monthly summary
  Future<PayrollMonthlySummary> getMonthlySummary(String month) async {
    return await _payrollRepository.getMonthlySummary(month);
  }

  /// Get payroll with details
  Future<PayrollWithStaff?> getPayrollWithDetails(int id) async {
    return await _payrollRepository.getByIdWithStaff(id);
  }

  /// Check if payroll exists for month
  Future<bool> payrollExistsForMonth(String month) async {
    return await _payrollRepository.payrollExistsForMonth(month);
  }

  /// Generate salary slip PDF
  Future<void> printSalarySlip(BuildContext context, int payrollId) async {
    final payroll = await _payrollRepository.getByIdWithStaff(payrollId);
    if (payroll == null) {
      throw PayrollNotFoundException('Payroll record not found');
    }

    // Debug logging
    debugPrint('=== PAYROLL DEBUG ===');
    debugPrint('Allowances: ${payroll.payroll.allowances}');
    debugPrint('Allowances Breakdown: ${payroll.payroll.allowancesBreakdown}');
    debugPrint('Deductions: ${payroll.payroll.deductions}');
    debugPrint('Deductions Breakdown: ${payroll.payroll.deductionsBreakdown}');
    debugPrint('Allowances Map: ${payroll.allowancesMap}');
    debugPrint('Deductions Map: ${payroll.deductionsMap}');
    debugPrint('====================');

    // Get school settings
    final schoolSettings = await _db.getSchoolSettings();
    final schoolName = schoolSettings?.schoolName ?? 'School Name';

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'SALARY SLIP',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatMonth(payroll.payroll.month),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Divider(thickness: 1),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Employee Details
              _buildInfoRow('Employee', payroll.staffName),
              _buildInfoRow('Employee ID', payroll.staff.employeeId),
              _buildInfoRow('Designation', payroll.staff.designation),
              if (payroll.staff.bankName != null)
                _buildInfoRow('Bank', payroll.staff.bankName!),
              if (payroll.staff.accountNumber != null)
                _buildInfoRow('Account', payroll.staff.accountNumber!),

              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),

              // Earnings & Deductions
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EARNINGS',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        _buildAmountRow(
                          'Basic Salary',
                          payroll.payroll.basicSalary,
                        ),
                        // Show individual allowances if breakdown exists
                        ...payroll.allowancesMap.entries.map(
                          (e) => _buildAmountRow(e.key, e.value),
                        ),
                        // Show generic "Allowances" line if there's total but no breakdown
                        if (payroll.allowancesMap.isEmpty && payroll.payroll.allowances > 0)
                          _buildAmountRow(
                            'Allowances',
                            payroll.payroll.allowances,
                          ),
                        // Show "None" if there are no allowances
                        if (payroll.allowancesMap.isEmpty && payroll.payroll.allowances == 0)
                          _buildAmountRow('Allowances', 0),
                        pw.Divider(thickness: 0.5),
                        _buildAmountRow(
                          'Total',
                          payroll.payroll.basicSalary +
                              payroll.payroll.allowances,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Deductions
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DEDUCTIONS',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        ...payroll.deductionsMap.entries.map(
                          (e) => _buildAmountRow(e.key, e.value),
                        ),
                        if (payroll.deductionsMap.isEmpty)
                          _buildAmountRow('None', 0),
                        pw.Divider(thickness: 0.5),
                        _buildAmountRow(
                          'Total',
                          payroll.payroll.deductions,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),

              // Net Salary
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: PdfColors.grey200,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET SALARY',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'PKR ${_formatAmount(payroll.payroll.netSalary)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Attendance Summary
              pw.Text(
                'Attendance Summary',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Working Days: ${payroll.payroll.workingDays}'),
                  pw.Text('Present: ${payroll.payroll.daysPresent}'),
                  pw.Text('Absent: ${payroll.payroll.daysAbsent}'),
                  pw.Text('Leave: ${payroll.payroll.leaveDays}'),
                ],
              ),

              if (payroll.payroll.status == 'paid') ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'Payment Status: PAID',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if (payroll.payroll.paidDate != null)
                  pw.Text('Paid on: ${_formatDate(payroll.payroll.paidDate!)}'),
                if (payroll.payroll.paymentMode != null)
                  pw.Text('Mode: ${payroll.payroll.paymentMode}'),
              ],
            ],
          ),
        );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'Salary_Slip_${payroll.staff.employeeId}_${payroll.payroll.month}',
      );
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildAmountRow(String label, double amount, {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle(fontSize: 10);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label, style: style),
          pw.SizedBox(width: 8),
          pw.Text(_formatAmount(amount), style: style),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[int.parse(parts[1]) - 1]} ${parts[0]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

/// Exception for payroll validation errors
class PayrollValidationException implements Exception {
  final String message;

  PayrollValidationException(this.message);

  @override
  String toString() => 'PayrollValidationException: $message';
}

/// Exception for payroll not found
class PayrollNotFoundException implements Exception {
  final String message;

  PayrollNotFoundException(this.message);

  @override
  String toString() => 'PayrollNotFoundException: $message';
}
