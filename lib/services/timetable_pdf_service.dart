/// EduX School Management System
/// Timetable PDF Service - Generates PDF for weekly timetable
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/app_database.dart';
import '../repositories/timetable_repository.dart';
import '../core/utils/pdf_helper.dart';

class TimetablePdfService {
  TimetablePdfService._();

  /// Safely encode text for PDF - handles non-Latin1 characters
  static String _safeText(String? text) {
    if (text == null) return '';
    // Replace common Unicode characters with ASCII equivalents
    return text
        .replaceAll('–', '-') // En dash to hyphen
        .replaceAll('—', '-') // Em dash to hyphen
        .replaceAll('"', "'") // Smart quotes to apostrophe
        .replaceAll('"', '"') // Smart double quotes
        .replaceAll('"', '"')
        .replaceAll('…', '...') // Ellipsis to dots
        .replaceAll('•', '*') // Bullet to asterisk
        .replaceAll(
          RegExp(r'[^\x00-\xFF]'),
          '?',
        ); // Replace other non-Latin1 with ?
  }

  static Future<Uint8List> generateTimetablePdf({
    required SchoolSetting schoolSettings,
    required String className,
    required String sectionName,
    required String academicYear,
    required List<PeriodDefinition> periods,
    required Map<String, Map<int, TimetableSlotWithDetails?>> timetable,
  }) async {
    final pdf = pw.Document(theme: await PdfHelper.getPdfTheme());

    // Filter valid periods and sort
    final sortedPeriods = List<PeriodDefinition>.from(periods)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // Days of week
    const daysOfWeek = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(
                schoolSettings,
                className,
                sectionName,
                academicYear,
              ),
              pw.SizedBox(height: 20),

              // Timetable Grid
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _buildCell('Period / Time', isHeader: true),
                        ...daysOfWeek.map(
                          (day) =>
                              _buildCell(day.toUpperCase(), isHeader: true),
                        ),
                      ],
                    ),

                    // Period Rows
                    ...sortedPeriods.map((period) {
                      return pw.TableRow(
                        decoration: period.isBreak
                            ? const pw.BoxDecoration(color: PdfColors.grey50)
                            : null,
                        children: [
                          // Period Info Column
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            width: 80,
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  _safeText(period.name),
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.Text(
                                  '${period.startTime} - ${period.endTime}',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Day Columns
                          ...daysOfWeek.map((day) {
                            if (period.isBreak) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'BREAK',
                                  style: pw.TextStyle(
                                    color: PdfColors.grey500,
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            final slot = timetable[day]?[period.periodNumber];
                            return _buildSlotCell(slot);
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // Footer
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on: ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    'EduX School Management System',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    SchoolSetting settings,
    String className,
    String sectionName,
    String academicYear,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _safeText(settings.schoolName),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (settings.address != null)
                pw.Text(
                  _safeText(settings.address),
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'WEEKLY TIMETABLE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Class: ${_safeText(className)} - ${_safeText(sectionName)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Academic Year: $academicYear',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        _safeText(text),
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 10 : 9,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSlotCell(TimetableSlotWithDetails? slot) {
    if (slot == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(5),
        alignment: pw.Alignment.center,
        child: pw.Text(
          '-',
          style: const pw.TextStyle(color: PdfColors.grey400),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _safeText(slot.subject?.name ?? slot.shortCode),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
          if (slot.teacherName != null)
            pw.Text(
              _safeText(slot.teacherName),
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
        ],
      ),
    );
  }
}
