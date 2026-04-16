/// EduX School Management System
/// Class Subject Assignment Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../database/app_database.dart';
import '../../providers/academics_provider.dart';
import '../../providers/staff_provider.dart'; // Added
import '../../repositories/class_subject_repository.dart';

/// Screen for managing subject assignments for a specific class
class ClassSubjectAssignmentScreen extends ConsumerStatefulWidget {
  final int classId;

  const ClassSubjectAssignmentScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassSubjectAssignmentScreen> createState() =>
      _ClassSubjectAssignmentScreenState();
}

class _ClassSubjectAssignmentScreenState
    extends ConsumerState<ClassSubjectAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    final classAsync = ref.watch(classWithSectionsProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(title: const Text('Subject Assignments')),
      body: academicYearAsync.when(
        data: (academicYear) => classAsync.when(
          data: (classData) {
            if (classData == null) {
              return const AppErrorState(message: 'Class not found');
            }
            return _buildContent(context, classData.schoolClass, academicYear);
          },
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorState(message: err.toString()),
        ),
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => AppErrorState(message: 'Failed to load year'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectsDialog(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Subjects'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SchoolClass schoolClass,
    String academicYear,
  ) {
    final assignmentAsync = ref.watch(
      classSubjectsProvider((
        classId: widget.classId,
        academicYear: academicYear,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign subjects to ${schoolClass.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Academic Year: $academicYear',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: assignmentAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return AppEmptyState(
                  icon: LucideIcons.bookOpen,
                  title: 'No Subjects Assigned',
                  description:
                      'Add subjects to this class to start scheduling.',
                  actionText: 'Add Subjects',
                  onAction: () => _showAddSubjectsDialog(context),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = assignments[index];
                  return _buildAssignmentTile(context, item);
                },
              );
            },
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.refresh(
                classSubjectsProvider((
                  classId: widget.classId,
                  academicYear: academicYear,
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentTile(
    BuildContext context,
    ClassSubjectWithDetails assignment,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          assignment.subject.code.substring(0, 1),
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(assignment.subject.name),
      subtitle: Text(
        'Code: ${assignment.subject.code} • ${assignment.teacherName ?? "No Teacher Assigned"}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'Assign Teacher',
            onPressed: () => _showAssignTeacherDialog(context, assignment),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
            tooltip: 'Unassign',
            onPressed: () => _confirmUnassign(context, assignment),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubjectsDialog(BuildContext context) async {
    final academicYear = await ref.read(currentAcademicYearProvider.future);

    // Get unassigned subjects
    final availableSubjects = await ref
        .read(classSubjectRepositoryProvider)
        .getUnassignedSubjects(widget.classId, academicYear);

    if (!context.mounted) return;

    final selected = await showDialog<List<int>>(
      context: context,
      builder: (context) => _SelectSubjectsDialog(subjects: availableSubjects),
    );

    if (selected != null && selected.isNotEmpty) {
      // Bulk assign
      await ref
          .read(classSubjectRepositoryProvider)
          .bulkAssign(widget.classId, selected, academicYear);

      ref.invalidate(classSubjectsProvider);
    }
  }

  Future<void> _showAssignTeacherDialog(
    BuildContext context,
    ClassSubjectWithDetails assignment,
  ) async {
    final teachers = await ref.read(teachersProvider.future);

    if (!context.mounted) return;

    int? selectedTeacherId = assignment.teacherId;

    await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Teacher for ${assignment.subject.name}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<int?>(
              initialValue: selectedTeacherId,
              decoration: const InputDecoration(
                labelText: 'Select Teacher',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Not Assigned'),
                ),
                ...teachers.map(
                  (t) => DropdownMenuItem(
                    value: t.staff.id,
                    child: Text(t.fullName),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => selectedTeacherId = val),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // We return the selected ID inside a wrapper or just the ID.
              // Since ID can be null (unassigned), we need to distinguish between "Cancel" (null result) and "Unassign" (null ID).
              // BUT showDialog returns T? which is null if dismissed.
              // So to pass "Unassign" (null), we can't just return null.
              // WORKAROUND: We perform the action HERE.
              Navigator.pop(context); // Close dialog
              _updateTeacher(
                context,
                assignment.classSubject.id,
                selectedTeacherId,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacher(
    BuildContext context,
    int classSubjectId,
    int? teacherId,
  ) async {
    final academicYear = await ref.read(currentAcademicYearProvider.future);
    await ref
        .read(classSubjectOperationProvider.notifier)
        .assignTeacher(classSubjectId, widget.classId, academicYear, teacherId);
    // No need to invalidate manually if notifier does it, but purely safer:
    // ref.invalidate(classSubjectsProvider); // Notifier does it.
  }

  // Revised method to ensure update works
  Future<void> _confirmUnassign(
    BuildContext context,
    ClassSubjectWithDetails assignment,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Subject?'),
        content: Text(
          'Are you sure you want to remove ${assignment.subject.name} from this class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(classSubjectRepositoryProvider)
          .unassign(assignment.classSubject.id);
      ref.invalidate(classSubjectsProvider);
    }
  }
}

class _SelectSubjectsDialog extends StatefulWidget {
  final List<Subject> subjects;

  const _SelectSubjectsDialog({required this.subjects});

  @override
  State<_SelectSubjectsDialog> createState() => _SelectSubjectsDialogState();
}

class _SelectSubjectsDialogState extends State<_SelectSubjectsDialog> {
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subjects'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: widget.subjects.isEmpty
            ? const Center(child: Text('No unassigned subjects available'))
            : ListView.builder(
                itemCount: widget.subjects.length,
                itemBuilder: (context, index) {
                  final subject = widget.subjects[index];
                  final isSelected = _selectedIds.contains(subject.id);
                  return CheckboxListTile(
                    title: Text(subject.name),
                    subtitle: Text(subject.code),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(subject.id);
                        } else {
                          _selectedIds.remove(subject.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedIds.toList()),
          child: Text('Add (${_selectedIds.length})'),
        ),
      ],
    );
  }
}
