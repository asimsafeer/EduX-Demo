/// EduX School Management System
/// Fee Structure Screen - Configure class-wise fee structures
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart' hide currentAcademicYearProvider;
import 'widgets/fee_structure_editor.dart';

class FeeStructureScreen extends ConsumerStatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  ConsumerState<FeeStructureScreen> createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends ConsumerState<FeeStructureScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final selectedClassId = ref.watch(selectedFeeClassIdProvider);
    final academicYear = ref.watch(currentAcademicYearProvider);
    final asyncFeeTypes = ref.watch(feeTypesProvider);
    final asyncClasses = ref.watch(classesProvider);
    final formState = ref.watch(feeStructureFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure'),
        actions: [
          if (selectedClassId != null && _isEditing)
            TextButton.icon(
              onPressed: _saveChanges,
              icon: formState.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                formState.isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Class and year selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Class dropdown
                Expanded(
                  flex: 2,
                  child: asyncClasses.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (classes) => DropdownButtonFormField<int>(
                      initialValue: selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        ref.read(selectedFeeClassIdProvider.notifier).state =
                            value;
                        if (value != null) {
                          ref
                              .read(feeStructureFormProvider.notifier)
                              .setClassId(value);
                        }
                        setState(() => _isEditing = false);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Academic year display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        academicYear,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: selectedClassId == null
                ? _buildEmptyState()
                : _buildFeeStructureContent(selectedClassId, asyncFeeTypes),
          ),
        ],
      ),
      floatingActionButton: selectedClassId != null
          ? FloatingActionButton.extended(
              onPressed: _isEditing
                  ? _saveChanges
                  : () => setState(() => _isEditing = true),
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              label: Text(_isEditing ? 'Save Changes' : 'Edit Fees'),
              backgroundColor: _isEditing
                  ? Theme.of(context).colorScheme.primary
                  : null,
              foregroundColor: _isEditing ? Colors.white : null,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Class',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a class to view and configure\nits fee structure',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStructureContent(
    int classId,
    AsyncValue<List<FeeType>> asyncFeeTypes,
  ) {
    return FeeStructureEditor(
      classId: classId,
      isEditing: _isEditing,
      onEditingChanged: (value) {
        setState(() => _isEditing = value);
      },
    );
  }

  Future<void> _saveChanges() async {
    final success = await ref.read(feeStructureFormProvider.notifier).save();

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee structure saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      final error = ref.read(feeStructureFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save fee structure'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
