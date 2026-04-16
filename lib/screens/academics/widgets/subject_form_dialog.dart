/// EduX School Management System
/// Subject Form Dialog - Add/Edit subject
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';

/// Dialog for creating or editing a subject
class SubjectFormDialog extends ConsumerStatefulWidget {
  final Subject? subject;

  const SubjectFormDialog({super.key, this.subject});

  @override
  ConsumerState<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends ConsumerState<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _creditHoursController;
  late final TextEditingController _descriptionController;

  String _selectedType = 'core';
  bool _isSubmitting = false;

  bool get isEditing => widget.subject != null;

  static const _typeOptions = {
    'core': 'Core Subject',
    'elective': 'Elective',
    'optional': 'Optional',
  };

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;

    _codeController = TextEditingController(text: subject?.code ?? '');
    _nameController = TextEditingController(text: subject?.name ?? '');
    _creditHoursController = TextEditingController(
      text: subject?.creditHours?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: subject?.description ?? '',
    );
    _selectedType = subject?.type ?? 'core';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(subjectOperationProvider.notifier);

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final creditHours = int.tryParse(_creditHoursController.text);
    final description = _descriptionController.text.trim();

    bool success;
    if (isEditing) {
      success = await notifier.updateSubject(
        id: widget.subject!.id,
        code: code,
        name: name,
        type: _selectedType,
        creditHours: creditHours,
        description: description.isEmpty ? null : description,
      );
    } else {
      success = await notifier.createSubject(
        code: code,
        name: name,
        type: _selectedType,
        creditHours: creditHours,
        description: description.isEmpty ? null : description,
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
    final operationState = ref.watch(subjectOperationProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? LucideIcons.edit2 : LucideIcons.plus,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Subject' : 'Add New Subject'),
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

                // Code and name row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code *',
                          hintText: 'e.g., ENG, MATH',
                          prefixIcon: Icon(LucideIcons.hash),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(10),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            );
                          }),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (value.length < 2) {
                            return 'Min 2 chars';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name *',
                          hintText: 'e.g., English, Mathematics',
                          prefixIcon: Icon(LucideIcons.book),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type and credit hours row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                        items: _typeOptions.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _creditHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Credit Hours',
                          hintText: 'e.g., 3',
                          prefixIcon: Icon(LucideIcons.clock),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description for this subject',
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
