/// EduX School Management System
/// Invoices List Screen - View and manage all invoices
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/status_extensions.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../repositories/invoice_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import 'widgets/invoice_card.dart';

import '../../core/utils/pdf_helper.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );



  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(invoiceFiltersProvider);
    final asyncInvoices = ref.watch(invoicesListProvider);
    final asyncClasses = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: Badge(
              isLabelVisible: _hasActiveFilters(filters),
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filters',
          ),
          IconButton(
            onPressed: () async {
              final invoices = asyncInvoices.value;
              if (invoices == null || invoices.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No invoices to export')),
                );
                return;
              }

              try {
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
                final pdfBytes = await exportService.generateInvoiceListPdf(
                  invoices,
                  school,
                  'Invoices List',
                );

                if (context.mounted) {
                  await PdfHelper.previewPdf(
                    context,
                    pdfBytes,
                    'Invoices_List',
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
            tooltip: 'Export List',
          ),
          IconButton(
            onPressed: () => ref.invalidate(invoicesListProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick filters
          _buildQuickFilters(filters, asyncClasses),

          // Stats summary
          _buildStatsSummary(),

          // Invoice list
          Expanded(
            child: asyncInvoices.when(
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildInvoiceList(invoices);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fees/invoices/generate'),
        icon: const Icon(Icons.add),
        label: const Text('Generate'),
      ),
    );
  }

  Widget _buildQuickFilters(
    InvoiceFilters filters,
    AsyncValue<List<dynamic>> asyncClasses,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status filter chips
            ...FeeConstants.invoiceStatuses.map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: filters.status == status,
                  label: Text(StatusHelpers.capitalize(status)),
                  onSelected: (selected) {
                    ref
                        .read(invoiceFiltersProvider.notifier)
                        .setStatus(selected ? status : null);
                  },
                  avatar: Icon(
                    status.invoiceStatusIcon,
                    size: 18,
                    color: filters.status == status
                        ? Colors.white
                        : status.invoiceStatusColor,
                  ),
                  selectedColor: status.invoiceStatusColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: filters.status == status
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Class filter dropdown
            asyncClasses.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (classes) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: filters.classId,
                    hint: const Text('All Classes'),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(invoiceFiltersProvider.notifier)
                          .setClassId(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final asyncStats = ref.watch(invoiceStatsProvider);

    return asyncStats.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat(
              'Total',
              stats.totalCount.toString(),
              _currencyFormat.format(stats.totalAmount),
              Colors.blue,
            ),
            _buildMiniStat(
              'Pending',
              stats.pendingCount.toString(),
              _currencyFormat.format(stats.pendingAmount),
              Colors.orange,
            ),
            _buildMiniStat(
              'Collected',
              '',
              _currencyFormat.format(stats.paidAmount),
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String count,
    String amount,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (count.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Invoices Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate invoices to see them here',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/fees/invoices/generate'),
            icon: const Icon(Icons.add),
            label: const Text('Generate Invoices'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(List<InvoiceWithDetails> invoices) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(invoicesListProvider);
      },
      child: ListView.builder(
        itemCount: invoices.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return InvoiceCard(
            invoice: invoice,
            onTap: () {
              context.pushNamed(
                'invoice-details',
                pathParameters: {'id': invoice.invoice.id.toString()},
              );
            },
            onPay: () {
              context.pushNamed(
                'collect-payment',
                queryParameters: {'invoiceId': invoice.invoice.id.toString()},
              );
              // Refresh list after returning from payment to ensure UI is in sync
              ref.invalidate(invoicesListProvider);
              ref.invalidate(invoiceStatsProvider);
            },
            onPrint: () => _printInvoiceSlip(invoice.invoice.id),
          );
        },
      ),
    );
  }

  Future<void> _printInvoiceSlip(int invoiceId) async {
    if (!mounted) return;

    final nav = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final receiptService = ref.read(receiptServiceProvider);
      final pdfBytes = await receiptService.generateFullInvoiceSlips([invoiceId]);

      nav.pop(); // close loading dialog
      if (mounted) {
        await PdfHelper.previewPdf(context, pdfBytes, 'Invoice_Slip');
      }
    } catch (e) {
      nav.pop(); // close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasActiveFilters(InvoiceFilters filters) {
    return filters.status != null ||
        filters.classId != null ||
        filters.studentId != null ||
        filters.month != null;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) =>
            _buildFilterContent(scrollController),
      ),
    );
  }

  Widget _buildFilterContent(ScrollController scrollController) {
    // final filters = ref.watch(invoiceFiltersProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ref.read(invoiceFiltersProvider.notifier).resetFilters();
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Add more filter options here as needed
        const Text('Additional filter options can be added here.'),
      ],
    );
  }
}
