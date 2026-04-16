/// EduX Teacher App - Classes Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/class_section.dart';
import '../../providers/classes_provider.dart';
import '../attendance/mark_attendance_screen.dart';
import '../home/home_screen.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(classesProvider);

    return Scaffold(
      appBar: const HomeAppBar(title: 'My Classes'),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(classesProvider.notifier).refreshClasses();
        },
        child: classesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : classesState.classes.isEmpty
                ? _buildEmptyState(context, ref)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: classesState.classes.length,
                    itemBuilder: (context, index) {
                      final classSection = classesState.classes[index];
                      return _ClassListTile(
                        classSection: classSection,
                        onTap: () => _openAttendance(context, ref, classSection),
                      )
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: AppTheme.textTertiary .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Classes Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t been assigned to any classes yet. Contact your school administrator.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref.read(classesProvider.notifier).refreshClasses();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _openAttendance(
    BuildContext context,
    WidgetRef ref,
    ClassSection classSection,
  ) {
    ref.read(selectedClassProvider.notifier).select(classSection);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(classSection: classSection),
      ),
    );
  }
}

class _ClassListTile extends StatelessWidget {
  final ClassSection classSection;
  final VoidCallback onTap;

  const _ClassListTile({
    required this.classSection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary .withValues(alpha: 0.8),
                      AppTheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    classSection.className.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            classSection.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (classSection.isClassTeacher)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppTheme.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Class Teacher',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (classSection.subjectName != null) ...[
                      Text(
                        classSection.subjectName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${classSection.totalStudents} Students',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
