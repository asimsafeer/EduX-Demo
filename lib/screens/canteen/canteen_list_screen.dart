import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../database/app_database.dart';
import '../../../providers/canteen_provider.dart';
import 'widgets/canteen_form_dialog.dart';
import 'canteen_details_screen.dart';

class CanteenListScreen extends ConsumerWidget {
  const CanteenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canteensAsync = ref.watch(activeCanteensProvider);
    final theme = Theme.of(context);

    // Watch operation state for error/success messages
    ref.listen(canteenOperationProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(canteenOperationProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(canteenOperationProvider.notifier).clearMessages();
      }
    });

    final operationState = ref.watch(canteenOperationProvider);

    return AppLoadingOverlay(
      isLoading: operationState.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Canteen Management'),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCanteenForm(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Canteen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: canteensAsync.when(
          data: (canteens) {
            if (canteens.isEmpty) {
              return const AppEmptyState(
                icon: LucideIcons.store,
                title: 'No Canteens Found',
                description:
                    'Add your school canteen or tuck shop to start tracking rent and profits.',
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount;
                  if (width >= 1000) {
                    crossAxisCount = 3;
                  } else if (width >= 600) {
                    crossAxisCount = 2;
                  } else {
                    crossAxisCount = 1;
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: canteens.length,
                    itemBuilder: (context, index) {
                      final canteen = canteens[index];
                      return _CanteenCard(canteen: canteen);
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  void _showCanteenForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CanteenFormDialog(),
    );
  }
}

class _CanteenCard extends ConsumerWidget {
  final Canteen canteen;

  const _CanteenCard({required this.canteen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(canteenSummaryProvider(canteen.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CanteenDetailsScreen(canteenId: canteen.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canteen.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              canteen.operatorName,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      canteen.businessModel == 'rent'
                          ? 'Rental'
                          : 'Profit Share',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(),
              summaryAsync.when(
                data: (summary) {
                  if (summary == null) return const SizedBox();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                        label: canteen.businessModel == 'rent'
                            ? 'Total Rent'
                            : 'Total Profit',
                        value:
                            '${AppConstants.defaultCurrencySymbol} ${summary.totalIncome.toStringAsFixed(0)}',
                        color: Colors.green,
                      ),
                      if (canteen.businessModel == 'profit_share')
                        _StatItem(
                          label: 'Investment',
                          value:
                              '${AppConstants.defaultCurrencySymbol} ${summary.totalInvestment.toStringAsFixed(0)}',
                          color: Colors.orange,
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error loading stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
