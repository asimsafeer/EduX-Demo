/// EduX School Management System
/// Defaulters Screen - List of all fee defaulters
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/fee_provider.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import 'widgets/defaulter_tile.dart';

class DefaultersScreen extends ConsumerStatefulWidget {
  const DefaultersScreen({super.key});

  @override
  ConsumerState<DefaultersScreen> createState() => _DefaultersScreenState();
}

class _DefaultersScreenState extends ConsumerState<DefaultersScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  int _minDays = 30;

  @override
  Widget build(BuildContext context) {
    // We use a family provider here to allow filtering by class and minDays
    // For now, let's assume we want to view all defaulters with at least _minDays overdue
    final asyncDefaulters = ref.watch(
      defaultersProvider((classId: null, minDays: _minDays)),
    );
    // final asyncClasses = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Defaulters'),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(defaultersProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withValues(alpha: 0.05),
            child: Text(
              'Showing defaulters overdue by $_minDays+ days',
              style: TextStyle(
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Defaulters list
          Expanded(
            child: asyncDefaulters.when(
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (defaulters) {
                if (defaulters.isEmpty) {
                  return _buildEmptyState();
                }

                // Calculate total outstanding
                final totalOutstanding = defaulters.fold<double>(
                  0,
                  (sum, d) => sum + d.totalPending,
                );

                return Column(
                  children: [
                    // Total outstanding card
                    _buildTotalOutstandingCard(
                      defaulters.length,
                      totalOutstanding,
                    ),

                    // List
                    Expanded(
                      child: ListView.separated(
                        itemCount: defaulters.length,
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final defaulter = defaulters[index];
                          return DefaulterTile(
                            defaulter: defaulter,
                            onTap: () {
                              context.push(
                                '/fees/collect-payment?studentId=${defaulter.student.id}',
                              );
                            },
                            onCollect: () {
                              context.push(
                                '/fees/collect-payment?studentId=${defaulter.student.id}',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalOutstandingCard(int count, double amount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Students',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Defaulters Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great job! All payments are up to date.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _FilterDialog(initialDays: _minDays),
    );

    if (result != null && mounted) {
      setState(() {
        _minDays = result;
      });
      // Invalidate to refresh with new filter
      ref.invalidate(defaultersProvider);
    }
  }
}

class _FilterDialog extends StatefulWidget {
  final int initialDays;

  const _FilterDialog({required this.initialDays});

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late double _days;

  @override
  void initState() {
    super.initState();
    _days = widget.initialDays.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Defaulters'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Minimum Days Overdue'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('${_days.toInt()} days'),
              Expanded(
                child: Slider(
                  value: _days,
                  min: 0,
                  max: 90,
                  divisions: 18,
                  label: '${_days.toInt()} days',
                  onChanged: (value) {
                    setState(() {
                      _days = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _days.toInt()),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
