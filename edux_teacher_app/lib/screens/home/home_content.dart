/// EduX Teacher App - Home Content
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/class_section.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classes_provider.dart';
import '../../providers/sync_provider.dart';
import '../attendance/mark_attendance_screen.dart';
import '../home/home_screen.dart';
import '../sync/sync_screen.dart';

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  @override
  Widget build(BuildContext context) {
    final teacher = ref.watch(currentTeacherProvider);
    final classesState = ref.watch(classesProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: const HomeAppBar(title: 'EduX Teacher'),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(classesProvider.notifier).refreshClasses();
          await ref.read(syncProvider.notifier).refreshPendingCount();
        },
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: _buildHeader(context, teacher?.name ?? 'Teacher'),
            ),

            // Date Section
            SliverToBoxAdapter(
              child: _buildDateSection(context),
            ),

            // Pending Sync Card
            if (syncState.pendingCount > 0)
              SliverToBoxAdapter(
                child: _buildPendingSyncCard(context, ref, syncState.pendingCount),
              ),

            // Classes Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Classes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (classesState.classes.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Navigate to all classes
                        },
                        child: Text('View All (${classesState.classes.length})'),
                      ),
                  ],
                ),
              ),
            ),

            // Classes List
            if (classesState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (classesState.classes.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context, ref),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: classesState.classes.take(5).length,
                  itemBuilder: (context, index) {
                    final classSection = classesState.classes[index];
                    return _ClassCard(
                      classSection: classSection,
                      onTap: () => _openAttendance(context, ref, classSection),
                    )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String teacherName) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white .withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            teacherName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white .withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildDateSection(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.add(Duration(days: index - 3)));

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).select(date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isToday ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday
                      ? AppTheme.primary
                      : AppTheme.border .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingSyncCard(BuildContext context, WidgetRef ref, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning .withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Records Pending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sync when connected to school WiFi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              );
            },
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Sync'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: AppTheme.textTertiary .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Classes Assigned',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or contact your admin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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

  void _openAttendance(BuildContext context, WidgetRef ref, ClassSection classSection) {
    ref.read(selectedClassProvider.notifier).select(classSection);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(
          classSection: classSection,
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassSection classSection;
  final VoidCallback onTap;

  const _ClassCard({
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.class_,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classSection.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (classSection.subjectName != null)
                      Text(
                        classSection.subjectName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${classSection.totalStudents} Students',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
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
                      child: const Text(
                        'Class Teacher',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
