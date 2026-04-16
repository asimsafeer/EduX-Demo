/// EduX School Management System
/// Exam Form Screen - Multi-step wizard for exam creation/editing
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/exam_provider.dart';
import '../../providers/student_provider.dart'
    show databaseProvider, classesProvider, currentAcademicYearProvider;
import '../../providers/auth_provider.dart' show currentUserProvider;
import '../../providers/dashboard_provider.dart';
import '../../services/exam_service.dart';
import '../../providers/academics_provider.dart'
    show classSubjectRepositoryProvider;

import '../../database/app_database.dart';

class ExamFormScreen extends ConsumerStatefulWidget {
  final int? examId;

  const ExamFormScreen({super.key, this.examId});

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saveAsDraft = false;
  bool _isSubmitting = false;

  bool get isEditing => widget.examId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(examFormProvider.notifier).loadExam(widget.examId!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(examFormProvider);

    // Sync text controllers with state
    if (_nameController.text != formState.name) {
      _nameController.text = formState.name;
    }
    if (_descriptionController.text != (formState.description ?? '')) {
      _descriptionController.text = formState.description ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam' : 'Create Exam'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(examFormProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Stepper header
          _buildStepperHeader(context, theme, formState.currentStep),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildStepContent(context, theme, formState),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(context, theme, formState),
        ],
      ),
    );
  }

  Widget _buildStepperHeader(
    BuildContext context,
    ThemeData theme,
    int currentStep,
  ) {
    const steps = ['Basic Info', 'Subjects', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _buildStepItem(
                theme,
                index: i,
                label: steps[i],
                isActive: i == currentStep,
                isComplete: i < currentStep,
              ),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(
    ThemeData theme, {
    required int index,
    required String label,
    required bool isActive,
    required bool isComplete,
  }) {
    final color = isComplete || isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isComplete || isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isComplete
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ThemeData theme,
    ExamFormState formState,
  ) {
    switch (formState.currentStep) {
      case 0:
        return _buildBasicInfoStep(context, theme, formState);
      case 1:
        return _buildSubjectsStep(context, theme, formState);
      case 2:
        return _buildReviewStep(context, theme, formState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep(
    BuildContext context,
    ThemeData theme,
    ExamFormState formState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the basic details for this exam',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Exam name
          AppTextField(
            controller: _nameController,
            label: 'Exam Name',
            hint: 'e.g., Annual Examination 2026',
            prefixIcon: Icons.quiz,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Exam name is required';
              }
              if (value.length > 100) {
                return 'Exam name must be 100 characters or less';
              }
              return null;
            },
            onChanged: (value) {
              ref.read(examFormProvider.notifier).setName(value);
            },
          ),
          const SizedBox(height: 16),

          // Exam type
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: formState.type,
                  decoration: const InputDecoration(
                    labelText: 'Exam Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ExamConstants.types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(ExamConstants.typeLabels[type] ?? type),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an exam type';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    ref.read(examFormProvider.notifier).setType(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ClassDropdown(
                  selectedClassId: formState.classId,
                  onChanged: (classId) {
                    ref.read(examFormProvider.notifier).setClassId(classId);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start Date',
                  value: formState.startDate,
                  isRequired: true,
                  onChanged: (date) {
                    ref.read(examFormProvider.notifier).setStartDate(date);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DateField(
                  label: 'End Date',
                  value: formState.endDate,
                  isRequired: false,
                  minDate: formState.startDate,
                  onChanged: (date) {
                    ref.read(examFormProvider.notifier).setEndDate(date);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          AppTextField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'Add any notes or instructions for this exam',
            prefixIcon: Icons.notes,
            maxLines: 3,
            onChanged: (value) {
              ref.read(examFormProvider.notifier).setDescription(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsStep(
    BuildContext context,
    ThemeData theme,
    ExamFormState formState,
  ) {
    if (formState.classId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Please select a class first',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppButton.secondary(
              text: 'Go Back',
              onPressed: () {
                ref.read(examFormProvider.notifier).previousStep();
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Configuration',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add subjects and configure marks for each',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppButton.primary(
                text: 'Add Subject',
                icon: Icons.add,
                size: AppButtonSize.small,
                onPressed: () => _showAddSubjectDialog(context, formState),
              ),
            ],
          ),
        ),

        Expanded(
          child: formState.subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subjects added yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add at least one subject to continue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: formState.subjects.length,
                  itemBuilder: (context, index) {
                    return _SubjectConfigCard(
                      subject: formState.subjects[index],
                      classId: formState.classId!,
                      onEdit: () =>
                          _showEditSubjectDialog(context, formState, index),
                      onDelete: () {
                        ref
                            .read(examFormProvider.notifier)
                            .removeSubject(index);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    ThemeData theme,
    ExamFormState formState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review the exam details before saving',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Basic info card
          _ReviewCard(
            title: 'Basic Information',
            icon: Icons.info_outline,
            children: [
              _ReviewRow('Exam Name', formState.name),
              _ReviewRow(
                'Exam Type',
                ExamConstants.typeLabels[formState.type] ??
                    formState.type ??
                    '-',
              ),
              _ReviewRow(
                'Start Date',
                formState.startDate != null
                    ? DateFormat('dd MMM yyyy').format(formState.startDate!)
                    : '-',
              ),
              if (formState.endDate != null)
                _ReviewRow(
                  'End Date',
                  DateFormat('dd MMM yyyy').format(formState.endDate!),
                ),
              if (formState.description != null &&
                  formState.description!.isNotEmpty)
                _ReviewRow('Description', formState.description!),
            ],
          ),
          const SizedBox(height: 16),

          // Subjects card
          _ReviewCard(
            title: 'Subjects (${formState.subjects.length})',
            icon: Icons.book_outlined,
            children: [
              for (final subject in formState.subjects)
                _SubjectReviewRow(
                  subject: subject,
                  classId: formState.classId!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _saveAsDraft
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _saveAsDraft
                    ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _saveAsDraft
                          ? Icons.drafts_outlined
                          : Icons.check_circle_outline,
                      color: _saveAsDraft
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'The exam will be updated with the new details.'
                            : (_saveAsDraft
                                  ? 'The exam will be saved as a draft. It will not be visible to students until published.'
                                  : 'The exam will be created and immediately active for marks entry.'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _saveAsDraft
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Save as Draft'),
                    subtitle: const Text('Publish later when ready'),
                    value: _saveAsDraft,
                    onChanged: (value) {
                      setState(() => _saveAsDraft = value);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Error message
          if (formState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: TextStyle(color: theme.colorScheme.error),
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

  Widget _buildNavigationButtons(
    BuildContext context,
    ThemeData theme,
    ExamFormState formState,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (formState.currentStep > 0)
            AppButton.secondary(
              text: 'Previous',
              icon: Icons.arrow_back,
              onPressed: () {
                ref.read(examFormProvider.notifier).previousStep();
              },
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              // Publish Button (Only for existing draft exams on the last step)
              if (isEditing &&
                  formState.currentStep == 2 &&
                  ref
                          .watch(examByIdProvider(widget.examId!))
                          .value
                          ?.exam
                          .status ==
                      'draft') ...[
                AppButton.success(
                  text: 'Publish',
                  icon: Icons.public,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : () => _handlePublish(),
                ),
                const SizedBox(width: 8),
              ],

              if (formState.currentStep < 2)
                AppButton.primary(
                  text: 'Next',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () => _handleNext(formState),
                )
              else
                AppButton.primary(
                  text: isEditing
                      ? 'Update Exam'
                      : (_saveAsDraft ? 'Save Draft' : 'Create Exam'),
                  icon: Icons.check,
                  isLoading: formState.isSaving || _isSubmitting,
                  onPressed: (formState.isSaving || _isSubmitting)
                      ? null
                      : () => _handleSave(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    if (_isSubmitting) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Exam?'),
        content: const Text(
          'This will make the exam active and available for marks entry. '
          'You cannot undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      await ref
          .read(examServiceProvider)
          .publishExam(examId: widget.examId!, publishedBy: currentUser.id);

      // Invalidate providers to refresh UI
      ref.invalidate(dashboardProvider);
      ref.invalidate(examsListProvider);
      ref.invalidate(activeExamsProvider);
      // Invalidate counts for tabs
      ref.invalidate(examCountByStatusProvider);
      // Invalidate details
      ref.invalidate(examByIdProvider(widget.examId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam published successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error publishing exam: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleNext(ExamFormState formState) {
    if (formState.currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (formState.classId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a class')));
        return;
      }
      if (formState.startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date')),
        );
        return;
      }
    }

    if (formState.currentStep == 1) {
      if (formState.subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one subject')),
        );
        return;
      }
    }

    ref.read(examFormProvider.notifier).nextStep();
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final academicYearAsync = await ref.read(
        currentAcademicYearProvider.future,
      );
      if (!context.mounted) return;

      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Missing context data')),
          );
        }
        return;
      }

      final notifier = ref.read(examFormProvider.notifier);

      if (isEditing) {
        final success = await notifier.updateExam(
          examId: widget.examId!,
          academicYear: academicYearAsync,
          updatedBy: currentUser.id,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam updated successfully')),
          );
          context.pop();
        }
      } else {
        final examId = await notifier.createExam(
          academicYear: academicYearAsync,
          createdBy: currentUser.id,
          status: _saveAsDraft ? 'draft' : 'active',
        );
        if (examId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _saveAsDraft
                    ? 'Exam draft saved successfully'
                    : 'Exam created and activated successfully',
              ),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving exam: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showAddSubjectDialog(BuildContext context, ExamFormState formState) {
    showDialog(
      context: context,
      builder: (context) => _SubjectConfigDialog(
        classId: formState.classId!,
        existingSubjectIds: formState.subjects.map((s) => s.subjectId).toSet(),
        onSave: (subject) {
          ref.read(examFormProvider.notifier).addSubject(subject);
        },
      ),
    );
  }

  void _showEditSubjectDialog(
    BuildContext context,
    ExamFormState formState,
    int index,
  ) {
    final subject = formState.subjects[index];
    showDialog(
      context: context,
      builder: (context) => _SubjectConfigDialog(
        classId: formState.classId!,
        existingSubjectIds: formState.subjects
            .asMap()
            .entries
            .where((e) => e.key != index)
            .map((e) => e.value.subjectId)
            .toSet(),
        initialData: subject,
        onSave: (updated) {
          ref.read(examFormProvider.notifier).updateSubject(index, updated);
        },
      ),
    );
  }
}

// Helper widgets

class _ClassDropdown extends ConsumerWidget {
  final int? selectedClassId;
  final ValueChanged<int?> onChanged;

  const _ClassDropdown({
    required this.selectedClassId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return classesAsync.when(
      data: (classes) => DropdownButtonFormField<int>(
        initialValue: selectedClassId,
        decoration: const InputDecoration(
          labelText: 'Class',
          prefixIcon: Icon(Icons.class_),
        ),
        items: classes.map((c) {
          return DropdownMenuItem(value: c.id, child: Text(c.name));
        }).toList(),
        validator: (value) {
          if (value == null) {
            return 'Please select a class';
          }
          return null;
        },
        onChanged: onChanged,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading classes'),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool isRequired;
  final DateTime? minDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.isRequired,
    this.minDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: () async {
        final defaultInitialDate = value ?? DateTime.now();
        final firstDate = minDate ?? DateTime(2020);
        final initialDate = defaultInitialDate.isBefore(firstDate)
            ? firstDate
            : defaultInitialDate;

        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: value != null && !isRequired
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null ? dateFormat.format(value!) : 'Select date',
          style: value == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}

class _SubjectConfigCard extends ConsumerWidget {
  final ExamSubjectData subject;
  final int classId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectConfigCard({
    required this.subject,
    required this.classId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectAsync = ref.watch(subjectByIdProvider(subject.subjectId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.book, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: subjectAsync.when(
          data: (s) => Text(s?.name ?? 'Subject #${subject.subjectId}'),
          loading: () => const Text('Loading...'),
          error: (_, __) => Text('Subject #${subject.subjectId}'),
        ),
        subtitle: Text(
          'Max: ${subject.maxMarks.toStringAsFixed(0)} | Pass: ${subject.passingMarks.toStringAsFixed(0)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectConfigDialog extends ConsumerStatefulWidget {
  final int classId;
  final Set<int> existingSubjectIds;
  final ExamSubjectData? initialData;
  final ValueChanged<ExamSubjectData> onSave;

  const _SubjectConfigDialog({
    required this.classId,
    required this.existingSubjectIds,
    this.initialData,
    required this.onSave,
  });

  @override
  ConsumerState<_SubjectConfigDialog> createState() =>
      _SubjectConfigDialogState();
}

class _SubjectConfigDialogState extends ConsumerState<_SubjectConfigDialog> {
  int? _selectedSubjectId;
  final _maxMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedSubjectId = widget.initialData!.subjectId;
      _maxMarksController.text = widget.initialData!.maxMarks.toString();
      _passingMarksController.text = widget.initialData!.passingMarks
          .toString();
      if (widget.initialData!.durationMinutes != null) {
        _durationController.text = widget.initialData!.durationMinutes
            .toString();
      }
    } else {
      _maxMarksController.text = '100';
      _passingMarksController.text = '33';
    }
  }

  @override
  void dispose() {
    _maxMarksController.dispose();
    _passingMarksController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(subjectsByClassProvider(widget.classId));

    return AlertDialog(
      title: Text(widget.initialData != null ? 'Edit Subject' : 'Add Subject'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.initialData == null)
              subjectsAsync.when(
                data: (subjects) {
                  final available = subjects
                      .where((s) => !widget.existingSubjectIds.contains(s.id))
                      .toList();

                  if (available.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'All subjects have been added',
                            style: TextStyle(color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.book),
                    ),
                    items: available.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSubjectId = value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading subjects'),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Marks',
                      prefixIcon: Icon(Icons.looks_one),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _passingMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Passing Marks',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes) - Optional',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _handleSave, child: const Text('Save')),
      ],
    );
  }

  void _handleSave() {
    final subjectId = _selectedSubjectId ?? widget.initialData?.subjectId;
    if (subjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    final maxMarks = double.tryParse(_maxMarksController.text);
    final passingMarks = double.tryParse(_passingMarksController.text);

    if (maxMarks == null || maxMarks <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid maximum marks')));
      return;
    }

    if (passingMarks == null || passingMarks < 0 || passingMarks > maxMarks) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid passing marks')));
      return;
    }

    final duration = int.tryParse(_durationController.text);

    widget.onSave(
      ExamSubjectData(
        subjectId: subjectId,
        maxMarks: maxMarks,
        passingMarks: passingMarks,
        durationMinutes: duration,
      ),
    );

    Navigator.of(context).pop();
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectReviewRow extends ConsumerWidget {
  final ExamSubjectData subject;
  final int classId;

  const _SubjectReviewRow({required this.subject, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectAsync = ref.watch(subjectByIdProvider(subject.subjectId));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: subjectAsync.when(
              data: (s) => Text(s?.name ?? '-'),
              loading: () => const Text('...'),
              error: (_, __) => const Text('-'),
            ),
          ),
          Text(
            'Max: ${subject.maxMarks.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          Text(
            'Pass: ${subject.passingMarks.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Add providers for subject lookup
final subjectByIdProvider = FutureProvider.family<Subject?, int>((
  ref,
  id,
) async {
  final db = ref.watch(databaseProvider);
  return await (db.select(
    db.subjects,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
});

final subjectsByClassProvider = FutureProvider.family<List<Subject>, int>((
  ref,
  classId,
) async {
  final academicYear = await ref.watch(currentAcademicYearProvider.future);
  final repo = ref.watch(classSubjectRepositoryProvider);
  final classSubjects = await repo.getByClass(classId, academicYear);
  return classSubjects.map((cs) => cs.subject).toList();
});
