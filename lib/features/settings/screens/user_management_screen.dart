/// EduX School Management System
/// User Management Screen - List and manage users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';
import '../../../providers/providers.dart';
import '../../../router/app_router.dart';
import '../../../services/services.dart';
import '../widgets/widgets.dart';

/// Screen for managing user accounts
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  String? _selectedRole;
  bool? _showActive;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    ref.read(userListFilterProvider.notifier).state = UserListFilter(
      role: _selectedRole,
      isActive: _showActive,
      searchQuery: _searchController.text,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = null;
      _showActive = null;
    });
    ref.read(userListFilterProvider.notifier).state = const UserListFilter();
  }

  Future<void> _toggleUserActive(int userId) async {
    try {
      final userService = ref.read(userServiceProvider);
      final activityLog = ref.read(activityLogServiceProvider);
      final currentUser = ref.read(currentUserProvider);

      final user = await userService.toggleUserActive(userId);

      await activityLog.logUpdate(
        userId: currentUser?.id,
        module: 'users',
        entityType: 'user',
        entityId: userId,
        description: user.isActive
            ? 'Activated user "${user.fullName}"'
            : 'Deactivated user "${user.fullName}"',
      );

      ref.invalidate(userListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isActive
                  ? 'User activated successfully'
                  : 'User deactivated successfully',
            ),
          ),
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

  Future<void> _resetPassword(int userId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a new password for this user:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      try {
        final userService = ref.read(userServiceProvider);
        final activityLog = ref.read(activityLogServiceProvider);
        final currentUser = ref.read(currentUserProvider);

        await userService.resetPassword(
          id: userId,
          newPassword: controller.text,
        );

        await activityLog.logUpdate(
          userId: currentUser?.id,
          module: 'users',
          entityType: 'user',
          entityId: userId,
          description: 'Reset password for user',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully')),
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
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Filters
          _buildFilters(),

          // User list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stackTrace) {
                debugPrint('User list error: $e');
                debugPrint('Stack trace: $stackTrace');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(userListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              data: (users) {
                try {
                  return users.isEmpty ? _buildEmptyState() : _buildUserList(users);
                } catch (e, stackTrace) {
                  debugPrint('Error building user list: $e');
                  debugPrint('Stack trace: $stackTrace');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error displaying users',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(userListProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
              },
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
                  'Login Credentials',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage login credentials and roles for staff',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.push('${AppRoutes.users}/new'),
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('Add Credentials'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasFilters =
        _searchController.text.isNotEmpty ||
        _selectedRole != null ||
        _showActive != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _updateFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _updateFilters(),
            ),
          ),
          const SizedBox(width: 16),

          // Role filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Role',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Roles')),
                ...UserService.validRoles.map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(UserService.getRoleDisplayName(role)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRole = value);
                _updateFilters();
              },
            ),
          ),
          const SizedBox(width: 16),

          // Status filter
          Expanded(
            child: DropdownButtonFormField<bool?>(
              initialValue: _showActive,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() => _showActive = value);
                _updateFilters();
              },
            ),
          ),

          // Clear filters
          if (hasFilters) ...[
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(LucideIcons.filterX, size: 18),
              label: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> users) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return UserListTile(
          user: user,
          onEdit: () => context.push('${AppRoutes.users}/${user.id}'),
          onToggleActive: user.isSystemAdmin
              ? null
              : () => _toggleUserActive(user.id),
          onResetPassword: () => _resetPassword(user.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create login credentials for a staff member',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('${AppRoutes.users}/new'),
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('Add Credentials'),
          ),
        ],
      ),
    );
  }
}
