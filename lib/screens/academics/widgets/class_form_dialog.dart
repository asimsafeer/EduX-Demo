/// EduX School Management System
/// Class Form Dialog - Add/Edit class
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';

/// Dialog for creating or editing a school class
class ClassFormDialog extends ConsumerStatefulWidget {
  final SchoolClass? schoolClass;

  const ClassFormDialog({super.key, this.schoolClass});

  @override
  ConsumerState<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends ConsumerState<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _gradeLevelController;
  late final TextEditingController _displayOrderController;
  late final TextEditingController _monthlyFeeController;
  late final TextEditingController _descriptionController;

  String _selectedLevel = 'primary';
  bool _isSubmitting = false;

  bool get isEditing => widget.schoolClass != null;

  static const _levelOptions = {
    'pre_primary': 'Pre-Primary',
    'primary': 'Primary',
    'middle': 'Middle School',
    'secondary': 'Secondary',
  };

  @override
  void initState() {
    super.initState();
    final schoolClass = widget.schoolClass;

    _nameController = TextEditingController(text: schoolClass?.name ?? '');
    _gradeLevelController = TextEditingController(
      text: schoolClass?.gradeLevel.toString() ?? '1',
    );
    _displayOrderController = TextEditingController(
      text: schoolClass?.displayOrder.toString() ?? '1',
    );
    _monthlyFeeController = TextEditingController(
      text: schoolClass?.monthlyFee.toStringAsFixed(0) ?? '0',
    );
    _descriptionController = TextEditingController(
      text: schoolClass?.description ?? '',
    );
    _selectedLevel = schoolClass?.level ?? 'primary';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeLevelController.dispose();
    _displayOrderController.dispose();
    _monthlyFeeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(classOperationProvider.notifier);

    final name = _nameController.text.trim();
    final gradeLevel = int.tryParse(_gradeLevelController.text) ?? 1;
    final displayOrder = int.tryParse(_displayOrderController.text) ?? 1;
    final monthlyFee = double.tryParse(_monthlyFeeController.text) ?? 0;
    final description = _descriptionController.text.trim();

    bool success;
    if (isEditing) {
      success = await notifier.updateClass(
        id: widget.schoolClass!.id,
        name: name,
        level: _selectedLevel,
        gradeLevel: gradeLevel,
        displayOrder: displayOrder,
        description: description.isEmpty ? null : description,
        monthlyFee: monthlyFee,
      );
    } else {
      success = await notifier.createClass(
        name: name,
        level: _selectedLevel,
        gradeLevel: gradeLevel,
        displayOrder: displayOrder,
        description: description.isEmpty ? null : description,
        monthlyFee: monthlyFee,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationState = ref.watch(classOperationProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? LucideIcons.edit2 : LucideIcons.plus,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Class' : 'Add New Class'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message
                if (operationState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          color: theme.colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            operationState.error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Class name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name *',
                    hintText: 'e.g., Class 1, Nursery, Grade 5',
                    prefixIcon: Icon(LucideIcons.type),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a class name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Level dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Level *',
                    prefixIcon: Icon(LucideIcons.layers),
                  ),
                  items: _levelOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Grade level and display order row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gradeLevelController,
                        decoration: const InputDecoration(
                          labelText: 'Grade Level *',
                          hintText: 'e.g., 1, 2, 3',
                          prefixIcon: Icon(LucideIcons.hash),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 0 || num > 20) {
                            return 'Invalid (0-20)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _displayOrderController,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                          hintText: 'e.g., 1, 2, 3',
                          prefixIcon: Icon(LucideIcons.arrowUpDown),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Monthly fee
                TextFormField(
                  controller: _monthlyFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fee',
                    hintText: 'e.g., 5000',
                    prefixIcon: Icon(LucideIcons.wallet),
                    prefixText: 'Rs. ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description for this class',
                    prefixIcon: Icon(LucideIcons.alignLeft),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isEditing ? LucideIcons.check : LucideIcons.plus),
          label: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
