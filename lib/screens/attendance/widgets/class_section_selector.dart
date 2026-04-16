/// EduX School Management System
/// Class Section Selector Widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/academics_provider.dart';

/// Combined class and section dropdown selector
class ClassSectionSelector extends ConsumerWidget {
  final int? selectedClassId;
  final int? selectedSectionId;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<int?> onSectionChanged;
  final bool showAllOption;
  final bool isCompact;
  final bool isEnabled;

  /// When non-null, only classes with these IDs are shown in the dropdown.
  /// Null means show all classes (for admin/principal).
  final List<int>? assignedClassIds;

  const ClassSectionSelector({
    super.key,
    required this.selectedClassId,
    required this.selectedSectionId,
    required this.onClassChanged,
    required this.onSectionChanged,
    this.showAllOption = false,
    this.isCompact = false,
    this.isEnabled = true,
    this.assignedClassIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Class Dropdown
        SizedBox(
          width: isCompact ? 120 : 160,
          child: classesAsync.when(
            data: (classes) {
              // Filter by assigned class IDs if provided
              final filtered = assignedClassIds != null
                  ? classes
                        .where((c) => assignedClassIds!.contains(c.id))
                        .toList()
                  : classes;
              return _buildClassDropdown(context, filtered);
            },
            loading: () => _buildLoadingDropdown(context),
            error: (_, __) => _buildErrorDropdown(context),
          ),
        ),
        SizedBox(width: isCompact ? 8 : 16),
        // Section Dropdown
        SizedBox(
          width: isCompact ? 100 : 140,
          child: selectedClassId == null
              ? _buildDisabledDropdown(context)
              : _SectionDropdown(
                  classId: selectedClassId!,
                  selectedSectionId: selectedSectionId,
                  onSectionChanged: onSectionChanged,
                  showAllOption: showAllOption,
                  isCompact: isCompact,
                  isEnabled: isEnabled,
                ),
        ),
      ],
    );
  }

  Widget _buildClassDropdown(BuildContext context, List<dynamic> classes) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      initialValue: selectedClassId,
      hint: const Text('Select Class'),
      items: classes
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id as int,
              child: Text(c.name as String),
            ),
          )
          .toList(),
      onChanged: isEnabled
          ? (v) {
              onClassChanged(v);
              if (v != selectedClassId) onSectionChanged(null);
            }
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: isCompact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
    );
  }

  Widget _buildLoadingDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading...'),
        ],
      ),
    );
  }

  Widget _buildErrorDropdown(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red),
    ),
    child: const Text('Error'),
  );

  Widget _buildDisabledDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      initialValue: null,
      hint: const Text('Section'),
      items: const [],
      onChanged: null,
      decoration: InputDecoration(
        isDense: isCompact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
    );
  }
}

class _SectionDropdown extends ConsumerWidget {
  final int classId;
  final int? selectedSectionId;
  final ValueChanged<int?> onSectionChanged;
  final bool showAllOption;
  final bool isCompact;
  final bool isEnabled;

  const _SectionDropdown({
    required this.classId,
    required this.selectedSectionId,
    required this.onSectionChanged,
    this.showAllOption = false,
    this.isCompact = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(sectionsByClassProvider(classId));

    return sectionsAsync.when(
      data: (sections) {
        if (selectedSectionId == null && sections.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onSectionChanged(sections.first.id),
          );
        }
        return DropdownButtonFormField<int>(
          initialValue: selectedSectionId,
          hint: const Text('Section'),
          items: sections
              .map(
                (s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
              )
              .toList(),
          onChanged: isEnabled ? onSectionChanged : null,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: isCompact,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isCompact ? 8 : 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
          ),
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const Text('Error'),
    );
  }
}
