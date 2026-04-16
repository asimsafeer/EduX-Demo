/// EduX School Management System
/// Student Promotion Screen - Bulk promote/graduate students by class
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../database/app_database.dart';
import '../../providers/student_provider.dart';
import '../../repositories/student_repository.dart';

/// Provider for students filtered by class and section (active only)
final _studentsForPromotionProvider = FutureProvider.autoDispose
    .family<List<StudentWithEnrollment>, ({int classId, int sectionId})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(studentRepositoryProvider);
      return await repo.getByClassSection(params.classId, params.sectionId);
    });

/// Provider to get next class suggestion
final _nextClassProvider = FutureProvider.autoDispose.family<SchoolClass?, int>(
  (ref, classId) async {
    final service = ref.watch(studentServiceProvider);
    return await service.getNextClass(classId);
  },
);

/// Provider to check if this is the highest class
final _isHighestClassProvider = FutureProvider.autoDispose.family<bool, int>((
  ref,
  classId,
) async {
  final service = ref.watch(studentServiceProvider);
  return await service.isHighestClass(classId);
});

class StudentPromotionScreen extends ConsumerStatefulWidget {
  const StudentPromotionScreen({super.key});

  @override
  ConsumerState<StudentPromotionScreen> createState() =>
      _StudentPromotionScreenState();
}

class _StudentPromotionScreenState
    extends ConsumerState<StudentPromotionScreen> {
  // Source selection
  int? _sourceClassId;
  int? _sourceSectionId;

  // Target selection
  int? _targetClassId;
  int? _targetSectionId;
  bool _isGraduating = false;

  // Action mode: 'promote' or 'status'
  String _actionMode = 'promote';

  // For bulk status change
  String _newStatus = 'active';

  // Selected students
  final Set<int> _selectedStudentIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Promotion & Status'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Mode Toggle
            _buildActionModeSelector(theme),
            const SizedBox(height: 24),

            // Source Class/Section Selector
            _buildSourceSelector(theme, classesAsync),
            const SizedBox(height: 24),

            // Target selector (only for promote mode)
            if (_actionMode == 'promote' &&
                _sourceClassId != null &&
                _sourceSectionId != null)
              _buildTargetSelector(theme, classesAsync),

            // Status selector (only for status mode)
            if (_actionMode == 'status' &&
                _sourceClassId != null &&
                _sourceSectionId != null)
              _buildStatusSelector(theme),

            const SizedBox(height: 24),

            // Students list
            if (_sourceClassId != null && _sourceSectionId != null)
              _buildStudentsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionModeSelector(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Action',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'promote',
                  label: Text('Promote / Graduate'),
                  icon: Icon(Icons.school),
                ),
                ButtonSegment(
                  value: 'status',
                  label: Text('Change Status'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_actionMode},
              onSelectionChanged: (value) {
                setState(() {
                  _actionMode = value.first;
                  _selectedStudentIds.clear();
                  _selectAll = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelector(
    ThemeData theme,
    AsyncValue<List<SchoolClass>> classesAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Source Class',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: classesAsync.when(
                    data: (classes) => DropdownButtonFormField<int>(
                      initialValue: _sourceClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
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
                        setState(() {
                          _sourceClassId = value;
                          _sourceSectionId = null;
                          _targetClassId = null;
                          _targetSectionId = null;
                          _isGraduating = false;
                          _selectedStudentIds.clear();
                          _selectAll = false;
                        });
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _sourceClassId != null
                      ? _buildSectionDropdown(
                          theme,
                          _sourceClassId!,
                          _sourceSectionId,
                          'Section',
                          (value) {
                            setState(() {
                              _sourceSectionId = value;
                              _selectedStudentIds.clear();
                              _selectAll = false;
                            });
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDropdown(
    ThemeData theme,
    int classId,
    int? currentValue,
    String label,
    ValueChanged<int?> onChanged,
  ) {
    final sectionsAsync = ref.watch(sectionsByClassProvider(classId));
    return sectionsAsync.when(
      data: (sections) => DropdownButtonFormField<int>(
        initialValue: currentValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.group),
        ),
        items: sections
            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
            .toList(),
        onChanged: onChanged,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildTargetSelector(
    ThemeData theme,
    AsyncValue<List<SchoolClass>> classesAsync,
  ) {
    final isHighestClassAsync = ref.watch(
      _isHighestClassProvider(_sourceClassId!),
    );
    final nextClassAsync = ref.watch(_nextClassProvider(_sourceClassId!));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promote To',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Show auto-graduation hint
            isHighestClassAsync.when(
              data: (isHighest) {
                if (isHighest) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is the highest class. Students will be Graduated.',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Graduate toggle
            CheckboxListTile(
              title: const Text('Graduate Students'),
              subtitle: const Text(
                'Mark as graduated instead of promoting to another class',
              ),
              value: _isGraduating,
              onChanged: (value) {
                setState(() {
                  _isGraduating = value ?? false;
                  if (_isGraduating) {
                    _targetClassId = null;
                    _targetSectionId = null;
                  }
                });
              },
            ),

            // Target class/section (if not graduating)
            if (!_isGraduating) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: classesAsync.when(
                      data: (classes) {
                        // Auto-set next class
                        nextClassAsync.whenData((nextClass) {
                          if (nextClass != null &&
                              _targetClassId == null &&
                              !_isGraduating) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _targetClassId == null) {
                                setState(() {
                                  _targetClassId = nextClass.id;
                                });
                              }
                            });
                          }
                        });

                        return DropdownButtonFormField<int>(
                          initialValue: _targetClassId,
                          decoration: const InputDecoration(
                            labelText: 'Target Class',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.arrow_forward),
                          ),
                          items: classes
                              .where((c) => c.id != _sourceClassId)
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _targetClassId = value;
                              _targetSectionId = null;
                            });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _targetClassId != null
                        ? _buildSectionDropdown(
                            theme,
                            _targetClassId!,
                            _targetSectionId,
                            'Target Section',
                            (value) {
                              setState(() {
                                _targetSectionId = value;
                              });
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String>(
                initialValue: _newStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: StudentStatus.all
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(StudentStatus.getDisplayName(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _newStatus = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(ThemeData theme) {
    final studentsAsync = ref.watch(
      _studentsForPromotionProvider((
        classId: _sourceClassId!,
        sectionId: _sourceSectionId!,
      )),
    );

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No active students in this class/section',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              // Header with Select All and Action Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = value ?? false;
                          if (_selectAll) {
                            _selectedStudentIds.addAll(
                              students.map((s) => s.student.id),
                            );
                          } else {
                            _selectedStudentIds.clear();
                          }
                        });
                      },
                    ),
                    Text(
                      'Select All (${students.length} students)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedStudentIds.isNotEmpty) ...[
                      Text(
                        '${_selectedStudentIds.length} selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(theme),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              // Student List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final swe = students[index];
                  final student = swe.student;
                  final isSelected = _selectedStudentIds.contains(student.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(student.id);
                        } else {
                          _selectedStudentIds.remove(student.id);
                        }
                        _selectAll =
                            _selectedStudentIds.length == students.length;
                      });
                    },
                    title: Text(student.studentName),
                    subtitle: Text(
                      'Adm#: ${student.admissionNumber} • '
                      'Roll: ${swe.currentEnrollment?.rollNumber ?? "N/A"}',
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        student.studentName.isNotEmpty
                            ? student.studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    final operationState = ref.watch(studentOperationProvider);

    if (operationState.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final isPromoteMode = _actionMode == 'promote';
    final buttonLabel = isPromoteMode
        ? (_isGraduating ? 'Graduate Selected' : 'Promote Selected')
        : 'Change Status';
    final buttonIcon = isPromoteMode
        ? (_isGraduating ? Icons.school : Icons.arrow_upward)
        : Icons.swap_horiz;
    final buttonColor = _isGraduating
        ? Colors.amber.shade700
        : theme.colorScheme.primary;

    return FilledButton.icon(
      icon: Icon(buttonIcon),
      label: Text(buttonLabel),
      style: FilledButton.styleFrom(backgroundColor: buttonColor),
      onPressed: _canPerformAction() ? _performAction : null,
    );
  }

  bool _canPerformAction() {
    if (_selectedStudentIds.isEmpty) return false;

    if (_actionMode == 'promote') {
      if (_isGraduating) return true;
      return _targetClassId != null && _targetSectionId != null;
    }

    // status mode
    return true;
  }

  Future<void> _performAction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _actionMode == 'promote'
              ? (_isGraduating ? 'Confirm Graduation' : 'Confirm Promotion')
              : 'Confirm Status Change',
        ),
        content: Text(
          _actionMode == 'promote'
              ? (_isGraduating
                    ? 'Are you sure you want to graduate ${_selectedStudentIds.length} students?'
                    : 'Are you sure you want to promote ${_selectedStudentIds.length} students to the selected class?')
              : 'Are you sure you want to change the status of ${_selectedStudentIds.length} students to "${StudentStatus.getDisplayName(_newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifier = ref.read(studentOperationProvider.notifier);
    int result = 0;

    if (_actionMode == 'promote') {
      final academicYear = await ref.read(currentAcademicYearProvider.future);

      result = await notifier.bulkPromoteStudents(
        studentIds: _selectedStudentIds.toList(),
        targetClassId: _isGraduating ? null : _targetClassId,
        targetSectionId: _isGraduating ? null : _targetSectionId,
        academicYear: academicYear,
      );
    } else {
      result = await notifier.bulkUpdateStatus(
        _selectedStudentIds.toList(),
        _newStatus,
      );
    }

    if (!mounted) return;

    if (result > 0) {
      // Refresh the students list
      ref.invalidate(_studentsForPromotionProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _actionMode == 'promote'
                ? (_isGraduating
                      ? 'Graduated $result students'
                      : 'Promoted $result students')
                : 'Updated $result students to ${StudentStatus.getDisplayName(_newStatus)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedStudentIds.clear();
        _selectAll = false;
      });
    } else {
      final opState = ref.read(studentOperationProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(opState.error ?? 'Operation failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
