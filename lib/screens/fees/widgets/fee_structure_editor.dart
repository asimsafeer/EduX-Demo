import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../database/app_database.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/fee_provider.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../repositories/fee_repository.dart';

class FeeStructureEditor extends ConsumerStatefulWidget {
  final int classId;
  final bool isEditing;
  final ValueChanged<bool> onEditingChanged;

  const FeeStructureEditor({
    super.key,
    required this.classId,
    required this.isEditing,
    required this.onEditingChanged,
  });

  @override
  ConsumerState<FeeStructureEditor> createState() => _FeeStructureEditorState();
}

class _FeeStructureEditorState extends ConsumerState<FeeStructureEditor> {
  final _amountControllers = <int, TextEditingController>{};
  final _currencyFormat = NumberFormat.currency(
    locale: AppConstants.defaultCurrencyLocale,
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(FeeStructureEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    final structures = ref.read(classFeeStructuresProvider).valueOrNull ?? [];
    for (final s in structures) {
      if (!_amountControllers.containsKey(s.feeType.id)) {
        _amountControllers[s.feeType.id] = TextEditingController();
      }
      // Always overwrite with latest amount so stale values don't persist
      _amountControllers[s.feeType.id]!.text = s.structure.amount
          .toStringAsFixed(0);
    }
    // Clear controllers for fee types no longer in structure
    final activeIds = structures.map((s) => s.feeType.id).toSet();
    for (final id in _amountControllers.keys.toList()) {
      if (!activeIds.contains(id)) {
        _amountControllers[id]!.text = '';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final s in structures) {
        ref
            .read(feeStructureFormProvider.notifier)
            .setFeeTypeAmount(s.feeType.id, s.structure.amount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncFeeTypes = ref.watch(feeTypesProvider);
    final asyncStructures = ref.watch(classFeeStructuresProvider);

    // When fresh structure data arrives (e.g. after save), reinitialize
    // controllers so edit mode shows up-to-date amounts.
    ref.listen<AsyncValue<List<FeeStructureWithDetails>>>(
      classFeeStructuresProvider,
      (_, next) {
        next.whenData((structures) {
          for (final s in structures) {
            final ctrl = _amountControllers[s.feeType.id];
            if (ctrl != null) {
              ctrl.text = s.structure.amount.toStringAsFixed(0);
            }
          }
          // Also sync to form provider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            for (final s in structures) {
              ref
                  .read(feeStructureFormProvider.notifier)
                  .setFeeTypeAmount(s.feeType.id, s.structure.amount);
            }
          });
        });
      },
    );

    return asyncFeeTypes.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(message: e.toString()),
      data: (feeTypes) {
        if (feeTypes.isEmpty) {
          return const Center(
            child: Text('No fee types configured. Please add fee types first.'),
          );
        }

        return asyncStructures.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => AppErrorState(message: e.toString()),
          data: (structures) {
            final structureMap = <int, double>{};
            double totalMonthly = 0;
            double totalOneTime = 0;

            for (final s in structures) {
              structureMap[s.feeType.id] = s.structure.amount;
              if (s.feeType.isMonthly) {
                totalMonthly += s.structure.amount;
              } else {
                totalOneTime += s.structure.amount;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(totalMonthly, totalOneTime),
                  const SizedBox(height: 24),
                  _buildFeeSection(
                    'Monthly Fees',
                    'Recurring fees charged every month',
                    feeTypes.where((f) => f.isMonthly && f.showInClassStructure).toList(),
                    structureMap,
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildFeeSection(
                    'One-Time Fees',
                    'Fees charged once per academic year',
                    feeTypes.where((f) => !f.isMonthly && f.showInClassStructure).toList(),
                    structureMap,
                    Colors.purple,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(double totalMonthly, double totalOneTime) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Monthly',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(totalMonthly),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 50, width: 1, color: Colors.grey[300]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total One-Time',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(totalOneTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection(
    String title,
    String subtitle,
    List<FeeType> feeTypes,
    Map<int, double> structureMap,
    Color color,
  ) {
    if (feeTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title.contains('Monthly')
                    ? Icons.calendar_month
                    : Icons.event_available,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feeTypes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final feeType = feeTypes[index];
              final hasAmount = structureMap.containsKey(feeType.id);
              final amount = structureMap[feeType.id] ?? 0;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasAmount
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasAmount ? Icons.check_circle : Icons.circle_outlined,
                    color: hasAmount ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  feeType.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: feeType.description != null
                    ? Text(
                        feeType.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: widget.isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _getController(feeType.id),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.end,
                              decoration: InputDecoration(
                                prefixText: 'Rs. ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                final amount = double.tryParse(value) ?? 0;
                                ref
                                    .read(feeStructureFormProvider.notifier)
                                    .setFeeTypeAmount(feeType.id, amount);
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red, size: 20),
                            tooltip: 'Remove fee',
                            onPressed: () {
                              _amountControllers[feeType.id]?.text = '';
                              ref
                                  .read(feeStructureFormProvider.notifier)
                                  .setFeeTypeAmount(feeType.id, 0);
                            },
                          ),
                        ],
                      )
                    : Text(
                        hasAmount ? _currencyFormat.format(amount) : 'Not set',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasAmount ? color : Colors.grey,
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  TextEditingController _getController(int feeTypeId) {
    if (!_amountControllers.containsKey(feeTypeId)) {
      _amountControllers[feeTypeId] = TextEditingController();
    }
    return _amountControllers[feeTypeId]!;
  }
}
