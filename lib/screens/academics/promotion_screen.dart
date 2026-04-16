/// EduX School Management System
/// Promotion Screen - Student class promotion management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart'
    hide Column; // Hide Column to avoid conflict with Flutter widget

import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_empty_state.dart';

import '../../providers/academics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart'
    hide currentAcademicYearProvider, databaseProvider;
import '../../repositories/section_repository.dart';
import '../../services/rbac_service.dart';
import 'widgets/promotion_student_list.dart';

/// Screen for promoting students between classes/sections
class PromotionScreen extends ConsumerStatefulWidget {
  const PromotionScreen({super.key});

  @override
  ConsumerState<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends ConsumerState<PromotionScreen> {
  int _currentStep = 0;
  ClassSectionPair? _sourceClassSection;
  ClassSectionPair? _destinationClassSection;
  Set<int> _selectedStudentIds = {};
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final canManage = rbacService.hasPermission(
      user,
      RbacService.manageAcademics,
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                Icon(
                  LucideIcons.arrowUpCircle,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Promotions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Promote students to the next class/section',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stepper content
          Expanded(
            child: canManage
                ? _buildStepperContent(context)
                : const AppEmptyState(
                    icon: LucideIcons.shieldAlert,
                    title: 'Access Restricted',
                    description:
                        'You do not have permission to manage student promotions.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperContent(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _handleStepContinue,
      onStepCancel: _handleStepCancel,
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              if (_currentStep < 3)
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 2 ? 'Promote' : 'Continue'),
                ),
              if (_currentStep < 3) const SizedBox(width: 12),
              if (_currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
            ],
          ),
        );
      },
      steps: [
        // Step 1: Select source class/section
        Step(
          title: const Text('Select Source'),
          subtitle: _sourceClassSection != null
              ? Text(_sourceClassSection!.displayName)
              : null,
          content: _buildSourceStep(context),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        // Step 2: Select students
        Step(
          title: const Text('Select Students'),
          subtitle: _selectedStudentIds.isNotEmpty
              ? Text('${_selectedStudentIds.length} selected')
              : null,
          content: _buildStudentsStep(context),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        // Step 3: Select destination
        Step(
          title: const Text('Select Destination'),
          subtitle: _destinationClassSection != null
              ? Text(_destinationClassSection!.displayName)
              : null,
          content: _buildDestinationStep(context),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
        // Step 4: Confirmation
        Step(
          title: const Text('Confirm Promotion'),
          content: _buildConfirmStep(context),
          isActive: _currentStep >= 3,
          state: _currentStep == 3 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildSourceStep(BuildContext context) {
    final classSectionsAsync = ref.watch(classSectionPairsProvider);

    return classSectionsAsync.when(
      data: (pairs) {
        if (pairs.isEmpty) {
          return const AppEmptyState(
            icon: LucideIcons.layoutGrid,
            title: 'No Classes Available',
            description: 'Add classes and sections first.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the class and section to promote students FROM:',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: pairs.map((pair) {
                final isSelected = _sourceClassSection == pair;
                return ChoiceChip(
                  label: Text(pair.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _sourceClassSection = selected ? pair : null;
                      _selectedStudentIds.clear();
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(classSectionPairsProvider),
      ),
    );
  }

  Widget _buildStudentsStep(BuildContext context) {
    if (_sourceClassSection == null) {
      return const Text('Please select a source class first.');
    }

    // Get students from the source class/section
    return FutureBuilder<List<StudentForPromotion>>(
      future: _getStudentsForPromotion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingIndicator();
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const AppEmptyState(
            icon: LucideIcons.users,
            title: 'No Students',
            description: 'No students enrolled in this class/section.',
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: PromotionStudentList(
            students: students,
            selectedIds: _selectedStudentIds,
            onSelectionChanged: (newSelection) {
              setState(() => _selectedStudentIds = newSelection);
            },
          ),
        );
      },
    );
  }

  Widget _buildDestinationStep(BuildContext context) {
    final classSectionsAsync = ref.watch(classSectionPairsProvider);

    return classSectionsAsync.when(
      data: (pairs) {
        // Filter out the source class/section
        final filteredPairs = pairs
            .where(
              (p) =>
                  _sourceClassSection == null ||
                  p.classId != _sourceClassSection!.classId ||
                  p.sectionId != _sourceClassSection!.sectionId,
            )
            .toList();

        if (filteredPairs.isEmpty) {
          return const AppEmptyState(
            icon: LucideIcons.layoutGrid,
            title: 'No Destination Available',
            description: 'Add more classes/sections.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select the class and section to promote students TO:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: filteredPairs.map((pair) {
                final isSelected = _destinationClassSection == pair;
                return ChoiceChip(
                  label: Text(pair.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _destinationClassSection = selected ? pair : null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => AppErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(classSectionPairsProvider),
      ),
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    final theme = Theme.of(context);

    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLoadingIndicator(),
            SizedBox(height: 16),
            Text('Processing promotions...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promotion Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context,
                  'Students to promote:',
                  '${_selectedStudentIds.length}',
                ),
                _buildSummaryRow(
                  context,
                  'From:',
                  _sourceClassSection?.displayName ?? '-',
                ),
                _buildSummaryRow(
                  context,
                  'To:',
                  _destinationClassSection?.displayName ?? '-',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.error),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'This action will:\n'
                  '• Close current enrollments\n'
                  '• Create new enrollments in destination class\n'
                  '• Assign new roll numbers automatically',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _processPromotions,
          icon: const Icon(LucideIcons.checkCircle),
          label: const Text('Confirm Promotion'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _handleStepContinue() {
    if (_currentStep == 0 && _sourceClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a source class/section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep == 1 && _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep == 2 && _destinationClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination class/section'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<List<StudentForPromotion>> _getStudentsForPromotion() async {
    if (_sourceClassSection == null) return [];

    final db = ref.read(databaseProvider);

    // Get students with active enrollments in the source class/section
    final query =
        db.select(db.enrollments).join([
            innerJoin(
              db.students,
              db.students.id.equalsExp(db.enrollments.studentId),
            ),
          ])
          ..where(
            db.enrollments.classId.equals(_sourceClassSection!.classId) &
                db.enrollments.sectionId.equals(
                  _sourceClassSection!.sectionId,
                ) &
                db.enrollments.isCurrent.equals(true) &
                db.enrollments.status.equals('active'),
          )
          ..orderBy([OrderingTerm.asc(db.enrollments.rollNumber)]);

    final results = await query.get();

    return results.map((row) {
      final student = row.readTable(db.students);
      final enrollment = row.readTable(db.enrollments);

      return StudentForPromotion(
        id: student.id,
        name: '${student.studentName} ${student.fatherName}',
        rollNumber: enrollment.rollNumber,
      );
    }).toList();
  }

  Future<void> _processPromotions() async {
    if (_selectedStudentIds.isEmpty ||
        _sourceClassSection == null ||
        _destinationClassSection == null) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final academicYear = await ref.read(currentAcademicYearProvider.future);
      final enrollmentRepo = ref.read(enrollmentRepositoryProvider);

      // Process each student
      for (final studentId in _selectedStudentIds) {
        await enrollmentRepo.promoteStudent(
          studentId,
          _destinationClassSection!.classId,
          _destinationClassSection!.sectionId,
          academicYear,
        );
      }

      if (mounted) {
        setState(() => _isProcessing = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully promoted ${_selectedStudentIds.length} students!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset the wizard
        setState(() {
          _currentStep = 0;
          _sourceClassSection = null;
          _destinationClassSection = null;
          _selectedStudentIds.clear();
        });

        // Invalidate relevant providers
        ref.invalidate(classSectionPairsProvider);
        ref.invalidate(classesWithStatsProvider);
        ref.invalidate(classStudentCountProvider);
        if (_sourceClassSection != null) {
          ref.invalidate(
            classStudentCountProvider(_sourceClassSection!.classId),
          );
        }
        if (_destinationClassSection != null) {
          ref.invalidate(
            classStudentCountProvider(_destinationClassSection!.classId),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
