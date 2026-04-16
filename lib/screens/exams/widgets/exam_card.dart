/// EduX School Management System
/// Exam Card Widget - Displays exam summary with actions
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../repositories/exam_repository.dart';
import '../../../core/constants/app_constants.dart';
import 'exam_status_badge.dart';

class ExamCard extends StatelessWidget {
  final ExamWithDetails exam;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onEnterMarks;
  final VoidCallback? onViewResults;

  final VoidCallback? onDelete;

  const ExamCard({
    super.key,
    required this.exam,
    required this.onTap,
    this.onEdit,
    this.onEnterMarks,
    this.onViewResults,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with exam info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTypeColor(exam.exam.type).withValues(alpha: 0.08),
                border: Border(
                  left: BorderSide(
                    color: _getTypeColor(exam.exam.type),
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Exam icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(
                        exam.exam.type,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(exam.exam.type),
                      color: _getTypeColor(exam.exam.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exam.exam.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ExamStatusBadge(status: exam.exam.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.class_outlined,
                              exam.classInfo.name,
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.category_outlined,
                              ExamConstants.typeLabels[exam.exam.type] ??
                                  exam.exam.type,
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.book_outlined,
                              '${exam.subjectCount} Subjects',
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress and dates section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              exam.exam.endDate != null
                                  ? '${dateFormat.format(exam.exam.startDate)} - ${dateFormat.format(exam.exam.endDate!)}'
                                  : dateFormat.format(exam.exam.startDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (exam.exam.description != null &&
                            exam.exam.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            exam.exam.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Progress indicator (for active exams)
                  if (exam.exam.status == ExamConstants.statusActive && exam.totalStudents > 0)
                    _buildProgressIndicator(context, theme),
                ],
              ),
            ),

            // Action buttons
            if (onEdit != null ||
                onEnterMarks != null ||
                onViewResults != null ||
                onDelete != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Delete Exam',
                      ),
                    const Spacer(),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    if (onEnterMarks != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onEnterMarks,
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Enter Marks'),
                      ),
                    ],
                    if (onViewResults != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onViewResults,
                        icon: const Icon(Icons.assessment, size: 18),
                        label: const Text('View Results'),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Marks Entry Progress',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: exam.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      exam.isComplete ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${exam.progressPercentage.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: exam.isComplete
                      ? AppColors.success
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'annual_exam':
        return AppColors.error;
      case 'term_exam':
        return AppColors.primary;
      case 'monthly_test':
        return AppColors.secondary;
      case 'unit_test':
        return AppColors.warning;
      case 'practice':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'annual_exam':
        return Icons.emoji_events;
      case 'term_exam':
        return Icons.assessment;
      case 'monthly_test':
        return Icons.date_range;
      case 'unit_test':
        return Icons.quiz;
      case 'practice':
        return Icons.school;
      default:
        return Icons.description;
    }
  }
}
