/// EduX School Management System
/// Main Exams Screen with tabs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../providers/exam_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../repositories/exam_repository.dart';
import '../../providers/student_provider.dart'
    show classesProvider, currentAcademicYearProvider;

import '../../core/constants/app_constants.dart';
import 'widgets/exam_card.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filters = ref.read(examFiltersProvider.notifier);
      switch (_tabController.index) {
        case 0:
          filters.setStatus(null);
          break;
        case 1:
          filters.setStatus('draft');
          break;
        case 2:
          filters.setStatus('active');
          break;
        case 3:
          filters.setStatus('completed');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(context, theme),

          // Tab bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab('All', null),
                _buildTab('Draft', 'draft'),
                _buildTab('Active', 'active'),
                _buildTab('Completed', 'completed'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ExamsListView(),
                _ExamsListView(),
                _ExamsListView(),
                _ExamsListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String? status) {
    if (status == null) {
      return Tab(text: label);
    }

    return Tab(
      child: Consumer(
        builder: (context, ref, child) {
          final countAsync = ref.watch(examCountByStatusProvider(status));
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              countAsync.when(
                data: (count) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return AppColors.warning;
      case 'active':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: AppTheme.pagePadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examinations',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage exams, enter marks, and generate report cards',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.secondary(
                    text: 'Grade Settings',
                    icon: Icons.tune,
                    onPressed: () => context.go('/exams/grades'),
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(
                    text: 'Create Exam',
                    icon: Icons.add,
                    onPressed: () => context.go('/exams/new'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter row
          _buildFilterRow(context, theme),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, ThemeData theme) {
    final filters = ref.watch(examFiltersProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Class filter
          SizedBox(
            width: 200,
            child: _ClassFilterDropdown(
              selectedClassId: filters.classId,
              onChanged: (classId) {
                ref.read(examFiltersProvider.notifier).setClassId(classId);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Type filter
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: filters.type,
              decoration: const InputDecoration(
                labelText: 'Exam Type',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...ExamConstants.types.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(ExamConstants.typeLabels[type] ?? type),
                  ),
                ),
              ],
              onChanged: (type) {
                ref.read(examFiltersProvider.notifier).setType(type);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Academic year display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  academicYearAsync.when(
                    data: (year) => 'Academic Year: $year',
                    loading: () => 'Loading...',
                    error: (_, __) => 'Not Set',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Clear filters button
          if (filters.classId != null || filters.type != null)
            TextButton.icon(
              onPressed: () {
                ref.read(examFiltersProvider.notifier).resetFilters();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}

class _ClassFilterDropdown extends ConsumerWidget {
  final int? selectedClassId;
  final ValueChanged<int?> onChanged;

  const _ClassFilterDropdown({
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Classes')),
          ...classes.map(
            (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
          ),
        ],
        onChanged: onChanged,
      ),
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const Text('Error loading classes'),
    );
  }
}

class _ExamsListView extends ConsumerWidget {
  const _ExamsListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsListProvider);
    final theme = Theme.of(context);

    return examsAsync.when(
      data: (exams) {
        if (exams.isEmpty) {
          return AppEmptyState(
            icon: Icons.quiz_outlined,
            title: 'No Exams Found',
            description:
                'Create a new exam to get started with marks entry and report cards.',
            actionText: 'Create Exam',
            onAction: () => context.go('/exams/new'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(examsListProvider.future),
          child: ListView.builder(
            padding: AppTheme.pagePadding,
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ExamCard(
                  exam: exam,
                  onTap: () {
                    ref.read(selectedExamIdProvider.notifier).state =
                        exam.exam.id;
                    context.go('/exams/${exam.exam.id}');
                  },
                  onEdit: exam.exam.status == 'draft'
                      ? () => context.go('/exams/${exam.exam.id}/edit')
                      : null,
                  onEnterMarks: exam.exam.status == ExamConstants.statusActive
                      ? () => context.go('/exams/${exam.exam.id}/marks')
                      : null,
                  onViewResults: exam.exam.status == 'completed'
                      ? () => context.go('/exams/${exam.exam.id}/results')
                      : null,
                  onDelete:
                      (exam.exam.status == 'draft' ||
                          exam.exam.status == ExamConstants.statusActive)
                      ? () => _handleDelete(context, ref, exam)
                      : null,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load exams', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(examsListProvider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ExamWithDetails exam,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text(
          'Are you sure you want to delete "${exam.exam.name}"? '
          'This will permanently remove all subjects and marks associated with this exam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      await ref
          .read(examServiceProvider)
          .deleteExam(examId: exam.exam.id, deletedBy: currentUser.id);

      // Invalidate providers to refresh UI
      ref.invalidate(examsListProvider);
      ref.invalidate(examCountByStatusProvider);
      ref.invalidate(activeExamsProvider);
      ref.invalidate(dashboardProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting exam: $e')));
      }
    }
  }
}
