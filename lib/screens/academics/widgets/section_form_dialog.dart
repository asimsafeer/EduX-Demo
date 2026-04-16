/// EduX School Management System
/// Section Form Dialog - Add/Edit section
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../database/app_database.dart';
import '../../../providers/academics_provider.dart';
import '../../../providers/staff_provider.dart'; // Added

/// Dialog for creating or editing a section
class SectionFormDialog extends ConsumerStatefulWidget {
  final int classId;
  final Section? section;

  const SectionFormDialog({super.key, required this.classId, this.section});

  @override
  ConsumerState<SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends ConsumerState<SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _roomNumberController;

  int? _selectedTeacherId;
  bool _isSubmitting = false;

  bool get isEditing => widget.section != null;

  @override
  void initState() {
    super.initState();
    final section = widget.section;

    _nameController = TextEditingController(text: section?.name ?? '');
    _capacityController = TextEditingController(
      text: section?.capacity?.toString() ?? '30',
    );
    _roomNumberController = TextEditingController(
      text: section?.roomNumber ?? '',
    );
    _selectedTeacherId = section?.classTeacherId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(sectionOperationProvider.notifier);

    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text);
    final roomNumber = _roomNumberController.text.trim();

    bool success;
    if (isEditing) {
      success = await notifier.updateSection(
        id: widget.section!.id,
        classId: widget.classId,
        name: name,
        capacity: capacity,
        roomNumber: roomNumber.isEmpty ? null : roomNumber,
        classTeacherId: _selectedTeacherId,
      );
    } else {
      success = await notifier.createSection(
        classId: widget.classId,
        name: name,
        capacity: capacity,
        roomNumber: roomNumber.isEmpty ? null : roomNumber,
        classTeacherId: _selectedTeacherId,
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
    final operationState = ref.watch(sectionOperationProvider);
    final classAsync = ref.watch(classWithSectionsProvider(widget.classId));
    final teachersAsync = ref.watch(teachersProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? LucideIcons.edit2 : LucideIcons.plus,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Section' : 'Add New Section'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Class info
                classAsync.when(
                  data: (data) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.graduationCap,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Class: ${data?.schoolClass.name ?? "Unknown"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

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

                // Section name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Section Name *',
                    hintText: 'e.g., A, B, C, Blue, Red',
                    prefixIcon: Icon(LucideIcons.type),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a section name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Capacity and room row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          hintText: 'e.g., 30',
                          prefixIcon: Icon(LucideIcons.users),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'e.g., 101-A',
                          prefixIcon: Icon(LucideIcons.doorOpen),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class teacher dropdown
                teachersAsync.when(
                  data: (teachers) => DropdownButtonFormField<int?>(
                    initialValue: _selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'Class Teacher (Optional)',
                      prefixIcon: Icon(LucideIcons.userCheck),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Not Assigned'),
                      ),
                      ...teachers.map(
                        (teacher) => DropdownMenuItem(
                          value: teacher.staff.id,
                          child: Text(teacher.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTeacherId = value);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load teachers'),
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
