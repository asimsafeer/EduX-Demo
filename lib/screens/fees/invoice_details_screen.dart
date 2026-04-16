/// EduX School Management System
/// Invoice Details Screen - Single invoice full view
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/fee_provider.dart';
import '../../repositories/invoice_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

import '../../core/utils/pdf_helper.dart';
import '../../providers/student_provider.dart'; // For school settings

class InvoiceDetailsScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInvoice = ref.watch(invoiceByIdProvider(invoiceId));
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            onPressed: () async {
              final invoice = asyncInvoice.value;
              if (invoice == null) return;

              final nav = Navigator.of(context, rootNavigator: true);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final receiptService = ref.read(receiptServiceProvider);
                final pdfBytes = await receiptService.generateFullInvoiceSlips([
                  invoice.invoice.id,
                ]);

                nav.pop(); // close loading dialog
                if (context.mounted) {
                  await PdfHelper.previewPdf(
                    context,
                    pdfBytes,
                    'Invoice_Slip_${invoice.invoice.invoiceNumber}',
                  );
                }
              } catch (e) {
                nav.pop(); // close loading dialog
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Print Invoice Slip',
          ),
          IconButton(
            onPressed: () async {
              final invoice = asyncInvoice.value;
              if (invoice == null) return;

              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF...')),
                );

                final school = await ref.read(
                  schoolSettingsForExportProvider.future,
                );
                if (school == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('School settings not found'),
                      ),
                    );
                  }
                  return;
                }

                final exportService = ref.read(invoiceExportServiceProvider);
                final pdfBytes = await exportService.generateInvoicePdf(
                  invoice: invoice,
                  school: school,
                );

                if (context.mounted) {
                  await PdfHelper.previewPdf(
                    context,
                    pdfBytes,
                    'Invoice_${invoice.invoice.invoiceNumber}',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
          ),
        ],
      ),
      body: asyncInvoice.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => AppErrorState(message: e.toString()),
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, invoice),
                const SizedBox(height: 16),
                _buildBreakdownCard(context, invoice, currencyFormat),
                const SizedBox(height: 16),
                _buildPaymentsCard(context, invoice, currencyFormat),
                const SizedBox(height: 24),
                if (invoice.invoice.balanceAmount > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          'collect-payment',
                          queryParameters: {
                            'invoiceId': invoice.invoice.id.toString(),
                          },
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Collect Payment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, InvoiceWithDetails invoice) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoice.invoice.invoiceNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(invoice.invoice.status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Student', invoice.studentName, isBold: true),
            const SizedBox(height: 8),
            _buildInfoRow('Class', invoice.classSection),
            const SizedBox(height: 8),
            _buildInfoRow('Month', _formatMonth(invoice.invoice.month)),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Due Date',
              DateFormat('dd MMM yyyy').format(invoice.invoice.dueDate),
              valueColor: _getDueDateColor(invoice.invoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context,
    InvoiceWithDetails invoice,
    NumberFormat currencyFormat,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (invoice.items.isEmpty)
              const Text(
                'No items found',
                style: TextStyle(color: Colors.grey),
              ),
            ...invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.feeType.name),
                    Text(currencyFormat.format(item.item.netAmount)),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Total Amount',
              currencyFormat.format(invoice.invoice.totalAmount),
            ),
            if (invoice.invoice.discountAmount > 0) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Discount',
                '- ${currencyFormat.format(invoice.invoice.discountAmount)}',
                valueColor: Colors.green,
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              'Net Amount',
              currencyFormat.format(invoice.invoice.netAmount),
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Paid Amount',
              currencyFormat.format(invoice.invoice.paidAmount),
              valueColor: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Balance Due',
              currencyFormat.format(invoice.invoice.balanceAmount),
              valueColor: invoice.invoice.balanceAmount > 0
                  ? Colors.red
                  : Colors.green,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsCard(
    BuildContext context,
    InvoiceWithDetails invoice,
    NumberFormat currencyFormat,
  ) {
    if (invoice.payments.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...invoice.payments.map((payment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(payment.paymentDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          payment.paymentMode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(payment.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          payment.receiptNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'paid':
        color = Colors.green;
        break;
      case 'partial':
        color = Colors.orange;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDueDateColor(dynamic invoice) {
    if (invoice.status == 'paid') return Colors.grey;
    if (invoice.dueDate.isBefore(DateTime.now())) return Colors.red;
    if (invoice.dueDate.isBefore(DateTime.now().add(const Duration(days: 7)))) {
      return Colors.orange;
    }
    return Colors.grey;
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
}
