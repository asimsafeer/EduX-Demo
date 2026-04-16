import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../database/app_database.dart';
import '../../../repositories/canteen_repository.dart';
import '../../../providers/canteen_provider.dart';
import 'widgets/canteen_transaction_dialog.dart';

class CanteenDetailsScreen extends ConsumerWidget {
  final int canteenId;

  const CanteenDetailsScreen({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(canteenSummaryProvider(canteenId));
    final transactionsAsync = ref.watch(canteenTransactionsProvider(canteenId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: summaryAsync.when(
          data: (s) => Text(s?.canteen.name ?? 'Canteen Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Canteen not found'));
          }

          return Column(
            children: [
              _HeaderSection(summary: summary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaction History',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _addTransaction(context, summary.canteen),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Record Transaction'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: transactionsAsync.when(
                          data: (transactions) {
                            if (transactions.isEmpty) {
                              return const AppEmptyState(
                                icon: LucideIcons.history,
                                title: 'No Transactions',
                                description:
                                    'Start recording rent payments or profits for this facility.',
                              );
                            }

                            return ListView.separated(
                              itemCount: transactions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final tx = transactions[index];
                                return _TransactionTile(tx: tx);
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              Center(child: Text('Error: $err')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _addTransaction(BuildContext context, Canteen canteen) {
    showDialog(
      context: context,
      builder: (context) => CanteenTransactionDialog(canteen: canteen),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final CanteenWithSummary summary;

  const _HeaderSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRent = summary.canteen.businessModel == 'rent';

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              label: 'Total Revenue',
              value:
                  '${AppConstants.defaultCurrencySymbol} ${summary.totalIncome.toStringAsFixed(0)}',
              icon: LucideIcons.trendingUp,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _InfoCard(
              label: isRent ? 'Active Model' : 'Total Investment',
              value: isRent
                  ? 'Fixed Rent'
                  : '${AppConstants.defaultCurrencySymbol} ${summary.totalInvestment.toStringAsFixed(0)}',
              icon: isRent ? LucideIcons.calendarCheck : LucideIcons.wallet,
              color: isRent ? theme.colorScheme.primary : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _InfoCard(
              label: 'Net Balance',
              value:
                  '${AppConstants.defaultCurrencySymbol} ${summary.netProfit.toStringAsFixed(0)}',
              icon: LucideIcons.barChart3,
              color: summary.netProfit >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final CanteenTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = tx.type.startsWith('income');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isIncome ? LucideIcons.arrowDown : LucideIcons.arrowUp,
          color: isIncome ? Colors.green : Colors.red,
          size: 18,
        ),
      ),
      title: Text(_getTypeLabel(tx.type)),
      subtitle: Text(DateFormat('MMM d, yyyy').format(tx.date)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? "+" : "-"}${AppConstants.defaultCurrencySymbol} ${tx.amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          if (tx.description != null && tx.description!.isNotEmpty)
            Text(tx.description!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income_rent':
        return 'Rent Payment';
      case 'income_profit':
        return 'Profit Share';
      case 'expense_investment':
        return 'School Investment';
      case 'expense_maintenance':
        return 'Maintenance Cost';
      default:
        return 'Other';
    }
  }
}
