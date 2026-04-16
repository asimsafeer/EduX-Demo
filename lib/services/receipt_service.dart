/// EduX School Management System
/// Receipt Service - PDF generation for payment receipts
library;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/payment_repository.dart';
import '../repositories/invoice_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/pdf_helper.dart';

/// PDF theme with Unicode font support for isolate tasks
pw.ThemeData _getPdfTheme() {
  return pw.ThemeData.withFont(
    base: pw.Font.times(),
    bold: pw.Font.timesBold(),
    italic: pw.Font.timesItalic(),
    boldItalic: pw.Font.timesBoldItalic(),
  );
}

/// Receipt data for PDF generation
class ReceiptData {
  final SchoolSetting schoolSettings;
  final Payment payment;
  final Invoice invoice;
  final Student student;
  final String className;
  final String? sectionName;
  final List<InvoiceItemWithType> invoiceItems;

  const ReceiptData({
    required this.schoolSettings,
    required this.payment,
    required this.invoice,
    required this.student,
    required this.className,
    this.sectionName,
    this.invoiceItems = const [],
  });

  String get studentName => '${student.studentName} ${student.fatherName}';
  String get classSection =>
      sectionName != null ? '$className-$sectionName' : className;
}

/// Receipt generation service
class ReceiptService {
  final AppDatabase _db;
  final PaymentRepository _paymentRepo;
  final InvoiceRepository _invoiceRepo;

  ReceiptService(this._db)
    : _paymentRepo = DriftPaymentRepository(_db),
      _invoiceRepo = DriftInvoiceRepository(_db);

  // ============================================
  // PDF GENERATION
  // ============================================

  /// Generate receipt PDF for a single payment
  Future<Uint8List> generateReceipt(ReceiptData data) async {
    return await compute(_generateReceiptTask, data);
  }

  static Future<Uint8List> _generateReceiptTask(ReceiptData data) async {
    final pdf = pw.Document(theme: _getPdfTheme());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Row(
            children: [
              // Student Copy
              pw.Expanded(
                child: _buildReceipt(data, copyTitle: 'STUDENT COPY'),
              ),
              pw.Container(
                width: 1,
                height: double.infinity,
                margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                color: PdfColors.grey400,
                child: pw.VerticalDivider(
                  color: PdfColors.grey400,
                  thickness: 1,
                ),
              ),
              // School Copy
              pw.Expanded(
                child: _buildReceipt(data, copyTitle: 'SCHOOL RECORD'),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate receipts for multiple payments
  Future<Uint8List> generateBulkReceipts(List<ReceiptData> dataList) async {
    return await compute(_generateBulkReceiptsTask, dataList);
  }

  static Future<Uint8List> _generateBulkReceiptsTask(
    List<ReceiptData> dataList,
  ) async {
    final pdf = pw.Document(theme: _getPdfTheme());

    for (final data in dataList) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Row(
              children: [
                pw.Expanded(
                  child: _buildReceipt(data, copyTitle: 'STUDENT COPY'),
                ),
                pw.Container(
                  width: 1,
                  height: double.infinity,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 20),
                  color: PdfColors.grey400,
                  child: pw.VerticalDivider(color: PdfColors.grey400),
                ),
                pw.Expanded(
                  child: _buildReceipt(data, copyTitle: 'SCHOOL RECORD'),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Print receipt directly (with preview)
  Future<void> printReceipt(BuildContext context, ReceiptData data) async {
    final pdfBytes = await generateReceipt(data);
    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'Receipt - ${data.payment.receiptNumber}',
      );
    }
  }

  /// Print receipt by payment ID
  Future<void> printReceiptByPaymentId(
    BuildContext context,
    int paymentId,
  ) async {
    final data = await getReceiptData(paymentId);
    if (data == null) return;
    if (context.mounted) {
      await printReceipt(context, data);
    }
  }

  // ============================================
  // DATA RETRIEVAL
  // ============================================

  /// Get receipt data for a payment
  Future<ReceiptData?> getReceiptData(int paymentId) async {
    // Get payment with details
    final paymentDetails = await _paymentRepo.getPaymentWithDetails(paymentId);
    if (paymentDetails == null) return null;

    // Get school settings
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) return null;

    // Get invoice items
    final invoiceDetails = await _invoiceRepo.getInvoiceWithDetails(
      paymentDetails.invoice.id,
    );

    return ReceiptData(
      schoolSettings: schoolSettings,
      payment: paymentDetails.payment,
      invoice: paymentDetails.invoice,
      student: paymentDetails.student,
      className: paymentDetails.schoolClass.name,
      sectionName: paymentDetails.section?.name,
      invoiceItems: invoiceDetails?.items ?? [],
    );
  }

  /// Get bulk receipt data for date range
  Future<List<ReceiptData>> getBulkReceiptData({
    required DateTime from,
    required DateTime to,
    String? paymentMode,
  }) async {
    final payments = await _paymentRepo.getPayments(
      PaymentFilters(
        dateFrom: from,
        dateTo: to,
        paymentMode: paymentMode,
        limit: 500,
      ),
    );

    final dataList = <ReceiptData>[];
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) return [];

    for (final p in payments) {
      // Get invoice items
      final invoiceDetails = await _invoiceRepo.getInvoiceWithDetails(
        p.invoice.id,
      );

      dataList.add(
        ReceiptData(
          schoolSettings: schoolSettings,
          payment: p.payment,
          invoice: p.invoice,
          student: p.student,
          className: p.schoolClass.name,
          sectionName: p.section?.name,
          invoiceItems: invoiceDetails?.items ?? [],
        ),
      );
    }

    return dataList;
  }

  // ============================================
  // PDF BUILDING
  // ============================================

  static pw.Widget _buildReceipt(
    ReceiptData data, {
    required String copyTitle,
  }) {
    final dateFormat = DateFormat(AppConstants.displayDateFormat);
    final timeFormat = DateFormat(AppConstants.displayTimeFormat);
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: '${AppConstants.defaultCurrencySymbol} ',
      decimalDigits: 2,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header with school info
        _buildHeader(data.schoolSettings),
        pw.SizedBox(height: 12),

        // Receipt title and copy type
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'PAYMENT RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  copyTitle,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 12),

        // Receipt details row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildLabelValue('Receipt No:', data.payment.receiptNumber),
                pw.SizedBox(height: 2),
                _buildLabelValue(
                  'Date:',
                  dateFormat.format(data.payment.paymentDate),
                ),
                _buildLabelValue(
                  'Time:',
                  timeFormat.format(data.payment.paymentDate),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildLabelValue('Invoice No:', data.invoice.invoiceNumber),
                pw.SizedBox(height: 2),
                _buildLabelValue('Month:', _formatMonth(data.invoice.month)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Student info
        _buildStudentInfo(data, dateFormat),
        pw.SizedBox(height: 12),

        // Payment details
        _buildPaymentDetails(data, currencyFormat),
        pw.SizedBox(height: 8),

        // Invoice items breakdown (if available)
        if (data.invoiceItems.isNotEmpty) ...[
          _buildInvoiceItemsTable(data.invoiceItems, currencyFormat),
          pw.SizedBox(height: 8),
        ],

        // Amount summary
        _buildAmountSummary(data, currencyFormat),
        pw.SizedBox(height: 8),

        // Amount in words
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Amount in Words:',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _convertAmountToWords(data.payment.amount),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Payment mode info
        if (data.payment.paymentMode != FeeConstants.paymentModeCash)
          _buildPaymentModeInfo(data),

        pw.SizedBox(height: 12),

        // School Bank Details (if configured)
        if (data.schoolSettings.accountNumber != null) ...[
          _buildBankDetails(data.schoolSettings),
          pw.SizedBox(height: 12),
        ],

        pw.Spacer(),

        // Footer with signatures
        _buildFooter(),
      ],
    );
  }

  static pw.Widget _buildHeader(SchoolSetting school) {
    // Build logo widget if available
    pw.Widget? logoWidget;
    if (school.logo != null && school.logo!.isNotEmpty) {
      try {
        final logoImage = pw.MemoryImage(Uint8List.fromList(school.logo!));
        logoWidget = pw.Image(
          logoImage,
          width: 40,
          height: 40,
          fit: pw.BoxFit.contain,
        );
      } catch (_) {
        // If logo parsing fails, skip it
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 10)],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: logoWidget != null
                  ? pw.CrossAxisAlignment.start
                  : pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  school.schoolName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (school.address != null)
                  pw.Text(
                    school.address!,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: logoWidget != null
                        ? pw.TextAlign.left
                        : pw.TextAlign.center,
                  ),
                if (school.phone != null || school.email != null)
                  pw.Text(
                    [
                      if (school.phone != null) 'Tel: ${school.phone}',
                      if (school.email != null) 'Email: ${school.email}',
                    ].join(' | '),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildStudentInfo(ReceiptData data, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Student Name', data.studentName),
                _buildInfoRow('Admission No', data.student.admissionNumber),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Class', data.classSection),
                _buildInfoRow("Father's Name", data.student.fatherName ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentDetails(
    ReceiptData data,
    NumberFormat currencyFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Mode',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                FeeConstants.getPaymentModeDisplayName(
                  data.payment.paymentMode,
                ),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Amount Received',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                currencyFormat.format(data.payment.amount),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceItemsTable(
    List<InvoiceItemWithType> items,
    NumberFormat currencyFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Fee Type', isHeader: true),
            _buildTableCell(
              'Amount',
              isHeader: true,
              align: pw.TextAlign.right,
            ),
            _buildTableCell('Net', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.feeType.name),
              _buildTableCell(
                currencyFormat.format(item.item.amount),
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                currencyFormat.format(item.item.netAmount),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildAmountSummary(
    ReceiptData data,
    NumberFormat currencyFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow(
            'Invoice Total',
            currencyFormat.format(data.invoice.netAmount),
          ),
          if (data.invoice.discountAmount > 0)
            _buildSummaryRow(
              'Discount',
              '- ${currencyFormat.format(data.invoice.discountAmount)}',
            ),
          _buildSummaryRow(
            'Previous Payments',
            currencyFormat.format(
              data.invoice.paidAmount - data.payment.amount,
            ),
          ),
          _buildSummaryRow(
            'This Payment',
            currencyFormat.format(data.payment.amount),
            highlight: true,
          ),
          pw.Divider(color: PdfColors.grey400, height: 8),
          _buildSummaryRow(
            'Balance Due',
            currencyFormat.format(data.invoice.balanceAmount),
            highlight: data.invoice.balanceAmount > 0,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? PdfColors.green800 : null,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentModeInfo(ReceiptData data) {
    final details = <String>[];

    if (data.payment.paymentMode == FeeConstants.paymentModeCheque) {
      if (data.payment.referenceNumber != null) {
        details.add('Cheque No: ${data.payment.referenceNumber}');
      }
      if (data.payment.bankName != null) {
        details.add('Bank: ${data.payment.bankName}');
      }
      if (data.payment.chequeDate != null) {
        details.add(
          'Date: ${DateFormat('dd/MM/yyyy').format(data.payment.chequeDate!)}',
        );
      }
    } else if (data.payment.referenceNumber != null) {
      details.add('Reference: ${data.payment.referenceNumber}');
    }

    if (details.isEmpty) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        details.join(' | '),
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  static pw.Widget _buildBankDetails(SchoolSetting school) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bank Details for Fee Deposit',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              if (school.bankName != null) ...[
                _buildBankInfoItem('Bank Name', school.bankName!),
                pw.SizedBox(width: 16),
              ],
              if (school.accountTitle != null) ...[
                _buildBankInfoItem('Account Title', school.accountTitle!),
                pw.SizedBox(width: 16),
              ],
              if (school.accountNumber != null)
                _buildBankInfoItem('Account/IBAN', school.accountNumber!),
            ],
          ),
          if (school.onlinePaymentInfo != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Online Payment: ${school.onlinePaymentInfo}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildBankInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSignatureLine('Received by'),
          _buildSignatureLine('Accountant'),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 100,
          height: 30,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600)),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  static String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final monthNum = int.parse(parts[1]);
        final date = DateTime(year, monthNum);
        return DateFormat('MMMM yyyy').format(date);
      }
    } catch (_) {}
    return month;
  }

  static String _convertAmountToWords(double amount) {
    final intAmount = amount.toInt();
    final paisaAmount = ((amount - intAmount) * 100).round();

    String result = _numberToWords(intAmount);

    if (paisaAmount > 0) {
      result += ' and ${_numberToWords(paisaAmount)} Paisa';
    }

    return '$result Rupees Only';
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String words = '';

    if (number >= 10000000) {
      words += '${_numberToWords(number ~/ 10000000)} Crore ';
      number %= 10000000;
    }

    if (number >= 100000) {
      words += '${_numberToWords(number ~/ 100000)} Lakh ';
      number %= 100000;
    }

    if (number >= 1000) {
      words += '${_numberToWords(number ~/ 1000)} Thousand ';
      number %= 1000;
    }

    if (number >= 100) {
      words += '${units[number ~/ 100]} Hundred ';
      number %= 100;
    }

    if (number > 0) {
      if (number < 20) {
        words += units[number];
      } else {
        words += tens[number ~/ 10];
        if (number % 10 > 0) {
          words += ' ${units[number % 10]}';
        }
      }
    }

    return words.trim();
  }

  // ============================================
  // INVOICE SLIP PDF GENERATION
  // ============================================

  /// Get invoice data for printing slips
  Future<List<InvoiceWithDetails>> getInvoiceSlipData(
    List<int> invoiceIds,
  ) async {
    final invoiceRepo = DriftInvoiceRepository(_db);
    final results = <InvoiceWithDetails>[];

    for (final id in invoiceIds) {
      final details = await invoiceRepo.getInvoiceWithDetails(id);
      if (details != null) {
        results.add(details);
      }
    }

    return results;
  }

  /// Generate printable invoice slips PDF for distribution to students
  Future<Uint8List> generateInvoiceSlips(List<int> invoiceIds) async {
    final invoiceDetails = await getInvoiceSlipData(invoiceIds);
    final schoolSettings = await _db.getSchoolSettings();

    if (invoiceDetails.isEmpty || schoolSettings == null) {
      throw Exception('No invoice data or school settings found');
    }

    // Serialize the data into a map for compute isolate
    final serializedData = <String, dynamic>{
      'invoices': invoiceDetails
          .map(
            (d) => {
              'invoiceNumber': d.invoice.invoiceNumber,
              'month': d.invoice.month,
              'academicYear': d.invoice.academicYear,
              'issueDate': d.invoice.issueDate.toIso8601String(),
              'dueDate': d.invoice.dueDate.toIso8601String(),
              'totalAmount': d.invoice.totalAmount,
              'discountAmount': d.invoice.discountAmount,
              'netAmount': d.invoice.netAmount,
              'status': d.invoice.status,
              'studentName': '${d.student.studentName} ${d.student.fatherName}',
              'admissionNumber': d.student.admissionNumber,
              'classSection': d.classSection,
              'items': d.items
                  .map(
                    (item) => {
                      'feeTypeName': item.feeType.name,
                      'amount': item.item.amount,
                      'discount': item.item.discount,
                      'netAmount': item.item.netAmount,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'school': {
        'name': schoolSettings.schoolName,
        'address': schoolSettings.address,
        'phone': schoolSettings.phone,
        'email': schoolSettings.email,
        'logo': schoolSettings.logo,
      },
    };

    return await compute(_generateInvoiceSlipsTask, serializedData);
  }

  static Future<Uint8List> _generateInvoiceSlipsTask(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document(theme: _getPdfTheme());
    final invoices = data['invoices'] as List<dynamic>;
    final school = data['school'] as Map<String, dynamic>;

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Build logo widget (compact for 4-per-page)
    pw.Widget? logoWidget;
    final logoBytes = school['logo'];
    if (logoBytes != null && (logoBytes as Uint8List).isNotEmpty) {
      try {
        final logoImage = pw.MemoryImage(Uint8List.fromList(logoBytes));
        logoWidget = pw.Image(
          logoImage,
          width: 20,
          height: 20,
          fit: pw.BoxFit.contain,
        );
      } catch (_) {}
    }

    // Portrait A4 — page-aware sizing for 4 slips
    const pageFormat = PdfPageFormat.a4;
    const pageMargin = 16.0;
    const slipsPerPage = 4;
    const cutLineHeight = 12.0;
    const totalCutLines = slipsPerPage - 1;
    final availableHeight = pageFormat.height - (pageMargin * 2);
    final slipHeight =
        (availableHeight - (cutLineHeight * totalCutLines)) / slipsPerPage;

    for (int i = 0; i < invoices.length; i += slipsPerPage) {
      final slipsOnPage = <pw.Widget>[];

      for (int j = i; j < i + slipsPerPage && j < invoices.length; j++) {
        final inv = invoices[j] as Map<String, dynamic>;

        // ✂ Cut line between slips
        if (j > i) {
          slipsOnPage.add(
            pw.SizedBox(
              height: cutLineHeight,
              child: pw.Center(
                child: pw.Row(
                  children: [
                    pw.Text(
                      '✂ ',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        height: 0,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey300,
                              width: 0.5,
                              style: pw.BorderStyle.dashed,
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.Text(
                      ' ✂',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        slipsOnPage.add(
          pw.SizedBox(
            height: slipHeight,
            child: _buildInvoiceSlip(
              inv,
              school,
              logoWidget,
              dateFormat,
              currencyFormat,
            ),
          ),
        );
      }

      // Fill remaining space if fewer than 4 slips
      final slipsCount = (invoices.length - i).clamp(0, slipsPerPage);
      for (int k = slipsCount; k < slipsPerPage; k++) {
        if (k > 0) slipsOnPage.add(pw.SizedBox(height: cutLineHeight));
        slipsOnPage.add(pw.SizedBox(height: slipHeight));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(pageMargin),
          build: (context) => pw.Column(children: slipsOnPage),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildInvoiceSlip(
    Map<String, dynamic> inv,
    Map<String, dynamic> school,
    pw.Widget? logoWidget,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    final items = inv['items'] as List<dynamic>;
    final issueDate = DateTime.parse(inv['issueDate'] as String);
    final dueDate = DateTime.parse(inv['dueDate'] as String);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ── Header bar: School name + logo + FEE INVOICE ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(2),
                topRight: pw.Radius.circular(2),
              ),
            ),
            child: pw.Row(
              children: [
                if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 8)],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (school['name'] as String).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (school['address'] != null)
                        pw.Text(
                          '${school['address']}${school['phone'] != null ? '  |  Tel: ${school['phone']}' : ''}',
                          style: const pw.TextStyle(
                            fontSize: 6.5,
                            color: PdfColors.grey300,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(3),
                    ),
                  ),
                  child: pw.Text(
                    'FEE INVOICE',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Student + Invoice details row ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              children: [
                _buildSlipInfoRow('Student', inv['studentName'] as String),
                pw.SizedBox(width: 10),
                _buildSlipInfoRow('Adm#', inv['admissionNumber'] as String),
                pw.SizedBox(width: 10),
                _buildSlipInfoRow('Class', inv['classSection'] as String),
                pw.Spacer(),
                _buildSlipInfoRow('Inv#', inv['invoiceNumber'] as String),
                pw.SizedBox(width: 10),
                _buildSlipInfoRow(
                  'Month',
                  _formatMonth(inv['month'] as String),
                ),
                pw.SizedBox(width: 10),
                _buildSlipInfoRow('Due', dateFormat.format(dueDate)),
              ],
            ),
          ),

          // ── Fee items table ──
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Table(
                border: pw.TableBorder(
                  horizontalInside: const pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.3,
                  ),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.blueGrey300,
                          width: 0.8,
                        ),
                      ),
                    ),
                    children: [
                      _buildSlipTableCell('Fee Type', isHeader: true),
                      _buildSlipTableCell(
                        'Amount',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _buildSlipTableCell(
                        'Discount',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _buildSlipTableCell(
                        'Net Amount',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final m = entry.value as Map<String, dynamic>;
                    final isEven = entry.key % 2 == 0;
                    return pw.TableRow(
                      decoration: isEven
                          ? null
                          : const pw.BoxDecoration(color: PdfColors.grey50),
                      children: [
                        _buildSlipTableCell(m['feeTypeName'] as String),
                        _buildSlipTableCell(
                          currencyFormat.format(m['amount']),
                          align: pw.TextAlign.right,
                        ),
                        _buildSlipTableCell(
                          (m['discount'] as double) > 0
                              ? currencyFormat.format(m['discount'])
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _buildSlipTableCell(
                          currencyFormat.format(m['netAmount']),
                          align: pw.TextAlign.right,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Total bar ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: PdfColors.blueGrey800,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL AMOUNT DUE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(inv['netAmount']),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          // ── Footer: Signature + Meta ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: issue date + due date warning
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Issued: ${dateFormat.format(issueDate)}',
                        style: const pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Pay before ${dateFormat.format(dueDate)} to avoid late fees',
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.red400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: Signature line
                pw.Column(
                  children: [
                    pw.Container(
                      width: 80,
                      height: 0.5,
                      color: PdfColors.grey600,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Authorized Signature',
                      style: pw.TextStyle(
                        fontSize: 5.5,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSlipInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey700,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
        ),
      ],
    );
  }

  static pw.Widget _buildSlipTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 7 : 6.5,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blueGrey800 : PdfColors.grey800,
        ),
        textAlign: align,
      ),
    );
  }

  // ============================================
  // FULL-SIZE INVOICE PDF (A4 landscape, like receipt)
  // ============================================

  /// Generate full-size invoice PDF — A4 landscape, 2 copies side-by-side
  /// (Student Copy | School Copy). Mirrors the collect-payment receipt format
  /// but shows invoice data instead of payment data.
  Future<Uint8List> generateFullInvoiceSlips(List<int> invoiceIds) async {
    final invoiceDetails = await getInvoiceSlipData(invoiceIds);
    final schoolSettings = await _db.getSchoolSettings();

    if (invoiceDetails.isEmpty || schoolSettings == null) {
      throw Exception('No invoice data or school settings found');
    }

    // Serialize for compute isolate
    final serializedData = <String, dynamic>{
      'invoices': invoiceDetails
          .map(
            (d) => {
              'invoiceNumber': d.invoice.invoiceNumber,
              'month': d.invoice.month,
              'academicYear': d.invoice.academicYear,
              'issueDate': d.invoice.issueDate.toIso8601String(),
              'dueDate': d.invoice.dueDate.toIso8601String(),
              'totalAmount': d.invoice.totalAmount,
              'discountAmount': d.invoice.discountAmount,
              'netAmount': d.invoice.netAmount,
              'status': d.invoice.status,
              'studentName': '${d.student.studentName} ${d.student.fatherName ?? ''}',
              'fatherName': d.student.fatherName ?? '',
              'admissionNumber': d.student.admissionNumber,
              'classSection': d.classSection,
              'items': d.items
                  .map(
                    (item) => {
                      'feeTypeName': item.feeType.name,
                      'amount': item.item.amount,
                      'discount': item.item.discount,
                      'netAmount': item.item.netAmount,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'school': {
        'name': schoolSettings.schoolName,
        'address': schoolSettings.address,
        'phone': schoolSettings.phone,
        'email': schoolSettings.email,
        'logo': schoolSettings.logo,
        'accountNumber': schoolSettings.accountNumber,
        'bankName': schoolSettings.bankName,
        'accountTitle': schoolSettings.accountTitle,
      },
    };

    return await compute(_generateFullInvoiceSlipsTask, serializedData);
  }

  static Future<Uint8List> _generateFullInvoiceSlipsTask(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document(theme: _getPdfTheme());
    final invoices = data['invoices'] as List<dynamic>;
    final school = data['school'] as Map<String, dynamic>;

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: '${AppConstants.defaultCurrencySymbol} ',
      decimalDigits: 0,
    );

    // Build logo widget
    pw.Widget? logoWidget;
    final logoBytes = school['logo'];
    if (logoBytes != null && (logoBytes as Uint8List).isNotEmpty) {
      try {
        final logoImage = pw.MemoryImage(Uint8List.fromList(logoBytes));
        logoWidget = pw.Image(logoImage, width: 40, height: 40, fit: pw.BoxFit.contain);
      } catch (_) {}
    }

    for (final inv in invoices) {
      final invMap = inv as Map<String, dynamic>;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Row(
            children: [
              pw.Expanded(
                child: _buildFullInvoiceCopy(
                  invMap, school, logoWidget, dateFormat, currencyFormat,
                  copyTitle: 'STUDENT COPY',
                ),
              ),
              pw.Container(
                width: 1,
                height: double.infinity,
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                color: PdfColors.grey400,
              ),
              pw.Expanded(
                child: _buildFullInvoiceCopy(
                  invMap, school, logoWidget, dateFormat, currencyFormat,
                  copyTitle: 'SCHOOL RECORD',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildFullInvoiceCopy(
    Map<String, dynamic> inv,
    Map<String, dynamic> school,
    pw.Widget? logoWidget,
    DateFormat dateFormat,
    NumberFormat currencyFormat, {
    required String copyTitle,
  }) {
    final items = inv['items'] as List<dynamic>;
    final issueDate = DateTime.parse(inv['issueDate'] as String);
    final dueDate = DateTime.parse(inv['dueDate'] as String);
    final totalAmount = (inv['totalAmount'] as num).toDouble();
    final discountAmount = (inv['discountAmount'] as num).toDouble();
    final netAmount = (inv['netAmount'] as num).toDouble();

    // School header widget
    pw.Widget? logoW = logoWidget;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── School header ──
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            children: [
              if (logoW != null) ...[logoW, pw.SizedBox(width: 10)],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: logoW != null
                      ? pw.CrossAxisAlignment.start
                      : pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      school['name'] as String,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    if (school['address'] != null)
                      pw.Text(
                        school['address'] as String,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: logoW != null ? pw.TextAlign.left : pw.TextAlign.center,
                      ),
                    if (school['phone'] != null || school['email'] != null)
                      pw.Text(
                        [
                          if (school['phone'] != null) 'Tel: ${school['phone']}',
                          if (school['email'] != null) 'Email: ${school['email']}',
                        ].join('  |  '),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Invoice title + copy label ──
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'FEE INVOICE',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  copyTitle,
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Invoice details row ──
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildLabelValue('Invoice No:', inv['invoiceNumber'] as String),
                pw.SizedBox(height: 2),
                _buildLabelValue('Issue Date:', dateFormat.format(issueDate)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildLabelValue('Month:', _formatMonth(inv['month'] as String)),
                pw.SizedBox(height: 2),
                _buildLabelValue('Due Date:', dateFormat.format(dueDate)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Student info ──
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Student Name', inv['studentName'] as String),
                    _buildInfoRow('Admission No', inv['admissionNumber'] as String),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Class', inv['classSection'] as String),
                    _buildInfoRow("Father's Name", inv['fatherName'] as String),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Fee items table ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Fee Type', isHeader: true),
                _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Discount', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Net Amount', isHeader: true, align: pw.TextAlign.right),
              ],
            ),
            ...items.map((item) {
              final m = item as Map<String, dynamic>;
              final disc = (m['discount'] as num).toDouble();
              return pw.TableRow(
                children: [
                  _buildTableCell(m['feeTypeName'] as String),
                  _buildTableCell(currencyFormat.format(m['amount']), align: pw.TextAlign.right),
                  _buildTableCell(disc > 0 ? currencyFormat.format(disc) : '-', align: pw.TextAlign.right),
                  _buildTableCell(currencyFormat.format(m['netAmount']), align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 8),

        // ── Amount summary ──
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow('Total Amount', currencyFormat.format(totalAmount)),
              if (discountAmount > 0)
                _buildSummaryRow('Discount', '- ${currencyFormat.format(discountAmount)}'),
              pw.Divider(color: PdfColors.grey400, height: 8),
              _buildSummaryRow('Net Payable', currencyFormat.format(netAmount), highlight: true),
            ],
          ),
        ),

        pw.Spacer(),

        // ── Footer ──
        _buildFooter(),
      ],
    );
  }
}
