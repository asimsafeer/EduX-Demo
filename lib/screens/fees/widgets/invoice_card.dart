import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../repositories/invoice_repository.dart';
import '../../../core/constants/app_constants.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceWithDetails invoice;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final VoidCallback? onPrint;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onPay,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildStatusChip(invoice.invoice.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    invoice.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    invoice.classSection,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatMonth(invoice.invoice.month),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (invoice.invoice.balanceAmount > 0)
                    Text(
                      'Due: ${DateFormat('dd MMM').format(invoice.invoice.dueDate)}',
                      style: TextStyle(
                        color: _getDueDateColor(invoice.invoice),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Text(
                        currencyFormat.format(invoice.invoice.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance Due',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Text(
                        currencyFormat.format(invoice.invoice.balanceAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: invoice.invoice.balanceAmount > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onPrint != null)
                        IconButton(
                          onPressed: onPrint,
                          icon: const Icon(Icons.print, size: 20),
                          tooltip: 'Print Invoice Slip',
                          visualDensity: VisualDensity.compact,
                          color: Colors.grey[600],
                        ),
                      if (onPay != null && invoice.invoice.balanceAmount > 0)
                        ElevatedButton(
                          onPressed: onPay,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Pay'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDueDateColor(dynamic invoice) {
    if (invoice.status == FeeConstants.invoiceStatusPaid) return Colors.grey;
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
        return DateFormat('MMM yyyy').format(date);
      }
    } catch (_) {}
    return month;
  }
}
