/// EduX School Management System
/// Academic Settings Screen - Manage academic years
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';
import '../../../providers/providers.dart';

/// Screen for managing academic years and sessions
class AcademicSettingsScreen extends ConsumerStatefulWidget {
  const AcademicSettingsScreen({super.key});

  @override
  ConsumerState<AcademicSettingsScreen> createState() =>
      _AcademicSettingsScreenState();
}

class _AcademicSettingsScreenState
    extends ConsumerState<AcademicSettingsScreen> {
  Future<void> _createAcademicYear() async {
    final year = await showDialog<AcademicYearFormData>(
      context: context,
      builder: (context) => const _AcademicYearFormDialog(),
    );

    if (year == null) return;

    try {
      final service = ref.read(schoolSettingsServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      await service.createAcademicYear(
        name: year.name,
        startDate: year.startDate,
        endDate: year.endDate,
        setAsCurrent: year.setAsCurrent,
      );

      await activityLog.logCreate(
        userId: currentUser?.id,
        module: 'settings',
        entityType: 'academic_year',
        entityId: 0,
        description: 'Created academic year "${year.name}"',
      );

      ref.invalidate(academicYearsProvider);
      ref.invalidate(currentAcademicYearProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Academic year "${year.name}" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _setAsCurrent(AcademicYear year) async {
    try {
      final service = ref.read(schoolSettingsServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      await service.setCurrentAcademicYear(year.id);

      await activityLog.logUpdate(
        userId: currentUser?.id,
        module: 'settings',
        entityType: 'academic_year',
        entityId: year.id,
        description: 'Set "${year.name}" as current academic year',
      );

      ref.invalidate(academicYearsProvider);
      ref.invalidate(currentAcademicYearProvider);
      ref.invalidate(schoolSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${year.name} is now the current year')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _archiveYear(AcademicYear year) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Academic Year?'),
        content: Text(
          'Archive "${year.name}"? This will mark it as inactive but preserve all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(schoolSettingsServiceProvider);
      await service.archiveAcademicYear(year.id);

      ref.invalidate(academicYearsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${year.name} has been archived')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final currentYear = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current year card
                  _buildCurrentYearCard(currentYear),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic Years',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _createAcademicYear,
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('New Year'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Years list
                  yearsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (years) => years.isEmpty
                        ? _buildEmptyState()
                        : _buildYearsList(years),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Settings',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage academic years and sessions',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentYearCard(AsyncValue<AcademicYear?> currentYear) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.calendarCheck,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Academic Year',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                currentYear.when(
                  loading: () => Text(
                    'Loading...',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Unable to load',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  data: (year) => year == null
                      ? Text(
                          'No active year',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              year.name,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat.yMMMd().format(year.startDate)} - ${DateFormat.yMMMd().format(year.endDate)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearsList(List<AcademicYear> years) {
    return Column(children: years.map((year) => _buildYearTile(year)).toList());
  }

  Widget _buildYearTile(AcademicYear year) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: year.isCurrent ? AppColors.success : AppColors.border,
          width: year.isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (year.isCurrent ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.calendar,
              color: year.isCurrent ? AppColors.success : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      year.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: year.isArchived
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (year.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (year.isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Archived',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat.yMMMd().format(year.startDate)} - ${DateFormat.yMMMd().format(year.endDate)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (!year.isCurrent && !year.isArchived)
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                color: AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'activate') {
                  _setAsCurrent(year);
                } else if (value == 'archive') {
                  _archiveYear(year);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'activate',
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, size: 18),
                      SizedBox(width: 12),
                      Text('Set as Current'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(LucideIcons.archive, size: 18),
                      SizedBox(width: 12),
                      Text('Archive'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(LucideIcons.calendar, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No academic years',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first academic year to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Form dialog for creating academic year
class _AcademicYearFormDialog extends StatefulWidget {
  const _AcademicYearFormDialog();

  @override
  State<_AcademicYearFormDialog> createState() =>
      _AcademicYearFormDialogState();
}

class _AcademicYearFormDialogState extends State<_AcademicYearFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _setAsCurrent = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      AcademicYearFormData(
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        setAsCurrent: _setAsCurrent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Academic Year'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., 2024-2025',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Date', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _selectStartDate,
                        child: Text(DateFormat.yMMMd().format(_startDate)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('End Date', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _selectEndDate,
                        child: Text(DateFormat.yMMMd().format(_endDate)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _setAsCurrent,
              onChanged: (value) => setState(() => _setAsCurrent = value!),
              title: const Text('Set as current year'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Create')),
      ],
    );
  }
}

class AcademicYearFormData {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool setAsCurrent;

  AcademicYearFormData({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.setAsCurrent,
  });
}
