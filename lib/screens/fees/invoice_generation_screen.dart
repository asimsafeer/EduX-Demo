/// EduX School Management System
/// Invoice Generation Screen - Bulk generate monthly invoices
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart' hide currentAcademicYearProvider;
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/utils/pdf_helper.dart';

class InvoiceGenerationScreen extends ConsumerStatefulWidget {
  final int? studentId;

  const InvoiceGenerationScreen({super.key, this.studentId});

  @override
  ConsumerState<InvoiceGenerationScreen> createState() =>
      _InvoiceGenerationScreenState();
}

class _InvoiceGenerationScreenState
    extends ConsumerState<InvoiceGenerationScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Set default month to current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final defaultMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.read(invoiceGenerationProvider.notifier).setMonth(defaultMonth);

      // Set default due date (15th of next month or so)
      final defaultDueDate = DateTime(now.year, now.month + 1, 15);
      ref.read(invoiceGenerationProvider.notifier).setDueDate(defaultDueDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceGenerationProvider);
    final asyncClasses = ref.watch(classesProvider);
    final academicYear = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Invoices')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            _buildInfoCard(academicYear),
            const SizedBox(height: 24),

            // Month selection
            _buildMonthSelector(state),
            const SizedBox(height: 16),

            // Due date selection
            _buildDueDateSelector(state),
            const SizedBox(height: 16),

            // Class filter (optional)
            _buildClassFilter(asyncClasses, state),
            const SizedBox(height: 24),

            // Preview/Summary
            if (state.classId != null) _buildPreview(state),
            const SizedBox(height: 24),

            // Generate button
            _buildGenerateButton(state),

            // Results
            if (state.result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(state.result!),
            ],

            // Error
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String academicYear) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Invoice Generation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Generate invoices for all active students. Existing invoices will be skipped.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Academic Year: $academicYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(InvoiceGenerationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Month *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: state.month,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: const Icon(Icons.calendar_month),
          ),
          items: _generateMonthOptions(),
          onChanged: (value) {
            ref.read(invoiceGenerationProvider.notifier).setMonth(value);
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _generateMonthOptions() {
    final now = DateTime.now();
    final options = <DropdownMenuItem<String>>[];

    // Generate months for past 3 months and next 2 months
    for (int i = -3; i <= 2; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final value = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final label = DateFormat('MMMM yyyy').format(date);

      options.add(DropdownMenuItem(value: value, child: Text(label)));
    }

    return options;
  }

  Widget _buildDueDateSelector(InvoiceGenerationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Due Date *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDueDate(state),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.event),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              state.dueDate != null
                  ? DateFormat('dd MMMM yyyy').format(state.dueDate!)
                  : 'Select due date',
              style: TextStyle(
                color: state.dueDate != null ? null : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDueDate(InvoiceGenerationState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          state.dueDate ?? DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      ref.read(invoiceGenerationProvider.notifier).setDueDate(date);
    }
  }

  Widget _buildClassFilter(
    AsyncValue<List<dynamic>> asyncClasses,
    InvoiceGenerationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Leave empty to generate for all classes',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        asyncClasses.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading classes: $e'),
          data: (classes) => DropdownButtonFormField<int?>(
            initialValue: state.classId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.school),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Classes'),
              ),
              ...classes.map(
                (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (value) {
              ref.read(invoiceGenerationProvider.notifier).setClassId(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(InvoiceGenerationState state) {
    final asyncSummaries = ref.watch(classFeeSummariesProvider);

    return asyncSummaries.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (summaries) {
        if (summaries.isEmpty) return const SizedBox.shrink();
        final classSummary = summaries.firstWhere(
          (s) => s.classId == state.classId,
          orElse: () => summaries.first,
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.preview, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Invoice Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPreviewRow('Class', classSummary.className),
                _buildPreviewRow(
                  'Monthly Fee',
                  _currencyFormat.format(classSummary.totalMonthlyFee),
                ),
                _buildPreviewRow(
                  'Fee Types',
                  '${classSummary.structures.length} configured',
                ),
                if (state.month != null)
                  _buildPreviewRow('Invoice Month', _formatMonth(state.month!)),
                if (state.dueDate != null)
                  _buildPreviewRow(
                    'Due Date',
                    DateFormat('dd MMM yyyy').format(state.dueDate!),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(InvoiceGenerationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isGenerating || !state.isValid
            ? null
            : () => _generateInvoices(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Generating Invoices...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long),
                  const SizedBox(width: 8),
                  Text(
                    state.classId != null
                        ? 'Generate Invoices for Class'
                        : 'Generate Invoices for All Classes',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultCard(dynamic result) {
    final isSuccess = result.successCount > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSuccess ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.warning,
              color: isSuccess ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess
                  ? 'Invoices Generated Successfully!'
                  : 'Generation Completed with Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green[800] : Colors.orange[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultStat(
                  'Total',
                  result.totalStudents.toString(),
                  Colors.blue,
                ),
                _buildResultStat(
                  'Generated',
                  result.successCount.toString(),
                  Colors.green,
                ),
                _buildResultStat(
                  'Skipped',
                  result.skippedCount.toString(),
                  Colors.grey,
                ),
                _buildResultStat(
                  'Errors',
                  result.errorCount.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Amount: ${_currencyFormat.format(result.totalAmount)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'View Errors (${result.errors.length})',
                  style: const TextStyle(color: Colors.red),
                ),
                children: result.errors
                    .take(10)
                    .map<Widget>(
                      (e) => ListTile(
                        leading: const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 16,
                        ),
                        title: Text(e, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (result.generatedInvoiceIds.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _printInvoices(result.generatedInvoiceIds),
                  icon: const Icon(Icons.print),
                  label: Text(
                    'Print Invoices (${result.generatedInvoiceIds.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatMonth(String month) {
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMMM yyyy').format(date);
      }
    } catch (_) {}
    return month;
  }

  Future<void> _printInvoices(List<int> invoiceIds) async {
    if (!mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final receiptService = ref.read(receiptServiceProvider);
      final pdfBytes = await receiptService.generateFullInvoiceSlips(invoiceIds);

      nav.pop(); // close loading dialog
      if (mounted) {
        await PdfHelper.previewPdf(context, pdfBytes, 'Invoice Slips');
      }
    } catch (e) {
      nav.pop(); // close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateInvoices() async {
    final success = await ref
        .read(invoiceGenerationProvider.notifier)
        .generateInvoices();

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Invoices generated successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
