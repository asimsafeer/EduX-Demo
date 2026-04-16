/// EduX School Management System
/// Expense PDF Service - Generates PDF for expense reports
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/database.dart';
import '../providers/expense_provider.dart';
import '../core/utils/pdf_helper.dart';

class ExpensePdfService {
  ExpensePdfService._();

  static Future<Uint8List> generateExpensePdf({
    required SchoolSetting schoolSettings,
    required ExpenseStats stats,
    required List<Expense> expenses,
    required DateTimeRange dateRange,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    final currencyFormat = NumberFormat('#,###', 'en_US');
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            // Header
            _buildHeader(schoolSettings, dateRange, dateFormat),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(
              'Financial Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildSummaryTable(stats, currencyFormat),
            pw.SizedBox(height: 30),

            // Transactions Section
            pw.Text(
              'Expense Transactions',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildExpenseTable(expenses, currencyFormat, dateFormat),

            // Footer
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    SchoolSetting settings,
    DateTimeRange dateRange,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.schoolName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (settings.address != null)
                  pw.Text(
                    settings.address!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'EXPENSE REPORT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Period: ${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(
    ExpenseStats stats,
    NumberFormat currencyFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildCell('Total Income (Fees)', isHeader: true),
            _buildCell('Payroll Expense', isHeader: true),
            _buildCell('Operational Expenses', isHeader: true),
            _buildCell('Net Income', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _buildCell(
              'PKR ${currencyFormat.format(stats.totalFeeCollected)}',
              color: PdfColors.green700,
              isBold: true,
            ),
            _buildCell(
              'PKR ${currencyFormat.format(stats.totalPayroll)}',
              color: PdfColors.orange700,
              isBold: true,
            ),
            _buildCell(
              'PKR ${currencyFormat.format(stats.totalExpenses)}',
              color: PdfColors.red700,
              isBold: true,
            ),
            _buildCell(
              'PKR ${currencyFormat.format(stats.netIncome)}',
              color: stats.netIncome >= 0
                  ? PdfColors.green700
                  : PdfColors.red700,
              isBold: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildExpenseTable(
    List<Expense> expenses,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    if (expenses.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No expenses recorded for this period.',
          style: const pw.TextStyle(color: PdfColors.grey600),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(4), // Title
        2: const pw.FlexColumnWidth(3), // Category
        3: const pw.FlexColumnWidth(2), // Amount
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildCell('Date', isHeader: true),
            _buildCell('Description', isHeader: true),
            _buildCell('Category', isHeader: true),
            _buildCell(
              'Amount (PKR)',
              isHeader: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        // Rows
        ...expenses.map((expense) {
          return pw.TableRow(
            children: [
              _buildCell(dateFormat.format(expense.date)),
              _buildCell(expense.title),
              _buildCell(expense.category),
              _buildCell(
                currencyFormat.format(expense.amount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'EduX School Management System',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'Page 1', // Simple footer, multipage handling would use context.pageNumber
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader || isBold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }
}
