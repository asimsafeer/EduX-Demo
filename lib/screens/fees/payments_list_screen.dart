/// EduX School Management System
/// Payments List Screen - View all collected payments
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../repositories/payment_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/utils/pdf_helper.dart';

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(paymentFiltersProvider);
    final asyncPayments = ref.watch(paymentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range),
            tooltip: 'Date Range',
          ),
          IconButton(
            onPressed: () => ref.invalidate(paymentsListProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'print_receipts') {
                _printBulkReceipts();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print_receipts',
                child: ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('Print Receipts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          _buildDateRangeIndicator(filters),

          // Quick filters
          _buildQuickFilters(filters),

          // Collection summary
          _buildCollectionSummary(filters),

          // Payments list
          Expanded(
            child: asyncPayments.when(
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (payments) {
                if (payments.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildPaymentsList(payments);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fees/collect-payment'),
        icon: const Icon(Icons.add),
        label: const Text('Collect'),
      ),
    );
  }

  Widget _buildDateRangeIndicator(PaymentFilters filters) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(
            filters.dateFrom != null && filters.dateTo != null
                ? '${dateFormat.format(filters.dateFrom!)} - ${dateFormat.format(filters.dateTo!)}'
                : filters.dateFrom != null
                ? 'From ${dateFormat.format(filters.dateFrom!)}'
                : 'All Dates',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (filters.dateFrom != null)
            TextButton(
              onPressed: () {
                ref
                    .read(paymentFiltersProvider.notifier)
                    .setDateRange(DateTime.now(), DateTime.now());
              },
              child: const Text('Reset to Today'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(PaymentFilters filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All modes chip
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: filters.paymentMode == null,
                label: const Text('All'),
                onSelected: (selected) {
                  if (selected) {
                    ref
                        .read(paymentFiltersProvider.notifier)
                        .setPaymentMode(null);
                  }
                },
              ),
            ),
            // Payment mode filter chips
            ...FeeConstants.paymentModes.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: filters.paymentMode == mode,
                  label: Text(FeeConstants.getPaymentModeDisplayName(mode)),
                  onSelected: (selected) {
                    ref
                        .read(paymentFiltersProvider.notifier)
                        .setPaymentMode(selected ? mode : null);
                  },
                  avatar: Icon(
                    FeeConstants.getPaymentModeIconData(mode),
                    size: 18,
                    color: filters.paymentMode == mode
                        ? Colors.white
                        : FeeConstants.getPaymentModeColor(mode),
                  ),
                  selectedColor: FeeConstants.getPaymentModeColor(mode),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: filters.paymentMode == mode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionSummary(PaymentFilters filters) {
    // Default to today if no date filter is set
    final dateFrom = filters.dateFrom ?? DateTime.now();

    final asyncCollection = ref.watch(
      dailyCollectionProvider(dateFrom),
    );

    return asyncCollection.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (collection) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Collection',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(collection.totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    collection.paymentCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Payments',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Payments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No payments for the selected date range',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/fees/collect-payment'),
            icon: const Icon(Icons.add),
            label: const Text('Collect Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<PaymentWithDetails> payments) {
    // Group payments by date
    final groupedPayments = <String, List<PaymentWithDetails>>{};
    for (final payment in payments) {
      final dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(payment.payment.paymentDate);
      groupedPayments.putIfAbsent(dateKey, () => []).add(payment);
    }

    final sortedDates = groupedPayments.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentsListProvider);
      },
      child: ListView.builder(
        itemCount: sortedDates.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final datePayments = groupedPayments[dateKey]!;
          final date = DateTime.parse(dateKey);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _isToday(date)
                          ? 'Today'
                          : _isYesterday(date)
                          ? 'Yesterday'
                          : DateFormat('EEEE, dd MMM').format(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${datePayments.length} payments',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Payments for this date
              ...datePayments.map((p) => _buildPaymentCard(p)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentWithDetails payment) {
    final isCancelled = payment.payment.isCancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCancelled
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Payment mode icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withValues(alpha: 0.1)
                      : FeeConstants.getPaymentModeColor(payment.payment.paymentMode).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel
                      : FeeConstants.getPaymentModeIconData(payment.payment.paymentMode),
                  color: isCancelled
                      ? Colors.red
                      : FeeConstants.getPaymentModeColor(payment.payment.paymentMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Payment info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          payment.payment.receiptNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (isCancelled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CANCELLED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.student.studentName} ${payment.student.fatherName}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    Text(
                      '${payment.schoolClass.name} • ${DateFormat('hh:mm a').format(payment.payment.paymentDate)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(payment.payment.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCancelled ? Colors.red : Colors.green,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    FeeConstants.getPaymentModeDisplayName(
                      payment.payment.paymentMode,
                    ),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Future<void> _showDateRangePicker() async {
    final filters = ref.read(paymentFiltersProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: filters.dateFrom != null && filters.dateTo != null
          ? DateTimeRange(start: filters.dateFrom!, end: filters.dateTo!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
    );

    if (range != null) {
      ref
          .read(paymentFiltersProvider.notifier)
          .setDateRange(range.start, range.end);
    }
  }

  void _showPaymentDetails(PaymentWithDetails payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _PaymentDetailsSheet(
          payment: payment,
          scrollController: scrollController,
          currencyFormat: _currencyFormat,
          onPaymentCancelled: () {
            // Refresh the payments list and collection summary
            ref.invalidate(paymentsListProvider);
            ref.invalidate(todayCollectionProvider);
          },
        ),
      ),
    );
  }

  Future<void> _printBulkReceipts() async {
    final filters = ref.read(paymentFiltersProvider);
    if (filters.dateFrom == null || filters.dateTo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date range first')),
        );
      }
      return;
    }

    final nav = Navigator.of(context);
    var dialogOpen = false;

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        dialogOpen = true;
      }

      final service = ref.read(receiptServiceProvider);
      final data = await service.getBulkReceiptData(
        from: filters.dateFrom!,
        to: filters.dateTo!,
        paymentMode: filters.paymentMode,
      );

      // Close loading dialog before proceeding
      if (dialogOpen) {
        nav.pop();
        dialogOpen = false;
      }

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No payments found for selected range'),
            ),
          );
        }
        return;
      }

      final pdfBytes = await service.generateBulkReceipts(data);

      if (mounted) {
        await PdfHelper.previewPdf(
          context,
          pdfBytes,
          'Bulk_Receipts_${DateFormat('yyyyMMdd').format(filters.dateFrom!)}',
        );
      }
    } catch (e) {
      // Only pop if dialog is still open
      if (dialogOpen) {
        nav.pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PaymentDetailsSheet extends ConsumerWidget {
  final PaymentWithDetails payment;
  final ScrollController scrollController;
  final NumberFormat currencyFormat;
  final VoidCallback? onPaymentCancelled;

  const _PaymentDetailsSheet({
    required this.payment,
    required this.scrollController,
    required this.currencyFormat,
    this.onPaymentCancelled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCancelled = payment.payment.isCancelled;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Handle
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
        const SizedBox(height: 20),

        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCancelled ? Icons.cancel : Icons.check_circle,
                color: isCancelled ? Colors.red : Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(payment.payment.amount),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    payment.payment.receiptNumber,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CANCELLED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Student info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  payment.student.studentName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment.student.studentName} ${payment.student.fatherName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${payment.student.admissionNumber} • ${payment.schoolClass.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment details
        _buildDetailRow(
          'Date & Time',
          DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(payment.payment.paymentDate),
        ),
        _buildDetailRow(
          'Payment Mode',
          FeeConstants.getPaymentModeDisplayName(payment.payment.paymentMode),
        ),
        _buildDetailRow('Invoice', payment.invoice.invoiceNumber),
        if (payment.payment.paymentMode == 'cheque') ...[
          if (payment.payment.referenceNumber != null)
            _buildDetailRow('Cheque No', payment.payment.referenceNumber!),
          if (payment.payment.bankName != null)
            _buildDetailRow('Bank', payment.payment.bankName!),
        ] else if (payment.payment.referenceNumber != null)
          _buildDetailRow('Reference', payment.payment.referenceNumber!),
        if (payment.payment.remarks != null)
          _buildDetailRow('Remarks', payment.payment.remarks!),

        // Actions
        const SizedBox(height: 32),
        if (!isCancelled) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printReceipt(context, ref),
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelPayment(context, ref),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(receiptServiceProvider);
      await service.printReceiptByPaymentId(context, payment.payment.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelPayment(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'This will reverse the payment and update the invoice balance. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(paymentServiceProvider);
        await service.cancelPayment(payment.payment.id, 'Cancelled by user');

        ref.invalidate(paymentsListProvider);
        ref.invalidate(invoicesListProvider);
        
        // Call the callback to refresh parent widget
        onPaymentCancelled?.call();

        if (context.mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
