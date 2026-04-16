/// EduX School Management System
/// Staff Export Service - PDF and Excel export functionality
library;

import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;

import '../repositories/staff_repository.dart';

/// Staff export service for PDF and Excel generation
class StaffExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Export staff list to Excel
  Future<List<int>> exportStaffListExcel(List<StaffWithRole> staffList) async {
    final excel = xl.Excel.createExcel();

    // Use default sheet
    final sheet = excel.sheets.values.first;

    // Header style
    final headerStyle = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.green100,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    // Headers
    final headers = [
      'S.No',
      'Employee ID',
      'Name',
      'Role',
      'Designation',
      'Department',
      'Phone',
      'Email',
      'Gender',
      'Status',
      'Joining Date',
      'Basic Salary',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = xl.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (int i = 0; i < staffList.length; i++) {
      final s = staffList[i];
      final staff = s.staff;
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
        staff.employeeId,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        '${staff.firstName} ${staff.lastName}',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        s.role.name,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        staff.designation,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        staff.department ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        staff.phone,
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        staff.email ?? '',
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _capitalize(staff.gender),
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _capitalize(staff.status),
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex),
          )
          .value = xl.TextCellValue(
        _dateFormat.format(staff.joiningDate),
      );
      sheet
          .cell(
            xl.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex),
          )
          .value = xl.DoubleCellValue(
        staff.basicSalary,
      );
    }

    // Auto-fit columns (approximate)
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
    sheet.setColumnWidth(2, 25); // Name
    sheet.setColumnWidth(7, 30); // Email

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw Exception('Failed to encode Excel file - output is empty');
    }
    return encoded;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
