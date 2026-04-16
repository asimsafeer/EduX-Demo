import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Data model for student promotion selection
class StudentForPromotion {
  final int id;
  final String name;
  final String? rollNumber; // Changed to String? to match DB schema
  final bool isPassing; // For visual indication if needed

  StudentForPromotion({
    required this.id,
    required this.name,
    this.rollNumber,
    this.isPassing = true,
  });
}

/// A widget for selecting multiple students from a list
class PromotionStudentList extends StatefulWidget {
  final List<StudentForPromotion> students;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onSelectionChanged;

  const PromotionStudentList({
    super.key,
    required this.students,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<PromotionStudentList> createState() => _PromotionStudentListState();
}

class _PromotionStudentListState extends State<PromotionStudentList> {
  final TextEditingController _searchController = TextEditingController();
  List<StudentForPromotion> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
    _searchController.addListener(_filterStudents);
  }

  @override
  void didUpdateWidget(PromotionStudentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students != widget.students) {
      _filterStudents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      if (mounted) setState(() => _filteredStudents = widget.students);
      return;
    }

    if (mounted) {
      setState(() {
        _filteredStudents = widget.students.where((s) {
          final nameMatch = s.name.toLowerCase().contains(query);
          final rollMatch =
              s.rollNumber?.toLowerCase().contains(query) ?? false;
          return nameMatch || rollMatch;
        }).toList();
      });
    }
  }

  void _toggleAll(bool? value) {
    final newSelection = Set<int>.from(widget.selectedIds);
    if (value == true) {
      // Select all currently filtered students
      newSelection.addAll(_filteredStudents.map((s) => s.id));
    } else {
      // Deselect all currently filtered students
      newSelection.removeAll(_filteredStudents.map((s) => s.id));
    }
    widget.onSelectionChanged(newSelection);
  }

  void _toggleStudent(int id, bool? value) {
    final newSelection = Set<int>.from(widget.selectedIds);
    if (value == true) {
      newSelection.add(id);
    } else {
      newSelection.remove(id);
    }
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected =
        _filteredStudents.isNotEmpty &&
        _filteredStudents.every((s) => widget.selectedIds.contains(s.id));
    final someSelected =
        _filteredStudents.isNotEmpty &&
        _filteredStudents.any((s) => widget.selectedIds.contains(s.id)) &&
        !allSelected;

    return Column(
      children: [
        // Search and Global Actions
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Students',
                    hintText: 'Search by name or roll no.',
                    prefixIcon: Icon(LucideIcons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Select All functionality
              FilterChip(
                label: const Text('All'),
                selected: allSelected,
                onSelected: (_) => _toggleAll(!allSelected),
                avatar: Icon(
                  allSelected
                      ? LucideIcons.checkSquare
                      : someSelected
                      ? LucideIcons.minusSquare
                      : LucideIcons.square,
                  size: 16,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filteredStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 48,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No students found.'
                            : 'No matches found.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredStudents.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    final isSelected = widget.selectedIds.contains(student.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) => _toggleStudent(student.id, val),
                      title: Text(student.name),
                      subtitle: Text('Roll No: ${student.rollNumber ?? '-'}'),
                      secondary: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name.substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
