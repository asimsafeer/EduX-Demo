/// EduX School Management System
/// Student Export Service - PDF and Excel export functionality
library;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;

import '../database/app_database.dart';
import '../repositories/student_repository.dart';
import '../repositories/guardian_repository.dart';
import '../core/utils/pdf_helper.dart';

/// Student export service for PDF and Excel generation
class StudentExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Generate PDF list of students
  Future<Uint8List> generateStudentListPdf({
    required List<StudentWithEnrollment> students,
    required SchoolSetting school,
    String? title,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final pageTitle = title ?? 'Student List';

    // Calculate rows per page (approximately 25 for A4)
    const rowsPerPage = 25;
    final totalPages = (students.length / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage < students.length)
          ? startIndex + rowsPerPage
          : students.length;
      final pageStudents = students.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(school, pageTitle),
                pw.SizedBox(height: 20),
                _buildStudentTable(pageStudents, startIndex),
                pw.Spacer(),
                _buildPdfFooter(context, page + 1, totalPages),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Generate PDF for individual student profile
  Future<Uint8List> generateStudentProfilePdf({
    required Student student,
    required List<StudentGuardianLink> guardians,
    required Enrollment? currentEnrollment,
    required SchoolClass? schoolClass,
    required Section? section,
    required SchoolSetting school,
  }) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(school, 'Student Profile'),
              pw.SizedBox(height: 20),
              _buildProfileSection(student, schoolClass, section),
              pw.SizedBox(height: 20),
              _buildPersonalInfoSection(student),
              pw.SizedBox(height: 20),
              _buildContactInfoSection(student),
              if (guardians.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildGuardiansSection(guardians),
              ],
              if (student.medicalInfo != null || student.allergies != null) ...[
                pw.SizedBox(height: 20),
                _buildMedicalSection(student),
              ],
              pw.Spacer(),
              _buildPdfFooter(context, 1, 1),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Export students to Excel
  Future<List<int>> exportStudentListExcel(
    List<StudentWithEnrollment> students,
  ) async {
    debugPrint('Exporting ${students.length} students to Excel');
    
    final excel = xl.Excel.createExcel();

    // Get default sheet instead of creating new one
    final sheet = excel.sheets.values.first;
    
    debugPrint('Excel sheet created: ${sheet.sheetName}');

    // Header style
    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.blue100,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    // Headers
    final headers = [
      'S.No',
      'Admission No',
      'Student Name',
      'Father Name',
      'Class',
      'Section',
      'Gender',
      'Date of Birth',
      'Phone',
      'Email',
      'Address',
      'City',
      'Status',
      'Admission Date',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final student = s.student;
      final rowIndex = i + 1;

      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          )
          .value = xl.IntCellValue(
        i + 1,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.admissionNumber,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.studentName,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.fatherName ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        s.schoolClass?.name ?? 'N/A',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        s.section?.name ?? 'N/A',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _capitalize(student.gender),
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.dateOfBirth != null
            ? _dateFormat.format(student.dateOfBirth!)
            : '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.phone ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.email ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.address ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        student.city ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _capitalize(student.status),
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _dateFormat.format(student.admissionDate),
      );
    }

    // Auto-fit columns (approximate)
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(1, 18); // Admission number
    sheet.setColumnWidth(10, 30); // Address

    debugPrint('Sheet rows: ${sheet.rows.length}');
    debugPrint('Sheet max rows: ${sheet.maxRows}');
    
    final encoded = excel.encode();
    debugPrint('Encoded bytes: ${encoded?.length ?? 0}');
    
    if (encoded == null || encoded.isEmpty) {
      throw Exception('Failed to encode Excel file - output is empty');
    }
    
    return encoded;
  }

  /// Generate Excel template for bulk import
  Future<List<int>> generateImportTemplate() async {
    final excel = xl.Excel.createExcel();

    // Use default sheet instead of creating new one
    final sheet = excel.sheets.values.first;

    // Header style
    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.blue100,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    final requiredStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#FFE0E0'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    // Headers - required fields marked with *
    final headers = [
      ('Admission No*', true),
      ('Student Name*', true),
      ('Father Name*', true),
      ('Class*', true),
      ('Section*', true),
      ('Gender*', true),
      ('Date of Birth', false),
      ('Phone', false),
      ('Email', false),
      ('Address', false),
      ('City', false),
      ('Guardian Name', false),
      ('Guardian Phone', false),
      ('Guardian Relation', false),
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = xl.TextCellValue(headers[i].$1);
      cell.cellStyle = headers[i].$2 ? requiredStyle : headerStyle;
    }

    // Add instructions sheet
    final instructionsSheet = excel['Instructions'];
    final instructions = [
      'STUDENT IMPORT TEMPLATE - INSTRUCTIONS',
      '',
      'Required Fields (marked with *):',
      '  • Admission No: Unique identifier for the student (e.g., ADM-00001)',
      '  • Student Name: Student\'s name (2-50 characters)',
      '  • Father Name: Father\'s name (2-50 characters)',
      '  • Class: Must match an existing class name exactly',
      '  • Section: Must match an existing section name for the class',
      '  • Gender: Must be "Male" or "Female"',
      '',
      'Optional Fields:',
      '  • Date of Birth: Format DD/MM/YYYY',
      '  • Phone: Pakistani format (03XX-XXXXXXX)',
      '  • Email: Valid email format',
      '  • Address: Full address',
      '  • City: City name',
      '  • Guardian Name: Full name of guardian',
      '  • Guardian Phone: Guardian\'s contact number',
      '  • Guardian Relation: Father, Mother, Guardian, or Other',
      '',
      'Notes:',
      '  • Do not modify the header row',
      '  • Each row represents one student',
      '  • Leave cells empty if data is not available',
      '  • Make sure class and section names match exactly with the system',
    ];

    for (int i = 0; i < instructions.length; i++) {
      instructionsSheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i))
          .value = xl.TextCellValue(
        instructions[i],
      );
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
    instructionsSheet.setColumnWidth(0, 60);

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw Exception('Failed to encode Excel template - output is empty');
    }
    return encoded;
  }

  // Private helper methods

  pw.Widget _buildPdfHeader(SchoolSetting school, String title) {
    // Build logo image if available
    pw.Widget? logoWidget;
    if (school.logo != null && school.logo!.isNotEmpty) {
      try {
        final logoImage = pw.MemoryImage(Uint8List.fromList(school.logo!));
        logoWidget = pw.Image(logoImage, width: 50, height: 50, fit: pw.BoxFit.contain);
      } catch (_) {
        // If logo parsing fails, skip it
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoWidget != null) ...[
              logoWidget,
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  school.schoolName,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                if (school.address != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(school.address!, style: const pw.TextStyle(fontSize: 10)),
                ],
                if (school.phone != null || school.email != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [school.phone, school.email].where((e) => e != null).join(' | '),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildStudentTable(
    List<StudentWithEnrollment> students,
    int startIndex,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FixedColumnWidth(50),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('#', isHeader: true),
            _tableCell('Adm. No', isHeader: true),
            _tableCell('Name', isHeader: true),
            _tableCell('Class', isHeader: true),
            _tableCell('Gender', isHeader: true),
            _tableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...students.asMap().entries.map((entry) {
          final index = entry.key + startIndex + 1;
          final s = entry.value;
          final isEven = entry.key % 2 == 0;

          return pw.TableRow(
            decoration: isEven
                ? const pw.BoxDecoration(color: PdfColors.grey50)
                : null,
            children: [
              _tableCell(index.toString()),
              _tableCell(s.student.admissionNumber),
              _tableCell(s.fullName),
              _tableCell(s.classSection),
              _tableCell(_capitalize(s.student.gender)),
              _tableCell(_capitalize(s.student.status)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  pw.Widget _buildPdfFooter(
    pw.Context context,
    int currentPage,
    int totalPages,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated: ${_dateTimeFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Page $currentPage of $totalPages',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildProfileSection(
    Student student,
    SchoolClass? schoolClass,
    Section? section,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [


          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${student.studentName} ${student.fatherName}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                _profileField('Admission No', student.admissionNumber),
                _profileField(
                  'Class',
                  schoolClass != null && section != null
                      ? '${schoolClass.name} - ${section.name}'
                      : 'Not Enrolled',
                ),
                _profileField('Status', _capitalize(student.status)),
                _profileField(
                  'Admission Date',
                  _dateFormat.format(student.admissionDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _profileField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildPersonalInfoSection(Student student) {
    return _buildSection('Personal Information', [
      _profileField('Gender', _capitalize(student.gender)),
      if (student.dateOfBirth != null)
        _profileField(
          'Date of Birth',
          _dateFormat.format(student.dateOfBirth!),
        ),
      if (student.bloodGroup != null)
        _profileField('Blood Group', student.bloodGroup!),
      if (student.religion != null)
        _profileField('Religion', student.religion!),
      _profileField('Nationality', student.nationality),
      if (student.cnic != null) _profileField('CNIC/B-Form', student.cnic!),
    ]);
  }

  pw.Widget _buildContactInfoSection(Student student) {
    return _buildSection('Contact Information', [
      if (student.phone != null) _profileField('Phone', student.phone!),
      if (student.email != null) _profileField('Email', student.email!),
      if (student.address != null) _profileField('Address', student.address!),
      if (student.city != null) _profileField('City', student.city!),
    ]);
  }

  pw.Widget _buildGuardiansSection(List<StudentGuardianLink> guardians) {
    return _buildSection(
      'Guardian Information',
      guardians.map((g) {
        final suffix = g.isPrimary ? ' (Primary)' : '';
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${g.fullName}$suffix',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            _profileField('Relation', _capitalize(g.guardian.relation)),
            _profileField('Phone', g.guardian.phone),
            if (g.guardian.email != null)
              _profileField('Email', g.guardian.email!),
            pw.SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildMedicalSection(Student student) {
    return _buildSection('Medical Information', [
      if (student.medicalInfo != null)
        _profileField('Medical Notes', student.medicalInfo!),
      if (student.allergies != null)
        _profileField('Allergies', student.allergies!),
      if (student.specialNeeds != null)
        _profileField('Special Needs', student.specialNeeds!),
    ]);
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    if (children.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
