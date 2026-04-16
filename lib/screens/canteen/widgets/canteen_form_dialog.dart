import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_constants.dart';
import '../../../database/app_database.dart';
import '../../../providers/canteen_provider.dart';

class CanteenFormDialog extends ConsumerStatefulWidget {
  final Canteen? canteen;

  const CanteenFormDialog({super.key, this.canteen});

  @override
  ConsumerState<CanteenFormDialog> createState() => _CanteenFormDialogState();
}

class _CanteenFormDialogState extends ConsumerState<CanteenFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _operatorController;
  late TextEditingController _phoneController;
  late TextEditingController _rentController;
  String _businessModel = 'rent';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.canteen?.name ?? '');
    _operatorController = TextEditingController(
      text: widget.canteen?.operatorName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.canteen?.operatorPhone ?? '',
    );
    _rentController = TextEditingController(
      text: widget.canteen?.monthlyRent.toString() ?? '0',
    );
    _businessModel = widget.canteen?.businessModel ?? 'rent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _operatorController.dispose();
    _phoneController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final operator = _operatorController.text.trim();
      final phone = _phoneController.text.trim();
      final rent = double.tryParse(_rentController.text.trim()) ?? 0;

      if (widget.canteen == null) {
        await ref
            .read(canteenOperationProvider.notifier)
            .createCanteen(
              name: name,
              operatorName: operator,
              operatorPhone: phone.isEmpty ? null : phone,
              businessModel: _businessModel,
              monthlyRent: rent,
            );
      } else {
        await ref
            .read(canteenOperationProvider.notifier)
            .updateCanteen(
              widget.canteen!.id,
              CanteensCompanion(
                name: drift.Value(name),
                operatorName: drift.Value(operator),
                operatorPhone: drift.Value(phone.isEmpty ? null : phone),
                businessModel: drift.Value(_businessModel),
                monthlyRent: drift.Value(rent),
              ),
            );
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.canteen == null ? 'Add Canteen' : 'Edit Canteen'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Canteen Name',
                  prefixIcon: Icon(LucideIcons.store),
                  hintText: 'e.g. Main Canteen, Junior Tuck Shop',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _operatorController,
                      decoration: const InputDecoration(
                        labelText: 'Operator Name',
                        prefixIcon: Icon(LucideIcons.user),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Operator Phone',
                        prefixIcon: Icon(LucideIcons.phone),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Financial Model',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'rent',
                    label: Text('Monthly Rent'),
                    icon: Icon(LucideIcons.calendar),
                  ),
                  ButtonSegment(
                    value: 'profit_share',
                    label: Text('Profit Sharing'),
                    icon: Icon(LucideIcons.pieChart),
                  ),
                ],
                selected: {_businessModel},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _businessModel = newSelection.first;
                    if (_businessModel == 'profit_share') {
                      _rentController.text = '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_businessModel == 'rent')
                TextFormField(
                  controller: _rentController,
                  decoration: InputDecoration(
                    labelText: 'Monthly Rent',
                    prefixIcon: const Icon(LucideIcons.banknote),
                    prefixText: '${AppConstants.defaultCurrencySymbol} ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'In this model, the school makes investments and picks profits based on canteen operations.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.canteen == null ? 'Add Canteen' : 'Save Changes'),
        ),
      ],
    );
  }
}
