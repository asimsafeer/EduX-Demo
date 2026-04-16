/// EduX School Management System
/// Generic Invoice Generation Screen - Generate invoices with selectable fee types
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart' show classesProvider;
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/utils/pdf_helper.dart';
import '../../database/app_database.dart';
import '../../services/invoice_service.dart';

/// Screen for generating generic invoices with selectable fee types
/// Supports both single student and bulk class generation
class GenericInvoiceGenerationScreen extends ConsumerStatefulWidget {
  final int? studentId;
  final String? studentName;

  const GenericInvoiceGenerationScreen({
    super.key,
    this.studentId,
    this.studentName,
  });

  @override
  ConsumerState<GenericInvoiceGenerationScreen> createState() =>
      _GenericInvoiceGenerationScreenState();
}

class _GenericInvoiceGenerationScreenState
    extends ConsumerState<GenericInvoiceGenerationScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Set default values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final defaultMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref
          .read(genericInvoiceGenerationProvider.notifier)
          .setMonth(defaultMonth);

      final defaultDueDate = DateTime(now.year, now.month + 1, 15);
      ref
          .read(genericInvoiceGenerationProvider.notifier)
          .setDueDate(defaultDueDate);

      if (widget.studentId != null) {
        ref
            .read(genericInvoiceGenerationProvider.notifier)
            .setStudentId(widget.studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(genericInvoiceGenerationProvider);
    final asyncClasses = ref.watch(classesProvider);
    final asyncFeeTypes = ref.watch(feeTypesProvider);
    final academicYear = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.studentId != null
              ? 'Generate Invoice - ${widget.studentName}'
              : 'Generic Invoice Generation',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(academicYear),
            const SizedBox(height: 24),
            _buildMonthSelector(state),
            const SizedBox(height: 16),
            _buildDueDateSelector(state),
            const SizedBox(height: 16),
            if (widget.studentId == null) ...[
              _buildClassFilter(asyncClasses, state),
              const SizedBox(height: 24),
            ],
            _buildFeeTypeSelection(asyncFeeTypes, state),
            const SizedBox(height: 24),
            if (state.selectedFeeTypeIds.isNotEmpty)
              _buildPreviewSection(state, asyncFeeTypes),
            const SizedBox(height: 24),
            _buildGenerateButton(state),
            if (state.result != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(state.result!),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(state.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String academicYear) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(LucideIcons.info, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generic Invoice Generation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Select specific fee types to include in the invoice.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
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

  Widget _buildMonthSelector(GenericInvoiceGenerationState state) {
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
            prefixIcon: const Icon(LucideIcons.calendar),
          ),
          items: _generateMonthOptions(),
          onChanged: (value) {
            ref.read(genericInvoiceGenerationProvider.notifier).setMonth(value);
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _generateMonthOptions() {
    final now = DateTime.now();
    final options = <DropdownMenuItem<String>>[];
    for (int i = -3; i <= 2; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final value = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final label = DateFormat('MMMM yyyy').format(date);
      options.add(DropdownMenuItem(value: value, child: Text(label)));
    }
    return options;
  }

  Widget _buildDueDateSelector(GenericInvoiceGenerationState state) {
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
              prefixIcon: const Icon(LucideIcons.calendarDays),
              suffixIcon: const Icon(LucideIcons.chevronDown),
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

  Future<void> _selectDueDate(GenericInvoiceGenerationState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          state.dueDate ?? DateTime.now().add(const Duration(days: 15)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      ref.read(genericInvoiceGenerationProvider.notifier).setDueDate(date);
    }
  }

  Widget _buildClassFilter(
    AsyncValue<List<dynamic>> asyncClasses,
    GenericInvoiceGenerationState state,
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
              prefixIcon: const Icon(LucideIcons.school),
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
              ref
                  .read(genericInvoiceGenerationProvider.notifier)
                  .setClassId(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeeTypeSelection(
    AsyncValue<List<FeeType>> asyncFeeTypes,
    GenericInvoiceGenerationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Fee Types *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () {
                asyncFeeTypes.whenData((feeTypes) {
                  ref
                      .read(genericInvoiceGenerationProvider.notifier)
                      .selectAllFeeTypes(feeTypes.map((f) => f.id).toList());
                });
              },
              icon: const Icon(LucideIcons.checkSquare, size: 16),
              label: const Text('Select All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose which fee types to include in the invoice',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        asyncFeeTypes.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => Text('Error loading fee types: $e'),
          data: (feeTypes) {
            if (feeTypes.isEmpty) {
              return Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(child: Text('No fee types configured.')),
                    ],
                  ),
                ),
              );
            }
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Column(
                children: feeTypes.map((feeType) {
                  final isSelected = state.selectedFeeTypeIds.contains(
                    feeType.id,
                  );
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) {
                      ref
                          .read(genericInvoiceGenerationProvider.notifier)
                          .toggleFeeType(feeType.id);
                    },
                    title: Text(feeType.name),
                    subtitle: feeType.description != null
                        ? Text(
                            feeType.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    secondary: Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        if (state.selectedFeeTypeIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${state.selectedFeeTypeIds.length} fee type(s) selected',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewSection(
    GenericInvoiceGenerationState state,
    AsyncValue<List<FeeType>> asyncFeeTypes,
  ) {
    return asyncFeeTypes.when(
      data: (feeTypes) {
        final selectedFees = feeTypes
            .where((f) => state.selectedFeeTypeIds.contains(f.id))
            .toList();
        return Card(
          elevation: 0,
          color: Colors.blue.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.eye, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Invoice Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selected Fee Types:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...selectedFees.map(
                  (fee) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(fee.name)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGenerateButton(GenericInvoiceGenerationState state) {
    final isSingleStudent = widget.studentId != null;
    final isValid = state.isValid && state.selectedFeeTypeIds.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isGenerating || !isValid
            ? null
            : () => _generateInvoices(isSingleStudent),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: state.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isSingleStudent ? LucideIcons.fileText : LucideIcons.files),
        label: Text(
          state.isGenerating
              ? 'Generating...'
              : isSingleStudent
              ? 'Generate Invoice'
              : 'Generate Invoices for Class',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _generateInvoices(bool isSingleStudent) async {
    final success = isSingleStudent
        ? await ref
              .read(genericInvoiceGenerationProvider.notifier)
              .generateSingleInvoice()
        : await ref
              .read(genericInvoiceGenerationProvider.notifier)
              .generateInvoices();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice(s) generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildResultCard(BulkInvoiceResult result) {
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
              isSuccess ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
              color: isSuccess ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess
                  ? 'Invoices Generated Successfully!'
                  : 'Completed with Issues',
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
                          LucideIcons.alertCircle,
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
                  icon: const Icon(LucideIcons.printer),
                  label: Text(
                    'Print Invoices (${result.generatedInvoiceIds.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
        ],
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
      nav.pop();
      if (mounted) {
        await PdfHelper.previewPdf(context, pdfBytes, 'Invoice Slips');
      }
    } catch (e) {
      nav.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
