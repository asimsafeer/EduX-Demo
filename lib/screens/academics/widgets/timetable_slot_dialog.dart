/// EduX School Management System
/// Timetable Slot Dialog - Add/Edit timetable slot
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/academics_provider.dart';
import '../../../providers/staff_provider.dart'; // Added
import '../../../repositories/timetable_repository.dart';
// import '../../../repositories/class_subject_repository.dart'; // Unused

/// Dialog for creating or editing a timetable slot
class TimetableSlotDialog extends ConsumerStatefulWidget {
  final int classId;
  final int sectionId;
  final String academicYear;
  final String dayOfWeek;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final TimetableSlotWithDetails? existingSlot;

  const TimetableSlotDialog({
    super.key,
    required this.classId,
    required this.sectionId,
    required this.academicYear,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.existingSlot,
  });

  @override
  ConsumerState<TimetableSlotDialog> createState() =>
      _TimetableSlotDialogState();
}

class _TimetableSlotDialogState extends ConsumerState<TimetableSlotDialog> {
  int? _selectedSubjectId;
  int? _selectedTeacherId;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingSlot != null;

  static const _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
  };

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _selectedSubjectId = widget.existingSlot!.slot.subjectId;
      _selectedTeacherId = widget.existingSlot!.teacherId;
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = ref.read(timetableOperationProvider.notifier);
    bool success;

    if (isEditing) {
      success = await notifier.updateSlot(
        id: widget.existingSlot!.slot.id,
        classId: widget.classId,
        sectionId: widget.sectionId,
        subjectId: _selectedSubjectId!,
        dayOfWeek: widget.dayOfWeek,
        periodNumber: widget.periodNumber,
        startTime: widget.startTime,
        endTime: widget.endTime,
        academicYear: widget.academicYear,
        teacherId: _selectedTeacherId,
      );
    } else {
      success = await notifier.createSlot(
        classId: widget.classId,
        sectionId: widget.sectionId,
        subjectId: _selectedSubjectId!,
        dayOfWeek: widget.dayOfWeek,
        periodNumber: widget.periodNumber,
        startTime: widget.startTime,
        endTime: widget.endTime,
        academicYear: widget.academicYear,
        teacherId: _selectedTeacherId,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to remove this slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      final success = await ref
          .read(timetableOperationProvider.notifier)
          .deleteSlot(
            widget.existingSlot!.slot.id,
            widget.classId,
            widget.sectionId,
            widget.academicYear,
          );

      if (mounted && success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationState = ref.watch(timetableOperationProvider);

    // Get class subjects
    final classSubjectsAsync = ref.watch(
      classSubjectsProvider((
        classId: widget.classId,
        academicYear: widget.academicYear,
      )),
    );

    // Get teachers
    final teachersAsync = ref.watch(teachersProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEditing ? LucideIcons.edit2 : LucideIcons.plus,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isEditing ? 'Edit Slot' : 'Add Slot',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slot info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_dayLabels[widget.dayOfWeek] ?? widget.dayOfWeek}, Period ${widget.periodNumber}',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.startTime} - ${widget.endTime}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

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
                                const SizedBox(width: 12),
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
                          const SizedBox(height: 24),
                        ],

                        // Subject dropdown
                        classSubjectsAsync.when(
                          data: (subjects) {
                            if (subjects.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      LucideIcons.alertTriangle,
                                      color: Colors.orange[700],
                                      size: 32,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Subjects Assigned',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(color: Colors.orange[900]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'There are no subjects assigned to this class for the selected academic year.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.orange[900]),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<int>(
                              initialValue: _selectedSubjectId,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                prefixIcon: Icon(LucideIcons.book),
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                              hint: const Text('Select Subject'),
                              items: subjects
                                  .map(
                                    (cs) => DropdownMenuItem(
                                      value: cs.subject.id,
                                      child: Text(cs.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubjectId = value;
                                  // Auto-select teacher if subject has one assigned
                                  final selected = subjects.firstWhere(
                                    (cs) => cs.subject.id == value,
                                    orElse: () => subjects.first,
                                  );
                                  if (selected.teacherId != null) {
                                    _selectedTeacherId = selected.teacherId;
                                  }
                                });
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, s) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Failed to load subjects: $e',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Teacher dropdown
                        teachersAsync.when(
                          data: (teachers) => DropdownButtonFormField<int?>(
                            initialValue: _selectedTeacherId,
                            decoration: const InputDecoration(
                              labelText: 'Teacher',
                              prefixIcon: Icon(LucideIcons.user),
                              border: OutlineInputBorder(),
                              filled: true,
                              helperText: 'Optional',
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
                          loading: () => const SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, s) => Text(
                            'Failed to load teachers',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isEditing) ...[
                        TextButton.icon(
                          onPressed: _isSubmitting ? null : _handleDelete,
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                        const Spacer(),
                      ],
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isEditing
                                    ? LucideIcons.check
                                    : LucideIcons.plus,
                                size: 18,
                              ),
                        label: Text(isEditing ? 'Update Slot' : 'Add Slot'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
