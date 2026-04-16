/// EduX School Management System
/// Guardian List Screen - Display all guardians with search
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../providers/guardian_provider.dart';
import '../../database/app_database.dart';

class GuardianListScreen extends ConsumerStatefulWidget {
  const GuardianListScreen({super.key});

  @override
  ConsumerState<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends ConsumerState<GuardianListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardiansAsync = ref.watch(allGuardiansProvider);
    final theme = Theme.of(context);

    // Filter guardians if search query exists
    // Note: In a real app with many records, search should be handled by the provider/database
    // For now we filter locally since we load all guardians

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardians'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () => context.go('/guardians/add'),
            tooltip: 'Add Guardian',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or CNIC',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Guardians List
          Expanded(
            child: guardiansAsync.when(
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, stack) => AppErrorState(
                message: 'Failed to load guardians',
                onRetry: () => ref.refresh(allGuardiansProvider),
              ),
              data: (guardians) {
                if (guardians.isEmpty) {
                  return AppEmptyState(
                    title: 'No Guardians Found',
                    description: 'Start by adding a new guardian.',
                    icon: LucideIcons.users,
                    actionText: 'Add Guardian',
                    onAction: () => context.go('/guardians/add'),
                  );
                }

                final filteredGuardians = _filterGuardians(guardians);

                if (filteredGuardians.isEmpty) {
                  return AppEmptyState(
                    title: 'No Matches Found',
                    description: 'Try adjusting your search query.',
                    icon: LucideIcons.searchX,
                    actionText: 'Clear Search',
                    onAction: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredGuardians.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final guardian = filteredGuardians[index];
                    return _buildGuardianCard(context, guardian, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Guardian> _filterGuardians(List<Guardian> guardians) {
    if (_searchQuery.isEmpty) return guardians;

    final query = _searchQuery.toLowerCase();
    return guardians.where((g) {
      final name = '${g.firstName} ${g.lastName}'.toLowerCase();
      final phone = g.phone.toLowerCase();
      final cnic = g.cnic?.toLowerCase() ?? '';
      return name.contains(query) ||
          phone.contains(query) ||
          cnic.contains(query);
    }).toList();
  }

  Widget _buildGuardianCard(
    BuildContext context,
    Guardian guardian,
    ThemeData theme,
  ) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/guardians/${guardian.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${guardian.firstName[0]}${guardian.lastName[0]}'
                      .toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guardian.firstName} ${guardian.lastName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guardian.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guardian.relation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(LucideIcons.chevronRight, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
