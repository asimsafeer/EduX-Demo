/// EduX School Management System
/// Report Service - PDF report generation
library;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'package:drift/drift.dart';
import '../repositories/student_repository.dart';
import '../repositories/staff_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../services/student_export_service.dart';
import '../repositories/class_repository.dart';
import '../repositories/section_repository.dart';
import '../repositories/guardian_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/concession_repository.dart';
import '../core/utils/pdf_helper.dart';
import '../services/report_card_service.dart';
import '../repositories/marks_repository.dart';
import '../repositories/timetable_repository.dart';
import '../services/timetable_pdf_service.dart';
import '../core/utils/excel_helper.dart';
import '../services/staff_attendance_report_service.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../repositories/staff_assignment_repository.dart';
import '../services/working_days_service.dart';

/// Report Service for generating PDF reports
class ReportService {
  final AppDatabase _db;
  final StudentRepository _studentRepo;
  final StaffRepository _staffRepo;
  final AttendanceRepository _attendanceRepo;
  final InvoiceRepository _invoiceRepo;
  final PaymentRepository _paymentRepo;
  final StudentExportService _studentExportService;
  final ClassRepository _classRepo;
  final SectionRepository _sectionRepo;
  final GuardianRepository _guardianRepo;
  final ExamRepository _examRepo;
  final MarksRepository _marksRepo;
  final ConcessionRepository _concessionRepo;
  final TimetableRepository _timetableRepo;

  late final ReportCardService _reportCardService;

  ReportService(this._db)
    : _studentRepo = StudentRepositoryImpl(_db),
      _staffRepo = StaffRepositoryImpl(_db),
      _attendanceRepo = AttendanceRepositoryImpl(_db),
      _invoiceRepo = DriftInvoiceRepository(_db),
      _paymentRepo = DriftPaymentRepository(_db),
      _studentExportService = StudentExportService(),
      _classRepo = ClassRepositoryImpl(_db),
      _sectionRepo = SectionRepositoryImpl(_db),
      _guardianRepo = GuardianRepositoryImpl(_db),
      _examRepo = DriftExamRepository(_db),
      _marksRepo = DriftMarksRepository(_db),
      _concessionRepo = DriftConcessionRepository(_db),
      _timetableRepo = TimetableRepositoryImpl(_db) {
    _reportCardService = ReportCardService(_db, _examRepo, _marksRepo);
  }

  // ============================================
  // STUDENT REPORTS
  // ============================================

  /// Generate complete student list report
  Future<void> generateStudentList(
    BuildContext context, {
    String sortBy = 'studentName', // Options: 'studentName', 'admissionNumber', 'admissionDate', 'rollNumber'
    bool ascending = true,
  }) async {
    // Fetch ALL active students with enrollment info
    final searchResults = await _studentRepo.search(
      StudentFilters(
        status: 'active',
        sortBy: sortBy,
        ascending: ascending,
        limit: 0, // No limit - fetch all records
      ),
    );
    final schoolSettings = await _db.getSchoolSettings();

    if (schoolSettings == null) throw Exception('School settings not found');

    // Fetch class and section names
    final classes = await _classRepo.getAll();
    final sections = await _sectionRepo.getAll();
    final classMap = {for (var c in classes) c.id: c.name};
    final sectionMap = {for (var s in sections) s.id: s.name};

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(schoolSettings, 'Student List'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Admission Number', 'Name', 'Phone', 'Class/Section', 'Status'],
            data: searchResults.asMap().entries.map((e) {
              final result = e.value;
              final s = result.student;
              final className = result.currentEnrollment != null 
                  ? (classMap[result.currentEnrollment!.classId] ?? '-')
                  : '-';
              final sectionName = result.currentEnrollment != null && result.currentEnrollment!.sectionId != null
                  ? (sectionMap[result.currentEnrollment!.sectionId] ?? '-')
                  : '';
              final classSection = sectionName.isNotEmpty ? '$className/$sectionName' : className;
              
              return [
                '${e.key + 1}',
                s.admissionNumber,
                '${s.studentName} ${s.fatherName}',
                s.phone ?? '-',
                classSection,
                s.status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
            cellAlignments: {0: pw.Alignment.centerRight},
            columnWidths: {
              0: const pw.FixedColumnWidth(30), // #
              1: const pw.FixedColumnWidth(90), // Admission Number
              2: const pw.FlexColumnWidth(3), // Name
              3: const pw.FixedColumnWidth(80), // Phone
              4: const pw.FixedColumnWidth(80), // Class/Section
              5: const pw.FixedColumnWidth(60), // Status
            },
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'student_list',
      onExportExcel: () =>
          _generateStudentListExcel(context, searchResults, schoolSettings, classMap, sectionMap),
    );
  }

  Future<void> _generateStudentListExcel(
    BuildContext context,
    List<StudentWithEnrollment> searchResults,
    SchoolSetting? schoolSettings,
    Map<int, String> classMap,
    Map<int, String> sectionMap,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, 'STUDENT LIST');
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Headers
    ExcelHelper.addHeader(sheet, [
      '#',
      'Admission Number',
      'Name',
      'Phone',
      'Class/Section',
      'Status',
    ], rowIndex: 2);

    int row = 3;
    for (int i = 0; i < searchResults.length; i++) {
      final result = searchResults[i];
      final s = result.student;
      final className = result.currentEnrollment != null 
          ? (classMap[result.currentEnrollment!.classId] ?? '-')
          : '-';
      final sectionName = result.currentEnrollment != null && result.currentEnrollment!.sectionId != null
          ? (sectionMap[result.currentEnrollment!.sectionId] ?? '-')
          : '';
      final classSection = sectionName.isNotEmpty ? '$className/$sectionName' : className;
      
      ExcelHelper.setCell(sheet, 0, row, '${i + 1}');
      ExcelHelper.setCell(sheet, 1, row, s.admissionNumber);
      ExcelHelper.setCell(sheet, 2, row, '${s.studentName} ${s.fatherName}');
      ExcelHelper.setCell(sheet, 3, row, s.phone ?? '-');
      ExcelHelper.setCell(sheet, 4, row, classSection);
      ExcelHelper.setCell(sheet, 5, row, s.status);
      row++;
    }

    // Auto-fit
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 30);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 30);
    sheet.setColumnWidth(5, 10);

    if (context.mounted) {
      await ExcelHelper.saveExcel(context, excel, 'student_list');
    }
  }

  /// Generate class-wise student list
  Future<void> generateClassList(
    BuildContext context,
    int classId, {
    String sortBy = 'studentName', // Options: 'studentName', 'admissionNumber', 'rollNumber'
    bool ascending = true,
  }) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final cls = await _classRepo.getById(classId);
    if (cls == null) throw Exception('Class not found');

    // Fetch ALL students in the class without limit
    final students = await _studentRepo.search(
      StudentFilters(
        classId: classId,
        status: 'active',
        sortBy: sortBy,
        ascending: ascending,
        limit: 0, // No limit - fetch all records
      ),
    );

    final pdfBytes = await _studentExportService.generateStudentListPdf(
      students: students,
      school: schoolSettings,
      title: 'Student List - Class ${cls.name}',
    );

    // Fetch class and section names for Excel export
    final classes = await _classRepo.getAll();
    final sections = await _sectionRepo.getAll();
    final classMap = {for (var c in classes) c.id: c.name};
    final sectionMap = {for (var s in sections) s.id: s.name};

    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'student_list_${cls.name}',
        onExportExcel: () => _generateStudentListExcel(
          context,
          students,
          schoolSettings,
          classMap,
          sectionMap,
        ),
      );
    }
  }

  /// Generate class-section student list
  Future<void> generateClassSectionList(
    BuildContext context,
    int classId,
    int sectionId, {
    String sortBy = 'studentName', // Options: 'studentName', 'admissionNumber', 'rollNumber'
    bool ascending = true,
  }) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final cls = await _classRepo.getById(classId);
    final section = await _sectionRepo.getById(sectionId);

    if (cls == null) throw Exception('Class not found');
    if (section == null) throw Exception('Section not found');

    // Fetch ALL students in the class-section without limit
    final students = await _studentRepo.search(
      StudentFilters(
        classId: classId,
        sectionId: sectionId,
        status: 'active',
        sortBy: sortBy,
        ascending: ascending,
        limit: 0, // No limit - fetch all records
      ),
    );

    final pdfBytes = await _studentExportService.generateStudentListPdf(
      students: students,
      school: schoolSettings,
      title: 'Student List - Class ${cls.name} (${section.name})',
    );

    // Fetch class and section names for Excel export
    final allClasses = await _classRepo.getAll();
    final allSections = await _sectionRepo.getAll();
    final classMap = {for (var c in allClasses) c.id: c.name};
    final sectionMap = {for (var s in allSections) s.id: s.name};

    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'student_list_${cls.name}_${section.name}',
        onExportExcel: () => _generateStudentListExcel(
          context,
          students,
          schoolSettings,
          classMap,
          sectionMap,
        ),
      );
    }
  }

  /// Generate student profile
  Future<void> generateStudentProfile(
    BuildContext context,
    int studentId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final studentData = await _studentRepo.getWithCurrentEnrollment(studentId);

    if (studentData == null) throw Exception('Student not found');

    // Fetch guardians
    final guardians = await _guardianRepo.getByStudentId(studentId);

    final pdfBytes = await _studentExportService.generateStudentProfilePdf(
      student: studentData.student,
      guardians: guardians,
      currentEnrollment: studentData.currentEnrollment,
      schoolClass: studentData.schoolClass,
      section: studentData.section,
      school: schoolSettings,
    );

    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'student_profile_${studentData.student.admissionNumber}',
      );
    }
  }

  /// Generate contact directory for students
  Future<void> generateContactDirectory(BuildContext context) async {
    // Fetch ALL active students without limit
    final searchResults = await _studentRepo.search(
      const StudentFilters(
        status: 'active',
        sortBy: 'studentName',
        ascending: true,
        limit: 0, // No limit - fetch all records
      ),
    );
    final students = searchResults.map((s) => s.student).toList();
    final schoolSettings = await _db.getSchoolSettings();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Student Contact Directory'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Student Name', 'Phone', 'Email', 'Address', 'City'],
            data: students.asMap().entries.map((e) {
              final s = e.value;
              return [
                '${e.key + 1}',
                '${s.studentName} ${s.fatherName}',
                s.phone ?? '-',
                s.email ?? '-',
                s.address ?? '-',
                s.city ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(3),
            columnWidths: {
              0: const pw.FixedColumnWidth(25), // #
              1: const pw.FlexColumnWidth(3), // Name
              2: const pw.FixedColumnWidth(70), // Phone
              3: const pw.FlexColumnWidth(3), // Email
              4: const pw.FlexColumnWidth(4), // Address
              5: const pw.FlexColumnWidth(2), // City
            },
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    final pdfBytes = await pdf.save();
    if (!context.mounted) return;
    await PdfHelper.previewPdf(
      context,
      pdfBytes,
      'contact_directory',
      onExportExcel: () => _generateStudentContactExcel(context, students),
    );
  }

  Future<void> _generateStudentContactExcel(
    BuildContext context,
    List<Student> students,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    ExcelHelper.addHeader(sheet, [
      'Admission No',
      'Name',
      'Phone',
      'Email',
      'Address',
      'City',
    ]);

    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      final row = i + 1;
      ExcelHelper.setCell(sheet, 0, row, s.admissionNumber);
      ExcelHelper.setCell(sheet, 1, row, s.studentName);
      ExcelHelper.setCell(sheet, 2, row, s.phone ?? '-');
      ExcelHelper.setCell(sheet, 3, row, s.email ?? '-');
      ExcelHelper.setCell(sheet, 4, row, s.address ?? '-');
      ExcelHelper.setCell(sheet, 5, row, s.city ?? '-');
    }

    await ExcelHelper.saveExcel(context, excel, 'contact_directory');
  }

  /// Generate admission report for a date range
  Future<void> generateAdmissionReport(
    BuildContext context,
    DateTime start,
    DateTime end, {
    String sortBy = 'admissionDate', // Options: 'admissionDate', 'studentName', 'admissionNumber'
  }) async {
    // Use database-level filtering for admission date instead of in-memory filtering
    // This ensures ALL students in the date range are fetched, not just first 10000
    final searchResults = await _studentRepo.search(
      StudentFilters(
        admissionFrom: start,
        admissionTo: end,
        sortBy: sortBy,
        ascending: sortBy == 'admissionDate', // Oldest first for admission date
        limit: 0, // 0 means no limit - fetch all records
      ),
    );
    final newAdmissions = searchResults.map((s) => s.student).toList();
    final schoolSettings = await _db.getSchoolSettings();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Admission Report: ${dateFormat.format(start)} - ${dateFormat.format(end)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Text(
            'Total Admissions: ${newAdmissions.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Admission No', 'Name', 'Admission Date', 'Status'],
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FixedColumnWidth(80),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(60),
            },
            data: newAdmissions.asMap().entries.map((e) {
              final s = e.value;
              return [
                '${e.key + 1}',
                s.admissionNumber,
                '${s.studentName} ${s.fatherName}',
                dateFormat.format(s.admissionDate),
                s.status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    final pdfBytes = await pdf.save();
    if (!context.mounted) return;
    await PdfHelper.previewPdf(
      context,
      pdfBytes,
      'admission_report',
      onExportExcel: () =>
          _generateAdmissionReportExcel(context, newAdmissions),
    );
  }

  Future<void> _generateAdmissionReportExcel(
    BuildContext context,
    List<Student> students,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    ExcelHelper.addHeader(sheet, [
      'Admission No',
      'Name',
      'Father Name',
      'Admission Date',
      'Status',
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      final row = i + 1;
      ExcelHelper.setCell(sheet, 0, row, s.admissionNumber);
      ExcelHelper.setCell(sheet, 1, row, s.studentName);
      ExcelHelper.setCell(sheet, 2, row, s.fatherName);
      ExcelHelper.setCell(sheet, 3, row, dateFormat.format(s.admissionDate));
      ExcelHelper.setCell(sheet, 4, row, s.status);
    }

    await ExcelHelper.saveExcel(context, excel, 'admission_report');
  }

  /// Generate birthday list with filter options
  /// 
  /// [filterType]: 'today', 'specific', or 'upcoming'
  /// [specificDate]: Required when filterType is 'specific'
  Future<void> generateBirthdayList(
    BuildContext context, {
    String filterType = 'upcoming', // 'today', 'specific', 'upcoming'
    DateTime? specificDate,
    int upcomingDays = 30,
  }) async {
    // Fetch ALL active students with enrollment info
    final searchResults = await _studentRepo.search(
      const StudentFilters(
        status: 'active',
        sortBy: 'studentName',
        ascending: true,
        limit: 0, // No limit - fetch all records
      ),
    );

    // Fetch class and section names
    final classes = await _classRepo.getAll();
    final sections = await _sectionRepo.getAll();
    final classMap = {for (var c in classes) c.id: c.name};
    final sectionMap = {for (var s in sections) s.id: s.name};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter students based on filterType
    final filteredResults = searchResults.where((result) {
      final s = result.student;
      if (s.dateOfBirth == null) return false;
      final dob = s.dateOfBirth!;

      switch (filterType) {
        case 'today':
          // Birthday is today (same month and day)
          return dob.month == today.month && dob.day == today.day;
        
        case 'specific':
          // Birthday matches specific date
          if (specificDate == null) return false;
          final targetDate = DateTime(specificDate.year, specificDate.month, specificDate.day);
          return dob.month == targetDate.month && dob.day == targetDate.day;
        
        case 'upcoming':
        default:
          // Birthday is within upcoming days
          final thisYearBirthday = DateTime(now.year, dob.month, dob.day);
          // If birthday has passed this year, check next year
          final nextBirthday = thisYearBirthday.isBefore(today) 
              ? DateTime(now.year + 1, dob.month, dob.day)
              : thisYearBirthday;
          final diff = nextBirthday.difference(today).inDays;
          return diff >= 0 && diff <= upcomingDays;
      }
    }).toList();

    // Sort by birthday (month, then day)
    filteredResults.sort((a, b) {
      final dobA = a.student.dateOfBirth!;
      final dobB = b.student.dateOfBirth!;
      // Compare by month first, then by day
      if (dobA.month != dobB.month) {
        return dobA.month.compareTo(dobB.month);
      }
      return dobA.day.compareTo(dobB.day);
    });

    final schoolSettings = await _db.getSchoolSettings();
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    // Build report title based on filter
    String reportTitle;
    switch (filterType) {
      case 'today':
        reportTitle = "Today's Birthdays - ${DateFormat('dd MMM yyyy').format(today)}";
        break;
      case 'specific':
        reportTitle = 'Birthdays on ${DateFormat('dd MMM yyyy').format(specificDate!)}';
        break;
      case 'upcoming':
      default:
        reportTitle = 'Upcoming Birthdays (Next $upcomingDays Days)';
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(schoolSettings, reportTitle),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary
          if (filteredResults.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Total Students: ${filteredResults.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  filterType == 'today' 
                      ? 'No birthdays today'
                      : filterType == 'specific'
                          ? 'No birthdays on selected date'
                          : 'No upcoming birthdays in next $upcomingDays days',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ),
            ),
          
          if (filteredResults.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Adm. No', 'Name', 'Class/Section', 'Birth Date', 'Turning', 'Phone'],
              columnWidths: {
                0: const pw.FixedColumnWidth(30),  // #
                1: const pw.FixedColumnWidth(60),  // Adm. No
                2: const pw.FlexColumnWidth(3),    // Name
                3: const pw.FixedColumnWidth(70),  // Class/Section
                4: const pw.FixedColumnWidth(60),  // Birth Date
                5: const pw.FixedColumnWidth(50),  // Turning
                6: const pw.FixedColumnWidth(70),  // Phone
              },
              data: filteredResults.asMap().entries.map((e) {
                final result = e.value;
                final s = result.student;
                final dob = s.dateOfBirth!;
                
                // Calculate age they'll be turning
                final currentYear = now.year;
                final turningAge = currentYear - dob.year;
                
                // Get class/section
                final className = result.currentEnrollment != null 
                    ? (classMap[result.currentEnrollment!.classId] ?? '-')
                    : '-';
                final sectionName = result.currentEnrollment != null && result.currentEnrollment!.sectionId != null
                    ? (sectionMap[result.currentEnrollment!.sectionId] ?? '')
                    : '';
                final classSection = sectionName.isNotEmpty ? '$className/$sectionName' : className;
                
                return [
                  '${e.key + 1}',
                  s.admissionNumber,
                  '${s.studentName} ${s.fatherName}',
                  classSection,
                  DateFormat('dd MMM').format(dob),
                  '$turningAge years',
                  s.phone ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3E3E3),
              ),
              cellPadding: const pw.EdgeInsets.all(4),
            ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context, 
      pdf, 
      'birthday_list',
      onExportExcel: () => _generateBirthdayListExcel(
        context,
        filteredResults,
        schoolSettings,
        reportTitle,
        classMap,
        sectionMap,
      ),
    );
  }

  /// Generate birthday list Excel export
  Future<void> _generateBirthdayListExcel(
    BuildContext context,
    List<StudentWithEnrollment> results,
    SchoolSetting? schoolSettings,
    String reportTitle,
    Map<int, String> classMap,
    Map<int, String> sectionMap,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, reportTitle.toUpperCase());
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Headers
    ExcelHelper.addHeader(sheet, [
      '#',
      'Admission No',
      'Name',
      'Class/Section',
      'Birth Date',
      'Turning Age',
      'Phone',
    ], rowIndex: 2);

    final now = DateTime.now();
    int row = 3;
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final s = result.student;
      final dob = s.dateOfBirth!;
      final turningAge = now.year - dob.year;
      
      final className = result.currentEnrollment != null 
          ? (classMap[result.currentEnrollment!.classId] ?? '-')
          : '-';
      final sectionName = result.currentEnrollment != null && result.currentEnrollment!.sectionId != null
          ? (sectionMap[result.currentEnrollment!.sectionId] ?? '')
          : '';
      final classSection = sectionName.isNotEmpty ? '$className/$sectionName' : className;

      ExcelHelper.setCell(sheet, 0, row, '${i + 1}');
      ExcelHelper.setCell(sheet, 1, row, s.admissionNumber);
      ExcelHelper.setCell(sheet, 2, row, '${s.studentName} ${s.fatherName}');
      ExcelHelper.setCell(sheet, 3, row, classSection);
      ExcelHelper.setCell(sheet, 4, row, DateFormat('dd MMM').format(dob));
      ExcelHelper.setCell(sheet, 5, row, '$turningAge years');
      ExcelHelper.setCell(sheet, 6, row, s.phone ?? '-');
      row++;
    }

    // Auto-fit
    for (int i = 0; i < 7; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(2, 30); // Name column wider

    if (context.mounted) {
      await ExcelHelper.saveExcel(context, excel, 'birthday_list');
    }
  }

  // ============================================
  // ATTENDANCE REPORTS
  // ============================================

  /// Generate daily attendance report
  Future<void> generateDailyAttendanceReport(
    BuildContext context,
    DateTime date,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    final classes = await (_db.select(_db.classes)).get();

    // Sort classes numerically by name (e.g., "1", "2", "3" or "Class 1", "Class 2")
    classes.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.name);
      final bMatch = RegExp(r'\d+').firstMatch(b.name);

      if (aMatch != null && bMatch != null) {
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        return aNum.compareTo(bNum);
      } else if (aMatch != null) {
        return -1;
      } else if (bMatch != null) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    final List<List<String>> tableData = [];
    for (final cls in classes) {
      final sections = await (_db.select(
        _db.sections,
      )..where((s) => s.classId.equals(cls.id))).get();
      for (final section in sections) {
        final summary = await _attendanceRepo.getDailySummary(
          classId: cls.id,
          sectionId: section.id,
          date: date,
        );
        tableData.add([
          cls.name,
          section.name,
          '${summary.totalStudents}',
          '${summary.presentCount}',
          '${summary.absentCount}',
          '${summary.lateCount}',
          summary.totalStudents > 0
              ? '${(summary.presentCount / summary.totalStudents * 100).toStringAsFixed(1)}%'
              : '0%',
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Daily Attendance Summary - ${dateFormat.format(date)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'Class',
              'Section',
              'Total',
              'Present',
              'Absent',
              'Late',
              '%',
            ],
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FixedColumnWidth(40),
              4: const pw.FixedColumnWidth(40),
              5: const pw.FixedColumnWidth(40),
              6: const pw.FixedColumnWidth(40),
            },
            data: tableData,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'daily_attendance_${dateFormat.format(date)}',
    );
  }

  /// Generate low attendance report
  Future<void> generateLowAttendanceReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final alerts = await _attendanceRepo.getLowAttendanceAlerts(
      threshold: 75,
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    // Sort alerts by admission number numerically
    alerts.sort((a, b) {
      // Extract numeric parts from admission numbers for proper sorting
      final aMatch = RegExp(r'\d+').firstMatch(a.student.admissionNumber);
      final bMatch = RegExp(r'\d+').firstMatch(b.student.admissionNumber);

      if (aMatch != null && bMatch != null) {
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        return aNum.compareTo(bNum);
      } else if (aMatch != null) {
        return -1;
      } else if (bMatch != null) {
        return 1;
      } else {
        return a.student.admissionNumber.compareTo(b.student.admissionNumber);
      }
    });

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Low Attendance Alert Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Text(
            'Students with attendance below 75% in the last 30 days',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Adm. No', 'Student', 'Class', 'Attendance %', 'Absent Days'],
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FlexColumnWidth(4),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(80),
              5: const pw.FixedColumnWidth(70),
            },
            data: alerts.asMap().entries.map((e) {
              final a = e.value;
              return [
                '${e.key + 1}',
                a.student.admissionNumber,
                '${a.student.studentName} ${a.student.fatherName}',
                '${a.className}-${a.sectionName}',
                '${a.attendancePercentage.toStringAsFixed(1)}%',
                '${a.absentDays}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'low_attendance_report');
  }

  /// Generate monthly attendance report
  Future<void> generateMonthlyAttendanceReport(
    BuildContext context,
    int classId,
    int sectionId,
    int month,
    int year,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final cls = await _classRepo.getById(classId);
    final section = await _sectionRepo.getById(sectionId);

    if (cls == null) throw Exception('Class not found');
    if (section == null) throw Exception('Section not found');

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    // Get class-specific working days configuration
    final workingDaysService = WorkingDaysService.instance();
    final academicYear =
        schoolSettings.currentAcademicYear ??
        '${DateTime.now().year}-${DateTime.now().year + 1}';
    final workingDays = await workingDaysService.getClassWorkingDays(
      classId,
      academicYear,
    );

    // Calculate working dates in the month (class-specific)
    final workingDates = <int>[];
    for (var day = 1; day <= endDate.day; day++) {
      final date = DateTime(year, month, day);
      final dayName = _getDayName(date.weekday);
      if (workingDays.contains(dayName)) {
        workingDates.add(day);
      }
    }

    // Fetch all students in class
    final students = await _studentRepo.getByClassSection(classId, sectionId);

    // Fetch attendance for the month
    final attendanceRecords = await _attendanceRepo.search(
      AttendanceFilters(
        classId: classId,
        sectionId: sectionId,
        startDate: startDate,
        endDate: endDate,
        limit: 0, // No limit - fetch all records
      ),
    );

    // Organize attendance by student ID and Day (only for working days)
    final Map<int, Map<int, String>> attendanceMap = {};
    for (final record in attendanceRecords) {
      final day = record.attendance.date.day;
      // Only include if it's a working day
      if (workingDates.contains(day)) {
        if (!attendanceMap.containsKey(record.student.id)) {
          attendanceMap[record.student.id] = {};
        }
        attendanceMap[record.student.id]![day] = record.attendance.status;
      }
    }

    // Create data object for PDF generation
    final reportData = MonthlyAttendanceReportData(
      schoolSettings: schoolSettings,
      className: cls.name,
      sectionName: section.name,
      month: month,
      year: year,
      startDate: startDate,
      endDate: endDate,
      students: students,
      attendanceMap: attendanceMap,
      workingDays: workingDays,
      workingDates: workingDates,
    );

    // Generate PDF (direct call without isolate to avoid serialization issues)
    final pdfBytes = await _generateMonthlyAttendanceReportTask(reportData);

    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'monthly_attendance_${month}_$year',
      );
    }
  }

  static Future<Uint8List> _generateMonthlyAttendanceReportTask(
    MonthlyAttendanceReportData data,
  ) async {
    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final monthName = DateFormat('MMMM yyyy').format(data.startDate);

    // Use working dates if available, otherwise fall back to all days
    final displayDays = data.workingDates.isNotEmpty
        ? data.workingDates
        : List.generate(data.endDate.day, (i) => i + 1);

    // Split students into chunks (e.g., 20 per page)
    const studentsPerPage = 20;
    final totalPages = (data.students.length / studentsPerPage).ceil();

    for (int p = 0; p < totalPages; p++) {
      final startIndex = p * studentsPerPage;
      final endIndex = (startIndex + studentsPerPage < data.students.length)
          ? startIndex + studentsPerPage
          : data.students.length;
      final pageStudents = data.students.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(
                  data.schoolSettings,
                  'Monthly Attendance: $monthName - ${data.className} (${data.sectionName})',
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell(
                          'Roll No',
                          isHeader: true,
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell('Name', isHeader: true),
                        // Only show working days
                        ...displayDays.map(
                          (day) => _buildTableCell(
                            '$day',
                            isHeader: true,
                            align: pw.TextAlign.center,
                            fontSize: 6,
                          ),
                        ),
                        _buildTableCell(
                          'Pres',
                          isHeader: true,
                          align: pw.TextAlign.center,
                          fontSize: 6,
                        ),
                        _buildTableCell(
                          'Abs',
                          isHeader: true,
                          align: pw.TextAlign.center,
                          fontSize: 6,
                        ),
                      ],
                    ),
                    // Student Rows
                    ...pageStudents.map((s) {
                      final studentId = s.student.id;
                      final studentAtt = data.attendanceMap[studentId] ?? {};

                      int present = 0;
                      int absent = 0;

                      // Only iterate through working days
                      final dayCells = displayDays.map((day) {
                        final status = studentAtt[day];
                        String symbol = '';
                        PdfColor? color;

                        if (status == 'present') {
                          symbol = 'P';
                          present++;
                        } else if (status == 'absent') {
                          symbol = 'A';
                          color = PdfColors.red;
                          absent++;
                        } else if (status == 'late') {
                          symbol = 'L';
                          color = PdfColors.orange;
                          present++;
                        } else if (status == 'leave') {
                          symbol = 'Lv';
                          color = PdfColors.blue;
                        }

                        return _buildTableCell(
                          symbol,
                          align: pw.TextAlign.center,
                          fontSize: 6,
                          color: color,
                        );
                      }).toList();

                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            s.currentEnrollment?.rollNumber ?? '-',
                            align: pw.TextAlign.center,
                            fontSize: 7,
                          ),
                          _buildTableCell(
                            '${s.student.studentName} ${s.student.fatherName}',
                            fontSize: 7,
                          ),
                          ...dayCells,
                          _buildTableCell(
                            '$present',
                            align: pw.TextAlign.center,
                            fontSize: 7,
                          ),
                          _buildTableCell(
                            '$absent',
                            align: pw.TextAlign.center,
                            fontSize: 7,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.Spacer(),
                _buildPdfFooter(context),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Generate student attendance history
  Future<void> generateStudentAttendanceHistory(
    BuildContext context,
    int studentId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final studentData = await _studentRepo.getWithCurrentEnrollment(studentId);
    if (studentData == null) throw Exception('Student not found');

    // Default to current academic session range or last 6 months effectively
    final endDate = DateTime.now();
    final startDate = endDate.subtract(
      const Duration(days: 180),
    ); // Last 6 months

    final history = await _attendanceRepo.getStudentHistory(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );

    final stats = await _attendanceRepo.getStudentStats(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Student Attendance History (${dateFormat.format(startDate)} - ${dateFormat.format(endDate)})',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student: ${studentData.student.studentName} ${studentData.student.fatherName}',
                    ),
                    pw.Text(
                      'Admission No: ${studentData.student.admissionNumber}',
                    ),
                    pw.Text('Class: ${studentData.classSection}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Days: ${stats.totalDays}'),
                    pw.Text(
                      'Present: ${stats.presentDays} (${stats.attendancePercentage.toStringAsFixed(1)}%)',
                    ),
                    pw.Text('Absent: ${stats.absentDays}'),
                    pw.Text('Late: ${stats.lateDays}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Status', 'Remarks'],
            data: history
                .map(
                  (h) => [
                    dateFormat.format(h.date),
                    h.status.toUpperCase(),
                    h.remarks ?? '-',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'attendance_history_${studentData.student.admissionNumber}',
    );
  }

  /// Generate staff attendance report with actual attendance data
  Future<void> generateStaffAttendanceReport(
    BuildContext context,
    DateTime start,
    DateTime end, {
    bool exportExcel = false,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Use Staff Attendance Report Service for proper data
      final reportService = StaffAttendanceReportService(_db);
      final summary = await reportService.getAttendanceReportData(
        startDate: start,
        endDate: end,
      );

      // Close loading dialog before showing the system dialogue
      // otherwise it blocks the file picker UI on some platforms
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (exportExcel) {
        // Generate Excel
        final excelBytes = await reportService.generateExcelReport(summary);
        if (context.mounted) {
          await PdfHelper.saveFile(
            context,
            excelBytes,
            'staff_attendance_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.xlsx',
          );
        }
      } else {
        // Generate PDF
        final pdfBytes = await reportService.generatePdfReport(summary);
        if (context.mounted) {
          await PdfHelper.previewPdf(
            context,
            pdfBytes,
            'staff_attendance_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      // Ensure it's closed even if an exception threw before the first pop
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  // ============================================
  // FEE REPORTS
  // ============================================

  /// Generate fee collection report
  Future<void> generateFeeCollectionReport(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Fetch payments for the period
    final payments = await _paymentRepo.getPayments(
      PaymentFilters(
        dateFrom: DateTime(start.year, start.month, start.day),
        dateTo: DateTime(end.year, end.month, end.day, 23, 59, 59),
        limit: 0, // No limit - fetch all records
      ),
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Fee Collection Report: ${dateFormat.format(start)} - ${dateFormat.format(end)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(
                'Total Collection',
                currencyFormat.format(
                  payments.fold(0.0, (sum, p) => sum + p.payment.amount),
                ),
                PdfColors.green700, // Changed to green for visibility
              ),
              _buildStatBox(
                'Transaction Count',
                payments.length.toString(),
                PdfColors.blue700,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Payments Table
          if (payments.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Receipt #', 'Student', 'Class', 'Amount'],
              data: payments.map((p) {
                return [
                  dateFormat.format(p.payment.paymentDate),
                  p.payment.receiptNumber,
                  p.studentName,
                  p.classSection,
                  currencyFormat.format(p.payment.amount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.black, // Explicit black
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black, // Explicit black
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
              columnWidths: {
                0: const pw.FixedColumnWidth(70),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FixedColumnWidth(80),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            )
          else
            pw.Center(
              child: pw.Text(
                'No payments recorded for this period.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.black,
                ),
              ),
            ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'fee_collection_report',
      onExportExcel: () => _generateFeeCollectionExcel(
        context,
        schoolSettings,
        start,
        end,
        payments,
      ),
    );
  }

  Future<void> _generateFeeCollectionExcel(
    BuildContext context,
    SchoolSetting? schoolSettings,
    DateTime start,
    DateTime end,
    List<PaymentWithDetails> payments,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, 'FEE COLLECTION REPORT');
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    ExcelHelper.setCell(
      sheet,
      0,
      1,
      'Period: ${dateFormat.format(start)} - ${dateFormat.format(end)}',
    );
    ExcelHelper.setCell(
      sheet,
      0,
      2,
      'Total Collection: ${currencyFormat.format(payments.fold(0.0, (sum, p) => sum + p.payment.amount))}',
    );

    // Headers
    ExcelHelper.addHeader(sheet, [
      'Date',
      'Receipt #',
      'Student Name',
      'Class & Section',
      'Amount',
    ], rowIndex: 4);

    int row = 5;
    for (final p in payments) {
      ExcelHelper.setCell(
        sheet,
        0,
        row,
        dateFormat.format(p.payment.paymentDate),
      );
      ExcelHelper.setCell(sheet, 1, row, p.payment.receiptNumber);
      ExcelHelper.setCell(sheet, 2, row, p.studentName);
      ExcelHelper.setCell(sheet, 3, row, p.classSection);
      ExcelHelper.setCell(sheet, 4, row, p.payment.amount.toString());
      row++;
    }

    // Auto-fit
    for (int i = 0; i < 5; i++) {
      sheet.setColumnWidth(i, 20);
    }
    sheet.setColumnWidth(2, 25);

    if (context.mounted) {
      await ExcelHelper.saveExcel(
        context,
        excel,
        'fee_collection_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}',
      );
    }
  }

  /// Generate outstanding fees report
  Future<void> generateOutstandingFeesReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final classes = await _classRepo.getAll();

    // Sort classes numerically by name (e.g., "1", "2", "3" or "Class 1", "Class 2")
    classes.sort((a, b) {
      final aMatch = RegExp(r'\d+').firstMatch(a.name);
      final bMatch = RegExp(r'\d+').firstMatch(b.name);

      if (aMatch != null && bMatch != null) {
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        return aNum.compareTo(bNum);
      } else if (aMatch != null) {
        return -1;
      } else if (bMatch != null) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '',
      decimalDigits: 0,
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    // We will build a list of widgets for the PDF
    final List<pw.Widget> reportContent = [];
    double grandTotalOutstanding = 0;

    for (final cls in classes) {
      // Get all students with outstanding balance (0 days overdue means any pending)
      // We use a high limit to get all
      // Get all students with outstanding balance - no limit
      final defaulters = await _invoiceRepo.getDefaulters(
        classId: cls.id,
        minDaysOverdue: 0,
        limit: 0, // No limit - fetch all records
      );

      if (defaulters.isEmpty) continue;

      final classTotal = defaulters.fold<double>(
        0,
        (sum, d) => sum + d.totalPending,
      );
      grandTotalOutstanding += classTotal;

      // Add Class Header
      reportContent.add(
        pw.Header(
          level: 2,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Class: ${cls.name}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                'Total: Rs. ${currencyFormat.format(classTotal)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.red700,
                ),
              ),
            ],
          ),
        ),
      );

      // Add Student Table for this Class
      reportContent.add(
        pw.TableHelper.fromTextArray(
          headers: ['Adm No', 'Student Name', 'Father Name', 'Pending Amount'],
          data: defaulters.map((d) {
            return [
              d.student.admissionNumber,
              d.student.studentName,
              d.student.fatherName ?? '-',
              currencyFormat.format(d.totalPending),
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.black,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(5),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FixedColumnWidth(100),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
        ),
      );

      reportContent.add(pw.SizedBox(height: 15));
    }

    if (reportContent.isEmpty) {
      reportContent.add(
        pw.Center(
          child: pw.Text(
            'No outstanding fees found.',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    } else {
      // Add Grand Total at the end
      reportContent.add(pw.Divider());
      reportContent.add(
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Grand Total Outstanding: Rs. ${currencyFormat.format(grandTotalOutstanding)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Outstanding Fees Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => reportContent,
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'outstanding_fees_report');
  }

  /// Generate defaulters report
  Future<void> generateDefaultersReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    // Use 1 day as threshold to capture any overdue, or 0 if we want strictly "outstanding"
    // For "Defaulters", usually it implies some lateness. Let's set to 1 for now,
    // but if the user wants to see everything we could set to 0.
    // Given the user's feedback, they probably want to see the people they owe money FROM.
    // Changing to 0 ensures we see all outstanding invoices that are past their due date (or due today).
    final defaulters = await _invoiceRepo.getDefaulters(minDaysOverdue: 0);

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Fee Defaulters Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Text(
            'Students with outstanding fees',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          if (defaulters.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Student', 'Class', 'Outstanding', 'Days Overdue'],
              data: defaulters.asMap().entries.map((e) {
                final d = e.value;
                return [
                  '${e.key + 1}',
                  d.studentName,
                  d.classSection,
                  'PKR ${NumberFormat('#,###').format(d.totalPending)}',
                  '${d.maxDaysOverdue}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              cellStyle: const pw.TextStyle(
                color: PdfColors.black,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3E3E3),
              ),
              cellPadding: const pw.EdgeInsets.all(4),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            )
          else
            pw.Center(
              child: pw.Text(
                'No defaulters found.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.black,
                ),
              ),
            ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'defaulters_report');
  }

  /// Generate daily collection report
  Future<void> generateDailyCollectionReport(
    BuildContext context,
    DateTime date,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Fetch payments for the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final payments = await _paymentRepo.getPayments(
      PaymentFilters(dateFrom: startOfDay, dateTo: endOfDay, limit: 0), // No limit
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Daily Collection Report - ${dateFormat.format(date)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(
                'Total Collection',
                currencyFormat.format(
                  payments.fold(0.0, (sum, p) => sum + p.payment.amount),
                ),
                PdfColors.green700, // Explicit color for visibility
              ),
              _buildStatBox(
                'Transaction Count',
                payments.length.toString(),
                PdfColors.green700,
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Payments Table
          if (payments.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Receipt #', 'Student', 'Class', 'Mode', 'Amount'],
              data: payments.map((p) {
                return [
                  p.payment.receiptNumber,
                  p.studentName,
                  p.classSection,
                  p.payment.paymentMode.toUpperCase(),
                  currencyFormat.format(p.payment.amount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(80),
              },
            )
          else
            pw.Center(
              child: pw.Text(
                'No payments recorded for this date.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'daily_collection_${dateFormat.format(date)}',
    );
  }

  pw.Widget _buildStatBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      width: 150,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate class-wise fee status
  Future<void> generateClasswiseFeeStatus(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final classes = await _classRepo.getAll();

    // Sort classes numerically by name (e.g., "1", "2", "3" or "Class 1", "Class 2")
    classes.sort((a, b) {
      // Extract numeric parts from class names
      final aMatch = RegExp(r'\d+').firstMatch(a.name);
      final bMatch = RegExp(r'\d+').firstMatch(b.name);

      if (aMatch != null && bMatch != null) {
        // Both have numbers, compare numerically
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        return aNum.compareTo(bNum);
      } else if (aMatch != null) {
        // Only a has a number, a comes first
        return -1;
      } else if (bMatch != null) {
        // Only b has a number, b comes first
        return 1;
      } else {
        // Neither has a number, compare alphabetically
        return a.name.compareTo(b.name);
      }
    });

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '',
      decimalDigits: 0,
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    final List<List<String>> tableData = [];
    double grandTotalInvoiced = 0;
    double grandTotalCollected = 0;

    for (final cls in classes) {
      final stats = await _invoiceRepo.getInvoiceStats(classId: cls.id);
      final studentCount = await _db
          .customSelect(
            'SELECT COUNT(*) as c FROM enrollments WHERE class_id = ? AND is_current = 1',
            variables: [Variable.withInt(cls.id)],
          )
          .getSingle();
      final count = studentCount.read<int>('c');

      tableData.add([
        cls.name,
        count.toString(),
        currencyFormat.format(stats.totalAmount),
        currencyFormat.format(stats.paidAmount),
        currencyFormat.format(stats.pendingAmount),
        stats.totalAmount > 0
            ? '${((stats.paidAmount / stats.totalAmount) * 100).toStringAsFixed(1)}%'
            : '0%',
      ]);

      grandTotalInvoiced += stats.totalAmount;
      grandTotalCollected += stats.paidAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Class-wise Fee Status'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'Class',
              'Students',
              'Invoiced',
              'Collected',
              'Pending',
              'Collected %',
            ],
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.black, // Explicit black
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.black, // Explicit black
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(6),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FixedColumnWidth(50),
              2: const pw.FixedColumnWidth(75),
              3: const pw.FixedColumnWidth(75),
              4: const pw.FixedColumnWidth(75),
              5: const pw.FixedColumnWidth(70),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Grand Total Invoiced: Rs. ${currencyFormat.format(grandTotalInvoiced)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Grand Total Collected: Rs. ${currencyFormat.format(grandTotalCollected)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Overall Collection Rate: ${grandTotalInvoiced > 0 ? ((grandTotalCollected / grandTotalInvoiced) * 100).toStringAsFixed(1) : 0}%',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'class_wise_fee_status',
      onExportExcel: () => _generateClasswiseFeeStatusExcel(
        context,
        schoolSettings,
        tableData,
        grandTotalInvoiced,
        grandTotalCollected,
      ),
    );
  }

  Future<void> _generateClasswiseFeeStatusExcel(
    BuildContext context,
    SchoolSetting? schoolSettings,
    List<List<String>> tableData,
    double grandTotalInvoiced,
    double grandTotalCollected,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, 'CLASS-WISE FEE STATUS');
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    ExcelHelper.setCell(
      sheet,
      0,
      1,
      'Grand Total Invoiced: ${currencyFormat.format(grandTotalInvoiced)}',
    );
    ExcelHelper.setCell(
      sheet,
      0,
      2,
      'Grand Total Collected: ${currencyFormat.format(grandTotalCollected)}',
    );
    ExcelHelper.setCell(
      sheet,
      0,
      3,
      'Overall Collection Rate: ${grandTotalInvoiced > 0 ? ((grandTotalCollected / grandTotalInvoiced) * 100).toStringAsFixed(1) : 0}%',
    );

    // Headers
    ExcelHelper.addHeader(sheet, [
      'Class',
      'Students',
      'Invoiced',
      'Collected',
      'Pending',
      'Collected %',
    ], rowIndex: 5);

    int row = 6;
    for (final dataRow in tableData) {
      for (int i = 0; i < dataRow.length; i++) {
        ExcelHelper.setCell(sheet, i, row, dataRow[i]);
      }
      row++;
    }

    // Auto-fit
    for (int i = 0; i < 6; i++) {
      sheet.setColumnWidth(i, 15);
    }

    if (context.mounted) {
      await ExcelHelper.saveExcel(
        context,
        excel,
        'classwise_fee_status_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    }
  }

  /// Generate concession report
  Future<void> generateConcessionReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final concessions = await _concessionRepo.getConcessions(
      const ConcessionFilters(activeOnly: true, limit: 0), // No limit
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '',
      decimalDigits: 0,
    );

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Fee Concession Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          if (concessions.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Student', 'Class', 'Type', 'Value', 'Reason'],
              data: concessions.map((c) {
                final displayValue = c.concession.discountType == 'percentage'
                    ? '${c.concession.discountValue}%'
                    : 'Rs. ${currencyFormat.format(c.concession.discountValue)}';

                return [
                  c.studentName,
                  c.classSection,
                  c.feeType?.name ?? 'All Fees',
                  displayValue,
                  c.concession.reason ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.black, // Explicit black
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.black, // Explicit black
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FlexColumnWidth(2),
              },
            )
          else
            pw.Center(
              child: pw.Text(
                'No active concessions recorded.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'concession_report');
  }

  // ============================================
  // ACADEMIC REPORTS
  // ============================================

  Future<void> generateExamResults(
    BuildContext context,
    int examId,
    int classId,
    int? sectionId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final exam = await _examRepo.getById(examId);
    if (exam == null) throw Exception('Exam not found');

    final cls = await _classRepo.getById(classId);
    if (cls == null) throw Exception('Class not found');

    Section? section;
    if (sectionId != null) {
      section = await _sectionRepo.getById(sectionId);
    }

    // Actually generic search is better if sectionId is optional
    final studentList = await _studentRepo.search(
      StudentFilters(classId: classId, sectionId: sectionId, limit: 0), // No limit
    );

    // Sort by roll number (handle both numeric and alphanumeric)
    studentList.sort((a, b) {
      final rollA = a.currentEnrollment?.rollNumber ?? '';
      final rollB = b.currentEnrollment?.rollNumber ?? '';
      
      // Try to extract numeric part for proper sorting
      final numA = int.tryParse(RegExp(r'\d+').firstMatch(rollA)?.group(0) ?? '');
      final numB = int.tryParse(RegExp(r'\d+').firstMatch(rollB)?.group(0) ?? '');
      
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      return rollA.compareTo(rollB);
    });

    // Fetch exam subjects
    final subjects = await _examRepo.getExamSubjects(examId);

    // Fetch marks
    final marksQuery = _db.select(_db.studentMarks).join([
      innerJoin(
        _db.examSubjects,
        _db.examSubjects.id.equalsExp(_db.studentMarks.examSubjectId),
      ),
    ])..where(_db.examSubjects.examId.equals(examId));

    final markRows = await marksQuery.get();

    final Map<int, Map<int, double>> marksMap =
        {}; // StudentId -> SubjectId -> Marks

    for (final row in markRows) {
      final mark = row.readTable(_db.studentMarks);
      final subjectId = row.readTable(_db.examSubjects).subjectId;

      if (!marksMap.containsKey(mark.studentId)) {
        marksMap[mark.studentId] = {};
      }
      marksMap[mark.studentId]![subjectId] = mark.marksObtained ?? 0;
    }

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Exam Results: ${exam.name} - ${cls.name}${section != null ? " (${section.name})" : ""}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Roll No', isHeader: true),
                  _buildTableCell('Name', isHeader: true),
                  ...subjects.map(
                    (s) => _buildTableCell(
                      s.subject.name,
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                  ),
                  _buildTableCell(
                    'Total',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell(
                    '%',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell(
                    'Grade',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                ],
              ),
              // Body
              ...studentList.map((s) {
                final studentMarks = marksMap[s.student.id] ?? {};
                double totalObtained = 0;
                double totalMax = 0;

                final subjectCells = subjects.map((sub) {
                  final obtained = studentMarks[sub.subject.id];
                  if (obtained != null) {
                    totalObtained += obtained;
                    totalMax += sub.examSubject.maxMarks;
                    return _buildTableCell(
                      obtained.toString(),
                      align: pw.TextAlign.center,
                    );
                  } else {
                    return _buildTableCell('-', align: pw.TextAlign.center);
                  }
                }).toList();

                double percentage = totalMax > 0
                    ? (totalObtained / totalMax) * 100
                    : 0;
                String grade = _calculateGrade(percentage);

                return pw.TableRow(
                  children: [
                    _buildTableCell(s.currentEnrollment?.rollNumber ?? '-'),
                    _buildTableCell(
                      '${s.student.studentName} ${s.student.fatherName}',
                    ),
                    ...subjectCells,
                    _buildTableCell(
                      totalObtained.toStringAsFixed(1),
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      percentage.toStringAsFixed(1),
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(grade, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'exam_results_${exam.name}_${cls.name}');
  }

  Future<void> generateGradeDistributionReport(
    BuildContext context,
    int examId,
    int classId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final exam = await _examRepo.getById(examId);
    final cls = await _classRepo.getById(classId);

    if (exam == null || cls == null) throw Exception('Exam or Class not found');

    // Fetch all students
    final students = await _studentRepo.search(
      StudentFilters(classId: classId, limit: 0), // No limit
    );
    final userMap = {for (var s in students) s.student.id: s};

    // Calculate grades for each student
    // Need marks for all subjects for this exam
    final marksQuery = _db.select(_db.studentMarks).join([
      innerJoin(
        _db.examSubjects,
        _db.examSubjects.id.equalsExp(_db.studentMarks.examSubjectId),
      ),
    ])..where(_db.examSubjects.examId.equals(examId));

    final markRows = await marksQuery.get();
    final examSubjects = await _examRepo.getExamSubjects(examId);
    final totalMaxMarks = examSubjects.fold<double>(
      0,
      (sum, item) => sum + item.examSubject.maxMarks,
    );

    final Map<int, double> studentTotalMarks = {};
    for (final row in markRows) {
      final mark = row.readTable(_db.studentMarks);
      studentTotalMarks[mark.studentId] =
          (studentTotalMarks[mark.studentId] ?? 0) + (mark.marksObtained ?? 0);
    }

    final Map<String, int> gradeDistribution = {
      'A+': 0,
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };

    for (final studentId in studentTotalMarks.keys) {
      if (!userMap.containsKey(studentId)) continue;

      final obtained = studentTotalMarks[studentId]!;
      final percentage = totalMaxMarks > 0
          ? (obtained / totalMaxMarks) * 100
          : 0.0;
      final grade = _calculateGrade(percentage);
      gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
    }

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Grade Distribution: ${exam.name} - ${cls.name}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Center(
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell(
                      'Grade',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      'Count',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                  ],
                ),
                ...gradeDistribution.entries.map(
                  (e) => pw.TableRow(
                    children: [
                      _buildTableCell(e.key, align: pw.TextAlign.center),
                      _buildTableCell(
                        e.value.toString(),
                        align: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          // Basic ASCII visual
          ...gradeDistribution.entries.map((e) {
            final count = e.value;
            return pw.Row(
              children: [
                pw.SizedBox(width: 30, child: pw.Text(e.key)),
                pw.Container(
                  width: count * 10.0,
                  height: 10,
                  color: PdfColors.blue,
                ),
                pw.SizedBox(width: 5),
                pw.Text(count.toString()),
              ],
            );
          }),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'grade_distribution');
  }

  Future<void> generateTopperListReport(
    BuildContext context,
    int examId,
    int classId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final exam = await _examRepo.getById(examId);
    final cls = await _classRepo.getById(classId);

    if (exam == null || cls == null) throw Exception('Exam or Class not found');

    // Similar logic to fetch marks and rank
    final students = await _studentRepo.search(
      StudentFilters(classId: classId, limit: 0), // No limit
    );
    final userMap = {for (var s in students) s.student.id: s};

    final marksQuery = _db.select(_db.studentMarks).join([
      innerJoin(
        _db.examSubjects,
        _db.examSubjects.id.equalsExp(_db.studentMarks.examSubjectId),
      ),
    ])..where(_db.examSubjects.examId.equals(examId));

    final markRows = await marksQuery.get();
    final examSubjects = await _examRepo.getExamSubjects(examId);
    final totalMaxMarks = examSubjects.fold<double>(
      0,
      (sum, item) => sum + item.examSubject.maxMarks,
    );

    final Map<int, double> studentTotalMarks = {};
    for (final row in markRows) {
      final mark = row.readTable(_db.studentMarks);
      studentTotalMarks[mark.studentId] =
          (studentTotalMarks[mark.studentId] ?? 0) + (mark.marksObtained ?? 0);
    }

    // Convert to list and sort
    final List<MapEntry<int, double>> rankedStudents =
        studentTotalMarks.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Descending

    final topStudents = rankedStudents.take(10).toList();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Topper List: ${exam.name} - ${cls.name}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary info
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text('Total Students: ${topStudents.length}'),
                pw.Text('Maximum Marks: ${totalMaxMarks.toStringAsFixed(0)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Rank', 'Adm. No', 'Name', 'Obtained', 'Max', 'Percentage', 'Grade', 'Status'],
            data: topStudents
                .asMap()
                .entries
                .map((e) {
                  final rank = e.key + 1;
                  final studentId = e.value.key;
                  final obtained = e.value.value;
                  final student = userMap[studentId];
                  final percentage = totalMaxMarks > 0
                      ? (obtained / totalMaxMarks) * 100
                      : 0.0;
                  final grade = _calculateGrade(percentage);
                  final status = percentage >= 40 ? 'Pass' : 'Fail';

                  if (student == null) return [];

                  return [
                    rank.toString(),
                    student.student.admissionNumber,
                    '${student.student.studentName} ${student.student.fatherName}',
                    obtained.toStringAsFixed(1),
                    totalMaxMarks.toStringAsFixed(0),
                    '${percentage.toStringAsFixed(2)}%',
                    grade,
                    status,
                  ];
                })
                .where((l) => l.isNotEmpty)
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
            columnWidths: {
              0: const pw.FixedColumnWidth(35),  // Rank
              1: const pw.FixedColumnWidth(60),  // Adm. No
              2: const pw.FlexColumnWidth(3),    // Name
              3: const pw.FixedColumnWidth(50),  // Obtained
              4: const pw.FixedColumnWidth(40),  // Max
              5: const pw.FixedColumnWidth(60),  // Percentage
              6: const pw.FixedColumnWidth(40),  // Grade
              7: const pw.FixedColumnWidth(45),  // Status
            },
          ),
          pw.SizedBox(height: 16),
          // Legend
          pw.Text(
            'Grade Scale: A+ (90%+) | A (80-89%) | B (70-79%) | C (60-69%) | D (50-59%) | F (<50%)',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'topper_list');
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  // ============================================
  // STAFF REPORTS
  // ============================================

  Future<void> generateStaffListReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final staff = await _staffRepo.getAll();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(schoolSettings, 'Staff List'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Employee ID', 'Name', 'Role', 'Phone', 'Status'],
            data: staff.asMap().entries.map((e) {
              final s = e.value;
              return [
                '${e.key + 1}',
                s.staff.employeeId,
                s.fullName,
                s.role.name,
                s.staff.phone,
                s.staff.status,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'staff_list',
      onExportExcel: () =>
          _generateStaffListExcel(context, staff, schoolSettings),
    );
  }

  Future<void> _generateStaffListExcel(
    BuildContext context,
    List<StaffWithRole> staff,
    SchoolSetting? schoolSettings,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    // Title
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    ExcelHelper.setCell(sheet, 0, 0, 'STAFF LIST');
    sheet
        .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = excel_lib.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Headers
    ExcelHelper.addHeader(sheet, [
      '#',
      'Employee ID',
      'Name',
      'Role',
      'Phone',
      'Status',
    ], rowIndex: 2);

    int row = 3;
    for (int i = 0; i < staff.length; i++) {
      final s = staff[i];
      ExcelHelper.setCell(sheet, 0, row, '${i + 1}');
      ExcelHelper.setCell(sheet, 1, row, s.staff.employeeId);
      ExcelHelper.setCell(sheet, 2, row, s.fullName);
      ExcelHelper.setCell(sheet, 3, row, s.role.name);
      ExcelHelper.setCell(sheet, 4, row, s.staff.phone);
      ExcelHelper.setCell(sheet, 5, row, s.staff.status);
      row++;
    }

    // Auto-fit
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 10);

    if (context.mounted) {
      await ExcelHelper.saveExcel(context, excel, 'staff_list');
    }
  }

  Future<void> generateStaffContactsReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final staff = await _staffRepo.getAll();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Staff Contact Directory'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Name', 'Role', 'Department', 'Phone', 'Email'],
            data: staff.asMap().entries.map((e) {
              final s = e.value;
              return [
                '${e.key + 1}',
                s.fullName,
                s.role.name,
                s.staff.department ?? '-',
                s.staff.phone,
                s.staff.email ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'staff_contacts');
  }

  Future<void> generateDepartmentwiseStaffReport(BuildContext context) async {
    final schoolSettings = await _db.getSchoolSettings();
    final departments = await _staffRepo.getDistinctDepartments();

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    final List<pw.Widget> content = [];
    
    // Handle empty departments
    if (departments.isEmpty) {
      content.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              'No departments found',
              style: const pw.TextStyle(color: PdfColors.grey600),
            ),
          ),
        ),
      );
    } else {
      for (final dept in departments) {
        final deptStaff = await _staffRepo.search(StaffFilters(department: dept));
        
        // Skip departments with no staff
        if (deptStaff.isEmpty) continue;
        
        content.add(
          pw.Container(
            color: PdfColors.blue50,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text(
              dept,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 8));
        content.add(
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Name', 'Designation', 'Phone'],
            data: deptStaff.asMap().entries.map((e) {
              final s = e.value;
              return [
                '${e.key + 1}',
                s.fullName,
                s.staff.designation.isNotEmpty ? s.staff.designation : '-',
                s.staff.phone.isNotEmpty ? s.staff.phone : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        );
        content.add(pw.SizedBox(height: 20));
      }
      
      // If no staff found in any department
      if (content.isEmpty) {
        content.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                'No staff members found in any department',
                style: const pw.TextStyle(color: PdfColors.grey600),
              ),
            ),
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) =>
            _buildPdfHeader(schoolSettings, 'Department-wise Staff Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => content,
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'departmentwise_staff');
  }

  Future<void> generateLeaveReport(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    final dateFormat = DateFormat('dd/MM/yyyy');

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Staff Leave Report: ${dateFormat.format(start)} - ${dateFormat.format(end)}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.Text(
            'Leave summary for the specified period',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(context, pdf, 'leave_report');
  }

  /// Generate timetable report
  Future<void> generateTimetableReport(
    BuildContext context,
    int classId,
    int? sectionId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final academicYearRow = await _db.getCurrentAcademicYear();
    final academicYear = academicYearRow?.name ?? '2025-2026';

    final cls = await _classRepo.getById(classId);
    if (cls == null) throw Exception('Class not found');

    Section? section;
    if (sectionId != null) {
      section = await _sectionRepo.getById(sectionId);
    } else {
      // If no section selected, try to get the first one for the class
      final sections = await _sectionRepo.getByClass(classId);
      if (sections.isNotEmpty) {
        section = sections.first;
        sectionId = section.id;
      } else {
        throw Exception('No sections found for this class');
      }
    }

    final timetable = await _timetableRepo.getWeeklyTimetable(
      classId,
      sectionId,
      academicYear,
    );

    final periods =
        await (_db.select(_db.periodDefinitions)
              ..where((t) => t.academicYear.equals(academicYear))
              ..orderBy([
                (t) => OrderingTerm.asc(t.startTime),
                (t) => OrderingTerm.asc(t.displayOrder),
              ]))
            .get();

    final pdfBytes = await TimetablePdfService.generateTimetablePdf(
      schoolSettings: schoolSettings,
      className: cls.name,
      sectionName: section?.name ?? '',
      academicYear: academicYear,
      periods: periods,
      timetable: timetable,
    );

    if (!context.mounted) return;
    await PdfHelper.previewPdf(
      context,
      pdfBytes,
      'timetable_${cls.name}_${section?.name}',
      onExportExcel: () => _generateTimetableReportExcel(
        context,
        cls.name,
        section?.name ?? '',
        academicYear,
        periods,
        timetable,
      ),
    );
  }

  Future<void> _generateTimetableReportExcel(
    BuildContext context,
    String className,
    String sectionName,
    String academicYear,
    List<PeriodDefinition> periods,
    Map<String, Map<int, TimetableSlotWithDetails?>> timetable,
  ) async {
    final excel = ExcelHelper.createWorkbook();
    final sheet = excel.sheets.values.first;

    // Header Info
    ExcelHelper.setCell(sheet, 0, 0, 'Class: $className $sectionName');
    ExcelHelper.setCell(sheet, 0, 1, 'Academic Year: $academicYear');

    // Headers
    final headers = [
      'Time',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // Manually set headers at row 3 (index 3) because rows are 0-indexed
    for (var i = 0; i < headers.length; i++) {
      ExcelHelper.setCell(sheet, i, 3, headers[i]);
    }

    int rowIndex = 4;
    for (final period in periods) {
      final timeStr = '${period.startTime} - ${period.endTime}';
      ExcelHelper.setCell(sheet, 0, rowIndex, timeStr);

      // Days
      _fillTimetableCell(
        sheet,
        1,
        rowIndex,
        period.periodNumber,
        timetable['monday'],
      );
      _fillTimetableCell(
        sheet,
        2,
        rowIndex,
        period.periodNumber,
        timetable['tuesday'],
      );
      _fillTimetableCell(
        sheet,
        3,
        rowIndex,
        period.periodNumber,
        timetable['wednesday'],
      );
      _fillTimetableCell(
        sheet,
        4,
        rowIndex,
        period.periodNumber,
        timetable['thursday'],
      );
      _fillTimetableCell(
        sheet,
        5,
        rowIndex,
        period.periodNumber,
        timetable['friday'],
      );
      _fillTimetableCell(
        sheet,
        6,
        rowIndex,
        period.periodNumber,
        timetable['saturday'],
      );
      _fillTimetableCell(
        sheet,
        7,
        rowIndex,
        period.periodNumber,
        timetable['sunday'],
      );

      rowIndex++;
    }

    await ExcelHelper.saveExcel(
      context,
      excel,
      'timetable_${className}_$sectionName',
    );
  }

  void _fillTimetableCell(
    dynamic sheet,
    int col,
    int row,
    int periodNumber,
    Map<int, TimetableSlotWithDetails?>? daySlots,
  ) {
    if (daySlots == null) {
      ExcelHelper.setCell(sheet, col, row, '-');
      return;
    }

    final slot = daySlots[periodNumber];
    if (slot != null) {
      final subjectName = slot.subject?.name ?? 'Unknown';
      final teacherName = slot.teacherName ?? 'No Teacher';
      ExcelHelper.setCell(sheet, col, row, '$subjectName\n$teacherName');
    } else {
      ExcelHelper.setCell(sheet, col, row, '-');
    }
  }

  /// Generate class report cards
  Future<void> generateClassReportCards(
    BuildContext context,
    int examId,
    int classId, {
    int? sectionId,
  }) async {
    // Fetch students
    final students = await _studentRepo.search(
      StudentFilters(classId: classId, sectionId: sectionId, limit: 0), // No limit
    );

    if (students.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found in this class')),
        );
      }
      return;
    }

    final reportCards = <ReportCardData>[];

    // Show progress dialog or loading indicator if possible
    // For now, relies on the UI's loading state

    for (final student in students) {
      final data = await _reportCardService.getReportCardData(
        examId: examId,
        studentId: student.student.id,
      );
      if (data != null) {
        reportCards.add(data);
      }
    }

    if (reportCards.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No report card data available')),
        );
      }
      return;
    }

    if (context.mounted) {
      await _reportCardService.printBulkReportCards(context, reportCards);
    }
  }

  /// Generate subject analysis report
  Future<void> generateSubjectAnalysis(
    BuildContext context,
    int examId,
    int classId,
    int subjectId,
  ) async {
    final schoolSettings = await _db.getSchoolSettings();
    if (schoolSettings == null) throw Exception('School settings not found');

    final exam = await _examRepo.getById(examId);
    final cls = await _classRepo.getById(classId);

    // Check if subject exists in the exam
    final examSubjects = await _examRepo.getExamSubjects(examId);
    final examSubjectDetails = examSubjects
        .cast<ExamSubjectWithDetails?>()
        .firstWhere((es) => es?.subject.id == subjectId, orElse: () => null);

    if (exam == null || cls == null || examSubjectDetails == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam, Class, or Subject not found')),
        );
      }
      return;
    }

    final students = await _studentRepo.search(
      StudentFilters(classId: classId, limit: 0), // No limit
    );
    final userMap = {for (var s in students) s.student.id: s};

    // Get marks for this exam subject
    final marks = await _marksRepo.getMarksForExamSubject(
      examId: examId,
      examSubjectId: examSubjectDetails.examSubject.id,
      classId: classId,
    );

    // Calculate stats
    double totalMarks = 0;
    double maxObtained = 0;
    double minObtained = examSubjectDetails.examSubject.maxMarks;
    int presentCount = 0;

    for (final mark in marks) {
      if (!mark.isAbsent && mark.marksObtained != null) {
        totalMarks += mark.marksObtained!;
        if (mark.marksObtained! > maxObtained) {
          maxObtained = mark.marksObtained!;
        }
        if (mark.marksObtained! < minObtained) {
          minObtained = mark.marksObtained!;
        }
        presentCount++;
      }
    }

    final average = presentCount > 0 ? totalMarks / presentCount : 0.0;

    final pdf = pw.Document(
      theme: await PdfHelper.getPdfTheme(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildPdfHeader(
          schoolSettings,
          'Subject Analysis: ${examSubjectDetails.subject.name}',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          _buildInfoRow('Exam', exam.name),
          _buildInfoRow('Class', cls.name),
          pw.SizedBox(height: 10),
          _buildInfoRow(
            'Max Marks',
            examSubjectDetails.examSubject.maxMarks.toString(),
          ),
          _buildInfoRow(
            'Passing Marks',
            examSubjectDetails.examSubject.passingMarks.toString(),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Total Students', students.length.toString()),
          _buildInfoRow('Present', presentCount.toString()),
          _buildInfoRow('Absent', (students.length - presentCount).toString()),
          pw.SizedBox(height: 10),
          _buildInfoRow('Average Marks', average.toStringAsFixed(1)),
          _buildInfoRow('Highest Marks', maxObtained.toString()),
          _buildInfoRow('Lowest Marks', minObtained.toString()),

          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            headers: ['Roll No', 'Name', 'Obtained', 'Status', '%', 'Grade'],
            data: marks
                .map((m) {
                  final student = userMap[m.student.id];
                  if (student == null) return [];

                  final obtained = m.marksObtained ?? 0;
                  final percentage =
                      (examSubjectDetails.examSubject.maxMarks > 0)
                      ? (obtained / examSubjectDetails.examSubject.maxMarks) *
                            100
                      : 0.0;
                  final grade = _calculateGrade(percentage);

                  return [
                    student.currentEnrollment?.rollNumber ?? '-',
                    student.student.studentName,
                    m.isAbsent ? 'Absent' : obtained.toString(),
                    m.isAbsent
                        ? 'Absent'
                        : (obtained >=
                                  examSubjectDetails.examSubject.passingMarks
                              ? 'Pass'
                              : 'Fail'),
                    m.isAbsent ? '-' : '${percentage.toStringAsFixed(1)}%',
                    m.isAbsent ? '-' : grade,
                  ];
                })
                .where((row) => row.isNotEmpty)
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE3E3E3),
            ),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await _printOrSave(
      context,
      pdf,
      'subject_analysis_${examSubjectDetails.subject.name}',
    );
  }

  Future<void> generateTeacherSubjectReport(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final schoolSettings = await _db.getSchoolSettings();
      final teachers = await _staffRepo.getTeachers();

      final pdf = pw.Document(
        theme: await PdfHelper.getPdfTheme(),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) =>
              _buildPdfHeader(schoolSettings, 'Teacher-Subject Assignment'),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Teacher Name', 'Employee ID', 'Status'],
              data: teachers.asMap().entries.map((e) {
                final s = e.value;
                return [
                  '${e.key + 1}',
                  s.fullName,
                  s.staff.employeeId,
                  s.staff.status,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3E3E3),
              ),
              cellPadding: const pw.EdgeInsets.all(4),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      await _printOrSave(context, pdf, 'teacher_subject_assignment');
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  Future<void> generateSubjectAssignmentReport(
    BuildContext context, {
    required bool byTeacher,
    int? classId,
    int? sectionId,
    bool exportExcel = false,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final schoolSettings = await _db.getSchoolSettings();
      final academicYearRow = await _db.getCurrentAcademicYear();
      final academicYear =
          academicYearRow?.name ?? DateTime.now().year.toString();

      if (!context.mounted) return;

      if (byTeacher) {
        await _generateSubjectAssignmentByTeacher(
          context,
          schoolSettings,
          academicYear,
          exportExcel,
        );
      } else {
        await _generateSubjectAssignmentByClass(
          context,
          schoolSettings,
          academicYear,
          classId,
          sectionId,
          exportExcel,
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  Future<void> _generateSubjectAssignmentByTeacher(
    BuildContext context,
    SchoolSetting? schoolSettings,
    String academicYear,
    bool exportExcel,
  ) async {
    // Get all teachers with their assignments
    final teachers = await _staffRepo.getTeachers();
    final assignmentRepo = StaffAssignmentRepositoryImpl(_db);

    // Build data
    final teacherAssignments = <Map<String, dynamic>>[];
    for (final teacher in teachers) {
      final assignments = await assignmentRepo.getByStaff(teacher.staff.id);
      teacherAssignments.add({'teacher': teacher, 'assignments': assignments});
    }

    // Sort by employee ID
    teacherAssignments.sort(
      (a, b) => (a['teacher'] as StaffWithRole).staff.employeeId.compareTo(
        (b['teacher'] as StaffWithRole).staff.employeeId,
      ),
    );

    if (exportExcel) {
      // Generate Excel
      final excel = ExcelHelper.createWorkbook();
      final sheet = excel.sheets.values.first;

      // Title
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
      );
      ExcelHelper.setCell(sheet, 0, 0, 'SUBJECT ASSIGNMENTS BY TEACHER');
      sheet
          .cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          )
          .cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      ExcelHelper.setCell(sheet, 0, 1, 'Academic Year: $academicYear');

      // Headers
      ExcelHelper.addHeader(sheet, [
        'Employee ID',
        'Teacher Name',
        'Class',
        'Subject',
        'Type',
      ], rowIndex: 3);

      int row = 4;
      for (final data in teacherAssignments) {
        final teacher = data['teacher'] as StaffWithRole;
        final assignments =
            data['assignments'] as List<StaffAssignmentWithDetails>;

        if (assignments.isEmpty) {
          ExcelHelper.setCell(sheet, 0, row, teacher.staff.employeeId);
          ExcelHelper.setCell(sheet, 1, row, teacher.fullName);
          ExcelHelper.setCell(sheet, 2, row, '-');
          ExcelHelper.setCell(sheet, 3, row, 'No Assignments');
          ExcelHelper.setCell(sheet, 4, row, '-');
          row++;
        } else {
          for (final assignment in assignments) {
            ExcelHelper.setCell(sheet, 0, row, teacher.staff.employeeId);
            ExcelHelper.setCell(sheet, 1, row, teacher.fullName);
            ExcelHelper.setCell(sheet, 2, row, assignment.classSection);
            ExcelHelper.setCell(sheet, 3, row, assignment.subject.name);
            ExcelHelper.setCell(
              sheet,
              4,
              row,
              assignment.assignment.isClassTeacher
                  ? 'Class Teacher'
                  : 'Subject Teacher',
            );
            row++;
          }
        }
      }

      // Auto-fit
      for (int i = 0; i < 5; i++) {
        sheet.setColumnWidth(i, 20);
      }
      sheet.setColumnWidth(1, 25);

      if (context.mounted) {
        await ExcelHelper.saveExcel(
          context,
          excel,
          'subject_assignments_by_teacher',
        );
      }
    } else {
      // Generate PDF
      final pdf = pw.Document(
        theme: await PdfHelper.getPdfTheme(),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildPdfHeader(
            schoolSettings,
            'Subject Assignments by Teacher - $academicYear',
          ),
          footer: (context) => _buildPdfFooter(context),
          build: (context) {
            final content = <pw.Widget>[];

            for (final data in teacherAssignments) {
              final teacher = data['teacher'] as StaffWithRole;
              final assignments =
                  data['assignments'] as List<StaffAssignmentWithDetails>;

              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Teacher Header
                      pw.Row(
                        children: [
                          pw.Text(
                            '${teacher.staff.employeeId} - ${teacher.fullName}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '(${teacher.staff.designation})',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),

                      // Assignments
                      if (assignments.isEmpty)
                        pw.Text(
                          'No subject assignments',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey600,
                          ),
                        )
                      else
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100,
                              ),
                              children: [
                                _buildTableCell('Class', isHeader: true),
                                _buildTableCell('Subject', isHeader: true),
                                _buildTableCell('Role', isHeader: true),
                              ],
                            ),
                            ...assignments.map(
                              (a) => pw.TableRow(
                                children: [
                                  _buildTableCell(a.classSection),
                                  _buildTableCell(a.subject.name),
                                  _buildTableCell(
                                    a.assignment.isClassTeacher
                                        ? 'Class Teacher'
                                        : 'Subject Teacher',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }

            return content;
          },
        ),
      );

      if (context.mounted) {
        await _printOrSave(context, pdf, 'subject_assignments_by_teacher');
      }
    }
  }

  Future<void> _generateSubjectAssignmentByClass(
    BuildContext context,
    SchoolSetting? schoolSettings,
    String academicYear,
    int? classId,
    int? sectionId,
    bool exportExcel,
  ) async {
    final assignmentRepo = StaffAssignmentRepositoryImpl(_db);
    final List<SchoolClass> classes;

    if (classId != null) {
      final cls = await _classRepo.getById(classId);
      classes = cls != null ? [cls] : [];
    } else {
      classes = await _classRepo.getAll();
    }

    if (classes.isEmpty) {
      throw Exception('No classes found');
    }

    // Build data
    final classAssignments = <Map<String, dynamic>>[];
    for (final cls in classes) {
      final sections = await _sectionRepo.getByClass(cls.id);

      if (sectionId != null) {
        final section = sections.firstWhere(
          (s) => s.id == sectionId,
          orElse: () => sections.first,
        );
        final assignments = await assignmentRepo.getByClass(
          cls.id,
          sectionId: section.id,
        );
        classAssignments.add({
          'class': cls,
          'section': section,
          'assignments': assignments,
        });
      } else {
        for (final section in sections) {
          final assignments = await assignmentRepo.getByClass(
            cls.id,
            sectionId: section.id,
          );
          classAssignments.add({
            'class': cls,
            'section': section,
            'assignments': assignments,
          });
        }
      }
    }

    // Sort by class name (numerically) then section
    classAssignments.sort((a, b) {
      final classA = a['class'] as SchoolClass;
      final classB = b['class'] as SchoolClass;

      // Extract numeric parts from class names
      final aMatch = RegExp(r'\d+').firstMatch(classA.name);
      final bMatch = RegExp(r'\d+').firstMatch(classB.name);

      int classCompare;
      if (aMatch != null && bMatch != null) {
        // Both have numbers, compare numerically
        final aNum = int.parse(aMatch.group(0)!);
        final bNum = int.parse(bMatch.group(0)!);
        classCompare = aNum.compareTo(bNum);
      } else if (aMatch != null) {
        classCompare = -1;
      } else if (bMatch != null) {
        classCompare = 1;
      } else {
        classCompare = classA.name.compareTo(classB.name);
      }

      if (classCompare != 0) return classCompare;

      // Sort sections numerically as well
      final sectionA = a['section'] as Section;
      final sectionB = b['section'] as Section;
      final sectionAMatch = RegExp(r'\d+').firstMatch(sectionA.name);
      final sectionBMatch = RegExp(r'\d+').firstMatch(sectionB.name);

      if (sectionAMatch != null && sectionBMatch != null) {
        return int.parse(sectionAMatch.group(0)!).compareTo(
          int.parse(sectionBMatch.group(0)!),
        );
      } else if (sectionAMatch != null) {
        return -1;
      } else if (sectionBMatch != null) {
        return 1;
      } else {
        return sectionA.name.compareTo(sectionB.name);
      }
    });

    if (exportExcel) {
      // Generate Excel
      final excel = ExcelHelper.createWorkbook();
      final sheet = excel.sheets.values.first;

      // Title
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
      );
      ExcelHelper.setCell(sheet, 0, 0, 'SUBJECT ASSIGNMENTS BY CLASS');
      sheet
          .cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          )
          .cellStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      ExcelHelper.setCell(sheet, 0, 1, 'Academic Year: $academicYear');

      // Headers
      ExcelHelper.addHeader(sheet, [
        'Class',
        'Section',
        'Subject',
        'Teacher',
        'Role',
      ], rowIndex: 3);

      int row = 4;
      for (final data in classAssignments) {
        final cls = data['class'] as SchoolClass;
        final section = data['section'] as Section;
        final assignments =
            data['assignments'] as List<StaffAssignmentWithDetails>;

        if (assignments.isEmpty) {
          ExcelHelper.setCell(sheet, 0, row, cls.name);
          ExcelHelper.setCell(sheet, 1, row, section.name);
          ExcelHelper.setCell(sheet, 2, row, '-');
          ExcelHelper.setCell(sheet, 3, row, 'No Assignments');
          ExcelHelper.setCell(sheet, 4, row, '-');
          row++;
        } else {
          for (final assignment in assignments) {
            ExcelHelper.setCell(sheet, 0, row, cls.name);
            ExcelHelper.setCell(sheet, 1, row, section.name);
            ExcelHelper.setCell(sheet, 2, row, assignment.subject.name);
            ExcelHelper.setCell(
              sheet,
              3,
              row,
              '${assignment.staff.firstName} ${assignment.staff.lastName}',
            );
            ExcelHelper.setCell(
              sheet,
              4,
              row,
              assignment.assignment.isClassTeacher
                  ? 'Class Teacher'
                  : 'Subject Teacher',
            );
            row++;
          }
        }
      }

      // Auto-fit
      for (int i = 0; i < 5; i++) {
        sheet.setColumnWidth(i, 18);
      }
      sheet.setColumnWidth(3, 25);

      if (context.mounted) {
        await ExcelHelper.saveExcel(
          context,
          excel,
          'subject_assignments_by_class',
        );
      }
    } else {
      // Generate PDF
      final pdf = pw.Document(
        theme: await PdfHelper.getPdfTheme(),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildPdfHeader(
            schoolSettings,
            'Subject Assignments by Class - $academicYear',
          ),
          footer: (context) => _buildPdfFooter(context),
          build: (context) {
            final content = <pw.Widget>[];

            for (final data in classAssignments) {
              final cls = data['class'] as SchoolClass;
              final section = data['section'] as Section;
              final assignments =
                  data['assignments'] as List<StaffAssignmentWithDetails>;

              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Class Header
                      pw.Text(
                        '${cls.name} - Section ${section.name}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 4),

                      // Assignments
                      if (assignments.isEmpty)
                        pw.Text(
                          'No subject assignments',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey600,
                          ),
                        )
                      else
                        pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300),
                          children: [
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey100,
                              ),
                              children: [
                                _buildTableCell('Subject', isHeader: true),
                                _buildTableCell('Teacher', isHeader: true),
                                _buildTableCell('Role', isHeader: true),
                              ],
                            ),
                            ...assignments.map(
                              (a) => pw.TableRow(
                                children: [
                                  _buildTableCell(a.subject.name),
                                  _buildTableCell(
                                    '${a.staff.firstName} ${a.staff.lastName}',
                                  ),
                                  _buildTableCell(
                                    a.assignment.isClassTeacher
                                        ? 'Class Teacher'
                                        : 'Subject Teacher',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }

            return content;
          },
        ),
      );

      if (context.mounted) {
        await _printOrSave(context, pdf, 'subject_assignments_by_class');
      }
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  static pw.Widget _buildPdfHeader(SchoolSetting? settings, String title) {
    // Build logo image if available
    pw.Widget? logoWidget;
    if (settings?.logo != null && settings!.logo!.isNotEmpty) {
      try {
        final logoImage = pw.MemoryImage(Uint8List.fromList(settings.logo!));
        logoWidget = pw.Image(
          logoImage,
          width: 50,
          height: 50,
          fit: pw.BoxFit.contain,
        );
      } catch (_) {
        // If logo parsing fails, skip it
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 1, color: PdfColor.fromInt(0xFFCCCCCC)),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 12)],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings?.schoolName ?? 'EduX School',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (settings?.address != null)
                  pw.Text(
                    '${settings!.address}${settings.city != null ? ", ${settings.city}" : ""}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (settings?.phone != null)
                  pw.Text(
                    'Phone: ${settings!.phone}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColor.fromInt(0xFFCCCCCC)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'EduX School Management System',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
    PdfColor? color,
  }) {
    return pw.Container(
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft),
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Future<void> _printOrSave(
    BuildContext context,
    pw.Document pdf,
    String filename, {
    VoidCallback? onExportExcel,
  }) async {
    final bytes = await pdf.save();
    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        bytes,
        filename,
        onExportExcel: onExportExcel,
      );
    }
  }

  /// Get day name from weekday number (1-7, Monday-Sunday)
  static String _getDayName(int weekday) {
    const days = [
      '',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday];
  }
}

/// DTO for Monthly Attendance Report
class MonthlyAttendanceReportData {
  final SchoolSetting? schoolSettings;
  final String className;
  final String sectionName;
  final int month;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final List<StudentWithEnrollment> students;
  final Map<int, Map<int, String>> attendanceMap;
  final List<String> workingDays;
  final List<int> workingDates;

  MonthlyAttendanceReportData({
    this.schoolSettings,
    required this.className,
    required this.sectionName,
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.students,
    required this.attendanceMap,
    this.workingDays = const [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
    ],
    this.workingDates = const [],
  });
}

/// Provider for report service
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(AppDatabase.instance);
});
