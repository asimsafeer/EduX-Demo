import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/core.dart';
import '../services/print_settings_service.dart';

class PrintSettingsScreen extends ConsumerStatefulWidget {
  const PrintSettingsScreen({super.key});

  @override
  ConsumerState<PrintSettingsScreen> createState() =>
      _PrintSettingsScreenState();
}

class _PrintSettingsScreenState extends ConsumerState<PrintSettingsScreen> {
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(printSettingsProvider);
    _footerController = TextEditingController(text: settings.footerText);
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printSettingsProvider);
    final notifier = ref.read(printSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Print Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Paper Configuration'),
            const SizedBox(height: 16),

            // Paper Size
            _buildSettingCard(
              title: 'Default Paper Size',
              subtitle: 'Select the paper size for receipts and reports',
              icon: LucideIcons.fileText,
              trailing: DropdownButton<String>(
                value: settings.paperSize,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'a4', child: Text('A4 (Standard)')),
                  DropdownMenuItem(value: 'a5', child: Text('A5 (Half A4)')),
                  DropdownMenuItem(value: 'letter', child: Text('Letter (US)')),
                  DropdownMenuItem(value: 'legal', child: Text('Legal (US)')),
                  DropdownMenuItem(value: 'b5', child: Text('B5')),
                  DropdownMenuItem(
                    value: 'thermal_80',
                    child: Text('Thermal 80mm'),
                  ),
                  DropdownMenuItem(
                    value: 'thermal_58',
                    child: Text('Thermal 58mm'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    notifier.setPaperSize(value);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Receipt Format'),
            const SizedBox(height: 16),

            // Show Header
            SwitchListTile(
              title: const Text('Show Header'),
              subtitle: const Text(
                'Include school logo and details at the top',
              ),
              value: settings.showHeader,
              onChanged: (value) {
                notifier.updateSettings(settings.copyWith(showHeader: value));
              },
              secondary: const Icon(LucideIcons.heading),
            ),
            const Divider(),

            // Show Footer
            SwitchListTile(
              title: const Text('Show Footer'),
              subtitle: const Text('Include custom message at the bottom'),
              value: settings.showFooter,
              onChanged: (value) {
                notifier.updateSettings(settings.copyWith(showFooter: value));
              },
              secondary: const Icon(LucideIcons.footprints),
            ),

            if (settings.showFooter) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _footerController,
                decoration: const InputDecoration(
                  labelText: 'Footer Text',
                  hintText: 'Enter custom footer message',
                  border: OutlineInputBorder(),
                  helperText: 'This text will appear at the bottom of receipts',
                ),
                maxLines: 2,
                onChanged: (value) {
                  notifier.updateFooterText(value);
                },
              ),
            ],

            const SizedBox(height: 32),
            Center(
              child: FilledButton.icon(
                onPressed: () => _printTestPage(context, settings),
                icon: const Icon(LucideIcons.printer),
                label: const Text('Design Test Print'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _printTestPage(
    BuildContext context,
    PrintSettings settings,
  ) async {
    final pdf = pw.Document();

    // Determine page format based on setting
    final pageFormat = switch (settings.paperSize) {
      'a5' => PdfPageFormat.a5,
      'letter' => PdfPageFormat.letter,
      'legal' => PdfPageFormat.legal,
      'b5' => const PdfPageFormat(
        176 * PdfPageFormat.mm,
        250 * PdfPageFormat.mm,
      ),
      'thermal_80' => PdfPageFormat.roll80,
      'thermal_58' => const PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
      ),
      _ => PdfPageFormat.a4,
    };

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (settings.showHeader) ...[
                pw.Text(
                  'SCHOOL NAME',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Address Line 1, City'),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),
              ],

              pw.Text(
                'TEST PRINT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Paper Size: ${_paperSizeLabel(settings.paperSize)}'),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${DateTime.now().toString().split('.')[0]}'),
              pw.SizedBox(height: 16),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Center(child: pw.Text('Print Area Preview')),
              ),

              if (settings.showFooter) ...[
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Text(
                  settings.footerText,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    if (context.mounted) {
      await PdfHelper.previewPdf(context, bytes, 'test_print.pdf');
    }
  }

  String _paperSizeLabel(String size) {
    return switch (size) {
      'a4' => 'A4 (Standard)',
      'a5' => 'A5 (Half A4)',
      'letter' => 'Letter (US)',
      'legal' => 'Legal (US)',
      'b5' => 'B5',
      'thermal_80' => 'Thermal 80mm',
      'thermal_58' => 'Thermal 58mm',
      _ => size.toUpperCase(),
    };
  }
}
