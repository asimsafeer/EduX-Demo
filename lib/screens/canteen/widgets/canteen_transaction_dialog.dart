import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../database/app_database.dart';
import '../../../providers/canteen_provider.dart';

class CanteenTransactionDialog extends ConsumerStatefulWidget {
  final Canteen canteen;

  const CanteenTransactionDialog({super.key, required this.canteen});

  @override
  ConsumerState<CanteenTransactionDialog> createState() =>
      _CanteenTransactionDialogState();
}

class _CanteenTransactionDialogState
    extends ConsumerState<CanteenTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _type;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();

    // Default type based on business model
    _type = widget.canteen.businessModel == 'rent'
        ? 'income_rent'
        : 'income_profit';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final success = await ref
        .read(canteenOperationProvider.notifier)
        .addTransaction(
          canteenId: widget.canteen.id,
          type: _type,
          amount: amount,
          date: _selectedDate,
          description: _descriptionController.text.trim(),
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRentModel = widget.canteen.businessModel == 'rent';

    return AlertDialog(
      title: const Text('Record Transaction'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  prefixIcon: Icon(LucideIcons.list),
                ),
                items: [
                  if (isRentModel)
                    const DropdownMenuItem(
                      value: 'income_rent',
                      child: Text('Rent Income'),
                    ),
                  if (!isRentModel)
                    const DropdownMenuItem(
                      value: 'income_profit',
                      child: Text('Profit Share'),
                    ),
                  const DropdownMenuItem(
                    value: 'expense_investment',
                    child: Text('School Investment'),
                  ),
                  const DropdownMenuItem(
                    value: 'expense_maintenance',
                    child: Text('Maintenance Cost'),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(LucideIcons.banknote),
                  prefixText: '${AppConstants.defaultCurrencySymbol} ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(LucideIcons.alignLeft),
                  hintText: 'e.g. Rent for March 2024',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Record')),
      ],
    );
  }
}
