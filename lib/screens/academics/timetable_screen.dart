/// EduX School Management System
/// Timetable Screen - Weekly timetable management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../providers/academics_provider.dart';
import '../../repositories/section_repository.dart';
import '../../repositories/timetable_repository.dart';
import 'widgets/timetable_grid.dart';
import 'widgets/timetable_slot_dialog.dart';
import 'period_configuration_screen.dart';
import '../../services/timetable_pdf_service.dart';
import '../../core/utils/pdf_helper.dart';
import '../../providers/auth_provider.dart';
import '../../services/rbac_service.dart';

/// Screen for viewing and editing weekly timetable
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  ClassSectionPair? _selectedClassSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classSectionsAsync = ref.watch(classSectionPairsProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    // Listen for operation messages
    ref.listen<OperationState>(timetableOperationProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(timetableOperationProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(timetableOperationProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with class/section selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                // Class-section dropdown
                classSectionsAsync.when(
                  data: (pairs) => Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Timetable for: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<ClassSectionPair>(
                          initialValue: _selectedClassSection,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('Select Class - Section'),
                          items: pairs
                              .map(
                                (pair) => DropdownMenuItem(
                                  value: pair,
                                  child: Text(pair.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedClassSection = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Failed to load classes'),
                ),
                const Spacer(),
                // Academic year display
                academicYearAsync.when(
                  data: (year) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendarDays,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          year,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                // Print/Download button
                if (_selectedClassSection != null)
                  academicYearAsync.when(
                    data: (year) => IconButton(
                      icon: const Icon(LucideIcons.printer),
                      tooltip: 'Print Timetable',
                      onPressed: () => _handlePrint(
                        context,
                        ref,
                        _selectedClassSection!,
                        year,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                if (canManage)
                  IconButton(
                    icon: const Icon(LucideIcons.settings),
                    tooltip: 'Configure Periods',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PeriodConfigurationScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedClassSection == null
                ? _buildNoSelectionState(context)
                : academicYearAsync.when(
                    data: (academicYear) => _buildTimetableContent(
                      context,
                      ref,
                      _selectedClassSection!,
                      academicYear,
                      canManage,
                    ),
                    loading: () => const Center(child: AppLoadingIndicator()),
                    error: (error, __) => AppErrorState(
                      message: 'Failed to load academic year',
                      onRetry: () =>
                          ref.invalidate(currentAcademicYearProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(
    BuildContext context,
    WidgetRef ref,
    ClassSectionPair classSection,
    String academicYear,
  ) async {
    if (!context.mounted) return;
    
    // Show loading dialog using root navigator to ensure it's on top
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch required data
      final periods = await ref.read(
        periodDefinitionsProvider(academicYear).future,
      );
      final query = TimetableQuery(
        classId: classSection.classId,
        sectionId: classSection.sectionId,
        academicYear: academicYear,
      );
      final timetable = await ref.read(weeklyTimetableProvider(query).future);

      // Get school settings for header
      final db = ref.read(databaseProvider);
      final settings = await db.getSchoolSettings();

      // Check if widget is still mounted before using context
      if (!context.mounted) return;

      // Close loading dialog using root navigator
      Navigator.of(context, rootNavigator: true).pop();

      if (settings == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School settings not found')),
        );
        return;
      }

      await PdfHelper.previewAndPrint(
        context,
        () => TimetablePdfService.generateTimetablePdf(
          schoolSettings: settings,
          className: classSection.className,
          sectionName: classSection.sectionName,
          academicYear: academicYear,
          periods: periods,
          timetable: timetable,
        ),
        'Timetable_${classSection.className}_${classSection.sectionName}',
      );
    } catch (e) {
      if (!context.mounted) return;
      
      // Close loading dialog if it's still open
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  Widget _buildNoSelectionState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendar, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Select a Class and Section',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose a class and section from the dropdown above\nto view or edit the timetable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableContent(
    BuildContext context,
    WidgetRef ref,
    ClassSectionPair classSection,
    String academicYear,
    bool canManage,
  ) {
    final query = TimetableQuery(
      classId: classSection.classId,
      sectionId: classSection.sectionId,
      academicYear: academicYear,
    );

    final timetableAsync = ref.watch(weeklyTimetableProvider(query));
    final periodsAsync = ref.watch(periodDefinitionsProvider(academicYear));
    // Use class-specific working days provider
    final workingDaysAsync = ref.watch(
      classWorkingDaysProvider((
        classId: classSection.classId,
        academicYear: academicYear,
      )),
    );

    return workingDaysAsync.when(
      data: (workingDays) => timetableAsync.when(
        data: (timetable) => periodsAsync.when(
          data: (periods) {
            if (periods.isEmpty) {
              return AppEmptyState(
                icon: LucideIcons.clock,
                title: 'No Period Definitions',
                description:
                    'Configure school periods before creating timetables.',
                actionText: canManage ? 'Configure Periods' : null,
                onAction: canManage
                    ? () {
                        // Would open period config dialog
                        _showPeriodSeedDialog(context, ref, academicYear);
                      }
                    : null,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: TimetableGrid(
                timetable: timetable,
                periods: periods,
                classId: classSection.classId,
                sectionId: classSection.sectionId,
                academicYear: academicYear,
                workingDays: workingDays,
                onSlotTap: canManage
                    ? (day, periodNum, slot) {
                        _showSlotDialog(
                          context,
                          ref,
                          classSection,
                          academicYear,
                          day,
                          periodNum,
                          periods.firstWhere(
                            (p) => p.periodNumber == periodNum,
                            orElse: () => periods.first,
                          ),
                          slot,
                        );
                      }
                    : null,
              ),
            );
          },
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, __) => AppErrorState(
            message: 'Failed to load periods: ${error.toString()}',
            onRetry: () =>
                ref.invalidate(periodDefinitionsProvider(academicYear)),
          ),
        ),
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, __) => AppErrorState(
          message: 'Failed to load timetable: ${error.toString()}',
          onRetry: () => ref.invalidate(weeklyTimetableProvider(query)),
        ),
      ),
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (_, __) => AppErrorState(
        message: 'Failed to load working days configuration',
        onRetry: () => ref.invalidate(workingDaysProvider),
      ),
    );
  }

  void _showSlotDialog(
    BuildContext context,
    WidgetRef ref,
    ClassSectionPair classSection,
    String academicYear,
    String day,
    int periodNumber,
    dynamic period,
    TimetableSlotWithDetails? existingSlot,
  ) {
    showDialog(
      context: context,
      builder: (context) => TimetableSlotDialog(
        classId: classSection.classId,
        sectionId: classSection.sectionId,
        academicYear: academicYear,
        dayOfWeek: day,
        periodNumber: periodNumber,
        startTime: period.startTime,
        endTime: period.endTime,
        existingSlot: existingSlot,
      ),
    );
  }

  Future<void> _showPeriodSeedDialog(
    BuildContext context,
    WidgetRef ref,
    String academicYear,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Period Schedule'),
        content: const Text(
          'Would you like to create a default school schedule with 8 periods and breaks? '
          'You can customize these later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Default'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(periodDefinitionOperationProvider.notifier)
          .seedDefaults(academicYear);
    }
  }
}
