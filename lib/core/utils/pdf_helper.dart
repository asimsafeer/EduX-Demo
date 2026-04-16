/// EduX School Management System
/// PDF Helper - Centralized PDF preview, save, and print utilities
library;

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import '../screens/pdf_preview_screen.dart';

class PdfHelper {
  PdfHelper._();

  /// Async PDF theme with Unicode font support
  /// Use this when creating PDFs to avoid Helvetica/Times warnings
  static Future<pw.ThemeData> getPdfTheme() async {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
      italic: await PdfGoogleFonts.robotoItalic(),
      boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
    );
  }

  /// Show a PDF preview screen with Save and Print options.
  /// This replaces all direct Printing.layoutPdf calls.
  static Future<void> previewPdf(
    BuildContext context,
    Uint8List pdfBytes,
    String documentName, {
    VoidCallback? onExportExcel,
  }) async {
    if (!context.mounted) return;

    // Await the push here so the caller waits until the PDF screen is closed.
    // This prevents the caller from popping the wrong route (like the PDF screen itself)
    // if it tries to close a loading dialog immediately after pushing.
    // Use rootNavigator: true to ensure the PDF screen is pushed above any dialogs
    // or other overlays (like the loading dialog) which are also on the root navigator.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          documentName: documentName,
          onExportExcel: onExportExcel,
        ),
      ),
    );
  }

  /// Safely print a PDF without crashing if user cancels.
  static Future<bool> safePrint(Uint8List pdfBytes, String name) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: name,
      );
      return true;
    } catch (e) {
      debugPrint('Print cancelled or failed: $e');
      return false;
    }
  }

  /// Save PDF to a user-chosen location.
  static Future<bool> savePdf(Uint8List pdfBytes, String defaultName) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '$defaultName.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(pdfBytes);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Save failed: $e');
      return false;
    }
  }

  /// Save any file (PDF, Excel, etc.) to a user-chosen location.
  static Future<bool> saveFile(
    BuildContext context,
    Uint8List bytes,
    String fileName, {
    String dialogTitle = 'Save File',
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [ext],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Save failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Generate PDF preview without context (for services).
  /// Returns bytes for further use.
  static Future<void> previewAndPrint(
    BuildContext context,
    Future<Uint8List> Function() generatePdf,
    String documentName, {
    VoidCallback? onExportExcel,
  }) async {
    try {
      final bytes = await generatePdf();
      if (context.mounted) {
        await previewPdf(
          context,
          bytes,
          documentName,
          onExportExcel: onExportExcel,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
