/// EduX School Management System
/// Staff Search Bar Widget
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/staff_provider.dart';

/// Search bar for staff list
class StaffSearchBar extends ConsumerStatefulWidget {
  const StaffSearchBar({super.key});

  @override
  ConsumerState<StaffSearchBar> createState() => _StaffSearchBarState();
}

class _StaffSearchBarState extends ConsumerState<StaffSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(staffFiltersProvider.notifier)
          .setSearchQuery(query.isEmpty ? null : query);
    });
  }

  void _onClear() {
    _controller.clear();
    ref.read(staffFiltersProvider.notifier).setSearchQuery(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, ID, phone...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _onClear,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
