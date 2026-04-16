import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../repositories/invoice_repository.dart';
import '../../../core/constants/app_constants.dart';

class DefaulterTile extends StatelessWidget {
  final DefaulterInfo defaulter;
  final VoidCallback? onTap;
  final VoidCallback? onCollect;

  const DefaulterTile({
    super.key,
    required this.defaulter,
    this.onTap,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: Text(
                  defaulter.studentName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      defaulter.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${defaulter.classSection} • ${defaulter.student.admissionNumber}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${defaulter.pendingMonths} Pending Invoices • Max ${defaulter.maxDaysOverdue} days',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(defaulter.totalPending),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[800],
                    ),
                  ),
                  if (onCollect != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onCollect,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'Collect',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
