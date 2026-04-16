/// EduX School Management System
/// Staff Assignments Screen - Teaching assignments management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/staff_provider.dart';
import '../../providers/academics_provider.dart'; // Added
import '../../repositories/staff_repository.dart';
import '../../repositories/staff_assignment_repository.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../database/app_database.dart'; // Added
import 'package:drift/drift.dart' hide Column; // Added

/// Teaching assignments management screen
class StaffAssignmentsScreen extends ConsumerStatefulWidget {
  const StaffAssignmentsScreen({super.key});

  @override
  ConsumerState<StaffAssignmentsScreen> createState() =>
      _StaffAssignmentsScreenState();
}

class _StaffAssignmentsScreenState extends ConsumerState<StaffAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // academicYear is used in dropdown value
    final academicYear = ref.watch(assignmentAcademicYearProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
        title: const Text('Teaching Assignments'),
        actions: [
          // Academic year selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: academicYear,
                items: _getAcademicYears()
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(assignmentAcademicYearProvider.notifier).state =
                        value;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Teacher'),
            Tab(text: 'By Class'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ByTeacherTab(), _ByClassTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignmentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
      ),
    );
  }

  List<String> _getAcademicYears() {
    final now = DateTime.now();
    final years = <String>[];
    for (int i = -2; i <= 1; i++) {
      final year = now.year + i;
      years.add('$year-${year + 1}');
    }
    return years;
  }

  Future<void> _showAssignmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _AssignmentDialog(),
    );
    ref.invalidate(staffAssignmentsProvider);
  }
}

class _ByTeacherTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);
    final _ = Theme.of(context); // unused but kept for consistency

    return teachersAsync.when(
      data: (teachers) {
        if (teachers.isEmpty) {
          return const Center(child: Text('No teachers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            return _TeacherAssignmentCard(teacher: teacher);
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Failed to load teachers: $e',
        onRetry: () => ref.invalidate(teachersProvider),
      ),
    );
  }
}

class _TeacherAssignmentCard extends ConsumerWidget {
  final StaffWithRole teacher;

  const _TeacherAssignmentCard({required this.teacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assignmentsAsync = ref.watch(
      assignmentsByStaffProvider(teacher.staff.id),
    );
    final workloadAsync = ref.watch(teacherWorkloadProvider(teacher.staff.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: teacher.staff.photo != null
              ? MemoryImage(teacher.staff.photo!)
              : null,
          child: teacher.staff.photo == null ? Text(teacher.fullName[0]) : null,
        ),
        title: Text(teacher.fullName),
        subtitle: Text(teacher.staff.designation),
        trailing: workloadAsync.when(
          data: (workload) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${workload.assignments.length} assignments',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${workload.totalClasses} classes',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          loading: () => const SizedBox(width: 60),
          error: (_, __) => const SizedBox(width: 60),
        ),
        children: [
          assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No assignments'),
                );
              }
              return Column(
                children: assignments.map((a) {
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        a.subject.name[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(a.subject.name),
                    subtitle: Text(a.classSection),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.assignment.isClassTeacher)
                          const Chip(
                            label: Text('CT', style: TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        const SizedBox(width: 8),
                        const Text('6/week'),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ByClassTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(staffAssignmentsProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Center(child: Text('No assignments found'));
        }

        // Group by class
        final byClass = <String, List<StaffAssignmentWithDetails>>{};
        for (final a in assignments) {
          byClass.putIfAbsent(a.classSection, () => []).add(a);
        }

        final sortedClasses = byClass.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedClasses.length,
          itemBuilder: (context, index) {
            final classSection = sortedClasses[index];
            final classAssignments = byClass[classSection]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(child: Text(classSection.split(' ')[0])),
                title: Text(classSection),
                subtitle: Text('${classAssignments.length} subjects assigned'),
                children: classAssignments.map((a) {
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text(
                        a.subject.name[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(a.subject.name),
                    subtitle: Text(
                      '${a.staff.firstName} ${a.staff.lastName}'.trim(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.assignment.isClassTeacher)
                          const Chip(
                            label: Text(
                              'Class Teacher',
                              style: TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Failed to load assignments: $e',
        onRetry: () => ref.invalidate(staffAssignmentsProvider),
      ),
    );
  }
}

class _AssignmentDialog extends ConsumerStatefulWidget {
  const _AssignmentDialog();

  @override
  ConsumerState<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends ConsumerState<_AssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedStaffId;
  int? _selectedClassId;
  int? _selectedSectionId;
  int? _selectedSubjectId;

  bool _isClassTeacher = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersProvider);

    return AlertDialog(
      title: const Text('New Teaching Assignment'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Teacher selection
              teachersAsync.when(
                data: (teachers) => DropdownButtonFormField<int>(
                  initialValue: _selectedStaffId,
                  decoration: const InputDecoration(
                    labelText: 'Teacher *',
                    border: OutlineInputBorder(),
                  ),
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.staff.id,
                          child: Text(t.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStaffId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load teachers'),
              ),
              const SizedBox(height: 16),

              // Class selection
              ref
                  .watch(classesProvider)
                  .when(
                    data: (classes) => DropdownButtonFormField<int>(
                      initialValue: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class *',
                        border: OutlineInputBorder(),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedClassId = v;
                        _selectedSectionId = null;
                      }),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load classes'),
                  ),
              const SizedBox(height: 16),

              // Section selection
              if (_selectedClassId != null) ...[
                ref
                    .watch(sectionsByClassProvider(_selectedClassId!))
                    .when(
                      data: (sections) => DropdownButtonFormField<int>(
                        initialValue: _selectedSectionId,
                        decoration: const InputDecoration(
                          labelText: 'Section *',
                          border: OutlineInputBorder(),
                        ),
                        items: sections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedSectionId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Failed to load sections'),
                    ),
                const SizedBox(height: 16),
              ],

              // Subject selection
              ref
                  .watch(subjectsProvider)
                  .when(
                    data: (subjects) => DropdownButtonFormField<int>(
                      initialValue: _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      items: subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load subjects'),
                  ),
              const SizedBox(height: 16),

              const SizedBox(height: 8),

              // Class teacher toggle
              CheckboxListTile(
                title: const Text('Is Class Teacher'),
                value: _isClassTeacher,
                onChanged: (v) => setState(() => _isClassTeacher = v ?? false),
                contentPadding: EdgeInsets.zero,
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
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(staffAssignmentRepositoryProvider);
      final academicYear = ref.read(assignmentAcademicYearProvider);

      await repository.create(
        StaffSubjectAssignmentsCompanion.insert(
          staffId: _selectedStaffId!,
          classId: _selectedClassId!,
          sectionId: Value(_selectedSectionId),
          subjectId: _selectedSubjectId!,
          academicYear: academicYear,
          isClassTeacher: Value(_isClassTeacher),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
