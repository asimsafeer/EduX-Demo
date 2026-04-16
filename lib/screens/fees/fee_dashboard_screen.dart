/// EduX School Management System
/// Fee Dashboard Screen - Main fee management hub
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

class FeeDashboardScreen extends ConsumerStatefulWidget {
  const FeeDashboardScreen({super.key});

  @override
  ConsumerState<FeeDashboardScreen> createState() => _FeeDashboardScreenState();
}

class _FeeDashboardScreenState extends ConsumerState<FeeDashboardScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's collection summary
              _buildTodayCollection(),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Invoice summary
              _buildInvoiceSummary(),
              const SizedBox(height: 24),

              // Recent payments
              _buildRecentPayments(),
              const SizedBox(height: 24),

              // Defaulters alert
              _buildDefaultersAlert(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCollection() {
    final asyncCollection = ref.watch(todayCollectionProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: asyncCollection.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Text(
              'Error loading collection',
              style: const TextStyle(color: Colors.white70),
            ),
            data: (collection) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Collection",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currencyFormat.format(collection.totalAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCollectionStat(
                      'Payments',
                      collection.paymentCount.toString(),
                      Icons.receipt_long,
                    ),
                    ...collection.byPaymentMode.entries
                        .take(3)
                        .map(
                          (e) => _buildCollectionStat(
                            FeeConstants.getPaymentModeDisplayName(
                              e.key,
                            ).split(' ').first,
                            _currencyFormat.format(e.value),
                            FeeConstants.getPaymentModeIconData(e.key),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount;
            double childAspectRatio;
            if (width >= 1000) {
              crossAxisCount = 4;
              childAspectRatio = 1.6;
            } else if (width >= 600) {
              crossAxisCount = 2;
              childAspectRatio = 2.0;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 3.0;
            }
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: [
                _buildActionCard(
                  'Fee Structure',
                  'Configure class fees',
                  Icons.settings,
                  Colors.blue,
                  () => context.push('/fees/structure'),
                ),
                _buildActionCard(
                  'Generate Invoices',
                  'Bulk invoice generation',
                  Icons.receipt,
                  Colors.green,
                  () => context.push('/fees/invoices/generate'),
                ),
                _buildActionCard(
                  'Collect Payment',
                  'Record fee payment',
                  Icons.payment,
                  Colors.orange,
                  () => context.push('/fees/collect-payment'),
                ),
                _buildActionCard(
                  'Fee Reports',
                  'View detailed reports',
                  Icons.bar_chart,
                  Colors.purple,
                  () => context.push('/fees/reports'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    final asyncStats = ref.watch(invoiceStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoice Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/fees/invoices'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorState(message: e.toString()),
          data: (stats) => LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _buildStatCard(
                  'Pending',
                  stats.pendingCount.toString(),
                  _currencyFormat.format(stats.pendingAmount),
                  Colors.orange,
                  Icons.pending_actions,
                ),
                _buildStatCard(
                  'Paid',
                  stats.paidCount.toString(),
                  _currencyFormat.format(stats.paidAmount),
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatCard(
                  'Overdue',
                  stats.overdueCount.toString(),
                  '${stats.overdueCount} students',
                  Colors.red,
                  Icons.warning,
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[2]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subValue,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayments() {
    final asyncPayments = ref.watch(recentPaymentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Payments',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/fees/payments'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        asyncPayments.when(
          loading: () => const AppLoadingIndicator(),
          error: (e, _) => AppErrorState(message: e.toString()),
          data: (payments) {
            if (payments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('No recent payments')),
              );
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      payment.receiptNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(payment.paymentDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      _currencyFormat.format(payment.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () => context.push('/fees/payments/${payment.id}'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDefaultersAlert() {
    final asyncDefaulters = ref.watch(allDefaultersProvider);

    return asyncDefaulters.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (defaulters) {
        if (defaulters.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Defaulters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/fees/defaulters'),
                  child: Text(
                    'View All (${defaulters.length})',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: defaulters.take(3).map((defaulter) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: Text(
                            defaulter.studentName[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                defaulter.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${defaulter.classSection} • ${defaulter.maxDaysOverdue} days overdue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormat.format(defaulter.totalPending),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(todayCollectionProvider);
    ref.invalidate(invoiceStatsProvider);
    ref.invalidate(recentPaymentsProvider);
    ref.invalidate(allDefaultersProvider);
  }
}
