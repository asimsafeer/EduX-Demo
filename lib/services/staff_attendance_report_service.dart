/// EduX School Management System
/// Staff Attendance Report Service - Production-grade PDF/Excel generation
library;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/database.dart';
import '../repositories/staff_repository.dart';
import '../repositories/staff_attendance_repository.dart';
import '../core/utils/excel_helper.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../core/utils/pdf_helper.dart';

/// Staff attendance report data model
class StaffAttendanceReportData {
  final StaffWithRole staff;
  final List<StaffAttendanceData> attendanceRecords;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int halfDays;
  final int leaveDays;
  final double attendancePercentage;

  const StaffAttendanceReportData({
    required this.staff,
    required this.attendanceRecords,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.halfDays,
    required this.leaveDays,
    required this.attendancePercentage,
  });
}

/// Staff attendance summary for period
class StaffAttendancePeriodSummary {
  final DateTime startDate;
  final DateTime endDate;
  final List<StaffAttendanceReportData> staffData;
  final int totalStaff;
  final int totalWorkingDays;

  const StaffAttendancePeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.staffData,
    required this.totalStaff,
    required this.totalWorkingDays,
  });
}

/// Staff Attendance Report Service - Production grade
class StaffAttendanceReportService {
  final StaffRepository _staffRepo;
  final StaffAttendanceRepository _attendanceRepo;

  StaffAttendanceReportService(AppDatabase db)
    : _staffRepo = StaffRepositoryImpl(db),
      _attendanceRepo = StaffAttendanceRepositoryImpl(db);

  // ===========================================================================
  // DATA COLLECTION
  // ===========================================================================

  /// Get comprehensive attendance report data for date range
  Future<StaffAttendancePeriodSummary> getAttendanceReportData({
    required DateTime startDate,
    required DateTime endDate,
    List<int>? staffIds, // Optional: filter specific staff
    String? status, // Optional: filter by staff status
  }) async {
    try {
      // Get all active staff or filtered list
      final List<StaffWithRole> staffList;
      if (staffIds != null && staffIds.isNotEmpty) {
        staffList = [];
        for (final id in staffIds) {
          final staff = await _staffRepo.getById(id);
          if (staff != null) staffList.add(staff);
        }
      } else {
        staffList = await _staffRepo.search(
          StaffFilters(status: status ?? 'active', limit: 0), // No limit - fetch all staff
        );
      }

      // Calculate working days (excluding weekends if configured)
      final workingDays = _calculateWorkingDays(startDate, endDate);

      // Build report data for each staff
      final List<StaffAttendanceReportData> reportData = [];
      for (final staff in staffList) {
        final data = await _getStaffAttendanceData(
          staff: staff,
          startDate: startDate,
          endDate: endDate,
        );
        reportData.add(data);
      }

      // Sort by employee ID
      reportData.sort(
        (a, b) => a.staff.staff.employeeId.compareTo(b.staff.staff.employeeId),
      );

      return StaffAttendancePeriodSummary(
        startDate: startDate,
        endDate: endDate,
        staffData: reportData,
        totalStaff: staffList.length,
        totalWorkingDays: workingDays,
      );
    } catch (e) {
      throw StaffAttendanceReportException(
        'Failed to generate report data: $e',
      );
    }
  }

  /// Get attendance data for single staff member
  Future<StaffAttendanceReportData> _getStaffAttendanceData({
    required StaffWithRole staff,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get attendance records for period
      final records = await _attendanceRepo.getStaffAttendanceHistory(
        staff.staff.id,
        startDate: startDate,
        endDate: endDate,
      );

      // Count by status
      int present = 0, absent = 0, late = 0, halfDay = 0, leave = 0;
      for (final record in records) {
        switch (record.status) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
          case 'half_day':
            halfDay++;
            break;
          case 'leave':
            leave++;
            break;
        }
      }

      final totalDays = records.length;
      final attendancePercentage = totalDays > 0
          ? ((present + late) / totalDays * 100)
          : 0.0;

      return StaffAttendanceReportData(
        staff: staff,
        attendanceRecords: records,
        totalDays: totalDays,
        presentDays: present,
        absentDays: absent,
        lateDays: late,
        halfDays: halfDay,
        leaveDays: leave,
        attendancePercentage: attendancePercentage,
      );
    } catch (e) {
      // Return empty data on error to prevent crash
      return StaffAttendanceReportData(
        staff: staff,
        attendanceRecords: [],
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        halfDays: 0,
        leaveDays: 0,
        attendancePercentage: 0.0,
      );
    }
  }

  /// Calculate working days between dates
  int _calculateWorkingDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      // Skip Sunday (weekend)
      if (current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  // ===========================================================================
  // PDF GENERATION
  // ===========================================================================

  /// Generate comprehensive PDF attendance report
  Future<Uint8List> generatePdfReport(
    StaffAttendancePeriodSummary summary,
  ) async {
    return await compute(_generatePdfReportIsolate, summary);
  }

  static Future<Uint8List> _generatePdfReportIsolate(
    StaffAttendancePeriodSummary summary,
  ) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat('#,##0.00');

    // Add summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => _buildSummaryPage(summary, dateFormat),
      ),
    );

    // Add detailed staff list page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildStaffListPage(summary, dateFormat),
      ),
    );

    // Add individual staff detail pages
    for (final staffData in summary.staffData) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => _buildStaffDetailPage(staffData, dateFormat, summary.startDate, summary.endDate),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildSummaryPage(
    StaffAttendancePeriodSummary summary,
    DateFormat dateFormat,
  ) {
    // Calculate totals
    int totalPresent = 0, totalAbsent = 0, totalLate = 0, totalLeave = 0, totalHalfDay = 0;
    for (final data in summary.staffData) {
      totalPresent += data.presentDays;
      totalAbsent += data.absentDays;
      totalLate += data.lateDays;
      totalLeave += data.leaveDays;
      totalHalfDay += data.halfDays;
    }

    final avgAttendance = summary.staffData.isNotEmpty
        ? summary.staffData
                  .map((d) => d.attendancePercentage)
                  .reduce((a, b) => a + b) /
              summary.staffData.length
        : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'STAFF ATTENDANCE REPORT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Summary Cards
        pw.Row(
          children: [
            _buildSummaryCard(
              'Total Staff',
              '${summary.totalStaff}',
              PdfColors.blue,
            ),
            pw.SizedBox(width: 12),
            _buildSummaryCard(
              'Working Days',
              '${summary.totalWorkingDays}',
              PdfColors.purple,
            ),
            pw.SizedBox(width: 12),
            _buildSummaryCard(
              'Avg Attendance',
              '${avgAttendance.toStringAsFixed(1)}%',
              PdfColors.green,
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // Attendance Summary
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Overall Attendance Summary',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                children: [
                  _buildSummaryRow(
                    'Total Present Days',
                    '$totalPresent',
                    PdfColors.green,
                  ),
                  _buildSummaryRow(
                    'Total Absent Days',
                    '$totalAbsent',
                    PdfColors.red,
                  ),
                  _buildSummaryRow(
                    'Total Late Days',
                    '$totalLate',
                    PdfColors.orange,
                  ),
                  _buildSummaryRow(
                    'Total Half Days',
                    '$totalHalfDay',
                    PdfColors.amber,
                  ),
                  _buildSummaryRow(
                    'Total Leave Days',
                    '$totalLeave',
                    PdfColors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Legend
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Status Legend',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _buildLegendItem('P', 'Present', PdfColors.green),
                  _buildLegendItem('A', 'Absent', PdfColors.red),
                  _buildLegendItem('L', 'Late', PdfColors.orange),
                  _buildLegendItem('HD', 'Half Day', PdfColors.amber),
                  _buildLegendItem('LV', 'Leave', PdfColors.blue),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Page guide
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.blue300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Report Contents:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Page 1: Summary (this page)', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Page 2: Staff Attendance List', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Page 3+: Individual Staff Details', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStaffListPage(
    StaffAttendancePeriodSummary summary,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'STAFF ATTENDANCE SUMMARY',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Data Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(25), // #
            1: const pw.FixedColumnWidth(55), // Emp ID
            2: const pw.FlexColumnWidth(2.5), // Name
            3: const pw.FlexColumnWidth(1.5), // Designation
            4: const pw.FixedColumnWidth(35), // Total
            5: const pw.FixedColumnWidth(30), // P
            6: const pw.FixedColumnWidth(30), // A
            7: const pw.FixedColumnWidth(30), // L
            8: const pw.FixedColumnWidth(30), // HD
            9: const pw.FixedColumnWidth(30), // LV
            10: const pw.FixedColumnWidth(50), // Attendance %
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildHeaderCell('#'),
                _buildHeaderCell('Emp ID'),
                _buildHeaderCell('Name'),
                _buildHeaderCell('Designation'),
                _buildHeaderCell('Total', align: pw.TextAlign.center),
                _buildHeaderCell('P', align: pw.TextAlign.center),
                _buildHeaderCell('A', align: pw.TextAlign.center),
                _buildHeaderCell('L', align: pw.TextAlign.center),
                _buildHeaderCell('HD', align: pw.TextAlign.center),
                _buildHeaderCell('LV', align: pw.TextAlign.center),
                _buildHeaderCell('Attendance %', align: pw.TextAlign.center),
              ],
            ),
            // Data Rows
            ...summary.staffData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index.isEven ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  _buildCell('${index + 1}', align: pw.TextAlign.center),
                  _buildCell(data.staff.staff.employeeId),
                  _buildCell(data.staff.fullName),
                  _buildCell(data.staff.staff.designation),
                  _buildCell('${data.totalDays}', align: pw.TextAlign.center),
                  _buildCell('${data.presentDays}', align: pw.TextAlign.center),
                  _buildCell(
                    '${data.absentDays}',
                    align: pw.TextAlign.center,
                    color: data.absentDays > 0 ? PdfColors.red : null,
                  ),
                  _buildCell('${data.lateDays}', align: pw.TextAlign.center),
                  _buildCell('${data.halfDays}', align: pw.TextAlign.center),
                  _buildCell('${data.leaveDays}', align: pw.TextAlign.center),
                  _buildCell(
                    '${data.attendancePercentage.toStringAsFixed(1)}%',
                    align: pw.TextAlign.center,
                    bold: true,
                    color: data.attendancePercentage >= 75 ? PdfColors.green : PdfColors.red,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStaffDetailPage(
    StaffAttendanceReportData staffData,
    DateFormat dateFormat,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'INDIVIDUAL STAFF ATTENDANCE REPORT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Staff Info Card
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildInfoRow('Employee ID', staffData.staff.staff.employeeId),
                  ),
                  pw.Expanded(
                    child: _buildInfoRow('Name', staffData.staff.fullName),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildInfoRow('Designation', staffData.staff.staff.designation),
                  ),
                  pw.Expanded(
                    child: _buildInfoRow('Department', staffData.staff.role?.name ?? 'N/A'),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Attendance Summary
        pw.Text(
          'Attendance Summary',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStaffStatItem('Total Days', '${staffData.totalDays}', PdfColors.blue),
              _buildStaffStatItem('Present', '${staffData.presentDays}', PdfColors.green),
              _buildStaffStatItem('Absent', '${staffData.absentDays}', PdfColors.red),
              _buildStaffStatItem('Late', '${staffData.lateDays}', PdfColors.orange),
              _buildStaffStatItem('Half Day', '${staffData.halfDays}', PdfColors.amber),
              _buildStaffStatItem('Leave', '${staffData.leaveDays}', PdfColors.purple),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Attendance Percentage
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Attendance Percentage: ${staffData.attendancePercentage.toStringAsFixed(2)}%',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: staffData.attendancePercentage >= 75 ? PdfColors.green700 : PdfColors.red700,
                ),
              ),
              pw.SizedBox(height: 8),
              // Progress bar
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
                        flex: staffData.attendancePercentage.round().clamp(0, 100),
                        child: pw.Container(
                          color: staffData.attendancePercentage >= 75 ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                      pw.Expanded(
                        flex: (100 - staffData.attendancePercentage).round().clamp(0, 100),
                        child: pw.Container(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Attendance History
        if (staffData.attendanceRecords.isNotEmpty) ...[
          pw.Text(
            'Daily Attendance Record',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // #
              1: const pw.FlexColumnWidth(2),   // Date
              2: const pw.FlexColumnWidth(1),   // Status
              3: const pw.FlexColumnWidth(3),   // Remarks
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildHeaderCell('#'),
                  _buildHeaderCell('Date'),
                  _buildHeaderCell('Status'),
                  _buildHeaderCell('Remarks'),
                ],
              ),
              // Data rows (max 15 records per page)
              ...staffData.attendanceRecords.take(15).toList().asMap().entries.map((entry) {
                final index = entry.key + 1;
                final record = entry.value;
                final statusColor = _getStatusColor(record.status);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isEven ? PdfColors.white : PdfColors.grey50,
                  ),
                  children: [
                    _buildCell('$index', align: pw.TextAlign.center),
                    _buildCell(dateFormat.format(record.date)),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          record.status.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                    _buildCell(record.remarks ?? '-'),
                  ],
                );
              }),
            ],
          ),
          if (staffData.attendanceRecords.length > 15)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                '... and ${staffData.attendanceRecords.length - 15} more records',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
        ] else ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                'No attendance records found for this period',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildStaffStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return PdfColors.green;
      case 'absent':
        return PdfColors.red;
      case 'late':
        return PdfColors.orange;
      case 'half_day':
        return PdfColors.amber;
      case 'leave':
        return PdfColors.blue;
      default:
        return PdfColors.grey;
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildSummaryRow(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegendItem(String code, String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Center(
            child: pw.Text(
              code,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  // ===========================================================================
  // EXCEL GENERATION
  // ===========================================================================

  /// Generate Excel report
  Future<Uint8List> generateExcelReport(
    StaffAttendancePeriodSummary summary,
  ) async {
    return await compute(_generateExcelReportIsolate, summary);
  }

  static Future<Uint8List> _generateExcelReportIsolate(
    StaffAttendancePeriodSummary summary,
  ) {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel.sheets.values.first;

    final dateFormat = DateFormat('dd MMM yyyy');

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, 'STAFF ATTENDANCE REPORT');
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Date Range
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 1),
    );
    ExcelHelper.setCell(
      sheet,
      0,
      1,
      'Period: ${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}',
    );
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .cellStyle = excel_lib.CellStyle(
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Headers
    final headers = [
      '#',
      'Employee ID',
      'Name',
      'Designation',
      'Total Days',
      'Present',
      'Absent',
      'Late',
      'Half Day',
      'Leave',
      'Attendance %',
    ];
    ExcelHelper.addHeader(sheet, headers, rowIndex: 3);

    // Data rows
    for (int i = 0; i < summary.staffData.length; i++) {
      final data = summary.staffData[i];
      final row = i + 4;

      ExcelHelper.setCell(sheet, 0, row, i + 1);
      ExcelHelper.setCell(sheet, 1, row, data.staff.staff.employeeId);
      ExcelHelper.setCell(sheet, 2, row, data.staff.fullName);
      ExcelHelper.setCell(sheet, 3, row, data.staff.staff.designation);
      ExcelHelper.setCell(sheet, 4, row, data.totalDays);
      ExcelHelper.setCell(sheet, 5, row, data.presentDays);
      ExcelHelper.setCell(sheet, 6, row, data.absentDays);
      ExcelHelper.setCell(sheet, 7, row, data.lateDays);
      ExcelHelper.setCell(sheet, 8, row, data.halfDays);
      ExcelHelper.setCell(sheet, 9, row, data.leaveDays);
      ExcelHelper.setCell(
        sheet,
        10,
        row,
        '${data.attendancePercentage.toStringAsFixed(2)}%',
      );

      // Highlight low attendance
      if (data.attendancePercentage < 75) {
        for (int col = 0; col <= 10; col++) {
          sheet
              .cell(
                excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: row,
                ),
              )
              .cellStyle = excel_lib.CellStyle(
            backgroundColorHex: excel_lib.ExcelColor.fromInt(0xFFFFCCCC),
          );
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(2, 25); // Name column wider
    sheet.setColumnWidth(3, 20); // Designation column wider

    return Future.value(Uint8List.fromList(excel.encode()!));
  }
}

/// Exception for staff attendance report errors
class StaffAttendanceReportException implements Exception {
  final String message;
  StaffAttendanceReportException(this.message);
  @override
  String toString() => 'StaffAttendanceReportException: $message';
}
