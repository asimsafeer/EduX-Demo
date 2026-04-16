/// EduX School Management System
/// Payment Details Screen - View single payment details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../repositories/payment_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

class PaymentDetailsScreen extends ConsumerStatefulWidget {
  final int paymentId;

  const PaymentDetailsScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailsScreen> createState() =>
      _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends ConsumerState<PaymentDetailsScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    // We'll use a FutureProvider family or just a FutureBuilder with the repo method
    // Since we don't have a specific provider for single payment in fee_provider.dart (likely),
    // let's check fee_provider.dart first or just use a FutureBuilder here for simplicity.
    // Actually, creating a provider is better practice. But for a quick fix, FutureBuilder is fine.
    // Wait, let's look at fee_provider.dart to see if we can easily add a provider.

    // For now, I'll use a FutureBuilder interacting directly with the repository provider
    final paymentRepo = ref.watch(paymentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: FutureBuilder<PaymentWithDetails?>(
        future: paymentRepo.getPaymentWithDetails(widget.paymentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          if (snapshot.hasError) {
            return AppErrorState(message: snapshot.error.toString());
          }

          if (snapshot.data == null) {
            return const AppErrorState(message: 'Payment not found');
          }

          final payment = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildContent(context, payment),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentWithDetails payment) {
    final isCancelled = payment.payment.isCancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status & Amount Card
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled ? Icons.cancel : Icons.check_circle,
                  color: isCancelled ? Colors.red : Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currencyFormat.format(payment.payment.amount),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                payment.payment.receiptNumber,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isCancelled) ...[
                const SizedBox(height: 12),
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
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Student Info
        Text(
          'Student Information',
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment.student.studentName} ${payment.student.fatherName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.student.admissionNumber} • ${payment.schoolClass.name}${payment.section != null ? '-${payment.section!.name}' : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Transaction Details
        Text(
          'Transaction Details',
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Date & Time',
                DateFormat(
                  'MMM dd, yyyy • hh:mm a',
                ).format(payment.payment.paymentDate),
                Icons.calendar_today,
              ),
              const Divider(height: 24),
              _buildDetailRow(
                'Payment Mode',
                FeeConstants.getPaymentModeDisplayName(
                  payment.payment.paymentMode,
                ),
                FeeConstants.getPaymentModeIconData(payment.payment.paymentMode),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                'Invoice',
                payment.invoice.invoiceNumber,
                Icons.receipt,
              ),
              if (payment.payment.paymentMode == 'cheque') ...[
                const Divider(height: 24),
                if (payment.payment.referenceNumber != null)
                  _buildDetailRow(
                    'Cheque No',
                    payment.payment.referenceNumber!,
                    Icons.numbers,
                  ),
                if (payment.payment.bankName != null)
                  _buildDetailRow(
                    'Bank',
                    payment.payment.bankName!,
                    Icons.account_balance,
                  ),
              ] else if (payment.payment.referenceNumber != null) ...[
                const Divider(height: 24),
                _buildDetailRow(
                  'Reference',
                  payment.payment.referenceNumber!,
                  Icons.tag,
                ),
              ],
              if (payment.payment.remarks != null &&
                  payment.payment.remarks!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildDetailRow(
                  'Remarks',
                  payment.payment.remarks!,
                  Icons.note,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

}
