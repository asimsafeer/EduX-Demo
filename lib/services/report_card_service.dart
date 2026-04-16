/// EduX School Management System
/// Report Card Service - PDF generation for student report cards
library;

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/widgets.dart';
import '../core/utils/pdf_helper.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../repositories/marks_repository.dart';
import '../repositories/exam_repository.dart';

/// Report card data for PDF generation
class ReportCardData {
  final SchoolSetting schoolSettings;
  final Exam exam;
  final StudentExamResult result;
  final String className;
  final String? sectionName;

  const ReportCardData({
    required this.schoolSettings,
    required this.exam,
    required this.result,
    required this.className,
    this.sectionName,
  });
}

/// Report card generation service
class ReportCardService {
  final AppDatabase _db;
  final ExamRepository _examRepo;
  final MarksRepository _marksRepo;

  ReportCardService(this._db, this._examRepo, this._marksRepo);

  /// Generate report card PDF for a single student
  Future<Uint8List> generateReportCard(ReportCardData data) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            margin: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: _buildReportCard(data),
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Generate report cards for multiple students
  Future<Uint8List> generateBulkReportCards(
    List<ReportCardData> dataList,
  ) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    for (final data in dataList) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => _buildReportCard(data),
        ),
      );
    }

    return pdf.save();
  }

  /// Print report card directly
  Future<void> printReportCard(
    BuildContext context,
    ReportCardData data,
  ) async {
    final pdfBytes = await generateReportCard(data);
    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'Report Card - ${data.result.student.studentName} ${data.result.student.fatherName}',
      );
    }
  }

  /// Print multiple report cards
  Future<void> printBulkReportCards(
    BuildContext context,
    List<ReportCardData> dataList,
  ) async {
    if (dataList.isEmpty) return;
    final pdfBytes = await generateBulkReportCards(dataList);
    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'Report Cards - ${dataList.first.exam.name}',
      );
    }
  }

  /// Get report card data for a student
  Future<ReportCardData?> getReportCardData({
    required int examId,
    required int studentId,
  }) async {
    // Get exam details
    final examDetails = await _examRepo.getExamWithDetails(examId);
    if (examDetails == null) return null;

    // Get student result
    final result = await _marksRepo.getStudentExamResult(
      examId: examId,
      studentId: studentId,
    );
    if (result == null) return null;

    // Get school settings
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) return null;

    // Get class name
    final className = examDetails.classInfo.name;

    // Get section name if enrollment has section
    String? sectionName;
    // Get section name if enrollment has section
    final section =
        await (_db.select(_db.sections)
              ..where((t) => t.id.equals(result.enrollment.sectionId)))
            .getSingleOrNull();
    sectionName = section?.name;

    return ReportCardData(
      schoolSettings: schoolSettings,
      exam: examDetails.exam,
      result: result,
      className: className,
      sectionName: sectionName,
    );
  }

  /// Get report card data for all students in an exam
  Future<List<ReportCardData>> getBulkReportCardData(int examId) async {
    // Get exam details
    final examDetails = await _examRepo.getExamWithDetails(examId);
    if (examDetails == null) return [];

    // Get school settings
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) return [];

    // Get all results
    final results = await _marksRepo.getClassRankings(examId);

    final dataList = <ReportCardData>[];
    for (final result in results) {
      String? sectionName;
      // Get section name if enrollment has section
      final section =
          await (_db.select(_db.sections)
                ..where((t) => t.id.equals(result.enrollment.sectionId)))
              .getSingleOrNull();
      sectionName = section?.name;

      dataList.add(
        ReportCardData(
          schoolSettings: schoolSettings,
          exam: examDetails.exam,
          result: result,
          className: examDetails.classInfo.name,
          sectionName: sectionName,
        ),
      );
    }

    return dataList;
  }

  // ============================================
  // PDF BUILDING
  // ============================================

  pw.Widget _buildReportCard(ReportCardData data) {
    final studentName =
        '${data.result.student.studentName} ${data.result.student.fatherName ?? ''}'
            .trim();
    final fatherName = data.result.student.fatherName ?? '';
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header with school info
        _buildHeader(data.schoolSettings, data.exam),
        pw.SizedBox(height: 12),

        // Student info section
        _buildStudentInfo(
          studentName: studentName,
          fatherName: fatherName,
          rollNumber: data.result.enrollment.rollNumber ?? '',
          admissionNumber: data.result.student.admissionNumber,
          className: data.className,
          sectionName: data.sectionName,
          dateOfBirth: data.result.student.dateOfBirth,
          dateFormat: dateFormat,
        ),
        pw.SizedBox(height: 12),

        // Subject performance table
        pw.Text(
          'SUBJECT PERFORMANCE',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        _buildSubjectTable(data.result.subjectResults),
        pw.SizedBox(height: 6),

        // Summary row
        _buildSummaryRow(data.result),
        pw.SizedBox(height: 12),

        // Result summary
        _buildResultSummary(data.result),
        pw.SizedBox(height: 16),

        // Remarks section
        _buildRemarksSection(data.result),
        pw.Spacer(),

        // Signatures
        _buildSignatures(),
      ],
    );
  }

  pw.Widget _buildHeader(SchoolSetting school, Exam exam) {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.Text(
            school.schoolName.toUpperCase(),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (school.address != null)
            pw.Text(
              '${school.address}${school.city != null ? ", ${school.city}" : ""}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (school.phone != null)
            pw.Text(
              'Phone: ${school.phone}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey800, width: 1),
                bottom: pw.BorderSide(color: PdfColors.grey800, width: 1),
              ),
            ),
            child: pw.Text(
              'REPORT CARD',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            exam.name,
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStudentInfo({
    required String studentName,
    required String fatherName,
    required String rollNumber,
    required String admissionNumber,
    required String className,
    String? sectionName,
    DateTime? dateOfBirth,
    required DateFormat dateFormat,
  }) {
    final fullClassName = sectionName != null
        ? '$className - $sectionName'
        : className;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', studentName),
                pw.SizedBox(height: 2),
                _buildInfoRow("Father's Name", fatherName),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Class', fullClassName),
                pw.SizedBox(height: 2),
                _buildInfoRow('Roll No.', rollNumber),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Adm No.', admissionNumber),
                pw.SizedBox(height: 2),
                if (dateOfBirth != null)
                  _buildInfoRow('DOB', dateFormat.format(dateOfBirth)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
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

  pw.Widget _buildSubjectTable(List<SubjectResult> subjects) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Subject', isHeader: true),
            _buildTableCell('Max Marks', isHeader: true),
            _buildTableCell('Obtained', isHeader: true),
            _buildTableCell('Grade', isHeader: true),
            _buildTableCell('Remarks', isHeader: true),
          ],
        ),
        // Subject rows
        ...subjects.map(
          (s) => pw.TableRow(
            children: [
              _buildTableCell(s.subject.name),
              _buildTableCell(
                s.maxMarks.toStringAsFixed(0),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                s.isAbsent
                    ? 'Absent'
                    : (s.marksObtained?.toStringAsFixed(1) ?? '-'),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(s.grade ?? '-', align: pw.TextAlign.center),
              _buildTableCell(
                s.remarks ?? (s.isPassed ? '' : 'Needs Improvement'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
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

  pw.Widget _buildSummaryRow(StudentExamResult result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total',
            '${result.totalMarksObtained.toStringAsFixed(1)} / ${result.totalMaxMarks.toStringAsFixed(0)}',
          ),
          _buildSummaryItem(
            'Percentage',
            '${result.percentage.toStringAsFixed(2)}%',
          ),
          _buildSummaryItem('Grade', result.overallGrade),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildResultSummary(StudentExamResult result) {
    final passColor = result.isPassed ? PdfColors.green700 : PdfColors.red700;
    final passText = result.isPassed ? 'PASSED' : 'FAILED';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: result.isPassed ? PdfColors.green50 : PdfColors.red50,
        border: pw.Border.all(color: passColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'RESULT: $passText',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: passColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Class Rank: ${result.classRank}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRemarksSection(StudentExamResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Teacher\'s Remarks:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                result.teacherRemarks ?? _getDefaultRemarks(result),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        if (result.principalRemarks != null) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Principal\'s Remarks:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  result.principalRemarks!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getDefaultRemarks(StudentExamResult result) {
    if (result.percentage >= 90) {
      return 'Outstanding performance! Keep up the excellent work.';
    } else if (result.percentage >= 80) {
      return 'Excellent performance. Well done!';
    } else if (result.percentage >= 70) {
      return 'Very good performance. Keep working hard.';
    } else if (result.percentage >= 60) {
      return 'Good performance. There is room for improvement.';
    } else if (result.percentage >= 50) {
      return 'Satisfactory. Needs to work harder.';
    } else if (result.isPassed) {
      return 'Needs significant improvement in studies.';
    } else {
      return 'Failed. Requires immediate attention and remedial classes.';
    }
  }

  pw.Widget _buildSignatures() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSignatureLine("Class Teacher's Signature"),
          _buildSignatureLine("Principal's Signature"),
          _buildSignatureLine("Parent's Signature"),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          height: 40,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}
