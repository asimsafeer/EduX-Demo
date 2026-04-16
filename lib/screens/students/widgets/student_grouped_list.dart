import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/student_repository.dart';
import 'student_data_table.dart';

class StudentGroupedList extends ConsumerWidget {
  final List<StudentWithEnrollment> students;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int) onView;

  const StudentGroupedList({
    super.key,
    required this.students,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    // Group students by class and section
    final groupedStudents = <String, List<StudentWithEnrollment>>{};
    for (final student in students) {
      final key = student.classSection;
      if (!groupedStudents.containsKey(key)) {
        groupedStudents[key] = [];
      }
      groupedStudents[key]!.add(student);
    }

    // Sort keys (Class Section names)
    final sortedKeys = groupedStudents.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final classStudents = groupedStudents[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: double.infinity,
              child: Row(
                children: [
                  Text(
                    key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${classStudents.length} students',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StudentDataTable(
              students: classStudents,
              onEdit: onEdit,
              onDelete: onDelete,
              onView: onView,
              showCheckboxColumn:
                  false, // Optional: might want to disable checkboxes in grouped view if bulk actions are complex
            ),
          ],
        );
      },
    );
  }
}
