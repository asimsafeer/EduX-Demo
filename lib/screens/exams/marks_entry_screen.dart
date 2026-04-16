/// EduX School Management System
/// Marks Entry Screen - Bulk marks entry with validation
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/exam_provider.dart';
import '../../providers/auth_provider.dart' show currentUserProvider;
import '../../providers/dashboard_provider.dart' show dashboardProvider;
import '../../repositories/exam_repository.dart';
import '../../repositories/marks_repository.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final int examId;
  final int? subjectId;

  const MarksEntryScreen({super.key, required this.examId, this.subjectId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  final Map<int, TextEditingController> _markControllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedExamIdProvider.notifier).state = widget.examId;
      if (widget.subjectId != null) {
        ref.read(selectedExamSubjectIdProvider.notifier).state =
            widget.subjectId;
      }
    });
  }

  @override
  void didUpdateWidget(covariant MarksEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.examId != widget.examId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedExamIdProvider.notifier).state = widget.examId;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _markControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examAsync = ref.watch(currentExamProvider);
    final subjectsAsync = ref.watch(examSubjectsProvider);
    final selectedSubjectId = ref.watch(selectedExamSubjectIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Marks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Save button
          Consumer(
            builder: (context, ref, _) {
              final marksState = ref.watch(marksEntryProvider);
              return AppButton.primary(
                text: 'Save',
                icon: Icons.save,
                isLoading: marksState.isSaving,
                size: AppButtonSize.small,
                onPressed: marksState.isSaving ? null : _handleSave,
              );
            },
          ),
          const SizedBox(width: 8),

          // Complete button (Only for active exams)
          if (examAsync.valueOrNull?.exam.status == ExamConstants.statusActive)
            IconButton(
              tooltip: 'Complete Exam',
              icon: const Icon(Icons.check_circle_outlined),
              onPressed: () => _handleComplete(context, ref, widget.examId),
            ),

          const SizedBox(width: 8),
        ],
      ),
      body: examAsync.when(
        skipLoadingOnReload: true,
        data: (exam) {
          if (exam == null) {
            return const Center(child: Text('Exam not found'));
          }

          if (exam.exam.status != 'active') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Marks entry is not available',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.exam.status == 'draft'
                        ? 'Publish the exam first to enter marks'
                        : 'This exam has been completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton.secondary(
                    text: 'Go Back',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          }

          // Calculate "live" progress by checking local state
          final studentMarksList =
              ref.watch(studentMarksProvider).valueOrNull ?? [];
          final marksState = ref.watch(marksEntryProvider);
          int newlyMarkedCount = 0;

          if (studentMarksList.isNotEmpty) {
            final alreadyMarkedIds = studentMarksList
                .where((e) => e.isMarked || e.isAbsent)
                .map((e) => e.student.id)
                .toSet();

            final locallyMarkedIds = <int>{
              ...marksState.marks.keys.where(
                (id) => marksState.marks[id] != null,
              ),
            };
            locallyMarkedIds.addAll(
              marksState.absent.keys.where(
                (id) => marksState.absent[id] == true,
              ),
            );

            newlyMarkedCount = locallyMarkedIds
                .difference(alreadyMarkedIds)
                .length;
          }

          return Column(
            children: [
              // Exam info header
              _buildExamHeader(context, theme, exam, newlyMarkedCount),

              // Subject selector
              subjectsAsync.when(
                skipLoadingOnReload: true,
                data: (subjects) => _buildSubjectSelector(
                  context,
                  theme,
                  subjects,
                  selectedSubjectId,
                  marksState,
                  studentMarksList,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),

              // Marks entry table
              Expanded(
                child: selectedSubjectId != null
                    ? _MarksEntryTable(
                        examId: widget.examId,
                        examSubjectId: selectedSubjectId,
                        markControllers: _markControllers,
                        focusNodes: _focusNodes,
                      )
                    : Center(
                        child: Text(
                          'Select a subject to enter marks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),

              // Bottom status bar
              _buildBottomBar(context, theme),
            ],
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildExamHeader(
    BuildContext context,
    ThemeData theme,
    ExamWithDetails exam,
    int newlyMarkedCount,
  ) {
    int totalMarked = exam.markedStudents + newlyMarkedCount;
    int totalCapacity = exam.totalStudents * exam.subjectCount;
    if (totalCapacity == 0) {
      totalCapacity = 1;
    }
    double progressPct = (totalMarked / totalCapacity) * 100;
    if (progressPct > 100) {
      progressPct = 100;
    }
    bool isComplete = totalMarked >= totalCapacity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.exam.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.class_,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      exam.classInfo.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.book,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.subjectCount} Subjects',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Overall progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Overall Progress',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPct / 100,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      isComplete
                          ? AppColors.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progressPct.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? AppColors.success
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(
    BuildContext context,
    ThemeData theme,
    List<ExamSubjectWithDetails> subjects,
    int? selectedSubjectId,
    MarksEntryState marksState,
    List<StudentMarkEntry> currentSubjectMarks,
  ) {
    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = subject.examSubject.id == selectedSubjectId;

          int localNewlyMarked = 0;
          if (isSelected && currentSubjectMarks.isNotEmpty) {
            final alreadyMarkedIds = currentSubjectMarks
                .where((e) => e.isMarked || e.isAbsent)
                .map((e) => e.student.id)
                .toSet();
            final locallyMarkedIds = <int>{
              ...marksState.marks.keys.where(
                (id) => marksState.marks[id] != null,
              ),
            };
            locallyMarkedIds.addAll(
              marksState.absent.keys.where(
                (id) => marksState.absent[id] == true,
              ),
            );
            localNewlyMarked = locallyMarkedIds
                .difference(alreadyMarkedIds)
                .length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SubjectChip(
              subject: subject,
              isSelected: isSelected,
              localNewlyMarked: localNewlyMarked,
              onTap: () {
                ref.read(selectedExamSubjectIdProvider.notifier).state =
                    subject.examSubject.id;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    final marksState = ref.watch(marksEntryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (marksState.error != null) ...[
            Icon(Icons.warning_amber, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                marksState.error!,
                style: TextStyle(color: theme.colorScheme.error),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter marks for each student. Check absent if student did not appear.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (marksState.savedCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, color: AppColors.success, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${marksState.savedCount} saved',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final selectedSubjectId = ref.read(selectedExamSubjectIdProvider);
    if (selectedSubjectId == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    await ref
        .read(marksEntryProvider.notifier)
        .saveMarks(
          examId: widget.examId,
          examSubjectId: selectedSubjectId,
          enteredBy: currentUser.id,
        );
  }

  Future<void> _handleComplete(
    BuildContext context,
    WidgetRef ref,
    int examId,
  ) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Exam?'),
        content: const Text(
          'This will mark the exam as completed and finalize results. '
          'You won\'t be able to edit marks after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    // Show loading dialog
    bool loadingDismissed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ).then((_) => loadingDismissed = true);

    bool success = false;
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User authentication required');
      }

      await ref
          .read(examServiceProvider)
          .completeExam(examId: examId, completedBy: currentUser.id);
      success = true;
      
      // Invalidate providers to refresh exam list
      ref.invalidate(examsListProvider);
      ref.invalidate(examCountByStatusProvider);
      ref.invalidate(activeExamsProvider);
      ref.invalidate(completedExamsProvider);
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing exam: $e')));
      }
    } finally {
      if (!loadingDismissed && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam completed successfully')),
      );
      context.pop(); // Pop screen
    }
  }
}

class _SubjectChip extends StatelessWidget {
  final ExamSubjectWithDetails subject;
  final bool isSelected;
  final VoidCallback onTap;
  final int localNewlyMarked;

  const _SubjectChip({
    required this.subject,
    required this.isSelected,
    required this.onTap,
    this.localNewlyMarked = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int totalMarked = subject.markedCount + localNewlyMarked;
    if (totalMarked > subject.totalStudents) {
      totalMarked = subject.totalStudents;
    }
    final isComplete =
        totalMarked >= subject.totalStudents && subject.totalStudents > 0;

    final color = isComplete
        ? AppColors.success
        : isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isComplete)
                    Icon(Icons.check_circle, size: 14, color: AppColors.success)
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 14,
                      color: color.withValues(alpha: 0.5),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    subject.subject.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$totalMarked/${subject.totalStudents} entered',
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarksEntryTable extends ConsumerStatefulWidget {
  final int examId;
  final int examSubjectId;
  final Map<int, TextEditingController> markControllers;
  final Map<int, FocusNode> focusNodes;

  const _MarksEntryTable({
    required this.examId,
    required this.examSubjectId,
    required this.markControllers,
    required this.focusNodes,
  });

  @override
  ConsumerState<_MarksEntryTable> createState() => _MarksEntryTableState();
}

class _MarksEntryTableState extends ConsumerState<_MarksEntryTable> {
  @override
  void didUpdateWidget(covariant _MarksEntryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.examSubjectId != widget.examSubjectId) {
      // Clear controllers when subject changes
      widget.markControllers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marksAsync = ref.watch(studentMarksProvider);

    return marksAsync.when(
      data: (marks) {
        if (marks.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline,
            title: 'No Students',
            description: 'No students are enrolled in this class.',
          );
        }

        // Initialize state from entries
        // Initialize state from entries - ONLY if not already initialized or empty
        // logic moved to post-frame callback in parent or regulated here
        // The issue was here: this was re-running on every build

        // Weuse a simple check to avoid re-initialization loops
        // In a real app we might use a separate provider state for "isInitialized"

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final notifier = ref.read(marksEntryProvider.notifier);
          // Only initialize if we have marks and haven't loaded them yet
          // or if the loaded marks don't match (e.g. subject changed)
          // For now, we'll rely on the provider state being managed correctly
          // and only initialize if the marks map is empty but we have data
          if (ref.read(marksEntryProvider).marks.isEmpty && marks.isNotEmpty) {
            notifier.initializeFromEntries(marks);
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: marks.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeader(theme);
            }

            final entry = marks[index - 1];
            return _MarksInputRow(
              entry: entry,
              index: index,
              totalStudents: marks.length,
              controller: _getController(entry),
              focusNode: _getFocusNode(entry),
              onMarksChanged: (marks) {
                ref
                    .read(marksEntryProvider.notifier)
                    .setMarks(entry.student.id, marks, entry.maxMarks);
              },
              onAbsentChanged: (isAbsent) {
                ref
                    .read(marksEntryProvider.notifier)
                    .setAbsent(entry.student.id, isAbsent);
              },
              onRemarksChanged: (remarks) {
                ref
                    .read(marksEntryProvider.notifier)
                    .setRemarks(entry.student.id, remarks);
              },
              onMoveToNext: () {
                _moveToNextRow(marks, index - 1);
              },
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Index column
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Roll No',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Marks',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text(
              'Absent',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text(
              'Remarks',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController _getController(StudentMarkEntry entry) {
    return widget.markControllers.putIfAbsent(
      entry.student.id,
      () => TextEditingController(
        text: entry.marksObtained?.toStringAsFixed(1) ?? '',
      ),
    );
  }

  FocusNode _getFocusNode(StudentMarkEntry entry) {
    return widget.focusNodes.putIfAbsent(entry.student.id, () => FocusNode());
  }

  void _moveToNextRow(List<StudentMarkEntry> marks, int currentIndex) {
    if (currentIndex < marks.length - 1) {
      final nextEntry = marks[currentIndex + 1];
      widget.focusNodes[nextEntry.student.id]?.requestFocus();
    }
  }
}

class _MarksInputRow extends ConsumerWidget {
  final StudentMarkEntry entry;
  final int index;
  final int totalStudents;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<double?> onMarksChanged;
  final ValueChanged<bool> onAbsentChanged;
  final ValueChanged<String?> onRemarksChanged;
  final VoidCallback onMoveToNext;

  const _MarksInputRow({
    required this.entry,
    required this.index,
    required this.totalStudents,
    required this.controller,
    required this.focusNode,
    required this.onMarksChanged,
    required this.onAbsentChanged,
    required this.onRemarksChanged,
    required this.onMoveToNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final marksState = ref.watch(marksEntryProvider);
    final isAbsent = marksState.absent[entry.student.id] ?? entry.isAbsent;

    // Validation error
    final validationError = marksState.validationErrors[entry.student.id];
    final remarks = marksState.remarks[entry.student.id] ?? entry.remarks;
    final hasRemarks = remarks != null && remarks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index.isOdd
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 40,
            child: Text(
              '$index',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Student name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.student.studentName} ${entry.student.fatherName}'
                      .trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.student.admissionNumber,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Roll number
          Expanded(
            flex: 1,
            child: Text(
              entry.enrollment.rollNumber ?? '-',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Marks input
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isAbsent,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  _MarksInputFormatter(entry.maxMarks),
                ],
                decoration: InputDecoration(
                  hintText: isAbsent ? 'Absent' : 'Enter marks',
                  errorText: validationError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixText: '/ ${entry.maxMarks.toStringAsFixed(0)}',
                  suffixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: isAbsent
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.surface,
                ),
                onChanged: (value) {
                  final marks = double.tryParse(value);
                  onMarksChanged(marks);
                },
                onSubmitted: (_) => onMoveToNext(),
              ),
            ),
          ),

          // Absent checkbox
          SizedBox(
            width: 80,
            child: Center(
              child: Checkbox(
                value: isAbsent,
                onChanged: (value) {
                  if (value ?? false) {
                    controller.clear();
                  }
                  onAbsentChanged(value ?? false);
                },
              ),
            ),
          ),

          // Remarks
          SizedBox(
            width: 80,
            child: Center(
              child: IconButton(
                icon: Icon(
                  hasRemarks ? Icons.note_alt : Icons.note_add_outlined,
                  color: hasRemarks
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: hasRemarks ? remarks : 'Add Remarks',
                onPressed: () => _showRemarksDialog(context, remarks),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemarksDialog(
    BuildContext context,
    String? currentRemarks,
  ) async {
    final controller = TextEditingController(text: currentRemarks);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Remarks'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter student remarks...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      onRemarksChanged(result.trim().isEmpty ? null : result.trim());
    }
  }
}

class _MarksInputFormatter extends TextInputFormatter {
  final double maxMarks;

  _MarksInputFormatter(this.maxMarks);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = double.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value > maxMarks) {
      return oldValue;
    }

    return newValue;
  }
}
