/// EduX School Management System
/// Fee Reports Screen - Comprehensive fee reports
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../repositories/payment_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../services/report_service.dart';

class FeeReportsScreen extends ConsumerStatefulWidget {
  const FeeReportsScreen({super.key});

  @override
  ConsumerState<FeeReportsScreen> createState() => _FeeReportsScreenState();
}

class _FeeReportsScreenState extends ConsumerState<FeeReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily Collection'),
            Tab(text: 'Monthly Summary'),
            Tab(text: 'By Class'),
            Tab(text: 'By Mode'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyCollectionTab(),
          _MonthlySummaryTab(),
          _CollectionByClassTab(),
          _CollectionByModeTab(),
        ],
      ),
    );
  }
}

class _DailyCollectionTab extends ConsumerStatefulWidget {
  const _DailyCollectionTab();

  @override
  ConsumerState<_DailyCollectionTab> createState() =>
      _DailyCollectionTabState();
}

class _DailyCollectionTabState extends ConsumerState<_DailyCollectionTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final asyncCollection = ref.watch(dailyCollectionProvider(_selectedDate));
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Date Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Select Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
              ),
            ),
          ),
        ),

        // Report Content
        Expanded(
          child: asyncCollection.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, _) => AppErrorState(message: e.toString()),
            data: (collection) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total Card
                _buildSummaryCard(
                  'Total Collection',
                  currencyFormat.format(collection.totalAmount),
                  collection.paymentCount.toString(),
                  Colors.blue,
                ),
                const SizedBox(height: 24),

                // Breakdown by Mode
                if (collection.byPaymentMode.isNotEmpty) ...[
                  const Text(
                    'Breakdown by Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...collection.byPaymentMode.entries.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        FeeConstants.getPaymentModeIconData(e.key),
                        color: FeeConstants.getPaymentModeColor(e.key),
                      ),
                      title: Text(
                        FeeConstants.getPaymentModeDisplayName(e.key),
                      ),
                      trailing: Text(
                        currencyFormat.format(e.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],

                // Recent Transactions
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final asyncPayments = ref.watch(
                      dailyPaymentsListProvider(_selectedDate),
                    );

                    return asyncPayments.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Error loading transactions: $e'),
                      ),
                      data: (payments) {
                        if (payments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No transactions found for this date',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: FeeConstants.getPaymentModeColor(
                                  payment.payment.paymentMode,
                                ).withValues(alpha: 0.1),
                                child: Icon(
                                  FeeConstants.getPaymentModeIconData(
                                    payment.payment.paymentMode,
                                  ),
                                  size: 16,
                                  color: FeeConstants.getPaymentModeColor(
                                    payment.payment.paymentMode,
                                  ),
                                ),
                              ),
                              title: Text(payment.studentName),
                              subtitle: Text(
                                '${payment.classSection} • ${payment.payment.receiptNumber}',
                              ),
                              trailing: Text(
                                currencyFormat.format(payment.payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final reportService = ref.read(reportServiceProvider);
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating report...')),
                  );
                  await reportService.generateDailyCollectionReport(
                    context,
                    _selectedDate,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Export Collection PDF'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    String count,
    Color color,
  ) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count Payments',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummaryTab extends ConsumerStatefulWidget {
  const _MonthlySummaryTab();

  @override
  ConsumerState<_MonthlySummaryTab> createState() => _MonthlySummaryTabState();
}

class _MonthlySummaryTabState extends ConsumerState<_MonthlySummaryTab> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final monthStr =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final asyncSummary = ref.watch(monthlyCollectionProvider(monthStr));
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Month Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),

        // Report Content
        Expanded(
          child: asyncSummary.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, _) => AppErrorState(message: e.toString()),
            data: (summary) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryGrid(summary, currencyFormat),
                const SizedBox(height: 24),
                // Add charts or breakdown here if needed
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final reportService = ref.read(reportServiceProvider);
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating report...')),
                  );
                  final start = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month,
                    1,
                  );
                  final end = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                    0,
                  );
                  await reportService.generateFeeCollectionReport(
                    context,
                    start,
                    end,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Export Monthly Summary'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(
    MonthlyCollectionSummary summary,
    NumberFormat format,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 1;
        final childAspectRatio = constraints.maxWidth >= 600 ? 2.8 : 4.0;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Total Invoiced',
              format.format(summary.totalInvoiced),
              Colors.blue,
            ),
            _buildStatCard(
              'Collected',
              format.format(summary.totalCollected),
              Colors.green,
            ),
            _buildStatCard(
              'Outstanding',
              format.format(summary.totalPending),
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CollectionByClassTab extends ConsumerStatefulWidget {
  const _CollectionByClassTab();

  @override
  ConsumerState<_CollectionByClassTab> createState() =>
      _CollectionByClassTabState();
}

class _CollectionByClassTabState extends ConsumerState<_CollectionByClassTab> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      collectionByClassProvider((from: _dateRange.start, to: _dateRange.end)),
    );
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Date Range Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() => _dateRange = range);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date Range',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                '${DateFormat('dd MMM').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, _) => AppErrorState(message: e.toString()),
            data: (data) => ListView.separated(
              itemCount: data.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(item.className),
                  subtitle: Text('${item.paymentCount} payments'),
                  trailing: Text(
                    currencyFormat.format(item.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final reportService = ref.read(reportServiceProvider);
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating report...')),
                  );
                  await reportService.generateClasswiseFeeStatus(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Export Class-wise Status'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionByModeTab extends ConsumerStatefulWidget {
  const _CollectionByModeTab();

  @override
  ConsumerState<_CollectionByModeTab> createState() =>
      _CollectionByModeTabState();
}

class _CollectionByModeTabState extends ConsumerState<_CollectionByModeTab> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      collectionByModeProvider((from: _dateRange.start, to: _dateRange.end)),
    );
    final currencyFormat = NumberFormat.currency(
      locale: AppConstants.defaultCurrencyLocale,
      symbol: AppConstants.defaultCurrencySymbol,
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Date Range Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() => _dateRange = range);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date Range',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                '${DateFormat('dd MMM').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, _) => AppErrorState(message: e.toString()),
            data: (data) => ListView.builder(
              itemCount: data.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = data[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FeeConstants.getPaymentModeColor(
                          item.paymentMode,
                        ).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FeeConstants.getPaymentModeIconData(item.paymentMode),
                        color: FeeConstants.getPaymentModeColor(item.paymentMode),
                      ),
                    ),
                    title: Text(
                      FeeConstants.getPaymentModeDisplayName(item.paymentMode),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${item.count} payments'),
                    trailing: Text(
                      currencyFormat.format(item.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: FeeConstants.getPaymentModeColor(item.paymentMode),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final reportService = ref.read(reportServiceProvider);
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating report...')),
                  );
                  await reportService.generateFeeCollectionReport(
                    context,
                    _dateRange.start,
                    _dateRange.end,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Export Collection Report'),
            ),
          ),
        ),
      ],
    );
  }

}
