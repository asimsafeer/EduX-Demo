import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/academics_provider.dart';
import '../../../../providers/exam_provider.dart';
import '../../../../providers/student_provider.dart'
    hide classesProvider, sectionsByClassProvider, currentAcademicYearProvider;
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_text_field.dart';

// ============================================
// CLASS SELECTOR DIALOG
// ============================================

class ClassSelectorDialog extends ConsumerStatefulWidget {
  final Function(int classId, int? sectionId) onSelected;
  final bool requireSection;
  final String title;

  const ClassSelectorDialog({
    super.key,
    required this.onSelected,
    this.requireSection = false,
    this.title = 'Select Class',
  });

  @override
  ConsumerState<ClassSelectorDialog> createState() =>
      _ClassSelectorDialogState();
}

class _ClassSelectorDialogState extends ConsumerState<ClassSelectorDialog> {
  int? _selectedClassId;
  int? _selectedSectionId;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // Class Dropdown
            classesAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (classes) {
                if (classes.isEmpty) {
                  return const Text('No classes found');
                }
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedClassId,
                  items: classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedClassId = val;
                      _selectedSectionId = null;
                      _error = null;
                    });
                  },
                );
              },
            ),

            // Section Dropdown
            if (_selectedClassId != null) ...[
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final sectionsAsync = ref.watch(
                    sectionsByClassProvider(_selectedClassId!),
                  );
                  return sectionsAsync.when(
                    loading: () => const AppLoadingIndicator(),
                    error: (e, _) => AppErrorState(message: e.toString()),
                    data: (sections) {
                      if (sections.isEmpty) {
                        return const Text('No active sections in this class');
                      }
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Section (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedSectionId,
                        items: sections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSectionId = val;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            if (_selectedClassId == null) {
              setState(() => _error = 'Please select a class');
              return;
            }
            if (widget.requireSection && _selectedSectionId == null) {
              setState(() => _error = 'Please select a section');
              return;
            }
            // Pop FIRST then call callback to avoid dialog transition issues
            final cid = _selectedClassId!;
            final sid = _selectedSectionId;
            Navigator.pop(context);
            widget.onSelected(cid, sid);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ============================================
// STUDENT SELECTOR DIALOG
// ============================================

class StudentSelectorDialog extends ConsumerStatefulWidget {
  final Function(int studentId) onSelected;
  final String title;

  const StudentSelectorDialog({
    super.key,
    required this.onSelected,
    this.title = 'Select Student',
  });

  @override
  ConsumerState<StudentSelectorDialog> createState() =>
      _StudentSelectorDialogState();
}

class _StudentSelectorDialogState extends ConsumerState<StudentSelectorDialog> {
  final _searchController = TextEditingController();
  int? _selectedStudentId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use allActiveStudentsProvider to get all students without pagination
    final studentsAsync = ref.watch(allActiveStudentsProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _searchController,
              label: 'Search Student',
              prefixIcon: Icons.search,
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                height: 300,
                child: studentsAsync.when(
                  loading: () => const Center(child: AppLoadingIndicator()),
                  error: (e, _) => AppErrorState(message: e.toString()),
                  data: (students) {
                    // Filter students locally based on search query
                    final filteredStudents = _searchQuery.isEmpty
                        ? students
                        : students.where((s) {
                            final name = '${s.student.studentName} ${s.student.fatherName ?? ''}'.toLowerCase();
                            final admNo = s.student.admissionNumber.toLowerCase();
                            final className = s.schoolClass?.name.toLowerCase() ?? '';
                            return name.contains(_searchQuery) ||
                                admNo.contains(_searchQuery) ||
                                className.contains(_searchQuery);
                          }).toList();
                    
                    if (filteredStudents.isEmpty) {
                      return const Center(child: Text('No students found'));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final isSelected =
                            _selectedStudentId == student.student.id;
                        return ListTile(
                          title: Text(
                            '${student.student.studentName} ${student.student.fatherName ?? ''}',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Adm: ${student.student.admissionNumber} | Class: ${student.classSection}',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                        .withValues(alpha: 0.8)
                                  : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          onTap: () {
                            setState(
                              () => _selectedStudentId = student.student.id,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _selectedStudentId == null
              ? null
              : () {
                  final sid = _selectedStudentId!;
                  Navigator.pop(context);
                  widget.onSelected(sid);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ============================================
// EXAM SELECTOR DIALOG
// ============================================

class ExamSelectorDialog extends ConsumerStatefulWidget {
  final Function(int examId) onSelected;
  final String title;

  const ExamSelectorDialog({
    super.key,
    required this.onSelected,
    this.title = 'Select Exam',
  });

  @override
  ConsumerState<ExamSelectorDialog> createState() => _ExamSelectorDialogState();
}

class _ExamSelectorDialogState extends ConsumerState<ExamSelectorDialog> {
  int? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsListProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            examsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (exams) {
                if (exams.isEmpty) {
                  return const Text('No exams found');
                }
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Exam',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedExamId,
                  items: exams
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.exam.id,
                          child: Text(e.exam.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedExamId = val);
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _selectedExamId == null
              ? null
              : () {
                  final eid = _selectedExamId!;
                  Navigator.pop(context);
                  widget.onSelected(eid);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ============================================
// SUBJECT SELECTOR DIALOG
// ============================================

class SubjectSelectorDialog extends ConsumerStatefulWidget {
  final int classId;
  final Function(int subjectId) onSelected;
  final String title;

  const SubjectSelectorDialog({
    super.key,
    required this.classId,
    required this.onSelected,
    this.title = 'Select Subject',
  });

  @override
  ConsumerState<SubjectSelectorDialog> createState() =>
      _SubjectSelectorDialogState();
}

class _SubjectSelectorDialogState extends ConsumerState<SubjectSelectorDialog> {
  int? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final yearAsync = ref.watch(currentAcademicYearProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: yearAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (e, _) => AppErrorState(message: e.toString()),
          data: (academicYear) {
            final subjectsAsync = ref.watch(
              classSubjectsProvider((
                classId: widget.classId,
                academicYear: academicYear,
              )),
            );

            return subjectsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return const Text('No subjects found for this class');
                }
                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedSubjectId,
                  items: subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.subject.id,
                          child: Text(s.subject.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSubjectId = val);
                  },
                );
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
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: _selectedSubjectId == null
              ? null
              : () {
                  final sid = _selectedSubjectId!;
                  Navigator.pop(context);
                  widget.onSelected(sid);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ============================================
// MONTH PICKER DIALOG
// ============================================

class MonthPickerDialog extends StatefulWidget {
  final Function(DateTime selectedDate) onSelected;
  final DateTime? initialDate;

  const MonthPickerDialog({
    super.key,
    required this.onSelected,
    this.initialDate,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Month'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simplified Year Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year - 1,
                      _selectedDate.month,
                    );
                  });
                },
                icon: const Icon(Icons.arrow_left),
              ),
              Text(
                '${_selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year + 1,
                      _selectedDate.month,
                    );
                  });
                },
                icon: const Icon(Icons.arrow_right),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            final date = _selectedDate;
            Navigator.pop(context);
            widget.onSelected(date);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
