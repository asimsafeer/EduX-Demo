/// EduX School Management System
/// User List Tile Widget - Display user in a list
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../database/database.dart';
import 'role_badge.dart';

/// A list tile widget for displaying a user
class UserListTile extends StatelessWidget {
  /// The user to display
  final User user;

  /// Callback when edit is tapped
  final VoidCallback? onEdit;

  /// Callback when toggle active is tapped
  final VoidCallback? onToggleActive;

  /// Callback when reset password is tapped
  final VoidCallback? onResetPassword;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.user,
    this.onEdit,
    this.onToggleActive,
    this.onResetPassword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: user.isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ),
                        RoleBadge(role: user.role, size: RoleBadgeSize.small),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.username,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (!user.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Inactive',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        if (user.isSystemAdmin)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'System Admin',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (user.lastLogin != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last login: ${_formatDateTime(user.lastLogin!)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (onEdit != null ||
                  onToggleActive != null ||
                  onResetPassword != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'toggle':
                        onToggleActive?.call();
                        break;
                      case 'reset':
                        onResetPassword?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit2, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onResetPassword != null)
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(LucideIcons.keyRound, size: 18),
                            SizedBox(width: 12),
                            Text('Reset Password'),
                          ],
                        ),
                      ),
                    if (onToggleActive != null && !user.isSystemAdmin)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              user.isActive
                                  ? LucideIcons.userMinus
                                  : LucideIcons.userCheck,
                              size: 18,
                              color: user.isActive
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              user.isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                color: user.isActive
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _getInitials(user.fullName);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getAvatarColor(user.role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '?';
    
    final parts = trimmedName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'principal':
        return AppColors.info;
      case 'teacher':
        return AppColors.success;
      case 'accountant':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
