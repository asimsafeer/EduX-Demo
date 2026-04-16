/// EduX School Management System
/// Grade Settings Screen - Manage grade configurations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/exam_provider.dart';
import '../../database/app_database.dart';

class GradeSettingsScreen extends ConsumerStatefulWidget {
  const GradeSettingsScreen({super.key});

  @override
  ConsumerState<GradeSettingsScreen> createState() =>
      _GradeSettingsScreenState();
}

class _GradeSettingsScreenState extends ConsumerState<GradeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradesAsync = ref.watch(gradeSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          AppButton.primary(
            text: 'Add Grade',
            icon: Icons.add,
            size: AppButtonSize.small,
            onPressed: () => _showGradeDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Configuration',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define percentage ranges for each grade. These settings are used to automatically calculate grades for student marks.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grade list
          Expanded(
            child: gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.grade_outlined,
                    title: 'No Grades Configured',
                    description:
                        'Add grade settings to define your grading scale.',
                    actionText: 'Add Grade',
                    onAction: () => _showGradeDialog(context),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grades.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final newOrder = List<GradeSetting>.from(grades);
                    final item = newOrder.removeAt(oldIndex);
                    newOrder.insert(newIndex, item);
                    ref
                        .read(gradeSettingsNotifierProvider.notifier)
                        .reorderGrades(newOrder);
                  },
                  itemBuilder: (context, index) {
                    final grade = grades[index];
                    return _GradeCard(
                      key: ValueKey(grade.id),
                      grade: grade,
                      onEdit: () => _showGradeDialog(context, grade: grade),
                      onDelete: () => _confirmDelete(context, grade),
                    );
                  },
                );
              },
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeDialog(BuildContext context, {GradeSetting? grade}) {
    showDialog(
      context: context,
      builder: (context) => _GradeDialog(
        grade: grade,
        onSave: (data) async {
          try {
            final notifier = ref.read(gradeSettingsNotifierProvider.notifier);
            if (grade != null) {
              await notifier.updateGrade(
                id: grade.id,
                gradeName: data.name,
                minPercentage: data.minPercentage,
                maxPercentage: data.maxPercentage,
                gpa: data.gpa,
                isPassing: data.isPassing,
                remarks: data.remarks,
              );
            } else {
              await notifier.addGrade(
                gradeName: data.name,
                minPercentage: data.minPercentage,
                maxPercentage: data.maxPercentage,
                gpa: data.gpa,
                isPassing: data.isPassing,
                remarks: data.remarks,
              );
            }

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    grade != null ? 'Grade updated' : 'Grade added',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, GradeSetting grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grade'),
        content: Text(
          'Are you sure you want to delete grade "${grade.grade}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(gradeSettingsNotifierProvider.notifier)
                    .deleteGrade(grade.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grade deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeSetting grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GradeCard({
    super.key,
    required this.grade,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getGradeColor(grade.grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: grade.displayOrder - 1,
              child: Icon(
                Icons.drag_indicator,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            // Grade badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  grade.grade,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              '${grade.minPercentage.toStringAsFixed(0)}% - ${grade.maxPercentage.toStringAsFixed(0)}%',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'GPA: ${grade.gpa.toStringAsFixed(2)}',
                style: theme.textTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 8),
            if (!grade.isPassing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Fail',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        subtitle: grade.remarks != null
            ? Text(
                grade.remarks!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
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

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'A-':
      case 'B+':
      case 'B':
        return AppColors.primary;
      case 'B-':
      case 'C+':
      case 'C':
        return AppColors.info;
      case 'C-':
      case 'D+':
      case 'D':
        return AppColors.warning;
      case 'F':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _GradeDialogData {
  final String name;
  final double minPercentage;
  final double maxPercentage;
  final double gpa;
  final bool isPassing;
  final String? remarks;

  const _GradeDialogData({
    required this.name,
    required this.minPercentage,
    required this.maxPercentage,
    required this.gpa,
    required this.isPassing,
    this.remarks,
  });
}

class _GradeDialog extends StatefulWidget {
  final GradeSetting? grade;
  final Function(_GradeDialogData) onSave;

  const _GradeDialog({this.grade, required this.onSave});

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _gpaController;
  late final TextEditingController _remarksController;
  late bool _isPassing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.grade?.grade ?? '');
    _minController = TextEditingController(
      text: widget.grade?.minPercentage.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.grade?.maxPercentage.toStringAsFixed(0) ?? '',
    );
    _gpaController = TextEditingController(
      text: widget.grade?.gpa.toStringAsFixed(2) ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.grade?.remarks ?? '',
    );
    _isPassing = widget.grade?.isPassing ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _gpaController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.grade != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Grade' : 'Add Grade'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grade name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Grade Name',
                hintText: 'e.g., A+, A, B+',
                prefixIcon: Icon(Icons.grade),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
            ),
            const SizedBox(height: 16),

            // Percentage range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: const InputDecoration(
                      labelText: 'Min %',
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(
                      labelText: 'Max %',
                      prefixIcon: Icon(Icons.arrow_upward),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // GPA
            TextField(
              controller: _gpaController,
              decoration: const InputDecoration(
                labelText: 'GPA Points',
                prefixIcon: Icon(Icons.star),
                hintText: 'e.g., 4.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Remarks
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                prefixIcon: Icon(Icons.notes),
                hintText: 'e.g., Excellent performance',
              ),
            ),
            const SizedBox(height: 16),

            // Is passing
            SwitchListTile(
              title: const Text('Is Passing Grade'),
              subtitle: const Text('Uncheck for failing grades like F'),
              value: _isPassing,
              onChanged: (value) {
                setState(() => _isPassing = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _handleSave,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    final gpa = double.tryParse(_gpaController.text);

    if (name.isEmpty) {
      _showError('Grade name is required');
      return;
    }

    if (min == null || min < 0 || min > 100) {
      _showError('Invalid minimum percentage');
      return;
    }

    if (max == null || max < 0 || max > 100 || max < min) {
      _showError('Invalid maximum percentage');
      return;
    }

    if (gpa == null || gpa < 0) {
      _showError('Invalid GPA');
      return;
    }

    widget.onSave(
      _GradeDialogData(
        name: name,
        minPercentage: min,
        maxPercentage: max,
        gpa: gpa,
        isPassing: _isPassing,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
