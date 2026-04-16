import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/fee_provider.dart';
import '../../../core/constants/app_constants.dart';

class PaymentDialog extends ConsumerWidget {
  final int invoiceId;
  final double amountDue;

  const PaymentDialog({
    super.key,
    required this.invoiceId,
    required this.amountDue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentCollectionProvider);
    final notifier = ref.read(paymentCollectionProvider.notifier);

    // Initialize if needed
    if (state.invoiceId != invoiceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setInvoiceId(invoiceId);
        notifier.setAmount(amountDue);
      });
    }

    // Listen for success
    ref.listen(paymentCollectionProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.result != null && next.result!.success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment collected: Rs. ${next.result!.amount}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return AlertDialog(
      title: const Text('Collect Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red[800], fontSize: 12),
                ),
              ),
            TextFormField(
              initialValue: amountDue.toStringAsFixed(0),
              decoration: const InputDecoration(
                labelText: 'Amount (Rs.)',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                notifier.setAmount(amount);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: state.paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
                border: OutlineInputBorder(),
              ),
              items: FeeConstants.paymentModes.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(FeeConstants.getPaymentModeDisplayName(mode)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) notifier.setPaymentMode(value);
              },
            ),
            if (state.paymentMode == FeeConstants.paymentModeCheque ||
                state.paymentMode == FeeConstants.paymentModeOnline) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reference / Cheque No',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (state.paymentMode == FeeConstants.paymentModeCheque) {
                    notifier.setChequeNumber(value);
                  } else {
                    notifier.setReferenceNumber(value);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => notifier.setRemarks(value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.isProcessing
              ? null
              : () => notifier.collectPayment(),
          child: state.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Collect'),
        ),
      ],
    );
  }
}
