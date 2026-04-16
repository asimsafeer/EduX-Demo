/// EduX School Management System
/// Period Configuration Screen - Manage school period timings
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../database/app_database.dart';
import '../../providers/academics_provider.dart';
// import '../../repositories/period_definition_repository.dart'; // Unused
import 'widgets/period_dialog.dart';

/// Screen to configure period definitions
class PeriodConfigurationScreen extends ConsumerStatefulWidget {
  const PeriodConfigurationScreen({super.key});

  @override
  ConsumerState<PeriodConfigurationScreen> createState() =>
      _PeriodConfigurationScreenState();
}

class _PeriodConfigurationScreenState
    extends ConsumerState<PeriodConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);

    // Listen for operation messages
    ref.listen<OperationState>(periodDefinitionOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(periodDefinitionOperationProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(periodDefinitionOperationProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Periods'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Add Period',
            onPressed: () {
              academicYearAsync.whenData((year) {
                _showPeriodDialog(context, ref, year);
              });
            },
          ),
        ],
      ),
      body: academicYearAsync.when(
        data: (academicYear) => _buildContent(context, ref, academicYear),
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, __) => AppErrorState(
          message: 'Failed to load academic year',
          onRetry: () => ref.invalidate(currentAcademicYearProvider),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String academicYear,
  ) {
    final periodsAsync = ref.watch(periodDefinitionsProvider(academicYear));

    return periodsAsync.when(
      data: (periods) {
        if (periods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.clock, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Periods Configured',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showSeedDialog(context, ref, academicYear),
                  icon: const Icon(LucideIcons.wand2),
                  label: const Text('Create Default Schedule'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPeriodDialog(context, ref, academicYear),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add Manually'),
                ),
              ],
            ),
          );
        }

        // Sort by display order
        final sortedPeriods = List<PeriodDefinition>.from(periods)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedPeriods.length,
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = sortedPeriods.removeAt(oldIndex);
            sortedPeriods.insert(newIndex, item);

            // Update orders in backend
            final ids = sortedPeriods.map((e) => e.id).toList();
            final orders = List.generate(sortedPeriods.length, (i) => i + 1);

            ref
                .read(periodDefinitionOperationProvider.notifier)
                .reorderPeriods(ids, orders, academicYear);
          },
          itemBuilder: (context, index) {
            final period = sortedPeriods[index];
            return Card(
              key: ValueKey(period.id),
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: period.isBreak
                  ? Colors.orange.withValues(alpha: 0.1)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: period.isBreak
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    period.isBreak ? LucideIcons.coffee : LucideIcons.clock,
                    size: 18,
                    color: period.isBreak
                        ? Colors.orange[800]
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  period.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${period.startTime} - ${period.endTime} (${period.durationMinutes} mins)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 18),
                      onPressed: () => _showPeriodDialog(
                        context,
                        ref,
                        academicYear,
                        period: period,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: Colors.red,
                      onPressed: () =>
                          _confirmDelete(context, ref, period, academicYear),
                    ),
                    const Icon(LucideIcons.gripVertical, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (error, __) => AppErrorState(
        message: 'Failed to load periods: $error',
        onRetry: () => ref.invalidate(periodDefinitionsProvider(academicYear)),
      ),
    );
  }

  Future<void> _showSeedDialog(
    BuildContext context,
    WidgetRef ref,
    String academicYear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Period Schedule'),
        content: const Text(
          'This will create a default schedule with 8 periods and breaks. '
          'You can modify them afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Default'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(periodDefinitionOperationProvider.notifier)
          .seedDefaults(academicYear);
    }
  }

  void _showPeriodDialog(
    BuildContext context,
    WidgetRef ref,
    String academicYear, {
    PeriodDefinition? period,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          PeriodDialog(academicYear: academicYear, period: period),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PeriodDefinition period,
    String academicYear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Period'),
        content: Text(
          'Are you sure you want to delete "${period.name}"? '
          'This might affect existing timetables.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(periodDefinitionOperationProvider.notifier)
          .deletePeriod(period.id, academicYear);
    }
  }
}
