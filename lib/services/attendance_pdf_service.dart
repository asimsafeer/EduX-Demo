/// EduX School Management System
/// Attendance PDF Service - PDF generation for attendance reports
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../repositories/attendance_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/pdf_helper.dart';

/// Service for generating attendance PDF reports
class AttendancePdfService {
  static const _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const _headerColor = PdfColor.fromInt(0xFFE3F2FD);
  static const _presentColor = PdfColor.fromInt(0xFF4CAF50);
  static const _absentColor = PdfColor.fromInt(0xFFF44336);
  static const _lateColor = PdfColor.fromInt(0xFFFF9800);
  static const _leaveColor = PdfColor.fromInt(0xFF2196F3);

  /// Generate daily attendance report PDF
  Future<Uint8List> generateDailyReport({
    required String schoolName,
    required String className,
    required String sectionName,
    required DateTime date,
    required List<StudentAttendanceEntry> attendanceData,
    required DailyAttendanceSummary summary,
    String? markedByName,
  }) async {
    // Sort attendance data by admission number numerically
    attendanceData.sort((a, b) {
      // Use the numeric admission number for proper sorting
      return a.admissionNumberNumeric.compareTo(b.admissionNumberNumeric);
    });

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat(AppConstants.displayDateFormat);
    final timeFormat = DateFormat(AppConstants.displayTimeFormat);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          schoolName: schoolName,
          title: 'Daily Attendance Report',
          subtitle: '$className - $sectionName',
          date: dateFormat.format(date),
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Summary section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _headerColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', summary.totalStudents.toString()),
                _buildStatItem(
                  'Present',
                  summary.presentCount.toString(),
                  color: _presentColor,
                ),
                _buildStatItem(
                  'Absent',
                  summary.absentCount.toString(),
                  color: _absentColor,
                ),
                _buildStatItem(
                  'Late',
                  summary.lateCount.toString(),
                  color: _lateColor,
                ),
                _buildStatItem(
                  'Leave',
                  summary.leaveCount.toString(),
                  color: _leaveColor,
                ),
                _buildStatItem(
                  'Percentage',
                  '${summary.attendancePercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Attendance table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _primaryColor),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('Adm. No'),
                  _buildTableHeader('Student Name'),
                  _buildTableHeader('Status'),
                  _buildTableHeader('Remarks'),
                ],
              ),
              // Data rows
              ...attendanceData.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final data = entry.value;
                final status = data.status ?? 'Not Marked';
                final statusColor = _getStatusColor(status);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isOdd ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell(data.student.admissionNumber),
                    _buildTableCell(
                      '${data.student.studentName} ${data.student.fatherName}',
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          AttendanceStatus.getDisplayName(status),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    _buildTableCell(data.remarks ?? ''),
                  ],
                );
              }),
            ],
          ),

          // Footer info
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Marked by: ${markedByName ?? 'System'}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Generated: ${dateFormat.format(DateTime.now())} ${timeFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate monthly attendance report PDF with calendar grid
  Future<Uint8List> generateMonthlyReport({
    required String schoolName,
    required String className,
    required String sectionName,
    required int year,
    required int month,
    required List<StudentAttendanceEntry> students,
    required Map<int, Map<int, String>>
    attendanceGrid, // studentId -> {day -> status}
    required AttendanceStats classStats,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Split days into chunks if more than 15 per page
    final dayChunks = <List<int>>[];
    final allDays = List.generate(daysInMonth, (i) => i + 1);
    for (var i = 0; i < allDays.length; i += 15) {
      dayChunks.add(allDays.sublist(i, (i + 15).clamp(0, allDays.length)));
    }

    for (var chunkIndex = 0; chunkIndex < dayChunks.length; chunkIndex++) {
      final days = dayChunks[chunkIndex];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => _buildReportHeader(
            schoolName: schoolName,
            title: 'Monthly Attendance Report',
            subtitle:
                '$className - $sectionName | $monthName${dayChunks.length > 1 ? ' (Part ${chunkIndex + 1})' : ''}',
          ),
          footer: (context) => _buildReportFooter(context),
          build: (context) => [
            // Summary
            if (chunkIndex == 0) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _headerColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Records',
                      classStats.totalDays.toString(),
                    ),
                    _buildStatItem(
                      'Present',
                      classStats.presentDays.toString(),
                      color: _presentColor,
                    ),
                    _buildStatItem(
                      'Absent',
                      classStats.absentDays.toString(),
                      color: _absentColor,
                    ),
                    _buildStatItem(
                      'Late',
                      classStats.lateDays.toString(),
                      color: _lateColor,
                    ),
                    _buildStatItem(
                      'Leave',
                      classStats.leaveDays.toString(),
                      color: _leaveColor,
                    ),
                    _buildStatItem(
                      'Avg. Attendance',
                      '${classStats.attendancePercentage.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
            ],

            // Legend
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildLegendItem('P', 'Present', _presentColor),
                pw.SizedBox(width: 15),
                _buildLegendItem('A', 'Absent', _absentColor),
                pw.SizedBox(width: 15),
                _buildLegendItem('L', 'Late', _lateColor),
                pw.SizedBox(width: 15),
                _buildLegendItem('LV', 'Leave', _leaveColor),
                pw.SizedBox(width: 15),
                _buildLegendItem('-', 'Not Marked', PdfColors.grey400),
              ],
            ),
            pw.SizedBox(height: 10),

            // Attendance grid table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.4),
                1: const pw.FlexColumnWidth(2),
                for (var i = 0; i < days.length; i++)
                  i + 2: const pw.FlexColumnWidth(0.35),
              },
              children: [
                // Header row with day numbers
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _primaryColor),
                  children: [
                    _buildTableHeader('#', fontSize: 8),
                    _buildTableHeader('Student Name', fontSize: 8),
                    ...days.map(
                      (day) => _buildTableHeader(day.toString(), fontSize: 8),
                    ),
                  ],
                ),
                // Student rows
                ...students.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final student = entry.value.student;
                  final studentAttendance = attendanceGrid[student.id] ?? {};

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isOdd ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _buildTableCell(index.toString(), fontSize: 8),
                      _buildTableCell(
                        '${student.studentName} ${student.fatherName}',
                        fontSize: 8,
                      ),
                      ...days.map((day) {
                        final status = studentAttendance[day];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              status != null
                                  ? AttendanceStatus.getShortCode(status)
                                  : '-',
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: _getStatusColor(status ?? ''),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  /// Generate individual student attendance history report
  Future<Uint8List> generateStudentHistoryReport({
    required String schoolName,
    required Student student,
    required String className,
    required String sectionName,
    required DateTime startDate,
    required DateTime endDate,
    required List<StudentAttendanceData> attendanceHistory,
    required AttendanceStats stats,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat(AppConstants.displayDateFormat);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          schoolName: schoolName,
          title: 'Student Attendance Report',
          subtitle: '${student.studentName} ${student.fatherName}',
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Student info
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Name',
                        '${student.studentName} ${student.fatherName}',
                      ),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Admission No',
                        student.admissionNumber,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Class',
                        '$className - $sectionName',
                      ),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow(
                        'Period',
                        '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Statistics summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _headerColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Attendance Summary',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Days', stats.totalDays.toString()),
                    _buildStatItem(
                      'Present',
                      stats.presentDays.toString(),
                      color: _presentColor,
                    ),
                    _buildStatItem(
                      'Absent',
                      stats.absentDays.toString(),
                      color: _absentColor,
                    ),
                    _buildStatItem(
                      'Late',
                      stats.lateDays.toString(),
                      color: _lateColor,
                    ),
                    _buildStatItem(
                      'Leave',
                      stats.leaveDays.toString(),
                      color: _leaveColor,
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                // Attendance percentage bar
                pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(10),
                    color: PdfColors.grey200,
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 10,
                    verticalRadius: 10,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: (stats.attendancePercentage).round(),
                          child: pw.Container(color: _presentColor),
                        ),
                        pw.Expanded(
                          flex: (100 - stats.attendancePercentage)
                              .round()
                              .clamp(0, 100),
                          child: pw.Container(),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Attendance: ${stats.attendancePercentage.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: stats.attendancePercentage >= 75
                        ? _presentColor
                        : _absentColor,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Attendance history table
          pw.Text(
            'Attendance History',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _primaryColor),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('Date'),
                  _buildTableHeader('Status'),
                  _buildTableHeader('Remarks'),
                ],
              ),
              ...attendanceHistory.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final data = entry.value;
                final statusColor = _getStatusColor(data.status);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isOdd ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell(dateFormat.format(data.date)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          AttendanceStatus.getDisplayName(data.status),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    _buildTableCell(data.remarks ?? ''),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate class summary report comparing all sections
  Future<Uint8List> generateClassSummaryReport({
    required String schoolName,
    required DateTime startDate,
    required DateTime endDate,
    required List<
      ({
        String className,
        String sectionName,
        int totalStudents,
        AttendanceStats stats,
      })
    >
    classSummaries,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat(AppConstants.displayDateFormat);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          schoolName: schoolName,
          title: 'Class Attendance Summary',
          subtitle:
              '${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Summary table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _primaryColor),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('Class'),
                  _buildTableHeader('Students'),
                  _buildTableHeader('Present'),
                  _buildTableHeader('Absent'),
                  _buildTableHeader('Late'),
                  _buildTableHeader('Leave'),
                  _buildTableHeader('Attendance %'),
                ],
              ),
              ...classSummaries.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final data = entry.value;
                final percentage = data.stats.attendancePercentage;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isOdd ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell(index.toString()),
                    _buildTableCell('${data.className} - ${data.sectionName}'),
                    _buildTableCell(data.totalStudents.toString()),
                    _buildTableCell(data.stats.presentDays.toString()),
                    _buildTableCell(data.stats.absentDays.toString()),
                    _buildTableCell(data.stats.lateDays.toString()),
                    _buildTableCell(data.stats.leaveDays.toString()),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: percentage >= 75
                              ? _presentColor
                              : _absentColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),

          // Overall summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _headerColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Overall Summary',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Classes',
                      classSummaries.length.toString(),
                    ),
                    _buildStatItem(
                      'Total Students',
                      classSummaries
                          .fold(0, (sum, c) => sum + c.totalStudents)
                          .toString(),
                    ),
                    _buildStatItem(
                      'Avg. Attendance',
                      '${_calculateOverallPercentage(classSummaries).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // Helper methods

  pw.Widget _buildReportHeader({
    required String schoolName,
    required String title,
    String? subtitle,
    String? date,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
        ],
        if (date != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 11)),
        ],
        pw.SizedBox(height: 15),
        pw.Divider(color: _primaryColor, thickness: 1),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'EduX School Management System',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, {double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: fontSize,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize)),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  pw.Widget _buildLegendItem(String code, String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 20,
          height: 20,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            code,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return _presentColor;
      case 'absent':
        return _absentColor;
      case 'late':
        return _lateColor;
      case 'leave':
        return _leaveColor;
      default:
        return PdfColors.grey400;
    }
  }

  double _calculateOverallPercentage(
    List<
      ({
        String className,
        String sectionName,
        int totalStudents,
        AttendanceStats stats,
      })
    >
    summaries,
  ) {
    if (summaries.isEmpty) return 0;

    int totalPresent = 0;
    int totalRecords = 0;

    for (final s in summaries) {
      totalPresent += s.stats.presentDays + s.stats.lateDays;
      totalRecords += s.stats.totalDays;
    }

    if (totalRecords == 0) return 0;
    return (totalPresent / totalRecords) * 100;
  }
}
