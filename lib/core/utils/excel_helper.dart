/// EduX School Management System
/// Excel Helper - Utilities for generating and saving Excel files
library;

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ExcelHelper {
  ExcelHelper._();

  /// Create a new Excel workbook
  static Excel createWorkbook() {
    return Excel.createExcel();
  }

  /// Save Excel file to user-chosen location
  static Future<bool> saveExcel(
    BuildContext context,
    Excel excel,
    String defaultName,
  ) async {
    try {
      final List<int>? fileBytes = excel.save();

      if (fileBytes == null) {
        throw Exception('Failed to generate Excel data');
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel Report',
        fileName: '$defaultName.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(fileBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel file saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Excel file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Helper to add a header row with styling
  static void addHeader(Sheet sheet, List<String> headers, {int rowIndex = 0}) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromInt(0xFFCCCCCC),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
  }

  /// Helper to specific cell value
  static void setCell(Sheet sheet, int col, int row, dynamic value) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    if (value is String) {
      cell.value = TextCellValue(value);
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is bool) {
      cell.value = BoolCellValue(value);
    } else if (value != null) {
      cell.value = TextCellValue(value.toString());
    }
  }
}
