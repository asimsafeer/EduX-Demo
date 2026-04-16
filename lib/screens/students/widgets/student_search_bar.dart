/// EduX School Management System
/// Student Search Bar - Search field with debouncing
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/student_provider.dart';

/// Search bar with debounced search for students
class StudentSearchBar extends ConsumerStatefulWidget {
  const StudentSearchBar({super.key});

  @override
  ConsumerState<StudentSearchBar> createState() => _StudentSearchBarState();
}

class _StudentSearchBarState extends ConsumerState<StudentSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize with current search query
    final currentQuery = ref.read(studentFiltersProvider).searchQuery;
    if (currentQuery != null) {
      _controller.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(studentFiltersProvider.notifier)
          .setSearchQuery(value.isEmpty ? null : value);
    });
  }

  void _onClear() {
    _controller.clear();
    ref.read(studentFiltersProvider.notifier).setSearchQuery(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name or admission number...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _onClear)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
