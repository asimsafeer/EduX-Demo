/// EduX School Management System
/// Invoice Export Service - PDF generation for invoices/challans
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../repositories/invoice_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/pdf_helper.dart';

/// Invoice Export Service
class InvoiceExportService {
  InvoiceExportService(AppDatabase db);

  // ============================================
  // PDF GENERATION
  // ============================================

  /// Generate PDF for a single invoice (Fee Challan)
  Future<Uint8List> generateInvoicePdf({
    required InvoiceWithDetails invoice,
    required SchoolSetting school,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildInvoiceChallan(invoice, school),
      ),
    );

    return pdf.save();
  }

  /// Generate PDF for invoice list
  Future<Uint8List> generateInvoiceListPdf(
    List<InvoiceWithDetails> invoices,
    SchoolSetting school,
    String? title,
  ) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildListHeader(school, title ?? 'Invoice List'),
        build: (context) => [_buildInvoiceTable(invoices)],
      ),
    );

    return pdf.save();
  }

  // ============================================
  // PDF WIDGETS - CHALLAN
  // ============================================

  /// Build a 2-copy challan (Student Copy | School/Institute Copy) side-by-side on landscape A4
  pw.Widget _buildInvoiceChallan(
    InvoiceWithDetails invoice,
    SchoolSetting school,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Student Copy
        pw.Expanded(child: _buildChallanCopy(invoice, school, 'STUDENT COPY')),
        // Dashed divider between copies
        pw.Container(
          width: 1,
          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              const dashHeight = 4.0;
              const gapHeight = 3.0;
              double y = 0;
              canvas
                ..setStrokeColor(PdfColors.grey400)
                ..setLineWidth(0.5);
              while (y < size.y) {
                canvas
                  ..moveTo(0, y)
                  ..lineTo(0, y + dashHeight)
                  ..strokePath();
                y += dashHeight + gapHeight;
              }
            },
          ),
        ),
        // School/Institute Copy
        pw.Expanded(
          child: _buildChallanCopy(invoice, school, 'SCHOOL / INSTITUTE COPY'),
        ),
      ],
    );
  }

  pw.Widget _buildChallanCopy(
    InvoiceWithDetails invoice,
    SchoolSetting school,
    String copyTitle,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: '${AppConstants.defaultCurrencySymbol} ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat(AppConstants.displayDateFormat);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── School Header ──
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  school.schoolName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (school.address != null)
                  pw.Text(
                    school.address!,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                if (school.phone != null)
                  pw.Text(
                    'Phone: ${school.phone}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // ── Title Badge ──
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey800,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Text(
                'FEE CHALLAN — $copyTitle',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Student Information ──
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Student:',
                        invoice.studentName,
                        isBold: true,
                      ),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Adm No:',
                        invoice.student.admissionNumber,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Class:', invoice.classSection),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Month:',
                        _formatMonth(invoice.invoice.month),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Invoice #:',
                        invoice.invoice.invoiceNumber,
                      ),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Issue Date:',
                        dateFormat.format(invoice.invoice.issueDate),
                      ),
                    ),
                  ],
                ),
                _buildInfoRow(
                  'Due Date:',
                  dateFormat.format(invoice.invoice.dueDate),
                  isBold: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Fee Breakdown Table ──
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell(
                    '#',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell('Fee Description', isHeader: true),
                  _buildTableCell(
                    'Amount (Rs.)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              // Items
              ...invoice.items.asMap().entries.map(
                (entry) => pw.TableRow(
                  decoration: entry.key % 2 == 1
                      ? const pw.BoxDecoration(color: PdfColors.grey50)
                      : null,
                  children: [
                    _buildTableCell(
                      (entry.key + 1).toString(),
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(entry.value.feeType.name),
                    _buildTableCell(
                      currencyFormat.format(entry.value.item.netAmount),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // ── Totals ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount:',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      currencyFormat.format(invoice.invoice.totalAmount),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                if (invoice.invoice.discountAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Discount:',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '- ${currencyFormat.format(invoice.invoice.discountAmount)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Net Payable ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey800,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'NET PAYABLE:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(invoice.invoice.netAmount),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          pw.Spacer(),

          // ── Signature Area ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 100, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Receiver\'s Sign.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 100, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Authorized Sign.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // PDF WIDGETS - LIST
  // ============================================

  pw.Widget _buildListHeader(SchoolSetting school, String title) {
    return pw.Column(
      children: [
        pw.Text(
          school.schoolName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildInvoiceTable(List<InvoiceWithDetails> invoices) {
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: '',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat(AppConstants.dbDateFormat);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // #
        1: const pw.FlexColumnWidth(2), // Invoice No
        2: const pw.FlexColumnWidth(3), // Student
        3: const pw.FlexColumnWidth(2), // Class
        4: const pw.FlexColumnWidth(2), // Month
        5: const pw.FlexColumnWidth(2), // Due Date
        6: const pw.FlexColumnWidth(2), // Amount
        7: const pw.FlexColumnWidth(2), // Status
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Invoice #'),
            _buildTableHeader('Student'),
            _buildTableHeader('Class'),
            _buildTableHeader('Month'),
            _buildTableHeader('Due Date'),
            _buildTableHeader('Amount', align: pw.TextAlign.right),
            _buildTableHeader('Status', align: pw.TextAlign.center),
          ],
        ),
        // Rows
        ...invoices.asMap().entries.map((entry) {
          final index = entry.key;
          final invoice = entry.value;
          final details = invoice.invoice;

          return pw.TableRow(
            decoration: index % 2 == 1
                ? const pw.BoxDecoration(color: PdfColors.grey50)
                : null,
            children: [
              _buildTableCell(
                (index + 1).toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(details.invoiceNumber),
              _buildTableCell(invoice.studentName),
              _buildTableCell(invoice.classSection),
              _buildTableCell(_formatMonth(details.month)),
              _buildTableCell(dateFormat.format(details.dueDate)),
              _buildTableCell(
                currencyFormat.format(details.netAmount),
                align: pw.TextAlign.right,
              ),
              _buildStatusCell(details.status),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildStatusCell(String status) {
    PdfColor color = PdfColors.black;
    if (status == FeeConstants.invoiceStatusPaid) color = PdfColors.green700;
    if (status == FeeConstants.invoiceStatusPending) color = PdfColors.orange700;
    if (status == FeeConstants.invoiceStatusOverdue) color = PdfColors.red700;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMM yyyy').format(date);
      }
    } catch (_) {}
    return month;
  }
}
